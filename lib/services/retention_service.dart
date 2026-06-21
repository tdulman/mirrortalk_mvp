import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class RetentionService {
  static const _keyDays = 'retention_days';

  /// Varsayılan: 7 gün
  static Future<int> getDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDays) ?? 7;
  }

  static Future<void> setDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDays, days);
  }

  /// days gününden eski video dosyalarını siler, transcript kalır.
  static Future<void> enforce() async {
    final days = await getDays();
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final items = await StorageService.loadEntries();
    bool changed = false;

    for (var i = 0; i < items.length; i++) {
      final e = items[i];
      if (e.videoPath != null &&
          e.createdAt.isBefore(cutoff) &&
          e.videoPath!.toLowerCase().endsWith('.mp4')) {
        try {
          final f = File(e.videoPath!);
          if (await f.exists()) {
            await f.delete();
          }
          items[i] = e.copyWith(videoPath: null); // transcript kalır
          changed = true;
        } catch (_) {
          /* ignore */
        }
      }
    }

    if (changed) {
      await StorageService.saveAll(items);
    }
  }
}
