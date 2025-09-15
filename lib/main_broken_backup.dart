import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/entry.dart';
import 'services/storage_service.dart';
import 'services/retention_service.dart';
import 'screens/record_screen.dart';
import 'screens/entry_detail_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum JournalRange { today, week, month, all }

class _HomeScreenState extends State<HomeScreen> {
  JournalRange _range = JournalRange.today;
  List<Entry> _all = [];
  bool _loading = true;

  // Today Summary (local prefs)
  final _goal1 = TextEditingController();
  final _goal2 = TextEditingController();
  final _goal3 = TextEditingController();
  bool _done1 = false, _done2 = false, _done3 = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadEntries();
    await _loadTodaySummary();
    await RetentionService.enforce();
  }

  Future<void> _loadEntries() async {
    final items = await StorageService.loadEntries();
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadTodaySummary() async {
    final p = await SharedPreferences.getInstance();
    _goal1.text = p.getString('goal1-$_todayKey') ?? '';
    _goal2.text = p.getString('goal2-$_todayKey') ?? '';
    _goal3.text = p.getString('goal3-$_todayKey') ?? '';
    _done1 = p.getBool('done1-$_todayKey') ?? false;
    _done2 = p.getBool('done2-$_todayKey') ?? false;
    _done3 = p.getBool('done3-$_todayKey') ?? false;
    if (mounted) setState(() {});
  }

  Future<void> _saveTodaySummary() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('goal1-$_todayKey', _goal1.text);
    await p.setString('goal2-$_todayKey', _goal2.text);
    await p.setString('goal3-$_todayKey', _goal3.text);
    await p.setBool('done1-$_todayKey', _done1);
    await p.setBool('done2-$_todayKey', _done2);
    await p.setBool('done3-$_todayKey', _done3);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Today summary saved')));
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

  String _captionForRange() {
    final now = DateTime.now();
    final fmtFull = DateFormat('EEEE, MMMM d, yyyy');
    final fmtMonY = DateFormat('MMMM yyyy');
    final fmtMonDay = DateFormat('MMMM d');
    final fmtDayY = DateFormat('d, yyyy');
    final fmtShort = DateFormat('MMM d');
    final fmtShortY = DateFormat('MMM d, yyyy');

    switch (_range) {
      case JournalRange.today:
        return fmtFull.format(now);
      case JournalRange.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        if (start.month == end.month && start.year == end.year) {
          return '${fmtMonDay.format(start)}–${fmtDayY.format(end)}';
        } else {
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
    await _loadEntries();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final fmtItem = DateFormat('EEE, MMM d • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('MirrorTalk'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'account') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              } else if (v == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) => RetentionService.enforce());
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
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Üst bloklar: (Today Summary yalnızca Today seçiliyken) + Segmentler + Başlık
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_range == JournalRange.today)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Today Summary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Morning Goals'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _goal1,
                                      decoration: const InputDecoration(
                                        hintText: 'Goal 1',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _goal2,
                                      decoration: const InputDecoration(
                                        hintText: 'Goal 2',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _goal3,
                                      decoration: const InputDecoration(
                                        hintText: 'Goal 3',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Evening Check'),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _done1,
                                      onChanged: (v) =>
                                          setState(() => _done1 = v ?? false),
                                      title: const Text('Completed goal 1'),
                                    ),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _done2,
                                      onChanged: (v) =>
                                          setState(() => _done2 = v ?? false),
                                      title: const Text('Completed goal 2'),
                                    ),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _done3,
                                      onChanged: (v) =>
                                          setState(() => _done3 = v ?? false),
                                      title: const Text('Completed goal 3'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.tonal(
                                        onPressed: _saveTodaySummary,
                                        child: const Text('Save'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Segmentler
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          child: SegmentedButton<JournalRange>(
                            segments: const [
                              ButtonSegment(
                                value: JournalRange.today,
                                label: Text('Today'),
                              ),
                              ButtonSegment(
                                value: JournalRange.week,
                                label: Text('This Week'),
                              ),
                              ButtonSegment(
                                value: JournalRange.month,
                                label: Text('This Month'),
                              ),
                              ButtonSegment(
                                value: JournalRange.all,
                                label: Text('All'),
                              ),
                            ],
                            selected: {_range},
                            onSelectionChanged: (s) =>
                                setState(() => _range = s.first),
                          ),
                        ),

                        // Başlık + çizgi
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
                      ],
                    ),
                  ),

                  // Liste
                  if (_filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No entries in this range.')),
                    )
                  else
                    SliverList.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
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
                          subtitle: Text(
                            DateFormat(
                              'EEE, MMM d • HH:mm',
                            ).format(e.createdAt),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _delete(e.id),
                            tooltip: 'Delete',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EntryDetailScreen(entry: e),
                              ),
                            ).then((_) => _loadEntries());
                          },
                        );
                      },
                    ),

                  // Altta butonlar için boşluk
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
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
                      builder: (_) =>
                          const RecordScreen(type: RecordType.morning),
                    ),
                  ).then((_) => _loadEntries()),
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
                      builder: (_) =>
                          const RecordScreen(type: RecordType.evening),
                    ),
                  ).then((_) => _loadEntries()),
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

// Basit placeholder
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _days = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _days = await RetentionService.getDays();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await RetentionService.setDays(_days);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Video Retention (days)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: _days,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 14, child: Text('14 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
            ],
            onChanged: (v) => setState(() => _days = v ?? 7),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(height: 24),
          const Text(
            'Old videos older than the selected days will be removed automatically.\nTranscripts remain saved.',
          ),
        ],
      ),
    );
  }
}
