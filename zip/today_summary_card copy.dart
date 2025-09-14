// lib/screens/today_summary_card.dart
import 'package:flutter/material.dart';

import '../models/day_summary.dart';
import '../services/storage_service.dart';

class TodaySummaryCard extends StatefulWidget {
  final DaySummary summary;
  final ValueChanged<DaySummary>? onChanged;

  const TodaySummaryCard({
    super.key,
    required this.summary,
    this.onChanged,
  });

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  late DaySummary _summary;

  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  final _g3 = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _summary = _normalize(widget.summary);
    _g1.text = _summary.goals[0];
    _g2.text = _summary.goals[1];
    _g3.text = _summary.goals[2];
  }

  @override
  void dispose() {
    _g1.dispose();
    _g2.dispose();
    _g3.dispose();
    super.dispose();
  }

  DaySummary _normalize(DaySummary s) {
    // Liste uzunluklarını garanti et
    final goals = List<String>.from(s.goals);
    final done = List<bool>.from(s.done);
    while (goals.length < 3) goals.add('');
    while (done.length < 3) done.add(false);
    return s.copyWith(goals: goals, done: done);
  }

  void _toggle(int index, bool value) {
    final next = List<bool>.from(_summary.done);
    next[index] = value;

    setState(() {
      _summary = _summary.copyWith(done: next);
    });

    StorageService.upsertDaySummary(_summary);
    widget.onChanged?.call(_summary);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final newGoals = <String>[
      _g1.text.trim(),
      _g2.text.trim(),
      _g3.text.trim(),
    ];

    final updated = _summary.copyWith(goals: newGoals);
    setState(() => _summary = updated);

    await StorageService.upsertDaySummary(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Today summary saved')),
    );

    widget.onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Summary • ${_summary.dayKey}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            _GoalRow(
              label: 'Goal 1',
              controller: _g1,
              value: _summary.done[0],
              onChanged: (v) => _toggle(0, v),
            ),
            const SizedBox(height: 8),
            _GoalRow(
              label: 'Goal 2',
              controller: _g2,
              value: _summary.done[1],
              onChanged: (v) => _toggle(1, v),
            ),
            const SizedBox(height: 8),
            _GoalRow(
              label: 'Goal 3',
              controller: _g3,
              value: _summary.done[2],
              onChanged: (v) => _toggle(2, v),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GoalRow({
    required this.label,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
