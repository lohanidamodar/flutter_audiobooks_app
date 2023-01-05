const imageRoot = "https://archive.org/services/get-item-image.php?identifier=";

class Book {
  final String title;
  final String id;
  final String? description;
  final String? totalTime;
  final String? author;
  final DateTime? date;
  final int? downloads;
  final List<dynamic>? subject;
  final int? size;
  final double? rating;
  final int? reviews;

  Book.fromJson(Map jsonBook):
    id=jsonBook["identifier"] ?? '',
    title=jsonBook["title"] ?? '',
    totalTime=jsonBook["runtime"],
    author=jsonBook["creator"],
    date= jsonBook['date'] != null ? DateTime.parse(jsonBook["date"]) : null,
    downloads=jsonBook["downloads"],
    subject= jsonBook["subject"] is String ? [jsonBook["subject"]] : jsonBook["subject"],
    size=jsonBook["item_size"],
    rating= jsonBook["avg_rating"] != null ? double.parse(jsonBook["avg_rating"].toString()) : null,
    reviews=jsonBook["num_reviews"],
    description=jsonBook["description"];

  Book.fromDB(Map jsonBook):
    id=jsonBook["identifier"] ?? '',
    title=jsonBook["title"] ?? '',
    totalTime=jsonBook["runtime"],
    author=jsonBook["creator"],
    date=DateTime.fromMillisecondsSinceEpoch(int.parse(jsonBook["date"])),
    downloads=jsonBook["downloads"],
    subject=jsonBook["subject"].split(';'),
    size=jsonBook["item_size"],
    rating= jsonBook["avg_rating"] != null ? double.parse(jsonBook["avg_rating"]) : null,
    reviews=jsonBook["num_reviews"],
    description=jsonBook["description"];


  static List<Book> fromJsonArray(List jsonBook) {
    List<Book> books = <Book>[];
    for (var book in jsonBook) {
      books.add(Book.fromJson(book));
    }
    return books;
  }
  static List<Book> fromDbArray(List jsonBook) {
    List<Book> books = <Book>[];
    for (var book in jsonBook) {
      books.add(Book.fromDB(book));
    }
    return books;
  }

  Map<String,dynamic> toMap() {
    return Map<String, dynamic>.from({
      "identifier":id,
      "title":title,
      "description":description,
      "runtime":totalTime,
      "creator":author,
      "date":date!.millisecondsSinceEpoch.toString(),
      "downloads":downloads,
      "subject":subject!.join(";"),
      "item_size":size,
      "avg_rating":rating,
      "num_reviews":reviews,
    });
  }

  String? getIdentifier() {
    return id;
  }

  String get image => "$imageRoot${getIdentifier()}"; 
}