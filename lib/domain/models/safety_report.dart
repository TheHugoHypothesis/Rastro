import 'package:latlong2/latlong.dart';

/// **SafetyReport**
///
/// Modela um relato de segurança rápido ou aviso de ocorrência em um ponto geográfico específico do mapa.
/// Compartilha dados cruciais de segurança em tempo real com a comunidade (RF006).
class SafetyReport {
  /// Identificador único do relato.
  final String id;

  /// Latitude geográfica da ocorrência.
  final double latitude;

  /// Longitude geográfica da ocorrência.
  final double longitude;

  /// Indica se a ocorrência reportada representa segurança (`true`) ou perigo/obstrução (`false`).
  final bool isSafe;

  /// Descrição detalhada fornecida pelo ciclista para orientar outros ciclistas.
  final String description;

  /// Unix Epoch milissegundos de quando o relato foi disparado.
  final int timestamp;

  /// Cria um novo alerta/relato rápido de via ou ponto.
  SafetyReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.isSafe,
    required this.description,
    required this.timestamp,
  });

  /// Coordenadas de plotagem no mapa do objeto [LatLng].
  LatLng get point => LatLng(latitude, longitude);

  /// Converte a instância em mapa JSON.
  ///
  /// Retorno:
  /// - `Map<String, dynamic>` serializado.
  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'isSafe': isSafe,
        'description': description,
        'timestamp': timestamp,
      };

  /// Converte mapa JSON em nova instância de [SafetyReport].
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON desserializado.
  ///
  /// Retorno:
  /// - Instância válida de [SafetyReport].
  factory SafetyReport.fromJson(Map<String, dynamic> json) => SafetyReport(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isSafe: json['isSafe'] as bool,
        description: json['description'] as String,
        timestamp: json['timestamp'] as int,
      );
}
