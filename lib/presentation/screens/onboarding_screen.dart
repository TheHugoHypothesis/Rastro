import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';
import '../../core/services/haptic_service.dart';
import 'home_screen.dart';

/// **OnboardingScreen (View)**
///
/// Tela de tutorial interativa e promocional exibida na primeira inicialização do Rastro.
/// Apresenta de forma elegante e de alto contraste as funcionalidades premium (roteamento, P2P, WoT, monetização).
class OnboardingScreen extends StatefulWidget {
  /// Construtor padrão da tela de Onboarding.
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      icon: Icons.directions_bike_rounded,
      title: 'Bem-vindo ao Rastro',
      subtitle: 'Mapeando caminhos, conectando ciclistas.',
      description: 'O Rastro é o primeiro aplicativo de navegação ciclística 100% colaborativo e focado na sua segurança.',
      features: [
        'Rotas inteligentes para ciclistas',
        'Foco total em segurança urbana',
        'Interface limpa de alto contraste'
      ],
    ),
    OnboardingSlideData(
      icon: Icons.tune_rounded,
      title: 'Rotas Adaptadas',
      subtitle: 'Caminhos calculados para a sua realidade.',
      description: 'Diga adeus a rotas inadequadas. O Rastro calcula caminhos específicos considerando o seu esforço físico e o tipo de bicicleta que você usa.',
      features: [
        'Evite irregularidades com bikes Dobráveis',
        'Rotas asfalto liso para Speed (Racing)',
        'Escolha entre Menor Esforço ou Menor Distância'
      ],
    ),
    OnboardingSlideData(
      icon: Icons.bluetooth_searching_rounded,
      title: 'Rede Mesh P2P Offline',
      subtitle: 'Sincronização comunitária sem internet.',
      description: 'Troque avaliações de segurança de vias e novos pontos de interesse com outros ciclistas em tempo real via Bluetooth e Wi-Fi Direct em segundo plano.',
      features: [
        'Compartilhamento 100% descentralizado',
        'Não consome plano de dados móveis',
        'Resiliência total fora de cobertura'
      ],
    ),
    OnboardingSlideData(
      icon: Icons.workspace_premium_rounded,
      title: 'Parceiros Bike-Friendly',
      subtitle: 'Monetização de paradas patrocinadas.',
      description: 'Encontre pontos iluminados no mapa que oferecem recarga elétrica, ferramentas gratuitas e água. O app sugere desvios inteligentes de parada durante o seu trajeto.',
      features: [
        'Locais validados por criptografia do admin',
        'Waypoints intermediários automáticos',
        'Descontos e apoio em percursos longos'
      ],
    ),
    OnboardingSlideData(
      icon: Icons.record_voice_over_rounded,
      title: 'Navegação Silenciosa',
      subtitle: 'Olhos fixos na pista, segurança tátil.',
      description: 'Navegue por áudio sintetizado em português (TTS) e padrões avançados de vibração física em seu bolso para manobras e perigos na rota.',
      features: [
        'Instruções sonoras sem tirar o foco da via',
        'Diferentes ritmos de vibração para curvas',
        'Design totalmente acessível para daltônicos'
      ],
    ),
  ];

  Future<void> _completeOnboarding() async {
    await HapticService().lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch_pref', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _onPageChanged(int index) {
    HapticService().selectionClick();
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.lightPrimary;
    final surfaceColor = isDark ? AppColors.surfaceElevated : AppColors.lightSurface;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textMuted : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho superior com botão pular
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pedal_bike_rounded, color: primaryColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'RASTRO',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: subtitleColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Pular',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            
            // Slider principal
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        
                        // Ícone grande com animação suave e design neo-brutalista
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: isDark ? AppColors.border : AppColors.lightBorder,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.1),
                                        offset: const Offset(4, 4),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(slide.icon, size: 64, color: primaryColor),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Título do slide
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtítulo descritivo em destaque
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Descrição longa
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Lista de recursos marcantes
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.border : AppColors.lightBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: slide.features.map((feature) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Área inferior com botões e indicador
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador de slides
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? primaryColor : subtitleColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  
                  // Botão de Avançar ou Iniciar
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white24, width: 1),
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding;
                        _completeOnboarding();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1
                              ? 'Começar ↗'
                              : 'Avançar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo de dados representativo para cada slide do onboarding.
class OnboardingSlideData {
  /// Ícone decorativo representativo do recurso.
  final IconData icon;

  /// Título em destaque do slide.
  final String title;

  /// Subtítulo explicativo resumido.
  final String subtitle;

  /// Descrição textual detalhada e promocional do recurso.
  final String description;

  /// Lista de tópicos específicos e facilidades.
  final List<String> features;

  /// Inicializa os dados estruturados de um slide promocional do onboarding.
  OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}
