import 'dart:convert';

const String _base = 'https://archive.org/download';

class AudioFile {
  final String? bookId;
  final String? title;
  final String? name;
  final String? url;
  final double? length;
  final int? track;
  final int? size;

  const AudioFile({
    this.bookId,
    this.title,
    this.name,
    this.url,
    this.length,
    this.track,
    this.size,
  });

  factory AudioFile.fromJson(Map json) {
    final bookId = json['book_id']?.toString();
    final name = json['name']?.toString();
    final url = (bookId != null && name != null) ? '$_base/$bookId/$name' : null;
    return AudioFile(
      bookId: bookId,
      title: json['title']?.toString(),
      name: name,
      track: _asTrack(json['track']),
      size: _asInt(json['size']),
      length: _asDouble(json['length']),
      url: url,
    );
  }

  factory AudioFile.fromDB(Map json) => AudioFile(
        bookId: json['book_id']?.toString(),
        title: json['title']?.toString(),
        name: json['name']?.toString(),
        track: _asInt(json['track']),
        size: _asInt(json['size']),
        length: _asDouble(json['length']),
        url: json['url']?.toString(),
      );

  static List<AudioFile> fromJsonArray(List json) =>
      [for (final a in json) AudioFile.fromJson(a)];

  static List<AudioFile> fromDBArray(List json) =>
      [for (final a in json) AudioFile.fromDB(a)];

  Map<String, dynamic> toMap() => {
        'name': name,
        'book_id': bookId,
        'url': url,
        'title': title,
        'length': length,
        'track': track,
        'size': size,
      };

  String toJson() => json.encode(toMap());

  static String toJsonArray(List<AudioFile> audiofiles) =>
      json.encode(audiofiles.map((a) => a.toMap()).toList());
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _asTrack(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  final s = v.toString();
  final first = s.split('/').first;
  return int.tryParse(first);
}
