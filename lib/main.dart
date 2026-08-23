import 'package:audiobooks/pages/main_shell.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:audiobooks/resources/audio_helper.dart';
import 'package:audiobooks/theme/audiobook_theme.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
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
      builder: (context, child) {
        // Bridges packages that still import package:flutter/material.dart —
        // google_fonts, cached_network_image/octo_image, just_audio_background
        // — so their widgets can resolve a legacy Theme and
        // MaterialLocalizations inside this material_ui tree. Without it they
        // throw at runtime.
        // Deprecated upstream on purpose: it is a migration utility, and it
        // stays necessary for exactly as long as our dependencies keep
        // importing frozen Material. Drop it once they no longer do.
        // ignore: deprecated_member_use
        return MaterialUiCompatibilityBridge(child: child!);
      },
      home: const MainShell(),
    );
  }
}
