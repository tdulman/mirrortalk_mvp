// lib/models/day_summary.dart
//
// ► TEK STANDART API
//   - dayKey: 'YYYY-MM-DD' (gün kimliği)
//   - goals : List<String> (3 eleman, boş string olabilir)
//   - done  : List<bool>   (3 eleman)
//
// ► GERİYE DÖNÜK UYUMLULUK
//   - fromJson() eski şemayı da okur: goal1/2/3 ve done1/2/3
//   - StorageService uyumu için: DaySummary.emptyFor(DateTime) ve .dayKey mevcut

class DaySummary {
  final String dayKey;
  final List<String> goals;
  final List<bool> done;

  DaySummary({
    required this.dayKey,
    List<String>? goals,
    List<bool>? done,
  })  : goals = _normGoals(goals),
        done = _normDone(done);

  // Gün anahtarı üret (YYYY-MM-DD)
  static String makeDayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  // StorageService bu fabrikayı çağırıyor
  factory DaySummary.emptyFor(DateTime day) =>
      DaySummary(dayKey: makeDayKey(day));

  DaySummary copyWith({
    String? dayKey,
    List<String>? goals,
    List<bool>? done,
  }) {
    return DaySummary(
      dayKey: dayKey ?? this.dayKey,
      goals: goals ?? this.goals,
      done: done ?? this.done,
    );
  }

  // ----- JSON -----
  factory DaySummary.fromJson(Map<String, dynamic> json) {
    final dk = (json['dayKey'] ??
            json['day'] ??
            json['date'] ??
            makeDayKey(DateTime.now()))
        .toString();

    List<String>? goals;
    if (json['goals'] is List) {
      goals = (json['goals'] as List)
          .map((e) => (e == null) ? '' : e.toString())
          .toList();
    } else {
      final g1 = json['goal1'], g2 = json['goal2'], g3 = json['goal3'];
      if (g1 != null || g2 != null || g3 != null) {
        goals = [
          g1?.toString() ?? '',
          g2?.toString() ?? '',
          g3?.toString() ?? ''
        ];
      }
    }

    List<bool>? done;
    if (json['done'] is List) {
      done = (json['done'] as List).map((e) {
        if (e is bool) return e;
        if (e is num) return e != 0;
        return (e?.toString().toLowerCase() == 'true');
      }).toList();
    } else {
      final d1 = json['done1'], d2 = json['done2'], d3 = json['done3'];
      if (d1 != null || d2 != null || d3 != null) {
        bool cast(x) {
          if (x is bool) return x;
          if (x is num) return x != 0;
          return (x?.toString().toLowerCase() == 'true');
        }

        done = [cast(d1), cast(d2), cast(d3)];
      }
    }

    return DaySummary(dayKey: dk, goals: goals, done: done);
  }

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'goals': goals,
        'done': done,
      };

  // ----- Helpers -----
  static List<String> _normGoals(List<String>? input) {
    final out = <String>[];
    if (input != null) out.addAll(input.take(3));
    while (out.length < 3) out.add('');
    return out;
  }

  static List<bool> _normDone(List<bool>? input) {
    final out = <bool>[];
    if (input != null) out.addAll(input.take(3));
    while (out.length < 3) out.add(false);
    return out;
  }
}
