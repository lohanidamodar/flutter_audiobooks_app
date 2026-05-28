import 'package:audiobooks/pages/main_shell.dart';
import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
  await FileDownloader().trackTasks();
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
      theme: AudiobookTheme.dark(),
      darkTheme: AudiobookTheme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
