import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';
import '../services/storage_service.dart';

class TodaySummaryCard extends StatefulWidget {
  const TodaySummaryCard({super.key});

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  bool _loading = true;
  late DaySummary _summary;

  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  final _g3 = TextEditingController();

  bool _c1 = false;
  bool _c2 = false;
  bool _c3 = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now();
    final s = await StorageService.loadDaySummary(today);
    if (!mounted) return;

    setState(() {
      _summary = s;
      _g1.text = s.goals[0] ?? '';
      _g2.text = s.goals[1] ?? '';
      _g3.text = s.goals[2] ?? '';
      _c1 = s.completed[0] ?? false;
      _c2 = s.completed[1] ?? false;
      _c3 = s.completed[2] ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final updated = _summary.copyWith(
      goals: [_g1.text.trim(), _g2.text.trim(), _g3.text.trim()],
      completed: [_c1, _c2, _c3],
    );
    await StorageService.upsertDaySummary(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
  }

  @override
  void dispose() {
    _g1.dispose();
    _g2.dispose();
    _g3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              "Today's Summary – $dateStr",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Morning Goals
            Text('Morning Goals',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _g1,
              decoration: const InputDecoration(
                hintText: 'Goal 1',
                border: UnderlineInputBorder(),
              ),
            ),
            TextField(
              controller: _g2,
              decoration: const InputDecoration(
                hintText: 'Goal 2',
                border: UnderlineInputBorder(),
              ),
            ),
            TextField(
              controller: _g3,
              decoration: const InputDecoration(
                hintText: 'Goal 3',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Evening Check
            Text('Evening Check',
                style: Theme.of(context).textTheme.titleSmall),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed goal 1'),
              value: _c1,
              onChanged: (v) => setState(() => _c1 = v ?? false),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed goal 2'),
              value: _c2,
              onChanged: (v) => setState(() => _c2 = v ?? false),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed goal 3'),
              value: _c3,
              onChanged: (v) => setState(() => _c3 = v ?? false),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            const SizedBox(height: 8),

            // Save
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

