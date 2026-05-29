import 'dart:convert';

import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:http/http.dart' show Client;

const _metadata = "https://archive.org/metadata";
const _fl =
    "fl=runtime,avg_rating,num_reviews,title,description,identifier,creator,date,downloads,subject,item_size";
const _commonParams = "q=collection:(librivoxaudio)&$_fl";

const _latestBooksApi =
    "https://archive.org/advancedsearch.php?$_commonParams&sort[]=addeddate desc&output=json";

const _mostDownloaded =
    "https://archive.org/advancedsearch.php?$_commonParams&sort[]=downloads desc&rows=10&page=1&output=json";

class ArchiveApiProvider implements Source {
  Client client = Client();

  Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('archive.org responded ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response shape');
    }
    return decoded;
  }

  List<Book> _docsToBooks(Map<String, dynamic> json) {
    final docs = (json['response'] as Map?)?['docs'];
    if (docs is! List) return [];
    return Book.fromJsonArray(docs);
  }

  @override
  Future<List<Book>> fetchBooks(int offset, int limit) async {
    final page = (offset ~/ limit) + 1;
    final json =
        await _getJson("$_latestBooksApi&rows=$limit&page=$page");
    return _docsToBooks(json);
  }

  @override
  Future<List<AudioFile>> fetchAudioFiles(String? bookId) async {
    if (bookId == null) return [];
    final json = await _getJson("$_metadata/$bookId/files");
    final result = json['result'];
    if (result is! List) return [];
    final afiles = <AudioFile>[];
    for (final item in result) {
      if (item is! Map) continue;
      if (item["source"] == "original" && item["track"] != null) {
        final map = Map<String, dynamic>.from(item)..["book_id"] = bookId;
        try {
          afiles.add(AudioFile.fromJson(map));
        } catch (_) {
          // skip malformed entries
        }
      }
    }
    return afiles;
  }

  @override
  Future<List<Book>> topBooks() async {
    return _docsToBooks(await _getJson(_mostDownloaded));
  }

  Future<List<Book>> _query(String q, {int rows = 30}) async {
    final encoded = Uri.encodeQueryComponent('$q AND collection:(librivoxaudio)');
    final url = 'https://archive.org/advancedsearch.php?q=$encoded&$_fl'
        '&sort[]=downloads desc&rows=$rows&page=1&output=json';
    return _docsToBooks(await _getJson(url));
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    // Match either the title or the author/creator so typing an author surfaces
    // their readings.
    return _query('(title:($trimmed) OR creator:($trimmed))');
  }

  @override
  Future<List<Book>> booksByAuthor(String author) async {
    final trimmed = author.trim();
    if (trimmed.isEmpty) return [];
    return _query('creator:("$trimmed")', rows: 20);
  }
}

final archiveApiProvider = ArchiveApiProvider();
