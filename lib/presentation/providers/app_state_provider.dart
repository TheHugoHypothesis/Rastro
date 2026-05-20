import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../domain/models/safety_evaluation.dart';
import '../../domain/models/partner_establishment.dart';
import '../../core/services/p2p_mesh_sync_service.dart';
import '../../core/services/partner_sync_service.dart';
import '../../data/local/preferences_service.dart';
import '../../data/remote/routing_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/haptic_service.dart';

/// Provedor bruto para injeção da instância de [SharedPreferences] de baixo nível do dispositivo.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Provedor para injeção do gerenciador de preferências estruturado [PreferencesService] (Model Layer).
final preferencesServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

/// **BikeTypeNotifier (ViewModel)**
///
/// Gerencia reativamente o tipo de bicicleta ativa do ciclista.
class BikeTypeNotifier extends Notifier<BikeType> {
  /// Inicializa e carrega a bicicleta ativa salvada anteriormente em disco.
  @override
  BikeType build() {
    return ref.read(preferencesServiceProvider).loadBikeType() ?? BikeType.comum;
  }
  
  /// Atualiza o tipo de bicicleta ativa e persiste no disco local.
  ///
  /// Parâmetros:
  /// - [type]: Novo tipo de bicicleta (`BikeType`).
  void updateBikeType(BikeType type) {
    state = type;
    ref.read(preferencesServiceProvider).saveBikeType(type);
  }
}

/// Provedor reativo para observar o tipo de bicicleta ativa no roteamento.
final bikeTypeProvider = NotifierProvider<BikeTypeNotifier, BikeType>(BikeTypeNotifier.new);

/// **RouteStrategyNotifier (ViewModel)**
///
/// Gerencia a estratégia/heurística de roteamento (ex: Segurança, Rapidez).
class RouteStrategyNotifier extends Notifier<RouteStrategy> {
  /// Inicializa e carrega a estratégia ativa do armazenamento.
  @override
  RouteStrategy build() {
    return ref.read(preferencesServiceProvider).loadRouteStrategy() ?? RouteStrategy.seguranca;
  }
  
  /// Atualiza a estratégia ativa e persiste no disco local.
  ///
  /// Parâmetros:
  /// - [newStrategy]: Nova estratégia (`RouteStrategy`).
  void updateStrategy(RouteStrategy newStrategy) {
    state = newStrategy;
    ref.read(preferencesServiceProvider).saveRouteStrategy(newStrategy);
  }
}

/// Provedor reativo para observar a estratégia ativa de rotas.
final routeStrategyProvider = NotifierProvider<RouteStrategyNotifier, RouteStrategy>(RouteStrategyNotifier.new);

/// **SurfaceSmoothnessNotifier (ViewModel)**
///
/// Controla se o aplicativo deve dar prioridade a asfaltos suaves e estáveis.
class SurfaceSmoothnessNotifier extends Notifier<bool> {
  /// Retorna o valor inicial padrão (suavidade ativa).
  @override
  bool build() => true;
  
  /// Altera o filtro de pavimentação lisa.
  ///
  /// Parâmetros:
  /// - [isSmooth]: Status ativo (`bool`).
  void updateSmoothness(bool isSmooth) {
    state = isSmooth;
  }
}

/// Provedor reativo para observar o filtro de pavimentos suaves.
final surfaceSmoothnessProvider = NotifierProvider<SurfaceSmoothnessNotifier, bool>(SurfaceSmoothnessNotifier.new);

/// Provedor para injeção do motor de rotas [RoutingService] (Model Layer).
final routingServiceProvider = Provider((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return RoutingService(prefs);
});

/// **ConnectivityNotifier (ViewModel)**
///
/// Monitora e publica o estado de conexão com a Internet de forma dinâmica (Ping/Lookup).
class ConnectivityNotifier extends Notifier<bool> {
  Timer? _timer;

  /// Inicia o timer recorrente para validar a presença de rede a cada 5 segundos.
  @override
  bool build() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkConnectivity());
    checkConnectivity();

    ref.onDispose(() {
      _timer?.cancel();
    });

    return true;
  }

  /// Efetua ping via Socket TCP de baixíssimo nível em IP público rápido (8.8.8.8) com fallback a google.com.
  Future<void> checkConnectivity() async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      if (state != true) {
        state = true;
      }
    } catch (_) {
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
        final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        if (state != isOnline) {
          state = isOnline;
        }
      } catch (__) {
        if (state != false) {
          state = false;
        }
      }
    }
  }
}

/// Provedor para observar o estado online/offline do celular em tempo real.
final connectivityProvider = NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

/// **TtsEnabledNotifier (ViewModel)**
///
/// Controla as preferências de narração de voz por Text-to-Speech (TTS).
class TtsEnabledNotifier extends Notifier<bool> {
  /// Inicializa e configura o status do recurso de fala a partir das preferências.
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final enabled = prefs.prefs.getBool('tts_enabled_pref') ?? true;
    TtsService().isEnabled = enabled;
    return enabled;
  }

  /// Alterna a presença de áudio de instruções de navegação por voz.
  void toggle() {
    final prefs = ref.read(preferencesServiceProvider);
    final newValue = !state;
    prefs.prefs.setBool('tts_enabled_pref', newValue);
    TtsService().isEnabled = newValue;
    if (!newValue) {
      TtsService().stop();
    }
    state = newValue;
  }
}

/// Provedor reativo para observar e alterar a voz do GPS.
final ttsEnabledProvider = NotifierProvider<TtsEnabledNotifier, bool>(TtsEnabledNotifier.new);

/// **LocationConsentNotifier (ViewModel)**
///
/// Gerencia os termos de privacidade de compartilhamento de dados geográficos do ciclista.
class LocationConsentNotifier extends Notifier<bool> {
  /// Inicializa o consentimento com base no status salvo.
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.prefs.getBool('location_consent_pref') ?? false;
  }

  /// Atualiza o termo de consentimento e limpa localização se revogado.
  ///
  /// Parâmetros:
  /// - [consented]: Consentimento ativo (`bool`).
  void setConsent(bool consented) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.prefs.setBool('location_consent_pref', consented);
    state = consented;
    if (!consented) {
      ref.read(locationEnabledProvider.notifier).setEnabled(false);
    }
  }
}

/// Provedor para observar o consentimento de termos.
final locationConsentProvider = NotifierProvider<LocationConsentNotifier, bool>(LocationConsentNotifier.new);

/// **LocationEnabledNotifier (ViewModel)**
///
/// Gerencia se o rastreamento ativo de GPS local está ativo.
class LocationEnabledNotifier extends Notifier<bool> {
  /// Carrega a preferência de status ativo do GPS de disco.
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.prefs.getBool('location_enabled_pref') ?? false;
  }

  /// Ativa ou suspende o uso de chips de GPS no sistema.
  ///
  /// Parâmetros:
  /// - [enabled]: Ativo (`bool`).
  void setEnabled(bool enabled) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.prefs.setBool('location_enabled_pref', enabled);
    state = enabled;
  }
}

/// Provedor reativo para verificar se o GPS está ativo.
final locationEnabledProvider = NotifierProvider<LocationEnabledNotifier, bool>(LocationEnabledNotifier.new);

/// **P2PEnabledNotifier (ViewModel)**
///
/// Gerencia se a rede mesh ponto a ponto offline com ciclistas próximos está habilitada.
class P2PEnabledNotifier extends Notifier<bool> {
  /// Carrega a preferência de uso de P2P.
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.prefs.getBool('p2p_enabled_pref') ?? true;
  }

  /// Habilita ou encerra dinamicamente a descoberta de Nearby Connections no background.
  ///
  /// Parâmetros:
  /// - [enabled]: Descoberta P2P ativa (`bool`).
  void setEnabled(bool enabled) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.prefs.setBool('p2p_enabled_pref', enabled);
    state = enabled;

    if (enabled) {
      P2PMeshSyncService().startSyncProcess();
    } else {
      P2PMeshSyncService().stopSyncProcess();
    }
  }
}

/// Provedor reativo para verificar se a busca por mesh P2P está ativa.
final p2pEnabledProvider = NotifierProvider<P2PEnabledNotifier, bool>(P2PEnabledNotifier.new);

/// **FrequentAddressesNotifier (ViewModel)**
///
/// Gerencia a lista de endereços e locais favoritos do ciclista (ex: Casa, Trabalho).
class FrequentAddressesNotifier extends Notifier<List<Map<String, dynamic>>> {
  /// Carrega os endereços persistidos em disco.
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.loadFrequentAddresses();
  }

  /// Adiciona ou substitui um endereço na lista e salva em disco.
  ///
  /// Parâmetros:
  /// - [id]: Identificador único do local (`String`).
  /// - [label]: Rótulo do endereço (ex: "Casa") (`String`).
  /// - [title]: Título descritivo (`String`).
  /// - [subtitle]: Endereço completo (`String`).
  /// - [lat]: Latitude (`double`).
  /// - [lon]: Longitude (`double`).
  void setAddress({
    required String id,
    required String label,
    required String title,
    required String subtitle,
    required double lat,
    required double lon,
  }) {
    final prefs = ref.read(preferencesServiceProvider);
    final current = List<Map<String, dynamic>>.from(state);
    
    current.removeWhere((item) => item['id'] == id);
    current.add({
      'id': id,
      'label': label,
      'title': title,
      'subtitle': subtitle,
      'lat': lat,
      'lon': lon,
    });
    
    prefs.saveFrequentAddresses(current);
    state = current;
  }

  /// Remove um endereço favorito a partir do seu ID.
  ///
  /// Parâmetros:
  /// - [id]: ID do endereço (`String`).
  void removeAddress(String id) {
    final prefs = ref.read(preferencesServiceProvider);
    final current = List<Map<String, dynamic>>.from(state);
    
    current.removeWhere((item) => item['id'] == id);
    
    prefs.saveFrequentAddresses(current);
    state = current;
  }

  /// Limpa todos os locais favoritos do usuário.
  void clearAll() {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.saveFrequentAddresses([]);
    state = [];
  }
}

/// Provedor para monitorar a lista de endereços frequentes em tempo real.
final frequentAddressesProvider = NotifierProvider<FrequentAddressesNotifier, List<Map<String, dynamic>>>(FrequentAddressesNotifier.new);

/// **HapticEnabledNotifier (ViewModel)**
///
/// Controla as respostas táteis físicas e vibrações do telefone ao realizar ações na UI.
class HapticEnabledNotifier extends Notifier<bool> {
  /// Inicializa e vincula as vibrações das preferências de sistema.
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final enabled = prefs.prefs.getBool('haptic_enabled_pref') ?? true;
    HapticService().isEnabled = enabled;
    return enabled;
  }

  /// Alterna a presença de vibração no toque.
  void toggle() {
    final prefs = ref.read(preferencesServiceProvider);
    final newValue = !state;
    prefs.prefs.setBool('haptic_enabled_pref', newValue);
    HapticService().isEnabled = newValue;
    state = newValue;
  }
}

/// Provedor reativo para observar o estado de resposta tátil.
final hapticEnabledProvider = NotifierProvider<HapticEnabledNotifier, bool>(HapticEnabledNotifier.new);

/// **SafetyEvaluationsNotifier (ViewModel)**
///
/// Gerencia e compartilha a lista local e baixada de avaliações de segurança de vias.
class SafetyEvaluationsNotifier extends Notifier<List<SafetyEvaluation>> {
  /// Carrega as avaliações locais de vias.
  @override
  List<SafetyEvaluation> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.loadSafetyEvaluations();
  }

  /// Adiciona uma avaliação de segurança inédita e persiste localmente.
  ///
  /// Parâmetros:
  /// - [evaluation]: Nova avaliação (`SafetyEvaluation`).
  void addEvaluation(SafetyEvaluation evaluation) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.addSafetyEvaluation(evaluation);
    state = [...state, evaluation];
  }

  /// Exclui uma avaliação local específica.
  ///
  /// Parâmetros:
  /// - [segmentId]: ID do segmento (`String`).
  /// - [creatorPublicKey]: Chave pública do autor (`String`).
  void removeEvaluation(String segmentId, String creatorPublicKey) {
    final prefs = ref.read(preferencesServiceProvider);
    final current = List<SafetyEvaluation>.from(state);
    current.removeWhere((e) => e.segmentId == segmentId && e.creatorPublicKey == creatorPublicKey);
    prefs.saveSafetyEvaluations(current);
    state = current;
  }
}

/// Provedor para expor a base ativa de avaliações de segurança.
final safetyEvaluationsProvider = NotifierProvider<SafetyEvaluationsNotifier, List<SafetyEvaluation>>(SafetyEvaluationsNotifier.new);

/// Provedor de fluxo contínuo (Stream) para escutar alertas e logs P2P do [P2PMeshSyncService].
final p2pMeshEventsProvider = StreamProvider<String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final syncService = P2PMeshSyncService();
  
  syncService.init(prefs, ref);
  return syncService.syncEvents;
});

/// **PartnerEstablishmentsNotifier (ViewModel)**
///
/// Gerencia a lista de estabelecimentos parceiros e dispara a sincronização automática online com o GitHub.
class PartnerEstablishmentsNotifier extends Notifier<List<PartnerEstablishment>> {
  /// Inicializa e dispara o download assíncrono oficial de parceiros da plataforma.
  @override
  List<PartnerEstablishment> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    _syncWithCloud();
    return prefs.loadPartnerEstablishments();
  }

  /// Efetua sincronização baixando dados assinados e autenticados de estabelecimentos parceiros.
  Future<void> _syncWithCloud() async {
    final cloudPartners = await PartnerSyncService().fetchOfficialPartners();
    if (cloudPartners.isNotEmpty) {
      final prefs = ref.read(preferencesServiceProvider);
      for (final p in cloudPartners) {
        prefs.addPartnerEstablishment(p);
      }
      state = prefs.loadPartnerEstablishments();
    }
  }

  /// Registra um novo parceiro (usado pelo P2P Mesh offline).
  ///
  /// Parâmetros:
  /// - [partner]: Estabelecimento parceiro validado (`PartnerEstablishment`).
  void addPartner(PartnerEstablishment partner) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.addPartnerEstablishment(partner);
    state = prefs.loadPartnerEstablishments();
  }
}

/// Provedor global para observar e gerenciar estabelecimentos parceiros legítimos.
final partnerEstablishmentsProvider = NotifierProvider<PartnerEstablishmentsNotifier, List<PartnerEstablishment>>(PartnerEstablishmentsNotifier.new);

