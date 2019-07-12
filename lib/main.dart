import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';

void main() => runApp(AudioBooksApp());

class AudioBooksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => AudioBooksNotifier(),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: TextTheme(
            title: TextStyle(fontFamily: "Aleo",fontWeight: FontWeight.bold),
            subtitle: TextStyle(fontFamily: "Slabo", fontSize: 16.0),

          ),
          buttonColor: Theme.of(context).accentColor,
          primarySwatch: Colors.pink,
          accentColor: Colors.indigoAccent
        ),
        home: HomePage(),
      ),
    );
  }
}
