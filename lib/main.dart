import 'package:audio_service/audio_service.dart';
import 'package:audiobooks/pages/main_screen.dart';
import 'package:audiobooks/resources/notifiers/audio_books_notifier.dart';
import 'package:audiobooks/resources/player_res.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';

AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await AudioService.init(
    builder: () => CustomAudioPlayer(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.popupbits.audiobooks.channel.audio',
      androidNotificationChannelName: 'Music playback',
    ),
  );
  runApp(AudioBooksApp());
}

class AudioBooksApp extends StatefulWidget {
  @override
  _AudioBooksAppState createState() => _AudioBooksAppState();
}

class _AudioBooksAppState extends State<AudioBooksApp>
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
          textTheme: TextTheme(
            headline6:
                TextStyle(fontFamily: "Aleo", fontWeight: FontWeight.bold),
            subtitle1: TextStyle(fontFamily: "Slabo", fontSize: 16.0),
          ),
          primarySwatch: Colors.pink,
        ),
        home: MainScreen(),
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
