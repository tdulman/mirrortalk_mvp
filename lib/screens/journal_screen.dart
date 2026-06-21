// lib/screens/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/day_summary.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

import 'today_summary_card.dart';
import 'record_screen.dart';
import 'entry_detail_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';
import '../services/prefs_service.dart';

enum FilterRange { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // -------- State --------
  FilterRange _range = FilterRange.today;
  final List<Entry> _all = <Entry>[];
  bool _loading = true;

  DaySummary? _todaySummary;
  StreakInfo? _streak;
  bool _celebratedToday = false;

  // -------- Lifecycle --------
  @override
  void initState() {
    super.initState();
    _load();
    _maybeShowOnboarding(); // first-run onboarding
  }

  // Show onboarding only on first run, refresh after user completes
  Future<void> _maybeShowOnboarding() async {
    final firstRun = await PrefsService.isFirstRun();
    if (!firstRun) return;

    if (!mounted) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );

    if (done == true && mounted) {
      await _reload();
    }
  }

  // -------- Data loading --------
  Future<void> _load() async {
    setState(() => _loading = true);

    // load entries
    final items = await StorageService.loadEntries();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // today summary
    final today = await StorageService.getDaySummary(DateTime.now());

    // habit-true streak in last 120 days
    final since = DateTime.now().subtract(const Duration(days: 120));
    final streak = await StreakService.computeHabitTrue(
      since: since,
      getDaySummary: StorageService.getDaySummary,
    );

    if (!mounted) return;
    setState(() {
      _all
        ..clear()
        ..addAll(items);
      _todaySummary = today;
      _streak = streak;
      _loading = false;
    });

    // tiny celebration: if there is an entry today and we haven't shown it yet
    final todayKey = DaySummary.makeDayKey(DateTime.now());
    final todayHasEntry =
        items.any((e) => DaySummary.makeDayKey(e.createdAt) == todayKey);
    if (todayHasEntry && !_celebratedToday) {
      _celebratedToday = true;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nice! You're on a habit streak — keep it going 🔥"),
        ),
      );
    }
  }

  Future<void> _reload() async => _load();

  List<Entry> _filtered() {
    // (currently no filtering logic other than the chips for Today card)
    return _all;
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteEntry(id);
    await _reload();
  }

  Future<void> _onAddPressed() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RecordScreen()),
    );
    if (changed == true) await _reload();
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final l10n = AppLocalizations.of(context);
    final ritual = _RitualMoment.now(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (changed == true && mounted) {
                setState(() {}); // refresh if settings affected anything
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    112,
                  ),
                  children: [
                    _RitualCard(
                      ritual: ritual,
                      onStart: _onAddPressed,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.todaysIntention,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_range == FilterRange.today) ...[
                      TodaySummaryCard(
                        summary: _todaySummary ??
                            DaySummary.emptyFor(DateTime.now()),
                        onChanged: (s) => setState(() => _todaySummary = s),
                      ),
                    ],
                    if (_streak != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _StreakCard(
                        current: _streak!.current,
                        longest: _streak!.longest,
                        thisWeekDays: _streak!.thisWeekDays,
                        goalsDoneThisWeek: _streak!.goalsDoneThisWeek,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.recentReflections,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _filterChips(l10n),
                    const SizedBox(height: AppSpacing.xs),
                    if (list.isEmpty)
                      _EmptyState(onAdd: _onAddPressed)
                    else ...[
                      Text(
                        'From ${DateFormat('yyyy-MM-dd').format(list.last.createdAt)} '
                        'to ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      ...list.map(
                        (e) => _EntryTile(
                          entry: e,
                          onDelete: () => _delete(e.id),
                          onChanged: _reload,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _onAddPressed,
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(l10n.startMirrorTalk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChips(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.filterToday),
          selected: _range == FilterRange.today,
          onSelected: (_) => setState(() => _range = FilterRange.today),
        ),
        ChoiceChip(
          label: Text(l10n.filterWeek),
          selected: _range == FilterRange.week,
          onSelected: (_) => setState(() => _range = FilterRange.week),
        ),
        ChoiceChip(
          label: Text(l10n.filterMonth),
          selected: _range == FilterRange.month,
          onSelected: (_) => setState(() => _range = FilterRange.month),
        ),
        ChoiceChip(
          label: Text(l10n.filterAll),
          selected: _range == FilterRange.all,
          onSelected: (_) => setState(() => _range = FilterRange.all),
        ),
      ],
    );
  }
}

// -------- Helper widgets --------

class _RitualMoment {
  final String eyebrow;
  final String title;
  final String prompt;

  const _RitualMoment({
    required this.eyebrow,
    required this.title,
    required this.prompt,
  });

  factory _RitualMoment.now(AppLocalizations l10n) {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday && now.hour >= 12) {
      return _RitualMoment(
        eyebrow: l10n.todaySectionTitle,
        title: l10n.weeklyRitualTitle,
        prompt: l10n.weeklyRitualPrompt,
      );
    }

    if (now.hour < 15) {
      return _RitualMoment(
        eyebrow: l10n.todaySectionTitle,
        title: l10n.morningRitualTitle,
        prompt: l10n.morningRitualPrompt,
      );
    }

    return _RitualMoment(
      eyebrow: l10n.todaySectionTitle,
      title: l10n.eveningRitualTitle,
      prompt: l10n.eveningRitualPrompt,
    );
  }
}

class _RitualCard extends StatelessWidget {
  final _RitualMoment ritual;
  final Future<void> Function() onStart;

  const _RitualCard({
    required this.ritual,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ritual.eyebrow.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ritual.title,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ritual.prompt,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.inkMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(l10n.startMirrorTalk),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.oneMinuteEnough,
            style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.noReflectionsYet,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.firstReflectionHint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.videocam_outlined),
              label: Text(l10n.startMirrorTalk),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final Future<void> Function() onDelete;
  final Future<void> Function() onChanged;

  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onChanged,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    HapticFeedback.selectionClick();
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await onDelete();
      HapticFeedback.lightImpact();
      await onChanged();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = DateFormat('EEE, MMM d • HH:mm').format(entry.createdAt);
    return Card(
      child: ListTile(
        title: Text(entry.type.name.toUpperCase()),
        subtitle: Text(subtitle),
        trailing: IconButton(
          tooltip: 'Delete entry',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () async {
          HapticFeedback.selectionClick();
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
          );
          await onChanged();
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int? current;
  final int? longest;
  final int? thisWeekDays;
  final int? goalsDoneThisWeek;

  const _StreakCard({
    required this.current,
    required this.longest,
    required this.thisWeekDays,
    required this.goalsDoneThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatBox(title: l10n.showingUp, value: '${current ?? 0}d'),
          const SizedBox(width: AppSpacing.xs),
          _StatBox(title: l10n.bestRun, value: '${longest ?? 0}d'),
          const SizedBox(width: AppSpacing.xs),
          _StatBox(title: l10n.thisWeek, value: '${thisWeekDays ?? 0}/7'),
          const SizedBox(width: AppSpacing.xs),
          _StatBox(title: l10n.goalsDone, value: '${goalsDoneThisWeek ?? 0}'),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: t.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
