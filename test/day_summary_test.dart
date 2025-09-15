import 'package:flutter_test/flutter_test.dart';
import 'package:mirrortalk_mvp/models/day_summary.dart';

void main() {
  group('DaySummary', () {
    test('toJson / fromJson round-trip', () {
      final ds = DaySummary(
        dayKey: '2025-09-14',
        goals: ['Read 20 pages', 'Email 1 person', 'Walk 15 min'],
        done: [true, false, true],
      );

      final map = ds.toJson();
      final ds2 = DaySummary.fromJson(map);
      expect(ds2.dayKey, equals('2025-09-14'));
      expect(ds2.goals,
          equals(['Read 20 pages', 'Email 1 person', 'Walk 15 min']));
      expect(ds2.done, equals([true, false, true]));
    });

    test('emptyFor creates safe defaults', () {
      final ds = DaySummary.emptyFor(DateTime(2025, 9, 14));
      expect(ds.dayKey, equals('2025-09-14'));
      expect(ds.goals.length, greaterThanOrEqualTo(0));
      expect(ds.done.length, greaterThanOrEqualTo(0));
    });
  });
}
