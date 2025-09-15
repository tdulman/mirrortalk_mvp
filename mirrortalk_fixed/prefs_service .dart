// lib/services/prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _kMorningHour = 'pref_morning_hour';
  static const _kMorningMin = 'pref_morning_min';
  static const _kEveningHour = 'pref_evening_hour';
  static const _kEveningMin = 'pref_evening_min';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<void> setMorning(int hour, int minute) async {
    final p = await _prefs();
    await p.setInt(_kMorningHour, hour);
    await p.setInt(_kMorningMin, minute);
  }

  static Future<void> setEvening(int hour, int minute) async {
    final p = await _prefs();
    await p.setInt(_kEveningHour, hour);
    await p.setInt(_kEveningMin, minute);
  }

  static Future<(int hour, int min)> getMorning() async {
    final p = await _prefs();
    return (p.getInt(_kMorningHour) ?? 8, p.getInt(_kMorningMin) ?? 0);
  }

  static Future<(int hour, int min)> getEvening() async {
    final p = await _prefs();
    return (p.getInt(_kEveningHour) ?? 20, p.getInt(_kEveningMin) ?? 0);
  }
}
