import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/entry.dart';
import 'services/storage_service.dart';
import 'screens/record_screen.dart';

void main() => runApp(const MirrorTalkApp());

class MirrorTalkApp extends StatelessWidget {
  const MirrorTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MirrorTalk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A7C7C)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum JournalRange { today, week, month, all }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JournalRange _range = JournalRange.today; // default: Today
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

  // -------- FILTERED LIST --------
  List<Entry> get _filtered {
    final now = DateTime.now();
    bool inRange(DateTime d) {
      switch (_range) {
        case JournalRange.today:
          final t = DateTime(now.year, now.month, now.day);
          final e = DateTime(d.year, d.month, d.day);
          return t == e;
        case JournalRange.week:
          final start = now.subtract(Duration(days: now.weekday - 1)); // Mon
          final end = start.add(const Duration(days: 7));
          return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
              d.isBefore(end);
        case JournalRange.month:
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 1);
          return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
              d.isBefore(end);
        case JournalRange.all:
          return true;
      }
    }
    return _all.where((e) => inRange(e.createdAt)).toList();
  }

  // -------- APPLE CALENDAR STYLE CAPTION --------
  String _captionForRange() {
    final now = DateTime.now();
    final fmtFull = DateFormat('EEEE, MMMM d, yyyy'); // Sunday, September 7, 2025
    final fmtMonY = DateFormat('MMMM yyyy');          // September 2025
    final fmtMonDay = DateFormat('MMMM d');           // September 7
    final fmtDayY = DateFormat('d, yyyy');            // 13, 2025
    final fmtShort = DateFormat('MMM d');             // Sep 28
    final fmtShortY = DateFormat('MMM d, yyyy');      // Oct 4, 2025

    switch (_range) {
      case JournalRange.today:
        return fmtFull.format(now);

      case JournalRange.week:
        final start = now.subtract(Duration(days: now.weekday - 1)); // Mon
        final end = start.add(const Duration(days: 6));              // Sun
        if (start.month == end.month && start.year == end.year) {
          // September 7–13, 2025
          return '${fmtMonDay.format(start)}–${fmtDayY.format(end)}';
        } else {
          // Sep 28 – Oct 4, 2025
          return '${fmtShort.format(start)} – ${fmtShortY.format(end)}';
        }

      case JournalRange.month:
        return fmtMonY.format(now);

      case JournalRange.all:
        if (_all.isEmpty) return 'No entries yet';
        final oldest = _all
            .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
            .createdAt;
        return 'Since ${fmtFull.format(oldest)}';
    }
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteById(id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmtItem = DateFormat('EEE, MMM d • HH:mm'); // list item subtitle

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'account') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()));
              } else if (value == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'account', child: Text('Account')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Start your 2-minute self-talk.\nChoose Morning or Evening below.',
                    textAlign: TextAlign.center,
                  ),
                ),

                // --- RANGE SEGMENTS ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: SegmentedButton<JournalRange>(
                    segments: const [
                      ButtonSegment(value: JournalRange.today, label: Text('Today')),
                      ButtonSegment(value: JournalRange.week, label: Text('This Week')),
                      ButtonSegment(value: JournalRange.month, label: Text('This Month')),
                      ButtonSegment(value: JournalRange.all, label: Text('All')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) => setState(() => _range = s.first),
                  ),
                ),

                // --- BIG CAPTION (Apple-like) + divider
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _captionForRange(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),

                // --- LIST ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No entries in this range.'))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(fmtItem.format(e.createdAt)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _delete(e.id),
                                  tooltip: 'Delete',
                                ),
                                onTap: () {}, // later: detail/transcript
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),

      // --- BOTTOM: RECORD BUTTONS ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecordScreen(type: RecordType.morning),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Morning Talk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecordScreen(type: RecordType.evening),
                    ),
                  ).then((_) => _load()),
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

// Placeholder pages
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Account page (coming soon)')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings page (coming soon)')),
    );
  }
}




