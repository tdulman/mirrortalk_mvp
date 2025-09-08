import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../services/storage_service.dart';
import '../services/transcription_service.dart';

enum JournalRange { today, week, month, all }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  JournalRange _range = JournalRange.today;
  List<Entry> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await StorageService.loadEntries();
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<Entry> get _filtered {
    final now = DateTime.now();

    bool inRange(DateTime d) {
      switch (_range) {
        case JournalRange.today:
          final t = DateTime(now.year, now.month, now.day);
          final e = DateTime(d.year, d.month, d.day);
          return t == e;
        case JournalRange.week:
          final start = now.subtract(Duration(days: now.weekday - 1)); // Pazartesi
          final end = start.add(const Duration(days: 7));
          return (d.isAfter(start.subtract(const Duration(seconds: 1))) &&
              d.isBefore(end));
        case JournalRange.month:
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 1);
          return (d.isAfter(start.subtract(const Duration(seconds: 1))) &&
              d.isBefore(end));
        case JournalRange.all:
          return true;
      }
    }

    return _all.where((e) => inRange(e.createdAt)).toList();
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );
  }

  Future<void> _transcribe(Entry e) async {
    final service = TranscriptionService();
    final text = await service.transcribe();

    final updated = e.copyWith(transcript: text);
    await StorageService.upsert(updated);
    await _load();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transcription'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmtDay = DateFormat('EEE, MMM d • HH:mm'); // Sat, Sep 6 • 18:03 gibi

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtre segmentleri
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: SegmentedButton<JournalRange>(
                    segments: const [
                      ButtonSegment(
                          value: JournalRange.today, label: Text('Today')),
                      ButtonSegment(
                          value: JournalRange.week, label: Text('This Week')),
                      ButtonSegment(
                          value: JournalRange.month, label: Text('This Month')),
                      ButtonSegment(
                          value: JournalRange.all, label: Text('All')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) =>
                        setState(() => _range = s.first),
                  ),
                ),
                const SizedBox(height: 8),
                // Liste
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('No entries yet. Pull to refresh.'),
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final e = _filtered[i];
                              final icon = e.type == 'morning'
                                  ? Icons.wb_sunny_outlined
                                  : Icons.nightlight_round;

                              return ListTile(
                                leading: Icon(icon),
                                title: Text(
                                  '${e.type.toUpperCase()} • ${e.durationSec}s',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(fmtDay.format(e.createdAt)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Transcribe',
                                      icon: const Icon(Icons.text_fields),
                                      onPressed: () => _transcribe(e),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _delete(e.id),
                                    ),
                                  ],
                                ),
                                // ileride: detay sayfası (transcript/etiket düzenleme)
                                onTap: () {},
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
