import 'package:latlong2/latlong.dart';

class PartnerEstablishment {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isBikeFriendly;
  final List<String> amenities;
  final String adminSignature;

  PartnerEstablishment({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isBikeFriendly,
    required this.amenities,
    required this.adminSignature,
  });

  LatLng get point => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'isBikeFriendly': isBikeFriendly,
        'amenities': amenities,
        'adminSignature': adminSignature,
      };

  factory PartnerEstablishment.fromJson(Map<String, dynamic> json) => PartnerEstablishment(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isBikeFriendly: json['isBikeFriendly'] as bool,
        amenities: List<String>.from(json['amenities'] as List),
        adminSignature: json['adminSignature'] as String,
      );
}
