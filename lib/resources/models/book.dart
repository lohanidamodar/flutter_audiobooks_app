const imageRoot = 'https://archive.org/services/get-item-image.php?identifier=';

class Book {
  final String title;
  final String id;
  final String? description;
  final String? totalTime;
  final String? author;
  final DateTime? date;
  final int? downloads;
  final List<String> subject;
  final int? size;
  final double? rating;
  final int? reviews;

  const Book({
    required this.id,
    required this.title,
    this.description,
    this.totalTime,
    this.author,
    this.date,
    this.downloads,
    this.subject = const [],
    this.size,
    this.rating,
    this.reviews,
  });

  factory Book.fromJson(Map json) {
    final rawSubject = json['subject'];
    final subject = rawSubject is String
        ? <String>[rawSubject]
        : rawSubject is List
            ? rawSubject.map((e) => e.toString()).toList()
            : <String>[];
    final rawDate = json['date'];
    DateTime? parsedDate;
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return Book(
      id: (json['identifier'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      totalTime: json['runtime']?.toString(),
      author: json['creator']?.toString(),
      date: parsedDate,
      downloads: _asInt(json['downloads']),
      subject: subject,
      size: _asInt(json['item_size']),
      rating: _asDouble(json['avg_rating']),
      reviews: _asInt(json['num_reviews']),
      description: json['description']?.toString(),
    );
  }

  factory Book.fromDB(Map json) {
    final rawSubject = json['subject'];
    final subject = rawSubject is String && rawSubject.isNotEmpty
        ? rawSubject.split(';')
        : <String>[];
    final rawDate = json['date'];
    DateTime? parsedDate;
    if (rawDate is String && rawDate.isNotEmpty) {
      final millis = int.tryParse(rawDate);
      if (millis != null) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
    return Book(
      id: (json['identifier'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      totalTime: json['runtime']?.toString(),
      author: json['creator']?.toString(),
      date: parsedDate,
      downloads: _asInt(json['downloads']),
      subject: subject,
      size: _asInt(json['item_size']),
      rating: _asDouble(json['avg_rating']),
      reviews: _asInt(json['num_reviews']),
      description: json['description']?.toString(),
    );
  }

  static List<Book> fromJsonArray(List jsonBook) =>
      [for (final b in jsonBook) Book.fromJson(b)];

  static List<Book> fromDbArray(List jsonBook) =>
      [for (final b in jsonBook) Book.fromDB(b)];

  Map<String, dynamic> toMap() => {
        'identifier': id,
        'title': title,
        'description': description,
        'runtime': totalTime,
        'creator': author,
        'date': date?.millisecondsSinceEpoch.toString(),
        'downloads': downloads,
        'subject': subject.join(';'),
        'item_size': size,
        'avg_rating': rating,
        'num_reviews': reviews,
      };

  String get image => '$imageRoot$id';
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
