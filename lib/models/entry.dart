// lib/models/entry.dart
import 'dart:convert';

enum RecordType { morning, evening }

class Entry {
  final String id;
  final RecordType type;
  final DateTime createdAt;
  final int durationSec;
  final String? transcript;
  final List<String> tags;
  final String? videoPath;

  Entry({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.durationSec,
    this.transcript,
    List<String>? tags,
    this.videoPath,
  }) : tags = List<String>.from(tags ?? const []);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'durationSec': durationSec,
        'transcript': transcript,
        'tags': tags,
        'videoPath': videoPath,
      };

  factory Entry.fromJson(Map<String, dynamic> m) {
    return Entry(
      id: m['id'] as String,
      type: RecordType.values.firstWhere(
        (e) => e.name == (m['type']?.toString() ?? 'morning'),
        orElse: () => RecordType.morning,
      ),
      createdAt:
          DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      durationSec:
          (m['durationSec'] is num) ? (m['durationSec'] as num).toInt() : 0,
      transcript: m['transcript'] as String?,
      tags:
          (m['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      videoPath: m['videoPath'] as String?,
    );
  }

  static String encodeList(List<Entry> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Entry> decodeList(String txt) {
    if (txt.trim().isEmpty) return <Entry>[];
    final raw = jsonDecode(txt) as List<dynamic>;
    return raw
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
