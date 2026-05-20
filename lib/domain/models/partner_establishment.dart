import 'package:latlong2/latlong.dart';

/// **PartnerEstablishment**
///
/// Representa a entidade de um estabelecimento parceiro bike-friendly que suporta
/// a ciclomobilidade (ex: bicicletários, oficinas, cafés de ciclistas) e é exibido
/// no mapa interativo com fins de utilidade pública e monetização de patrocínio.
///
/// A autenticidade dos dados é validada localmente por meio de assinaturas criptográficas
/// baseadas no modelo Web of Trust (WoT).
class PartnerEstablishment {
  /// O identificador único oficial do estabelecimento parceiro.
  final String id;

  /// O nome de exibição do estabelecimento.
  final String name;

  /// A latitude geográfica da localização do estabelecimento.
  final double latitude;

  /// A longitude geográfica da localização do estabelecimento.
  final double longitude;

  /// Indica se o parceiro é certificado como "bike-friendly" oficial pela plataforma.
  final bool isBikeFriendly;

  /// Lista de comodidades ou facilidades de apoio a ciclistas no local (ex: bomba de ar, tomada e-bike).
  final List<String> amenities;

  /// A assinatura digital criptográfica do administrador para validação anti-fraude offline e P2P.
  final String adminSignature;

  /// Cria uma nova instância de [PartnerEstablishment] com validação e parâmetros obrigatórios.
  ///
  /// Parâmetros:
  /// - [id]: Identificador único (`String`).
  /// - [name]: Nome comercial do parceiro (`String`).
  /// - [latitude]: Latitude geográfica (`double`).
  /// - [longitude]: Longitude geográfica (`double`).
  /// - [isBikeFriendly]: Status de facilidades certificadas (`bool`).
  /// - [amenities]: Lista de amenidades oferecidas (`List<String>`).
  /// - [adminSignature]: Assinatura criptográfica da administração (`String`).
  PartnerEstablishment({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isBikeFriendly,
    required this.amenities,
    required this.adminSignature,
  });

  /// Retorna as coordenadas geográficas mapeadas em um objeto [LatLng] para fins de renderização.
  ///
  /// Retorno:
  /// - Um objeto [LatLng] contendo latitude e longitude.
  LatLng get point => LatLng(latitude, longitude);

  /// Converte a instância atual em um mapa de chave-valor JSON serializável.
  ///
  /// Retorno:
  /// - Um mapa contendo os campos de dados estruturados (`Map<String, dynamic>`).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'isBikeFriendly': isBikeFriendly,
        'amenities': amenities,
        'adminSignature': adminSignature,
      };

  /// Cria uma instância de [PartnerEstablishment] a partir de um mapa de dados desserializado (JSON).
  ///
  /// Parâmetros:
  /// - [json]: O mapa de dados a ser convertido (`Map<String, dynamic>`).
  ///
  /// Retorno:
  /// - Uma nova instância válida de [PartnerEstablishment].
  ///
  /// Exceções:
  /// - Pode lançar [TypeError] ou [NullThrownError] se os campos obrigatórios estiverem ausentes ou com tipos incompatíveis.
  factory PartnerEstablishment.fromJson(Map<String, dynamic> json) => PartnerEstablishment(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isBikeFriendly: json['isBikeFriendly'] as bool? ?? true,
        amenities: List<String>.from(json['amenities'] as List),
        adminSignature: json['adminSignature'] as String,
      );
}
