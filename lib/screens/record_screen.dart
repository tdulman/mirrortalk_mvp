// lib/screens/record_screen.dart
import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  RecordType _type = RecordType.morning;
  final _durationCtrl = TextEditingController(text: '60');
  final _transcriptCtrl = TextEditingController();

  @override
  void dispose() {
    _durationCtrl.dispose();
    _transcriptCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    final entry = Entry(
      id: id,
      type: _type,
      createdAt: DateTime.now(),
      durationSec: duration,
      transcript:
          _transcriptCtrl.text.trim().isEmpty ? null : _transcriptCtrl.text.trim(),
      tags: const [],
    );
    await StorageService.appendEntry(entry);
    if (!mounted) return;
    Navigator.of(context).pop(true); // true => listeyi yenile
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
                ButtonSegment(value: RecordType.morning, label: Text('Morning')),
                ButtonSegment(value: RecordType.evening, label: Text('Evening')),
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
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Transcript (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

