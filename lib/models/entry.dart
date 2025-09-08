class Entry {
  final String id;              // benzersiz id
  final DateTime createdAt;     // kayıt zamanı
  final String type;            // 'morning' | 'evening'
  final int durationSec;        // saniye
  String transcript;            // transcribe sonucu
  List<String> tags;            // etiketler

  Entry({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.durationSec,
    this.transcript = '',
    List<String>? tags,
  }) : tags = tags ?? [];

  // JSON'a çevir
  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'durationSec': durationSec,
        'transcript': transcript,
        'tags': tags,
      };

  // JSON'dan nesneye çevir
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        type: j['type'] as String,
        durationSec: (j['durationSec'] as num).toInt(),
        transcript: (j['transcript'] ?? '') as String,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  // Kısmi güncelleme
  Entry copyWith({String? transcript, List<String>? tags}) {
    return Entry(
      id: id,
      createdAt: createdAt,
      type: type,
      durationSec: durationSec,
      transcript: transcript ?? this.transcript,
      tags: tags ?? this.tags,
    );
  }
}


