import 'package:audiobooks/pages/main_shell.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initAudioService();
  await FileDownloader().trackTasks();
  FileDownloader().configureNotification(
    running: const TaskNotification('Downloading {filename}', '{progress}'),
    complete: const TaskNotification('Download complete', '{filename}'),
    error: const TaskNotification('Download failed', '{filename}'),
    progressBar: true,
  );
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const AudioBooksApp(),
    ),
  );
}

class AudioBooksApp extends ConsumerWidget {
  const AudioBooksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    return MaterialApp(
      title: 'Listora',
      theme: AudiobookTheme.light(),
      darkTheme: AudiobookTheme.dark(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
