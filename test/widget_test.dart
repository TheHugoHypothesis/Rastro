import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rastro/main.dart';
import 'package:rastro/domain/models/partner_establishment.dart';
import 'package:rastro/presentation/providers/app_state_provider.dart';
import 'package:rastro/presentation/screens/onboarding_screen.dart';

/// Notificador falso para simular conectividade online constante sem disparar Timers recorrentes.
class FakeConnectivityNotifier extends ConnectivityNotifier {
  @override
  bool build() => true;
}

/// Notificador falso de estabelecimentos parceiros para desativar a sincronização HTTP durante o teste de widgets.
class FakePartnerEstablishmentsNotifier extends PartnerEstablishmentsNotifier {
  @override
  List<PartnerEstablishment> build() => [];
}

/// Notificador falso de controle P2P para manter o Nearby Connections desativado e livre de timers nos testes.
class FakeP2PEnabledNotifier extends P2PEnabledNotifier {
  @override
  bool build() => false;
}

/// **main**
///
/// Ponto de entrada para os testes de integração visual/widgets (Widget/Smoke Tests).
/// Simula o arranque completo do app Rastro em ambiente controlado de teste.
void main() {
  testWidgets('Rastro App Bootstrap and Smoke Test', (WidgetTester tester) async {
    // Configura mock do canal do Geolocator para retornar desativado
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'isLocationServiceEnabled') {
        return false;
      }
      return null;
    });

    // Define os valores mockados iniciais para evitar erros de leitura de preferências
    SharedPreferences.setMockInitialValues({'is_first_launch_pref': true});
    final prefs = await SharedPreferences.getInstance();

    // Constrói o app injetando o mock nas dependências Riverpod
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          connectivityProvider.overrideWith(FakeConnectivityNotifier.new),
          partnerEstablishmentsProvider.overrideWith(FakePartnerEstablishmentsNotifier.new),
          p2pEnabledProvider.overrideWith(FakeP2PEnabledNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    // Garante que o widget raiz MyApp foi inflado com sucesso na árvore de componentes
    expect(find.byType(MyApp), findsOneWidget);

    // Drena os timers pendentes criados pelos atrasos da SplashScreen (ex: minDelay de 2s)
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('OnboardingScreen first launch and interaction test', (WidgetTester tester) async {
    // Configura mock do canal do Geolocator para retornar desativado
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'isLocationServiceEnabled') {
        return false;
      }
      return null;
    });

    SharedPreferences.setMockInitialValues({'is_first_launch_pref': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          connectivityProvider.overrideWith(FakeConnectivityNotifier.new),
          partnerEstablishmentsProvider.overrideWith(FakePartnerEstablishmentsNotifier.new),
          p2pEnabledProvider.overrideWith(FakeP2PEnabledNotifier.new),
        ],
        child: const MyApp(),
      ),
    );

    // Drena splash screen de 2 segundos para revelar OnboardingScreen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Deve achar OnboardingScreen
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Deve achar textos do primeiro slide
    expect(find.text('Bem-vindo ao Rastro'), findsOneWidget);
    expect(find.text('Avançar'), findsOneWidget);

    // Clica em avançar
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    // Próximo slide
    expect(find.text('Rotas Adaptadas'), findsOneWidget);
  });
}
