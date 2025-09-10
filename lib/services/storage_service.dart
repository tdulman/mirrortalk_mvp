// lib/services/storage_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';

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
}

