import 'package:latlong2/latlong.dart';

class SafetyEvaluation {
  final String segmentId;
  final double latitude;
  final double longitude;
  final int safetyScore; // 1-5
  final int lightingScore; // 1-5
  final int trafficScore; // 1-5
  final int accidentScore; // 1-5
  final bool hasCycleway;
  final String safeTimePeriod; // 'sempre', 'dia', 'noite', 'evitar_noite'
  final int timestamp;
  final String creatorPublicKey;
  final String signature;

  SafetyEvaluation({
    required this.segmentId,
    required this.latitude,
    required this.longitude,
    required this.safetyScore,
    required this.lightingScore,
    required this.trafficScore,
    required this.accidentScore,
    required this.hasCycleway,
    required this.safeTimePeriod,
    required this.timestamp,
    required this.creatorPublicKey,
    required this.signature,
  });

  LatLng get point => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'segmentId': segmentId,
        'latitude': latitude,
        'longitude': longitude,
        'safetyScore': safetyScore,
        'lightingScore': lightingScore,
        'trafficScore': trafficScore,
        'accidentScore': accidentScore,
        'hasCycleway': hasCycleway,
        'safeTimePeriod': safeTimePeriod,
        'timestamp': timestamp,
        'creatorPublicKey': creatorPublicKey,
        'signature': signature,
      };

  factory SafetyEvaluation.fromJson(Map<String, dynamic> json) => SafetyEvaluation(
        segmentId: json['segmentId'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        safetyScore: json['safetyScore'] as int,
        lightingScore: json['lightingScore'] as int,
        trafficScore: json['trafficScore'] as int,
        accidentScore: json['accidentScore'] as int,
        hasCycleway: json['hasCycleway'] as bool,
        safeTimePeriod: json['safeTimePeriod'] as String,
        timestamp: json['timestamp'] as int,
        creatorPublicKey: json['creatorPublicKey'] as String,
        signature: json['signature'] as String,
      );
}
