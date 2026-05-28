import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance so settings resolve
/// synchronously (no theme flash on launch).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class AppSettings {
  final ThemeMode themeMode;
  final double defaultSpeed;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.defaultSpeed = 1.0,
  });

  AppSettings copyWith({ThemeMode? themeMode, double? defaultSpeed}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'settings.themeMode';
  static const speedKey = 'settings.defaultSpeed';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final themeIndex = _prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
    return AppSettings(
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      defaultSpeed: _prefs.getDouble(speedKey) ?? 1.0,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setDefaultSpeed(double speed) async {
    state = state.copyWith(defaultSpeed: speed);
    await _prefs.setDouble(speedKey, speed);
  }
}
