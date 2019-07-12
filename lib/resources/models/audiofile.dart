import 'dart:convert';

const String _base = "https://archive.org/download";
class AudioFile{
  final String bookId;
  final String title;
  final String name;
  final String url;
  final double length;
  final int track;
  final int size;


  AudioFile.fromJson(Map json):
    bookId=json["book_id"],
    title=json["title"],
    name=json["name"],
    track=int.parse(json["track"].split("/")[0]),
    size=int.parse(json["size"]),
    length=double.parse(json["length"]),
    url="$_base/${json['book_id']}/${json['name']}";

  AudioFile.fromDB(Map json):
    bookId=json["book_id"],
    title=json["title"],
    name=json["name"],
    track=json["track"],
    size=json["size"],
    length=json["length"],
    url=json["url"];

  static List<AudioFile> fromJsonArray(List json) {
    List<AudioFile> audiofiles = List<AudioFile>();
    json.forEach((audiofile)=>audiofiles.add(AudioFile.fromJson(audiofile)));
    return audiofiles;
  }
  static List<AudioFile> fromDBArray(List json) {
    List<AudioFile> audiofiles = List<AudioFile>();
    json.forEach((audiofile)=>audiofiles.add(AudioFile.fromDB(audiofile)));
    return audiofiles;
  }

  Map<String,dynamic> toMap(){
    return {
      "name":name,
      "book_id":bookId,
      "url":url,
      "title":title,
      "length":length,
      "track":track,
      "size":size
    };
  }

  String toJson() {
    return json.encode(this.toMap());
  }

  static String toJsonArray(List<AudioFile> audiofiles){
    return json.encode(audiofiles.map((audiofile)=>audiofile.toMap()).toList());
  }

}