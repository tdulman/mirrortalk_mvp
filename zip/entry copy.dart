// lib/models/entry.dart
import 'dart:convert';

/// Sabah / akşam kayıt tipi
enum RecordType { morning, evening }

/// Tek bir konuşma kaydı
class Entry {
  final String id;
  final RecordType type;
  final DateTime createdAt;
  final int durationSec;
  final String? transcript;
  final List<String> tags;
  final String? videoPath;

  const Entry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.durationSec,
    this.transcript,
    this.tags = const [],
    this.videoPath,
  });

  Entry copyWith({
    String? id,
    RecordType? type,
    DateTime? createdAt,
    int? durationSec,
    String? transcript,
    List<String>? tags,
    String? videoPath,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      durationSec: durationSec ?? this.durationSec,
      transcript: transcript ?? this.transcript,
      tags: tags ?? this.tags,
      videoPath: videoPath ?? this.videoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name, // morning / evening
        'createdAt': createdAt.toIso8601String(),
        'durationSec': durationSec,
        'transcript': transcript,
        'tags': tags,
        'videoPath': videoPath,
      };

  static Entry fromJson(Map<String, dynamic> m) => Entry(
        id: m['id'] as String,
        type: (m['type'] as String) == 'evening'
            ? RecordType.evening
            : RecordType.morning,
        createdAt: DateTime.parse(m['createdAt'] as String),
        durationSec: (m['durationSec'] as num).toInt(),
        transcript: m['transcript'] as String?,
        tags:
            (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        videoPath: m['videoPath'] as String?,
      );

  /// Yardımcı: List<Entry> ↔ JSON
  static String encodeList(List<Entry> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Entry> decodeList(String txt) {
    final raw = jsonDecode(txt) as List<dynamic>;
    return raw.map((e) => Entry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
