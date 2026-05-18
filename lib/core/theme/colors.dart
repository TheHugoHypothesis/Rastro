import 'package:flutter/material.dart';

class AppColors {
  // === MODO ESCURO (Roxo + Preto) ===
  static const Color primary = Color(0xFF7C3AED);        // Roxo principal
  static const Color primaryLight = Color(0xFFA855F7);   // Roxo claro / glow
  static const Color primaryDark = Color(0xFF5B21B6);    // Roxo escuro

  static const Color background = Color(0xFF0D0D0F);     // Preto profundo
  static const Color surface = Color(0xFF1A1A2E);        // Superfície escura azulada
  static const Color surfaceElevated = Color(0xFF252540); // Card elevado
  static const Color cardDark = Color(0xFF16213E);       // Card dark

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6B6B8A);

  static const Color routeColorDark = Color(0xFFA855F7); // Cor da rota no modo escuro
  static const Color border = Color(0xFF2D2D4E);

  // === MODO CLARO (Branco + Preto) ===
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F0F5);
  static const Color lightPrimary = Color(0xFF1A1A2E);   // Preto azulado
  static const Color lightTextPrimary = Color(0xFF0D0D0F);
  static const Color lightTextSecondary = Color(0xFF555566);
  static const Color routeColorLight = Color(0xFF1A1A1A); // Cor da rota no modo claro
  static const Color lightBorder = Color(0xFFE0E0EA);

  // === Cores de POI (pontos de interesse) ===
  static const Color poiFood = Color(0xFFFF9800);         // Laranja - restaurante
  static const Color poiHospital = Color(0xFFE53935);     // Vermelho - hospital
  static const Color poiBike = Color(0xFF43A047);         // Verde - bike shop
  static const Color poiParking = Color(0xFF1E88E5);      // Azul - estacionamento

  // Gradiente roxo
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGlowGradient = LinearGradient(
    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
