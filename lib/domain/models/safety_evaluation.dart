import 'package:latlong2/latlong.dart';

/// **SafetyEvaluation**
///
/// Modela a avaliação de segurança e iluminação de um segmento de via ou ponto geográfico
/// preenchida por um ciclista. Propaga-se via rede P2P Mesh e compõe a inteligência
/// de cálculo de rotas do sistema (RF003).
class SafetyEvaluation {
  /// Identificador do segmento da via avaliada.
  final String segmentId;

  /// Latitude geográfica da avaliação.
  final double latitude;

  /// Longitude geográfica da avaliação.
  final double longitude;

  /// Pontuação geral de segurança física (1 a 5).
  final int safetyScore;

  /// Pontuação de luminosidade e iluminação pública da via (1 a 5).
  final int lightingScore;

  /// Pontuação de fluxo de tráfego de veículos (1 a 5).
  final int trafficScore;

  /// Pontuação de periculosidade de acidentes (1 a 5).
  final int accidentScore;

  /// Indica se a via possui ciclovia ou ciclofaixa segregada dedicada.
  final bool hasCycleway;

  /// Período ideal em que a via é segura: 'sempre', 'dia', 'noite', 'evitar_noite'.
  final String safeTimePeriod;

  /// Época de criação da avaliação medida em Unix Epoch milissegundos.
  final int timestamp;

  /// Chave pública do ciclista autor da avaliação no modelo Web of Trust (WoT).
  final String creatorPublicKey;

  /// Assinatura digital gerada com a chave privada do criador para validar integridade e autoria.
  final String signature;

  /// Inicializa uma nova avaliação de segurança de via com todos os parâmetros obrigatórios.
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

  /// Retorna as coordenadas geográficas mapeadas em um objeto [LatLng] para fins de plotagem no mapa.
  LatLng get point => LatLng(latitude, longitude);

  /// Converte a instância em um mapa de chave-valor JSON serializável.
  ///
  /// Retorno:
  /// - `Map<String, dynamic>` contendo as propriedades serializadas da avaliação.
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

  /// Cria uma nova instância de [SafetyEvaluation] a partir de dados serializados JSON.
  ///
  /// Parâmetros:
  /// - [json]: Mapa JSON desserializado.
  ///
  /// Retorno:
  /// - Uma nova instância válida de [SafetyEvaluation].
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
