import 'package:flutter/services.dart';

/// **HapticService (Model/Service)**
///
/// Serviço Singleton encarregado por disparar vibrações físicas e respostas táteis.
/// Facilita a navegação sem tela de ciclistas através de padrões táteis intuitivos (RF003).
class HapticService {
  static final HapticService _instance = HapticService._internal();

  /// Construtor de fábrica (Factory) que retorna a instância única global do Singleton.
  factory HapticService() => _instance;

  /// Indica se a resposta física tátil está habilitada nas configurações reativas.
  bool isEnabled = true;

  HapticService._internal();

  /// Vibração rápida e leve para cliques de botão ou interações comuns de seleção de UI.
  Future<void> selectionClick() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibração leve para indicação de conclusão silenciosa ou interações táteis de confirmação geral.
  Future<void> lightImpact() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Padrão tátil para Mudança de Direção (Duas vibrações sucessivas rápidas e de médio impacto).
  Future<void> vibrateTurnChange() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  /// Padrão tátil para Alertas de Segurança (Vibração de alto impacto, pausa e segunda vibração pesada).
  Future<void> vibrateSafetyAlert() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
  }
}
