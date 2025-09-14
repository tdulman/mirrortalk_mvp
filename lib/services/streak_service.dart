// lib/services/streak_service.dart
import '../models/entry.dart';
import '../models/day_summary.dart';

class StreakInfo {
  final int current;      // consecutive days incl. today if active
  final int longest;      // best historical streak
  final int thisWeekDays; // active days Mon..Sun
  final int goalsDoneThisWeek; // will be filled in UI

  const StreakInfo({
    required this.current,
    required this.longest,
    required this.thisWeekDays,
    required this.goalsDoneThisWeek,
  });
}

class StreakService {
  static String _dayKey(DateTime d) =>
      DaySummary.makeDayKey(DateTime(d.year, d.month, d.day));

  /// Streak: bir günde en az 1 entry varsa o gün "aktif" sayılır.
  static StreakInfo compute({
    required List<Entry> entries,
  }) {
    // Günlere göre kümele
    final days = <String, int>{}; // dayKey -> count
    for (final e in entries) {
      final k = _dayKey(e.createdAt);
      days[k] = (days[k] ?? 0) + 1;
    }

    // current streak (bugünden geriye)
    int cur = 0;
    DateTime cursor = DateTime.now();
    while (true) {
      final k = _dayKey(cursor);
      if (days.containsKey(k)) {
        cur += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // longest streak
    final sortedKeys = days.keys.toList()..sort();
    int longest = 0, run = 0;
    DateTime? prev;
    for (final k in sortedKeys) {
      final parts = k.split('-').map(int.parse).toList();
      final d = DateTime(parts[0], parts[1], parts[2]);
      if (prev == null || d.difference(prev!).inDays == 1) {
        run += 1;
      } else {
        if (run > longest) longest = run;
        run = 1;
      }
      prev = d;
    }
    if (run > longest) longest = run;

    // this week: Monday..Sunday
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1)));
    int thisWeekDays = 0;
    for (int i = 0; i < 7; i++) {
      final k = _dayKey(monday.add(Duration(days: i)));
      if (days.containsKey(k)) thisWeekDays++;
    }

    return StreakInfo(
      current: cur,
      longest: longest,
      thisWeekDays: thisWeekDays,
      goalsDoneThisWeek: 0, // UI tarafında dolduracağız
    );
  }
}
