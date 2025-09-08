class Entry {
  final String id;              // unique id
  final DateTime createdAt;     // timestamp
  final String type;            // 'morning' | 'evening'
  final int durationSec;        // seconds
  String transcript;            // transcribed text
  List<String> tags;            // labels
  String? videoPath;            // saved .mp4 (device) or simulated .txt (simulator)

  Entry({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.durationSec,
    this.transcript = '',
    List<String>? tags,
    this.videoPath,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'durationSec': durationSec,
        'transcript': transcript,
        'tags': tags,
        'videoPath': videoPath,
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        type: j['type'] as String,
        durationSec: (j['durationSec'] as num).toInt(),
        transcript: (j['transcript'] ?? '') as String,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        videoPath: j['videoPath'] as String?,
      );

  Entry copyWith({
    String? transcript,
    List<String>? tags,
    String? videoPath,
  }) {
    return Entry(
      id: id,
      createdAt: createdAt,
      type: type,
      durationSec: durationSec,
      transcript: transcript ?? this.transcript,
      tags: tags ?? this.tags,
      videoPath: videoPath ?? this.videoPath,
    );
  }
}



