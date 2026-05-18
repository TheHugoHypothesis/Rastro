import 'package:latlong2/latlong.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';

class RoutingService {
  /// Retorna as GeoPoints de uma rota calculada com base na estratégia do usuário
  /// Para este MVP, simula a requisição ao OSRM ou GraphHopper.
  Future<List<LatLng>> calculateRoute({
    required LatLng start,
    required LatLng end,
    required BikeType bikeType,
    required RouteStrategy strategy,
  }) async {
    // Na prática, aqui faríamos uma chamada HTTP (ex: pacote http) para um server OSRM:
    // GET http://router.project-osrm.org/route/v1/bicycle/lng,lat;lng,lat
    
    // Simulação do tempo de requisição...
    await Future.delayed(const Duration(seconds: 1));

    // Se a bike for Dobrável, a configuração da rota na API exigiria desviar paralelepípedos.
    // OSRM Custom Profile: 'avoid=cobblestone'
    // Como estamos no MVP, retornamos pontos arbitrários simulando a rota.

    return [
      start,
      LatLng((start.latitude + end.latitude) / 2, (start.longitude + end.longitude) / 2),
      end,
    ];
  }
}
