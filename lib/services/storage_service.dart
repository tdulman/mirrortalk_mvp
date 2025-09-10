// lib/services/storage_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';

class StorageService {
  static const _fileName = 'mirrortalk_entries.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Entry>> loadEntries() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final txt = await f.readAsString();
      if (txt.trim().isEmpty) return [];
      return Entry.decodeList(txt)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Entry> items) async {
    final f = await _file();
    await f.writeAsString(Entry.encodeList(items));
  }

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

  /// Belirli bir tarih (yyyy-MM-dd) için en son Entry (sabah/akşam fark etmez)
  static Future<Entry?> findByDay(DateTime dayUtc) async {
    final items = await loadEntries();
    final key = _dayKey(dayUtc);
    for (final e in items) {
      if (_dayKey(e.createdAt.toUtc()) == key) {
        return e;
      }
    }
    return null;
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}



