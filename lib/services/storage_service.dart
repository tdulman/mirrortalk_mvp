import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/entry.dart';

class StorageService {
  static const _fileName = 'entries.json';

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
      final data = jsonDecode(txt) as List<dynamic>;
      return data
          .map((e) => Entry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<Entry> items) async {
    final f = await _file();
    final data = items.map((e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(data));
  }

  static Future<void> upsert(Entry e) async {
    final items = await loadEntries();
    final idx = items.indexWhere((x) => x.id == e.id);
    if (idx >= 0) {
      items[idx] = e;
    } else {
      items.add(e);
    }
    await saveAll(items);
  }

  static Future<void> deleteById(String id) async {
    final items = await loadEntries();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }
}