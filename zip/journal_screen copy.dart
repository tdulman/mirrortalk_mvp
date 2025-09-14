// lib/screens/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/day_summary.dart';
import '../models/entry.dart';
import '../services/storage_service.dart';
import 'today_summary_card.dart';

enum FilterRange { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // ---- State ----
  FilterRange _range = FilterRange.today;
  List<Entry> _all = <Entry>[];
  bool _loading = true;

  DaySummary? _todaySummary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- Data ----
  Future<void> _load() async {
    setState(() => _loading = true);

    // entries
    final items = await StorageService.loadEntries();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // new -> old

    // today summary (gün anahtarı zorunlu)
    final DaySummary today = DaySummary.emptyFor(DateTime.now());

    if (!mounted) return;
    setState(() {
      _all = items;
      _todaySummary = today;
      _loading = false;
    });
  }

  Future<void> _reload() async => _load();

  List<Entry> _filtered() {
    // Basit bırakıyoruz; istersen filtre mantığını sonra ekleriz.
    return _all;
  }

  Future<void> _delete(String id) async {
    try {
      await StorageService.deleteEntry(id);
      await _reload();
    } catch (_) {
      // sessiz geç
    }
  }

  void _onAddPressed() {
    // Buraya yeni kayıt ekleme ekranına geçişi koyabilirsin
  }

  // ---- UI ----
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
            onPressed: () {},
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
                      TodaySummaryCard(
                        summary: (_todaySummary ??
                            DaySummary.emptyFor(DateTime.now())),
                        onChanged: (s) {
                          setState(() => _todaySummary = s);
                          // İstersen anında kaydet:
                          // StorageService.upsertDaySummary(s);
                        },
                      ),
                    ],

                    if (list.isEmpty)
                      _EmptyState(onAdd: _reload)
                    else ...[
                      Text(
                        'Since ${DateFormat('yyyy-MM-dd').format(list.last.createdAt)} '
                        'to ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 6),
                      ...list.map((e) => _EntryTile(
                            entry: e,
                            onDelete: () => _delete(e.id),
                            onChanged: _reload,
                          )),
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
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Basit filtre chipleri (placeholder)
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

// ---- Yardımcı widgetlar (basit, hatasız) ----

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('No entries yet'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => onAdd(),
              child: const Text('Add your first entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onDelete;
  final Future<void> Function() onChanged;

  const _EntryTile({
    required this.entry,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle =
        DateFormat('EEE, MMM d • HH:mm').format(entry.createdAt);
    return Card(
      child: ListTile(
        title: Text(entry.type.name.toUpperCase()),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await onDelete();
            await onChanged();
          },
        ),
        onTap: () {
          // detay ekranına geçişi burada yapabilirsin
        },
      ),
    );
  }
}
