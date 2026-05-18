import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_state_provider.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.read(preferencesServiceProvider).loadThemeMode();
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }

  void setDark() {
    state = ThemeMode.dark;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }
  
  void setLight() {
    state = ThemeMode.light;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }
  
  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
