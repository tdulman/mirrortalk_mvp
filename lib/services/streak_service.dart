// lib/services/streak_service.dart
import '../models/day_summary.dart';

class StreakInfo {
  final int current; // consecutive days ending today if active
  final int longest; // best historical streak
  final int thisWeekDays; // Mon..Sun active days (habit-true)
  final int goalsDoneThisWeek; // # of done==true in this week

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

  /// HABIT-TRUE STREAK:
  /// Bir gün "aktif" sayılır eğer DaySummary.done listesindeki herhangi bir eleman true ise.
  /// 'since' başlangıcından bugüne kadar tarar (performans için makul bir pencere öner: 120-180 gün).
  static Future<StreakInfo> computeHabitTrue({
    required DateTime since,
    required Future<DaySummary> Function(DateTime day) getDaySummary,
  }) async {
    // 1) Pencere: since..today (gün gün)
    final today = DateTime.now();
    final start = DateTime(since.year, since.month, since.day);
    final end = DateTime(today.year, today.month, today.day);

    // aktif günlerin dayKey'lerini topla
    final active = <String>{};

    // hafta sayımı için (Mon..Sun)
    final monday = end.subtract(Duration(days: end.weekday - 1));
    int goalsDoneThisWeek = 0;

    // Tarama
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      final ds = await getDaySummary(cursor);
      final isActive = ds.done.any((d) => d == true);

      if (isActive) {
        active.add(_dayKey(cursor));
      }

      // Haftalık goals-done sayımı
      if (!cursor.isBefore(monday) &&
          !cursor.isAfter(monday.add(const Duration(days: 6)))) {
        goalsDoneThisWeek += ds.done.where((d) => d == true).length;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    // 2) current streak: bugünden geriye aralıksız aktif gün say
    int current = 0;
    DateTime c = end;
    while (active.contains(_dayKey(c))) {
      current += 1;
      c = c.subtract(const Duration(days: 1));
    }

    // 3) longest streak: start..end arası tüm günleri dola
    int longest = 0, run = 0;
    DateTime l = start;
    while (!l.isAfter(end)) {
      if (active.contains(_dayKey(l))) {
        run += 1;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
      l = l.add(const Duration(days: 1));
    }

    // 4) thisWeekDays: Mon..Sun arası aktif gün sayısı
    int thisWeekDays = 0;
    for (int i = 0; i < 7; i++) {
      final dk = _dayKey(monday.add(Duration(days: i)));
      if (active.contains(dk)) thisWeekDays++;
    }

    return StreakInfo(
      current: current,
      longest: longest,
      thisWeekDays: thisWeekDays,
      goalsDoneThisWeek: goalsDoneThisWeek,
    );
  }
}
