import 'package:meta/meta.dart';

class Section {
  final String number, title,playtime,listenUrl;

  Section({@required this.number, @required this.title, @required this.playtime, this.listenUrl});

  Section.fromJson(Map json):
    number=json["number"],
    title=json["title"],
    playtime=json["playtime"],
    listenUrl=json["listen_url"];

  static List<Section> fromJsonArray(List json){
    final List<Section> sections = List<Section>();
    json.map((section)=>sections.add(Section.fromJson(section)));
    return sections;
  }

}