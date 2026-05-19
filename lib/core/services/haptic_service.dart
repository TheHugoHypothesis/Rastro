import 'package:flutter/services.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;

  bool isEnabled = true;

  HapticService._internal();

  /// Vibração rápida e leve para cliques ou interações comuns
  Future<void> selectionClick() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibração leve para indicação de sucesso/interações táteis gerais
  Future<void> lightImpact() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Padrão para Mudança de Direção (Duas vibrações rápidas e médias)
  Future<void> vibrateTurnChange() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  /// Padrão para Alertas de Segurança (Vibração pesada, pausa, vibração pesada)
  Future<void> vibrateSafetyAlert() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
  }
}
