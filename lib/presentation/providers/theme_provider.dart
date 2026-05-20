import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_state_provider.dart';

/// **ThemeNotifier (ViewModel)**
///
/// Gerencia reativamente o modo visual do tema global do aplicativo (Claro ou Escuro).
/// Permite que as Views adaptem sua estilização visual premium de forma instantânea.
class ThemeNotifier extends Notifier<ThemeMode> {
  /// Inicializa o tema padrão recuperando a configuração persistida do usuário.
  ///
  /// Retorno:
  /// - `ThemeMode` correspondente ao tema salvo ou padrão do sistema.
  @override
  ThemeMode build() {
    return ref.read(preferencesServiceProvider).loadThemeMode();
  }

  /// Alterna o tema de forma cíclica entre Claro e Escuro e persiste no `PreferencesService`.
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }

  /// Define explicitamente o tema como Escuro e persiste a configuração.
  void setDark() {
    state = ThemeMode.dark;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }
  
  /// Define explicitamente o tema como Claro e persiste a configuração.
  void setLight() {
    state = ThemeMode.light;
    ref.read(preferencesServiceProvider).saveThemeMode(state);
  }
  
  /// Atalho de conveniência para verificar se o modo ativo atual é Escuro.
  bool get isDark => state == ThemeMode.dark;
}

/// Provedor global para injeção e observação do estado visual [ThemeMode].
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
