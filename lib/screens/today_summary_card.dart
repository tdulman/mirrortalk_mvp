// lib/screens/today_summary_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class TodaySummaryCard extends StatefulWidget {
  const TodaySummaryCard({super.key});

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  final _goalCtrls = List.generate(3, (_) => TextEditingController());
  final _checks = [false, false, false];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final today = DateTime.now().toUtc();
    final entry = await StorageService.findByDay(today);
    if (entry?.summary != null) {
      final s = entry!.summary!;
      for (var i = 0; i < 3; i++) {
        _goalCtrls[i].text = (i < s.goals.length) ? s.goals[i] : '';
        _checks[i] = (i < s.eveningChecks.length) ? s.eveningChecks[i] : false;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _goalCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final todayUtc = DateTime.now().toUtc();
    final existing = await StorageService.findByDay(todayUtc);

    final summary = DaySummary(
      goals: _goalCtrls.map((e) => e.text.trim()).toList(),
      eveningChecks: List<bool>.from(_checks),
    );

    if (existing != null) {
      await StorageService.upsert(existing.copyWith(summary: summary));
    } else {
      // O gün hiç kayıt yoksa “sanal” bir entry açalım (type: morning, duration 0)
      final id = const Uuid().v4();
      final e = Entry(
        id: id,
        type: RecordType.morning,
        createdAt: DateTime.now().toUtc(),
        durationSec: 0,
        transcript: null,
        tags: const [],
        videoPath: null,
        summary: summary,
      );
      await StorageService.upsert(e);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today Summary – $dateStr',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Morning Goals',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++) ...[
              TextField(
                controller: _goalCtrls[i],
                decoration: InputDecoration(hintText: 'Goal ${i + 1}'),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(
              'Evening Check',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Completed goal ${i + 1}'),
                value: _checks[i],
                onChanged: (v) => setState(() => _checks[i] = v ?? false),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
