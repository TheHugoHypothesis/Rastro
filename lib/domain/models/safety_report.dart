import 'package:latlong2/latlong.dart';

class SafetyReport {
  final String id;
  final double latitude;
  final double longitude;
  final bool isSafe;
  final String description;
  final int timestamp;

  SafetyReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.isSafe,
    required this.description,
    required this.timestamp,
  });

  LatLng get point => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'isSafe': isSafe,
        'description': description,
        'timestamp': timestamp,
      };

  factory SafetyReport.fromJson(Map<String, dynamic> json) => SafetyReport(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isSafe: json['isSafe'] as bool,
        description: json['description'] as String,
        timestamp: json['timestamp'] as int,
      );
}
