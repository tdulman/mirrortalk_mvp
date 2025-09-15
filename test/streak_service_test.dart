import 'package:flutter_test/flutter_test.dart';
import 'package:mirrortalk_mvp/models/day_summary.dart';
import 'package:mirrortalk_mvp/services/streak_service.dart';

Future<DaySummary> _fakeGetDaySummary(DateTime d) async {
  // Pazartesi=1 ... Pazar=7; sadece bazı günleri done sayalım
  final k = DaySummary.makeDayKey(d);
  final weekday = d.weekday;
  final doneToday =
      (weekday == 1 || weekday == 3 || weekday == 5); // Mon/Wed/Fri
  return DaySummary(
    dayKey: k,
    goals: ['A', 'B', 'C'],
    done: [doneToday, false, false],
  );
}

void main() {
  test('computeHabitTrue: basic streak & weekly aggregates', () async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final info = await StreakService.computeHabitTrue(
      since: since,
      getDaySummary: _fakeGetDaySummary,
    );

    expect(info.current, greaterThanOrEqualTo(0));
    expect(info.longest, greaterThanOrEqualTo(info.current));
    expect(info.thisWeekDays, inInclusiveRange(0, 7));
    expect(info.goalsDoneThisWeek, inInclusiveRange(0, 21)); // 3 goals * 7 days
  });
}
