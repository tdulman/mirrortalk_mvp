import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';
import 'record_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await StorageService.loadEntries();
    // tarihe göre yeni → eski
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  Future<void> _reload() async => _load();

  List<Entry> _filtered() {
    if (_range == FilterRange.all) return _all;

    final now = DateTime.now();
    DateTime start;

    switch (_range) {
      case FilterRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case FilterRange.week:
        final weekday = now.weekday; // Mon=1 … Sun=7
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        break;
      case FilterRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case FilterRange.all:
        start = DateTime(1970);
        break;
    }

    return _all.where((e) => e.createdAt.isAfter(start)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    await _load();
  }

  Future<void> _openRecord(RecordType type) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RecordScreen(type: type),
    ),
  );
  // geri dönünce listeyi yenile
  _reload();
}


  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // ileride Settings
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 100.0),
                  children: [
                    _filterChips(),
                    const SizedBox(height: 8),

                    // Sadece Today'de "Today Summary" kartı
                    if (_range == FilterRange.today) ...[
                      _TodaySummaryCard(),
                      const SizedBox(height: 8),
                    ],

                    if (list.isEmpty) ...[
                      _EmptyState(onAdd: _reload),
                    ] else ...[
                      if (_range == FilterRange.all) ...[
                        Text(
                          'Since ${DateFormat('yyyy-MM-dd').format(list.last.createdAt)} '
                          'to ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                      ],
                      ...list.map(
  (e) => GestureDetector(
    onTap: () async {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: e)),
      );
      if (changed == true && mounted) {
        _load(); // kaydedildiyse listeyi tazele
      }
    },
    child: _EntryTile(
      entry: e,
      onDelete: () => _delete(e.id),
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

  /// Filtre chip’leri – ChoiceChip hatasını önlemek için **Widget** döner.
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

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: FilterRange.values.map((r) {
        return ChoiceChip(
          label: Text(label(r)),
          selected: _range == r,
          onSelected: (_) => setState(() => _range = r),
        );
      }).toList(),
    );
  }
}

/// Boş liste durumunda kullanıcıyı kayıt başlatmaya yönlendirir.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
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
            FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecordScreen(type: RecordType.morning),
                  ),
                );
                onAdd();
              },
              child: const Text('Morning Talk Başlat'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecordScreen(type: RecordType.evening),
                  ),
                );
                onAdd();
              },
              child: const Text('Evening Talk Başlat'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste öğesi
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});

  final Entry entry;
  final VoidCallback onDelete;

  IconData _icon() {
    switch (entry.type) {
      case RecordType.morning:
        return Icons.wb_sunny_outlined;
      case RecordType.evening:
        return Icons.nightlight_round;
    }
  }

  String _when() =>
      DateFormat('EEE, MMM d · HH:mm').format(entry.createdAt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_icon()),
        title: Text(
          '${entry.type.name.toUpperCase()} · ${entry.durationSec}s',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(_when()),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// Basit bir “Today Summary” kartı (lokal state’li, örnek)
class _TodaySummaryCard extends StatefulWidget {
  @override
  State<_TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<_TodaySummaryCard> {
  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  final _g3 = TextEditingController();
  bool _c1 = false, _c2 = false, _c3 = false;

  @override
  void dispose() {
    _g1.dispose();
    _g2.dispose();
    _g3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        'Today Summary – ${DateFormat('EEEE, MMM d').format(DateTime.now())}';

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          border: const UnderlineInputBorder(),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Morning Goals',
                style: Theme.of(context).textTheme.labelLarge),
            TextField(controller: _g1, decoration: deco('Goal 1')),
            TextField(controller: _g2, decoration: deco('Goal 2')),
            TextField(controller: _g3, decoration: deco('Goal 3')),
            const SizedBox(height: 12),
            Text('Evening Check',
                style: Theme.of(context).textTheme.labelLarge),
            CheckboxListTile(
              dense: true,
              value: _c1,
              onChanged: (v) => setState(() => _c1 = v ?? false),
              title: const Text('Completed goal 1'),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            CheckboxListTile(
              dense: true,
              value: _c2,
              onChanged: (v) => setState(() => _c2 = v ?? false),
              title: const Text('Completed goal 2'),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            CheckboxListTile(
              dense: true,
              value: _c3,
              onChanged: (v) => setState(() => _c3 = v ?? false),
              title: const Text('Completed goal 3'),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved')),
                  );
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


