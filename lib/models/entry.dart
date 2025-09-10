// lib/models/entry.dart
import 'dart:convert';

enum RecordType { morning, evening }

class DaySummary {
  final List<String> goals;        // 3 sabah hedefi
  final List<bool> eveningChecks;  // 3 akşam tik

  DaySummary({
    required this.goals,
    required this.eveningChecks,
  });

  DaySummary copyWith({
    List<String>? goals,
    List<bool>? eveningChecks,
  }) =>
      DaySummary(
        goals: goals ?? this.goals,
        eveningChecks: eveningChecks ?? this.eveningChecks,
      );

  Map<String, dynamic> toJson() => {
        'goals': goals,
        'checks': eveningChecks,
      };

  factory DaySummary.fromJson(Map<String, dynamic> m) => DaySummary(
        goals: (m['goals'] as List?)?.cast<String>() ?? ['', '', ''],
        eveningChecks: (m['checks'] as List?)?.cast<bool>() ?? [false, false, false],
      );
}

class Entry {
  final String id;
  final RecordType type;
  final DateTime createdAt;
  final int durationSec;
  final String? transcript;
  final List<String> tags;
  final String? videoPath;

  /// Yeni: o güne ait özet
  final DaySummary? summary;

  Entry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.durationSec,
    this.transcript,
    this.tags = const [],
    this.videoPath,
    this.summary,
  });

  Entry copyWith({
    String? id,
    RecordType? type,
    DateTime? createdAt,
    int? durationSec,
    String? transcript,
    List<String>? tags,
    String? videoPath,
    DaySummary? summary,
  }) =>
      Entry(
        id: id ?? this.id,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        durationSec: durationSec ?? this.durationSec,
        transcript: transcript ?? this.transcript,
        tags: tags ?? this.tags,
        videoPath: videoPath ?? this.videoPath,
        summary: summary ?? this.summary,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'durationSec': durationSec,
        'transcript': transcript,
        'tags': tags,
        'videoPath': videoPath,
        'summary': summary == null ? null : summary!.toJson(),
      };

  factory Entry.fromJson(Map<String, dynamic> m) => Entry(
        id: m['id'] as String,
        type: (m['type'] as String) == 'evening' ? RecordType.evening : RecordType.morning,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        durationSec: (m['durationSec'] as num? ?? 0).toInt(),
        transcript: m['transcript'] as String?,
        tags: (m['tags'] as List?)?.cast<String>() ?? const [],
        videoPath: m['videoPath'] as String?,
        summary: (m['summary'] is Map<String, dynamic>)
            ? DaySummary.fromJson(m['summary'] as Map<String, dynamic>)
            : null,
      );

  static String encodeList(List<Entry> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Entry> decodeList(String txt) {
    final raw = (jsonDecode(txt) as List).cast<Map>().cast<Map<String, dynamic>>();
    return raw.map((m) => Entry.fromJson(m)).toList();
  }
}








