import 'package:meta/meta.dart';
import 'dart:convert';

class Author{
  final String id;
  final String firstName;
  final String lastName;
  final String dob;
  final String dod;

  Author({@required this.id, @required this.firstName, @required this.lastName, this.dob, this.dod});

  Author.fromJson(Map json):
    id=json["id"],
    firstName=json["first_name"],
    lastName=json["last_name"],
    dob=json["dob"],
    dod=json["dod"];

  static List<Author> fromJsonArray(List json) {
    List<Author> authors = List<Author>();
    json.forEach((author)=>authors.add(Author.fromJson(author)));
    return authors;
  }

  Map<String,dynamic> toMap(){
    return {
      "id":id,
      "first_name":firstName,
      "last_name":lastName,
      "dob":dob,
      "dod":dod
    };
  }

  String toJson() {
    return json.encode(this.toMap());
  }

  static String toJsonArray(List<Author> authors){
    return json.encode(authors.map((author)=>author.toMap()).toList());
  }

}