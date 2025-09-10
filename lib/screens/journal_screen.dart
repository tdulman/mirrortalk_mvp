// lib/screens/journal_screen.dart
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
  List<Entry> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await StorageService.loadEntries();
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<Entry> _filtered() {
    final now = DateTime.now();
    DateTime start;
    switch (_range) {
      case FilterRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case FilterRange.week:
        final weekday = now.weekday; // Mon=1..Sun=7
        start = DateTime(now.year, now.month, now.day).subtract(
          Duration(days: weekday - 1),
        );
        break;
      case FilterRange.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case FilterRange.all:
        return _all;
    }
    return _all.where((e) => e.createdAt.isAfter(start)).toList();
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    await _load();
  }

  Future<void> _openRecord(RecordType type) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecordScreen(type: type)),
    );
    if (changed == true) _load();
  }

  Widget _filterChips() {
    ChoiceChip chip(FilterRange r, String label) {
      return ChoiceChip(
        label: Text(label),
        selected: _range == r,
        onSelected: (_) => setState(() => _range = r),
      );
    }

    return Wrap(
      spacing: 12,
      children: [
        chip(FilterRange.today, 'Today'),
        chip(FilterRange.week, 'This Week'),
        chip(FilterRange.month, 'This Month'),
        chip(FilterRange.all, 'All'),
      ],
    );
  }

  Widget _todaySummaryCard() {
    if (_range != FilterRange.today) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today Summary – ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Morning Goals', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const _GoalField(hint: 'Goal 1'),
            const _GoalField(hint: 'Goal 2'),
            const _GoalField(hint: 'Goal 3'),
            const SizedBox(height: 16),
            Text('Evening Check', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const _CheckRow(label: 'Completed goal 1'),
            const _CheckRow(label: 'Completed goal 2'),
            const _CheckRow(label: 'Completed goal 3'),
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

  @override
  Widget build(BuildContext context) {
    final list = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _filterChips(),
                    _todaySummaryCard(),
                    const SizedBox(height: 8),
                    if (list.isNotEmpty)
                      Text(
                        _range == FilterRange.all
                            ? 'Since ${DateFormat('yMMMd').format(list.last.createdAt)}'
                            : DateFormat('yMMMM').format(DateTime.now()),
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.black54),
                      ),
                    const SizedBox(height: 6),
                    ...list.map((e) => _EntryTile(
                          entry: e,
                          onDelete: () => _delete(e.id),
                        )),
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
                child: FilledButton.tonalIcon(
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

class _EntryTile extends StatelessWidget {
  final Entry entry;
  final VoidCallback onDelete;
  const _EntryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final icon = entry.type == RecordType.morning
        ? Icons.wb_sunny_outlined
        : Icons.nightlight_round;
    final when = DateFormat('EEE, MMM d – HH:mm').format(entry.createdAt);

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text('${entry.type.name.toUpperCase()} · ${entry.durationSec}s'),
        subtitle: Text(when),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
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
    return TextField(
      decoration: InputDecoration(hintText: hint),
    );
    }
}

class _CheckRow extends StatefulWidget {
  final String label;
  const _CheckRow({required this.label});
  @override
  State<_CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<_CheckRow> {
  bool v = false;
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: v,
      onChanged: (x) => setState(() => v = x ?? false),
      title: Text(widget.label),
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

