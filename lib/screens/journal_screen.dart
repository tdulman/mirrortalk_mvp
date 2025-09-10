// lib/screens/journal_screen.dart
import 'package:flutter/material.dart';

import '../models/entry.dart';                 // Entry ve RecordType
import '../services/storage_service.dart';     // StorageService
import 'record_screen.dart';                   // RecordScreen

enum Range { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  Range _range = Range.today;
  bool _loading = true;
  List<Entry> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await StorageService.loadEntries();
      if (!mounted) return;
      setState(() {
        _all = items..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Entry> get _filtered {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case Range.today:
        return _all.where((e) =>
            e.createdAt.year == now.year &&
            e.createdAt.month == now.month &&
            e.createdAt.day == now.day).toList();
      case Range.week:
        final startOfWeek =
            startOfToday.subtract(Duration(days: startOfToday.weekday - 1)); // Pazartesi
        return _all.where((e) => !e.createdAt.isBefore(startOfWeek)).toList();
      case Range.month:
        return _all
            .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
            .toList();
      case Range.all:
        return _all;
    }
  }

  IconData _iconFor(RecordType t) =>
      t == RecordType.morning ? Icons.wb_sunny_outlined : Icons.nightlight_round;

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 16;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
              itemCount: _listItemCount(entries.length),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildListItem(context, index, entries),
            ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecordScreen(type: RecordType.morning),
                      ),
                    ).then((_) => _load());
                  },
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Morning Talk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecordScreen(type: RecordType.evening),
                      ),
                    ).then((_) => _load());
                  },
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

  // --- ListView öğe üretimi ---

  int _listItemCount(int entryCount) {
    // 1: filtre çubukları
    // +1: eğer Range.today ise Today Summary kartı
    // +entryCount: kayıtlar
    return 1 + (_range == Range.today ? 1 : 0) + entryCount;
  }

  Widget _buildListItem(BuildContext context, int index, List<Entry> entries) {
    int cursor = 0;

    // 0 -> filtreler
    if (index == cursor) return _filters();
    cursor++;

    // (opsiyonel) Today Summary kartı
    if (_range == Range.today) {
      if (index == cursor) return _todaySummaryCard();
      cursor++;
    }

    // kayıtlar
    final e = entries[index - cursor];
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(e.type)),
        title: Text('${e.type.name.toUpperCase()} • ${e.durationSec}s'),
        subtitle: Text(_fmt(e.createdAt)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(e.id),
        ),
        onTap: () {},
      ),
    );
  }

  // --- yardımcı widgetlar ---

  Widget _filters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _chip('Today', Range.today),
        _chip('This Week', Range.week),
        _chip('This Month', Range.month),
        _chip('All', Range.all),
      ],
    );
  }

  Widget _chip(String label, Range r) {
    return ChoiceChip(
      label: Text(label),
      selected: _range == r,
      onSelected: (_) => setState(() => _range = r),
    );
  }

  Widget _todaySummaryCard() {
    final title = 'Today Summary – ${_fmt(DateTime.now())}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Morning Goals', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            const _GoalField(hint: 'Goal 1'),
            const _GoalField(hint: 'Goal 2'),
            const _GoalField(hint: 'Goal 3'),
            const SizedBox(height: 12),
            Text('Evening Check', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            const _CheckRow('Completed goal 1'),
            const _CheckRow('Completed goal 2'),
            const _CheckRow('Completed goal 3'),
            const SizedBox(height: 12),
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

class _GoalField extends StatelessWidget {
  final String hint;
  const _GoalField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }
}

class _CheckRow extends StatefulWidget {
  final String label;
  const _CheckRow(this.label);

  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow> {
  bool v = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label)),
        Checkbox(value: v, onChanged: (b) => setState(() => v = b ?? false)),
      ],
    );
  }
}
