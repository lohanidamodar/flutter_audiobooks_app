import 'package:meta/meta.dart';
import 'dart:convert';

class AudioFile{
  final String bookId;
  final String title;
  final String link;
  final String id;

  AudioFile({@required this.bookId, @required this.title, @required this.link, this.id});

  AudioFile.fromJson(Map json):
    id=json["id"],
    bookId=json["book_id"],
    title=json["title"],
    link=json["link"];

  static List<AudioFile> fromJsonArray(List json) {
    List<AudioFile> audiofiles = List<AudioFile>();
    json.forEach((audiofile)=>audiofiles.add(AudioFile.fromJson(audiofile)));
    return audiofiles;
  }

  Map<String,dynamic> toMap(){
    return {
      "id":id,
      "book_id":bookId,
      "link":link,
      "title":title,
    };
  }

  String toJson() {
    return json.encode(this.toMap());
  }

  static String toJsonArray(List<AudioFile> audiofiles){
    return json.encode(audiofiles.map((audiofile)=>audiofile.toMap()).toList());
  }

}