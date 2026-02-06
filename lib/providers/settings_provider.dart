import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final double fontSize;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 16.0,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    fontSize: fontSize ?? this.fontSize,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';

  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;
    state = SettingsState(
      themeMode: ThemeMode.values[themeModeIndex],
      fontSize: fontSize,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
