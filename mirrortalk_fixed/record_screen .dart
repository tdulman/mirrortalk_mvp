// lib/screens/record_screen.dart
import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../models/day_summary.dart';
import '../services/storage_service.dart';
import '../services/goal_suggester.dart';
import 'voice_record_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  RecordType _type = RecordType.morning;
  final _transcriptCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');

  @override
  void dispose() {
    _transcriptCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    final transcript = _transcriptCtrl.text.trim();

    // 1) Save entry
    final entry = Entry(
      id: id,
      type: _type,
      createdAt: DateTime.now(),
      durationSec: duration,
      transcript: transcript.isEmpty ? null : transcript,
      tags: const [],
    );
    await StorageService.appendEntry(entry);

    // 2) Suggest goals from transcript (MVP heuristic)
    final suggestions = GoalSuggester.suggest(transcript, maxGoals: 3);

    // 3) Show suggestion sheet → Apply will write to today's DaySummary
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SuggestionSheet(suggestions: suggestions),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true); // signal list to reload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Record')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Type'),
            const SizedBox(height: 6),
            SegmentedButton<RecordType>(
              segments: const [
                ButtonSegment(
                    value: RecordType.morning, label: Text('Morning')),
                ButtonSegment(
                    value: RecordType.evening, label: Text('Evening')),
              ],
              selected: <RecordType>{_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (sec)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _transcriptCtrl,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Transcript (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final res = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const VoiceRecordScreen()),
                );
                if (res != null && res.trim().isNotEmpty) {
                  _transcriptCtrl.text = res.trim();
                }
              },
              icon: const Icon(Icons.mic),
              label: const Text('Record voice'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionSheet extends StatefulWidget {
  final List<String> suggestions;
  const _SuggestionSheet({required this.suggestions});

  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  late final TextEditingController g1;
  late final TextEditingController g2;
  late final TextEditingController g3;

  @override
  void initState() {
    super.initState();
    g1 = TextEditingController(
        text: widget.suggestions.isNotEmpty ? widget.suggestions[0] : '');
    g2 = TextEditingController(
        text: widget.suggestions.length > 1 ? widget.suggestions[1] : '');
    g3 = TextEditingController(
        text: widget.suggestions.length > 2 ? widget.suggestions[2] : '');
  }

  @override
  void dispose() {
    g1.dispose();
    g2.dispose();
    g3.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final today = await StorageService.getDaySummary(DateTime.now());
    final newGoals = <String>[g1.text.trim(), g2.text.trim(), g3.text.trim()];
    final updated = today.copyWith(goals: newGoals);
    await StorageService.upsertDaySummary(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggested goals',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: g1,
            decoration: const InputDecoration(
                labelText: 'Goal 1',
                border: OutlineInputBorder(),
                isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: g2,
            decoration: const InputDecoration(
                labelText: 'Goal 2',
                border: OutlineInputBorder(),
                isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: g3,
            decoration: const InputDecoration(
                labelText: 'Goal 3',
                border: OutlineInputBorder(),
                isDense: true),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apply,
              child: const Text('Apply to Today'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
