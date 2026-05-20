import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// **SplashScreen (View)**
///
/// Tela de splash inicial que exibe a identidade de carregamento premium do Rastro,
/// verifica permissões de GPS/localização físicas e inicia o bootstrap do app antes de
/// transicionar suavemente para a [OnboardingScreen] (se primeira execução) ou [HomeScreen] (RF001).
class SplashScreen extends ConsumerStatefulWidget {
  /// Cria uma tela de splash inicial.
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Estado interno da [SplashScreen] contendo a lógica de inicialização de recursos e permissões.
class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final minDelay = Future.delayed(const Duration(seconds: 2)); // Um pouco mais de tempo para a sensação de carregamento da tela do app e ícones
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          try {
            // Garante que o GPS pegue o primeiro fix e acorde o sensor
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                timeLimit: Duration(seconds: 3),
              ),
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      // Ignora falhas em ambientes de testes sem geolocalização nativa
    }
    
    await minDelay;
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch_pref') ?? true;
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              isFirstLaunch ? const OnboardingScreen() : const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pedal_bike_rounded, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'RASTRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
