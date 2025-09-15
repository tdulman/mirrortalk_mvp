// lib/services/storage_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';

// lib/services/storage_service.dart  (dosyanın sonuna yakın, class içine)
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/day_summary.dart';

// --- DaySummary storage helpers ---

class StorageService {
  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/mirrortalk_entries.json');
  }

  /// Tüm girişleri oku (yoksa boş liste)
  static Future<List<Entry>> loadEntries() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final txt = await f.readAsString();
      if (txt.trim().isEmpty) return [];
      final items = Entry.decodeList(txt);
      // yeniler üstte
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Entry> items) async {
    final f = await _file();
    await f.writeAsString(Entry.encodeList(items), flush: true);
  }

  /// Varsa günceller, yoksa ekler
  static Future<void> upsert(Entry e) async {
    final items = await loadEntries();
    final idx = items.indexWhere((x) => x.id == e.id);
    if (idx >= 0) {
      items[idx] = e;
    } else {
      items.add(e);
    }
    await _saveAll(items);
  }

  static Future<void> deleteById(String id) async {
    final items = await loadEntries();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);
  }

  static Future<File> _daySummaryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/day_summaries.json');
  }

  static Future<Map<String, dynamic>> _readDaySummaryMap() async {
    final f = await _daySummaryFile();
    if (await f.exists() == false) {
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

  static Future<DaySummary> loadDaySummary(DateTime day) async {
    final map = await _readDaySummaryMap();
    final key = DaySummary.emptyFor(day).dayKey;
    if (map.containsKey(key)) {
      return DaySummary.fromJson(map[key] as Map<String, dynamic>);
    }
    return DaySummary.emptyFor(day);
  }

  static Future<void> upsertDaySummary(DaySummary s) async {
    final map = await _readDaySummaryMap();
    map[s.dayKey] = s.toJson();
    await _writeDaySummaryMap(map);
  }
}
