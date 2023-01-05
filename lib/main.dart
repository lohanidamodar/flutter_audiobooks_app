import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await initAudioService();
  runApp(const AudioBooksApp());
}

class AudioBooksApp extends StatefulWidget {
  const AudioBooksApp({Key? key}) : super(key: key);

  @override
  AudioBooksAppState createState() => AudioBooksAppState();
}

class AudioBooksAppState extends State<AudioBooksApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    connect();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        connect();
        break;
      case AppLifecycleState.paused:
        disconnect();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioBooksNotifier(),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            headline6:
                TextStyle(fontFamily: "Aleo", fontWeight: FontWeight.bold),
            subtitle1: TextStyle(fontFamily: "Slabo", fontSize: 16.0),
          ),
          primarySwatch: Colors.pink,
        ),
        home: const HomePage(),
      ),
    );
  }

  void connect() async {
    // await AudioService.connect();
  }

  void disconnect() {
    // AudioService.disconnect();
  }
}
