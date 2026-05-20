import 'package:latlong2/latlong.dart';
import 'bike_type.dart';
import 'route_preference.dart';
import 'route_instruction.dart';

/// **CachedRoute**
///
/// Modela uma rota calculada e persistida localmente em cache para permitir
/// a navegação offline resiliente (RF003 / RF008).
class CachedRoute {
  /// Ponto geográfico inicial (partida).
  final LatLng start;

  /// Ponto geográfico final (destino).
  final LatLng end;

  /// O tipo de bicicleta utilizado no cálculo de tempo e via.
  final BikeType bikeType;

  /// A heurística/estratégia de roteamento adotada.
  final RouteStrategy strategy;

  /// Lista ordenada de coordenadas que traçam a rota geográfica completa no mapa.
  final List<LatLng> points;

  /// Lista estruturada de instruções de navegação por voz/painel (passo a passo).
  final List<RouteInstruction> instructions;

  /// Distância total do percurso calculada em metros.
  final double distance;

  /// Duração aproximada estimada em segundos para o trajeto.
  final double duration;

  /// Unix Epoch milissegundos de quando a rota foi gerada e armazenada no cache local.
  final int timestamp;

  /// Inicializa uma nova rota em cache com parâmetros obrigatórios.
  CachedRoute({
    required this.start,
    required this.end,
    required this.bikeType,
    required this.strategy,
    required this.points,
    required this.instructions,
    required this.distance,
    required this.duration,
    required this.timestamp,
  });

  /// Converte o objeto em um mapa JSON para armazenamento local robusto.
  ///
  /// Retorno:
  /// - `Map<String, dynamic>` serializado.
  Map<String, dynamic> toJson() {
    return {
      'start_lat': start.latitude,
      'start_lon': start.longitude,
      'end_lat': end.latitude,
      'end_lon': end.longitude,
      'bikeType': bikeType.name,
      'strategy': strategy.name,
      'points': points.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList(),
      'instructions': instructions.map((i) => i.toJson()).toList(),
      'distance': distance,
      'duration': duration,
      'timestamp': timestamp,
    };
  }

  /// Reconstrói um objeto [CachedRoute] a partir de dados serializados JSON.
  ///
  /// Parâmetros:
  /// - [json]: Mapa de dados desserializado.
  ///
  /// Retorno:
  /// - Uma instância válida de [CachedRoute].
  factory CachedRoute.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pointsList = json['points'] as List<dynamic>? ?? [];
    final List<dynamic> instList = json['instructions'] as List<dynamic>? ?? [];

    return CachedRoute(
      start: LatLng(json['start_lat'] as double, json['start_lon'] as double),
      end: LatLng(json['end_lat'] as double, json['end_lon'] as double),
      bikeType: BikeType.values.firstWhere(
        (e) => e.name == json['bikeType'],
        orElse: () => BikeType.comum,
      ),
      strategy: RouteStrategy.values.firstWhere(
        (e) => e.name == json['strategy'],
        orElse: () => RouteStrategy.seguranca,
      ),
      points: pointsList.map((p) => LatLng(p['lat'] as double, p['lon'] as double)).toList(),
      instructions: instList.map((i) => RouteInstruction.fromJson(i as Map<String, dynamic>)).toList(),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
