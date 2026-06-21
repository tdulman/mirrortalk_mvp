import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import '../models/day_summary.dart';
import '../services/storage_service.dart';

class TodaySummaryCard extends StatefulWidget {
  final DaySummary summary;
  final ValueChanged<DaySummary> onChanged;

  const TodaySummaryCard({
    super.key,
    required this.summary,
    required this.onChanged,
  });

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  late DaySummary _s;

  // Text alanları için controller listesi
  final List<TextEditingController> _controllers =
      List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _s = widget.summary;
    _syncControllersFromModel();
  }

  // Parent yeni summary gönderirse controllerları güncelle
  @override
  void didUpdateWidget(covariant TodaySummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary) {
      _s = widget.summary;
      _syncControllersFromModel();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllersFromModel() {
    for (int i = 0; i < 3; i++) {
      final txt = (_s.goals.length > i) ? _s.goals[i] : '';
      _controllers[i].text = txt;
      _controllers[i].selection =
          TextSelection.collapsed(offset: _controllers[i].text.length);
    }
  }

  // === Toggle helper (hafif titreşim dahil) ===
  void _toggleDone(int index, bool value) {
    setState(() {
      while (_s.done.length <= index) {
        _s.done.add(false);
      }
      _s.done[index] = value;
    });
    HapticFeedback.lightImpact();

    // Değişikliği yukarıya ANINDA iletmek istersen aç:
    // widget.onChanged(_s);
  }

  Future<void> _save() async {
    await StorageService.upsertDaySummary(_s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Today's summary saved")),
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
            Text(
              "Today's Summary",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _goalRow(0, hint: 'e.g., Read 20 pages of a book'),
            const SizedBox(height: 8),
            _goalRow(1, hint: 'e.g., Send 1 important email'),
            const SizedBox(height: 8),
            _goalRow(2, hint: 'e.g., Take a 15-min walk'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save Summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(int i, {required String hint}) {
    final done = (_s.done.length > i ? _s.done[i] : false);

    return Row(
      children: [
        Checkbox(
          value: done,
          onChanged: (v) => _toggleDone(i, v ?? false),
        ),
        Expanded(
          child: TextField(
            controller: _controllers[i],
            onChanged: (v) {
              setState(() {
                while (_s.goals.length <= i) {
                  _s.goals.add('');
                }
                _s.goals[i] = v;
              });
              // Değişikliği yukarıya ANINDA iletmek istersen aç:
              // widget.onChanged(_s);
            },
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }
}
