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

final routingServiceProvider = Provider((ref) => RoutingService());
