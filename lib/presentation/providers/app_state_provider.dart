import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../domain/models/safety_evaluation.dart';
import '../../core/services/p2p_mesh_sync_service.dart';
import '../../data/local/preferences_service.dart';
import '../../data/remote/routing_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/haptic_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final preferencesServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

class BikeTypeNotifier extends Notifier<BikeType> {
  @override
  BikeType build() {
    return ref.read(preferencesServiceProvider).loadBikeType() ?? BikeType.comum;
  }
  
  void updateBikeType(BikeType type) {
    state = type;
    ref.read(preferencesServiceProvider).saveBikeType(type);
  }
}

final bikeTypeProvider = NotifierProvider<BikeTypeNotifier, BikeType>(BikeTypeNotifier.new);

class RouteStrategyNotifier extends Notifier<RouteStrategy> {
  @override
  RouteStrategy build() {
    return ref.read(preferencesServiceProvider).loadRouteStrategy() ?? RouteStrategy.seguranca;
  }
  
  void updateStrategy(RouteStrategy newStrategy) {
    state = newStrategy;
    ref.read(preferencesServiceProvider).saveRouteStrategy(newStrategy);
  }
}

final routeStrategyProvider = NotifierProvider<RouteStrategyNotifier, RouteStrategy>(RouteStrategyNotifier.new);

class SurfaceSmoothnessNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  
  void updateSmoothness(bool isSmooth) {
    state = isSmooth;
  }
}

final surfaceSmoothnessProvider = NotifierProvider<SurfaceSmoothnessNotifier, bool>(SurfaceSmoothnessNotifier.new);

final routingServiceProvider = Provider((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return RoutingService(prefs);
});

class ConnectivityNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkConnectivity());
    checkConnectivity();

    ref.onDispose(() {
      _timer?.cancel();
    });

    return true; // Assume conectado inicialmente
  }

  Future<void> checkConnectivity() async {
    try {
      // Tenta conexão direta por Socket TCP a um IP público extremamente disponível (Google DNS)
      // na porta 53 (DNS) sem precisar de resolução de host (evitando falhas de lookup locais).
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      if (state != true) {
        state = true;
      }
    } catch (_) {
      try {
        // Fallback robusto usando lookup clássico de DNS para google.com
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

final connectivityProvider = NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class TtsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final enabled = prefs.prefs.getBool('tts_enabled_pref') ?? true;
    TtsService().isEnabled = enabled;
    return enabled;
  }

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

final ttsEnabledProvider = NotifierProvider<TtsEnabledNotifier, bool>(TtsEnabledNotifier.new);

class LocationConsentNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.prefs.getBool('location_consent_pref') ?? false;
  }

  void setConsent(bool consented) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.prefs.setBool('location_consent_pref', consented);
    state = consented;
    if (!consented) {
      ref.read(locationEnabledProvider.notifier).setEnabled(false);
    }
  }
}

final locationConsentProvider = NotifierProvider<LocationConsentNotifier, bool>(LocationConsentNotifier.new);

class LocationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.prefs.getBool('location_enabled_pref') ?? false;
  }

  void setEnabled(bool enabled) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.prefs.setBool('location_enabled_pref', enabled);
    state = enabled;
  }
}

final locationEnabledProvider = NotifierProvider<LocationEnabledNotifier, bool>(LocationEnabledNotifier.new);

class FrequentAddressesNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.loadFrequentAddresses();
  }

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

  void removeAddress(String id) {
    final prefs = ref.read(preferencesServiceProvider);
    final current = List<Map<String, dynamic>>.from(state);
    
    current.removeWhere((item) => item['id'] == id);
    
    prefs.saveFrequentAddresses(current);
    state = current;
  }

  void clearAll() {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.saveFrequentAddresses([]);
    state = [];
  }
}

final frequentAddressesProvider = NotifierProvider<FrequentAddressesNotifier, List<Map<String, dynamic>>>(FrequentAddressesNotifier.new);

class HapticEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final enabled = prefs.prefs.getBool('haptic_enabled_pref') ?? true;
    HapticService().isEnabled = enabled;
    return enabled;
  }

  void toggle() {
    final prefs = ref.read(preferencesServiceProvider);
    final newValue = !state;
    prefs.prefs.setBool('haptic_enabled_pref', newValue);
    HapticService().isEnabled = newValue;
    state = newValue;
  }
}

final hapticEnabledProvider = NotifierProvider<HapticEnabledNotifier, bool>(HapticEnabledNotifier.new);

class SafetyEvaluationsNotifier extends Notifier<List<SafetyEvaluation>> {
  @override
  List<SafetyEvaluation> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.loadSafetyEvaluations();
  }

  void addEvaluation(SafetyEvaluation evaluation) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.addSafetyEvaluation(evaluation);
    state = [...state, evaluation];
  }

  void removeEvaluation(String segmentId, String creatorPublicKey) {
    final prefs = ref.read(preferencesServiceProvider);
    final current = List<SafetyEvaluation>.from(state);
    current.removeWhere((e) => e.segmentId == segmentId && e.creatorPublicKey == creatorPublicKey);
    prefs.saveSafetyEvaluations(current);
    state = current;
  }
}

final safetyEvaluationsProvider = NotifierProvider<SafetyEvaluationsNotifier, List<SafetyEvaluation>>(SafetyEvaluationsNotifier.new);

// Provedor para expor o stream de eventos P2P
final p2pMeshEventsProvider = StreamProvider<String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final syncService = P2PMeshSyncService();
  
  // Inicializa o serviço com o preferencesServiceProvider caso ainda não inicializado
  syncService.init(prefs, ref);
  
  return syncService.syncEvents;
});
