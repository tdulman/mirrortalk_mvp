import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import '../l10n/generated/app_localizations.dart';
import '../models/day_summary.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.intentionSaved)),
    );
    widget.onChanged(_s);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryCardTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _goalRow(0, hint: l10n.goalHintRead),
            const SizedBox(height: AppSpacing.xxs),
            _goalRow(1, hint: l10n.goalHintEmail),
            const SizedBox(height: AppSpacing.xxs),
            _goalRow(2, hint: l10n.goalHintWalk),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _save,
                style: OutlinedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.saveIntention),
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
          visualDensity: VisualDensity.compact,
          onChanged: (v) => _toggleDone(i, v ?? false),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: TextField(
            controller: _controllers[i],
            style: Theme.of(context).textTheme.bodyMedium,
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
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              hintStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.inkMuted),
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }
}
