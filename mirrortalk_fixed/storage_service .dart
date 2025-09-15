// lib/services/storage_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import '../models/entry.dart';
import '../models/day_summary.dart';

class StorageService {
  // ---- Entries ----
  static Future<File> _entriesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/entries.json');
  }

  static Future<List<Entry>> loadEntries() async {
    final f = await _entriesFile();
    if (!await f.exists()) return <Entry>[];
    final txt = await f.readAsString();
    try {
      return Entry.decodeList(txt);
    } catch (_) {
      return <Entry>[];
    }
  }

  static Future<void> _saveAll(List<Entry> items) async {
    final f = await _entriesFile();
    await f.writeAsString(Entry.encodeList(items));
  }

  static Future<void> appendEntry(Entry e) async {
    final items = await loadEntries();
    items.add(e);
    await _saveAll(items);
  }

  static Future<void> deleteEntry(String id) async {
    final items = await loadEntries();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);
  }

  // ---- DaySummary ----
  static Future<File> _daySummaryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/day_summaries.json');
  }

  static Future<Map<String, dynamic>> _readDaySummaryMap() async {
    final f = await _daySummaryFile();
    if (!await f.exists()) {
      await f.writeAsString(jsonEncode({}));
      return {};
    }
    final txt = await f.readAsString();
    try {
      final m = jsonDecode(txt);
      if (m is Map<String, dynamic>) return m;
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeDaySummaryMap(Map<String, dynamic> m) async {
    final f = await _daySummaryFile();
    await f.writeAsString(jsonEncode(m));
  }

  static Future<DaySummary> getDaySummary(DateTime day) async {
    final key = DaySummary.makeDayKey(day);
    final map = await _readDaySummaryMap();
    if (map.containsKey(key)) {
      final data = map[key];
      if (data is Map<String, dynamic>) {
        return DaySummary.fromJson(data);
      }
    }
    return DaySummary.emptyFor(day);
  }

  static Future<void> upsertDaySummary(DaySummary s) async {
    final map = await _readDaySummaryMap();
    map[s.dayKey] = s.toJson();
    await _writeDaySummaryMap(map);
  }
}
