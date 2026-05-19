import 'package:latlong2/latlong.dart';
import 'bike_type.dart';
import 'route_preference.dart';
import 'route_instruction.dart';

class CachedRoute {
  final LatLng start;
  final LatLng end;
  final BikeType bikeType;
  final RouteStrategy strategy;
  final List<LatLng> points;
  final List<RouteInstruction> instructions;
  final double distance;
  final double duration;
  final int timestamp;

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
