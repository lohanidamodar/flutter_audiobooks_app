import 'package:audiobooks/resources/models/models.dart';
import 'package:audiobooks/resources/repository.dart';
import 'package:http/http.dart' show Client;
import 'dart:convert';

final _metadata = "https://archive.org/metadata/";
final _commonParams = "q=collection:(librivoxaudio)&fl=runtime,avg_rating,num_reviews,title,description,identifier,creator,date,downloads,subject,item_size";

final _latestBooksApi = "https://archive.org/advancedsearch.php?$_commonParams&sort[]=addeddate desc&output=json";

final _mostDownloaded = "https://archive.org/advancedsearch.php?$_commonParams&sort[]=downloads desc&rows=10&page=1&output=json";
  final query="title:(secret tomb) AND collection:(librivoxaudio)";

class ArchiveApiProvider implements Source{

  Client client = Client();

  Future<List<Book>> fetchBooks(int offset, int limit) async {
    final response = await client.get(Uri.parse("$_latestBooksApi&rows=$limit&page=${offset/limit + 1}"));
    Map resJson = json.decode(response.body);
    return Book.fromJsonArray(resJson['response']['docs']);
  }

  Future<List<AudioFile>> fetchAudioFiles(String bookId) async {
    final response = await client.get(Uri.parse("$_metadata/$bookId/files"));
    Map resJson = json.decode(response.body);
    List<AudioFile> afiles = List<AudioFile>();
    resJson["result"].forEach((item) {
      if(item["source"] == "original" &&item["track"] != null) {
        item["book_id"] = bookId;
          afiles.add(AudioFile.fromJson(item));
      }
    });
    return afiles;
  }

  @override
  Future<List<Book>> topBooks() async {
    final response = await client.get(Uri.parse("$_mostDownloaded"));
    Map resJson = json.decode(response.body);
    return Book.fromJsonArray(resJson['response']['docs']);
  }

}

final archiveApiProvider = ArchiveApiProvider();