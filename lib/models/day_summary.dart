// lib/models/day_summary.dart
class DaySummary {
  final String dayKey;            // yyyy-MM-dd
  final DateTime day;
  final List<String?> goals;      // 3 hedef
  final List<bool?> completed;    // 3 checkbox

  DaySummary({
    required this.dayKey,
    required this.day,
    required this.goals,
    required this.completed,
  });

  factory DaySummary.emptyFor(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    final key = "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
    return DaySummary(
      dayKey: key,
      day: date,
      goals: [null, null, null],
      completed: [false, false, false],
    );
  }

  DaySummary copyWith({
    List<String?>? goals,
    List<bool?>? completed,
  }) =>
      DaySummary(
        dayKey: dayKey,
        day: day,
        goals: goals ?? this.goals,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'day': day.toIso8601String(),
        'goals': goals,
        'completed': completed,
      };

  factory DaySummary.fromJson(Map<String, dynamic> m) => DaySummary(
        dayKey: m['dayKey'] as String,
        day: DateTime.parse(m['day'] as String),
        goals: (m['goals'] as List?)?.cast<String?>() ?? [null, null, null],
        completed:
            (m['completed'] as List?)?.cast<bool?>() ?? [false, false, false],
      );
}

