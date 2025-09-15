import 'package:flutter/material.dart';
import '../models/day_summary.dart';
import '../services/storage_service.dart';

class TodaySummaryCard extends StatefulWidget {
  final DaySummary summary;
  final ValueChanged<DaySummary> onChanged;
  const TodaySummaryCard({super.key, required this.summary, required this.onChanged});

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  late DaySummary _s;

  @override
  void initState() {
    super.initState();
    _s = widget.summary;
  }

  Future<void> _save() async {
    await StorageService.upsertDaySummary(_s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved today's summary")),
    );
    widget.onChanged(_s);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Summary",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _goalRow(0, hint: 'e.g., Read 20 pages of a book'),
            const SizedBox(height: 8),
            _goalRow(1, hint: 'e.g., Send 1 important email'),
            const SizedBox(height: 8),
            _goalRow(2, hint: 'e.g., Take a 15-min walk'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(int i, {required String hint}) {
    final goal = (_s.goals.length > i ? _s.goals[i] : '');
    final done = (_s.done.length > i ? _s.done[i] : false);
    return Row(
      children: [
        Checkbox(
          value: done,
          onChanged: (v) => setState(() {
            while (_s.done.length <= i) _s.done.add(false);
            _s.done[i] = v ?? false;
          }),
        ),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: goal),
            onChanged: (v) => setState(() {
              while (_s.goals.length <= i) _s.goals.add('');
              _s.goals[i] = v;
            }),
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
