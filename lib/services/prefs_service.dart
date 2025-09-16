// lib/services/prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _kFirstRun = 'first_run';
  static const _kMorningH = 'morning_h';
  static const _kMorningM = 'morning_m';
  static const _kEveningH = 'evening_h';
  static const _kEveningM = 'evening_m';

  /// İlk kurulumda varsayılan saatleri yaz ve first_run=true ayarla.
  static Future<void> ensureDefaults() async {
    final p = await SharedPreferences.getInstance();

    if (!p.containsKey(_kFirstRun)) {
      await p.setBool(_kFirstRun, true);
    }
    // Varsayılan saatler: 08:00 ve 20:00
    if (!p.containsKey(_kMorningH)) await p.setInt(_kMorningH, 8);
    if (!p.containsKey(_kMorningM)) await p.setInt(_kMorningM, 0);
    if (!p.containsKey(_kEveningH)) await p.setInt(_kEveningH, 20);
    if (!p.containsKey(_kEveningM)) await p.setInt(_kEveningM, 0);
  }

  static Future<bool> isFirstRun() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kFirstRun) ?? true;
  }

  static Future<void> setFirstRun(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFirstRun, v);
  }

  // Reminders
  static Future<(int,int)> getMorning() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kMorningH) ?? 8, p.getInt(_kMorningM) ?? 0);
  }

  static Future<(int,int)> getEvening() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kEveningH) ?? 20, p.getInt(_kEveningM) ?? 0);
  }

  static Future<void> setMorning(int h, int m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kMorningH, h);
    await p.setInt(_kMorningM, m);
  }

  static Future<void> setEvening(int h, int m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kEveningH, h);
    await p.setInt(_kEveningM, m);
  }
}

