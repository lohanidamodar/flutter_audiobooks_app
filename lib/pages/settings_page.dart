import 'package:audiobooks/providers/providers.dart';
import 'package:audiobooks/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _storageBytesProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(downloadsServiceProvider).totalDownloadedBytes(),
);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    const mb = 1024 * 1024;
    if (bytes < mb) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * mb)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final storage = ref.watch(_storageBytesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionLabel(context, 'Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(settingsProvider.notifier).setThemeMode(mode);
              }
            },
            child: const Column(
              children: [
                RadioListTile(
                  value: ThemeMode.system,
                  title: Text('System default'),
                ),
                RadioListTile(value: ThemeMode.light, title: Text('Light')),
                RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          _sectionLabel(context, 'Playback'),
          ListTile(
            title: const Text('Default speed'),
            subtitle: const Text('Applied when a book starts playing'),
            trailing: DropdownButton<double>(
              value: settings.defaultSpeed,
              underline: const SizedBox.shrink(),
              items: const [0.75, 1.0, 1.25, 1.5, 2.0]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}x'),
                      ))
                  .toList(),
              onChanged: (s) {
                if (s != null) {
                  ref.read(settingsProvider.notifier).setDefaultSpeed(s);
                }
              },
            ),
          ),
          const Divider(),
          _sectionLabel(context, 'Storage'),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: const Text('Downloaded audio'),
            subtitle: Text(storage.when(
              data: _formatBytes,
              loading: () => 'Calculating…',
              error: (_, __) => 'Unknown',
            )),
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined,
                color: theme.colorScheme.error),
            title: Text('Remove all downloads',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _removeAll(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary)),
    );
  }

  Future<void> _removeAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove all downloads?'),
        content:
            const Text('Delete every downloaded chapter from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(downloadsServiceProvider).deleteAll();
    ref.invalidate(libraryProvider);
    ref.invalidate(_storageBytesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All downloads removed')),
      );
    }
  }
}
