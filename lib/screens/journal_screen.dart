import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';
import 'record_screen.dart';
import 'entry_detail_screen.dart';
import 'today_summary_card.dart';

enum FilterRange { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // --- State ---
  FilterRange _range = FilterRange.today;
  List<Entry> _all = <Entry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- Data ---
  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await StorageService.loadEntries();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // yeni -> eski
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  Future<void> _reload() async => _load();

  List<Entry> _filtered() {
    if (_range == FilterRange.all) return _all;

    final now = DateTime.now();
    DateTime start = DateTime(1970);

    switch (_range) {
      case FilterRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case FilterRange.week:
        final wd = now.weekday; // 1..7 (Mon..Sun)
        start =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: wd - 1));
        break;
      case FilterRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case FilterRange.all:
        start = DateTime(1970);
        break;
    }

    return _all
        .where((e) => e.createdAt.isAfter(start))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _openRecord(RecordType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RecordScreen(type: type)),
    );
    if (changed == true && mounted) {
      _reload();
    }
  }

  // --- UI helpers ---
  Widget _filterChips() {
    String label(FilterRange r) {
      switch (r) {
        case FilterRange.today:
          return 'Today';
        case FilterRange.week:
          return 'This Week';
        case FilterRange.month:
          return 'This Month';
        case FilterRange.all:
          return 'All';
      }
    }

    Widget chip(FilterRange r) {
      final selected = _range == r;
      return OutlinedButton(
        onPressed: () => setState(() => _range = r),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.black12 : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 16),
              ),
            Text(label(r)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: FilterRange.values.map(chip).toList(),
    );
  }

  // --- Silme ---
  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    await _load();
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {}, // ileride eklenecek
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
                    _filterChips(),
                    const SizedBox(height: 8),
                    if (_range == FilterRange.today) ...[
                      const SizedBox(height: 8),
                      TodaySummaryCard(), // const DEĞİL
                    ],
                    if (list.isEmpty)
                      _EmptyState(onAdd: _reload)
                    else ...[
                      if (_range == FilterRange.all)
                        Text(
                          'Since ${DateFormat('yyyy-MM-dd').format(list.last.createdAt)} '
                          'to ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      const SizedBox(height: 6),
                      ...list
                          .map(
                            (e) => _EntryTile(
                              entry: e,
                              onDelete: () => _delete(e.id),
                              onChanged: _reload,
                            ),
                          )
                          .toList(),
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
                  onPressed: () => _openRecord(RecordType.morning),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Morning Talk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openRecord(RecordType.evening),
                  icon: const Icon(Icons.nightlight_round),
                  label: const Text('Evening Talk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================
// AŞAĞIDAKİLER SINIF DIŞI
// =====================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, super.key});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_call, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Henüz hiç kayıt yok.',
              style: TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAdd, child: const Text('Morning Talk Başlat')),
            const SizedBox(height: 12),
            FilledButton(onPressed: onAdd, child: const Text('Evening Talk Başlat')),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onChanged,
    super.key,
  });

  final Entry entry;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  IconData _icon() {
    switch (entry.type) {
      case RecordType.morning:
        return Icons.wb_sunny_outlined;
      case RecordType.evening:
        return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('EEE, MMM d • HH:mm').format(entry.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(_icon()),
        title: Text(
          '${entry.type.name.toUpperCase()} · ${entry.durationSec}s',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(when),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    entry.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EntryDetailScreen(entry: entry),
            ),
          );
          if (changed == true) onChanged();
        },
      ),
    );
  }
}





