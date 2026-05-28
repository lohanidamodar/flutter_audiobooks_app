import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
  FileDownloader().configureNotification(
    running: const TaskNotification('Downloading {filename}', '{progress}'),
    complete: const TaskNotification('Download complete', '{filename}'),
    error: const TaskNotification('Download failed', '{filename}'),
    progressBar: true,
  );
  runApp(const ProviderScope(child: AudioBooksApp()));
}

class AudioBooksApp extends StatelessWidget {
  const AudioBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobooks',
      theme: AudiobookTheme.light(),
      darkTheme: AudiobookTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
