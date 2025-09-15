import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import 'today_summary_card.dart';
import 'record_screen.dart';
import 'entry_detail_screen.dart';
import 'settings_screen.dart';

enum FilterRange { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  FilterRange _range = FilterRange.today;
  List<Entry> _all = <Entry>[];
  bool _loading = true;

  DaySummary? _todaySummary;
  StreakInfo? _streak;
  int _goalsDoneThisWeek = 0;
  bool _celebratedToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final items = await StorageService.loadEntries();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final today = await StorageService.getDaySummary(DateTime.now());

    // habit-true streak (last 120 days)
    final since = DateTime.now().subtract(const Duration(days: 120));
    final streak = await StreakService.computeHabitTrue(
      since: since,
      getDaySummary: StorageService.getDaySummary,
    );

    if (!mounted) return;
    setState(() {
      _all = items;
      _todaySummary = today;
      _streak = streak;
      _goalsDoneThisWeek = streak.goalsDoneThisWeek;
      _loading = false;
    });

    // light celebration when first entry is added today
    final todayKey = DaySummary.makeDayKey(DateTime.now());
    final todayHadEntry =
        items.any((e) => DaySummary.makeDayKey(e.createdAt) == todayKey);
    if (todayHadEntry && !_celebratedToday) {
      _celebratedToday = true;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nice! You're on a habit streak — keep it going 🔥")),
      );
    }
  }

  Future<void> _reload() async => _load();
  List<Entry> _filtered() => _all;

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

  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (changed == true) setState(() {});
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    if (_streak != null) ...[
                      _StreakCard(
                        current: _streak!.current,
                        longest: _streak!.longest,
                        thisWeekDays: _streak!.thisWeekDays,
                        goalsDoneThisWeek: _streak!.goalsDoneThisWeek,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _filterChips(),
                    const SizedBox(height: 8),
                    if (_range == FilterRange.today)
                      TodaySummaryCard(
                        summary: _todaySummary ??
                            DaySummary.emptyFor(DateTime.now()),
                        onChanged: (s) => setState(() => _todaySummary = s),
                      ),
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
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Today'),
          selected: _range == FilterRange.today,
          onSelected: (_) => setState(() => _range = FilterRange.today),
        ),
        ChoiceChip(
          label: const Text('Week'),
          selected: _range == FilterRange.week,
          onSelected: (_) => setState(() => _range = FilterRange.week),
        ),
        ChoiceChip(
          label: const Text('Month'),
          selected: _range == FilterRange.month,
          onSelected: (_) => setState(() => _range = FilterRange.month),
        ),
        ChoiceChip(
          label: const Text('All'),
          selected: _range == FilterRange.all,
          onSelected: (_) => setState(() => _range = FilterRange.all),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No entries yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              "Tap 'Add' to create your first record. "
              "You can speak a quick voice note and we'll suggest goals instantly.",
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                      'Tip: marking at least one goal as Done counts toward your streak.'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onAdd,
                child: const Text('Add your first record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final Future<void> Function() onDelete;
  final Future<void> Function() onChanged;

  const _EntryTile(
      {required this.entry, required this.onDelete, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final subtitle = DateFormat('EEE, MMM d • HH:mm').format(entry.createdAt);
    return Card(
      child: ListTile(
        title: Text(entry.type.name.toUpperCase()),
        subtitle: Text(subtitle),
        trailing: IconButton(
          tooltip: 'Delete entry', // <— eklendi
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await onDelete();
            await onChanged();
          },
        ),
        onTap: () async {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatBox(title: 'Streak', value: (current ?? 0).toString()),
            const SizedBox(width: 12),
            _StatBox(title: 'Best', value: (longest ?? 0).toString()),
            const SizedBox(width: 12),
            _StatBox(title: 'Active days', value: '${thisWeekDays ?? 0}/wk'),
            const SizedBox(width: 12),
            _StatBox(
                title: 'Goals done', value: '${goalsDoneThisWeek ?? 0}/wk'),
          ],
        ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(value, style: t.titleMedium),
            const SizedBox(height: 4),
            Text(title, style: t.labelMedium?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
