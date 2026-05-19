import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../data/local/preferences_service.dart';
import '../../data/remote/routing_service.dart';

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
