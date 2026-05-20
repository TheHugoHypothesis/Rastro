import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// **PoiCategory (Model/Enum)**
///
/// Categorias possíveis de Pontos de Interesse (POIs) exibidos no mapa.
enum PoiCategory {
  /// Restaurantes, praças de alimentação ou lanchonetes.
  restaurant,

  /// Cafeterias ou sorveterias.
  cafe,

  /// Hospitais, clínicas e consultórios médicos.
  hospital,

  /// Farmácias ou drogarias.
  pharmacy,

  /// Lojas especializadas em peças ou consertos de bicicletas.
  bikeShop,

  /// Supermercados, mercados locais ou hortifrútis.
  supermarket,

  /// Padarias ou panificadoras.
  bakery,

  /// Bares, pubs ou choperias.
  bar,
}

/// Extensão utilitária para obter descrições humanizadas em português das categorias de POI.
extension PoiCategoryExt on PoiCategory {
  /// Retorna o rótulo descritivo amigável para exibição em português.
  String get label {
    switch (this) {
      case PoiCategory.restaurant:  return 'Restaurante';
      case PoiCategory.cafe:        return 'Café';
      case PoiCategory.hospital:    return 'Hospital';
      case PoiCategory.pharmacy:    return 'Farmácia';
      case PoiCategory.bikeShop:    return 'Bike Shop';
      case PoiCategory.supermarket: return 'Mercado';
      case PoiCategory.bakery:      return 'Padaria';
      case PoiCategory.bar:         return 'Bar';
    }
  }
}

/// **PoiResult (Model/Data)**
///
/// Representação física de um Ponto de Interesse mapeado espacialmente.
class PoiResult {
  /// Nome de exibição pública do estabelecimento ou POI (`String`).
  final String name;

  /// Coordenadas geográficas exatas do ponto (`LatLng`).
  final LatLng point;

  /// Categoria classificada do Ponto de Interesse (`PoiCategory`).
  final PoiCategory category;

  /// Construtor de imutabilidade padrão do PoiResult.
  const PoiResult({required this.name, required this.point, required this.category});

  /// Converte a instância de PoiResult em um mapa estruturado para codificação JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': point.latitude,
    'lng': point.longitude,
    'category': category.name,
  };

  /// Constrói e inicializa uma nova instância de PoiResult a partir de um mapa de chaves-valores JSON decodificado.
  factory PoiResult.fromJson(Map<String, dynamic> json) {
    return PoiResult(
      name: json['name'] as String,
      point: LatLng(json['lat'] as double, json['lng'] as double),
      category: PoiCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PoiCategory.restaurant,
      ),
    );
  }
}

/// **PoiService (Model/Data/Remote)**
///
/// Serviço encarregado de consumir remotamente a API oficial de mapeamento OpenStreetMap (OSM) via Overpass QL.
/// Permite descobrir estabelecimentos comerciais de apoio próximos ao trajeto do ciclista (RF007/RF009).
class PoiService {
  // Endpoints alternativos do Overpass (OSM oficial) — fallback sequencial
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.karte.io/api/interpreter',
  ];

  /// Consulta e extrai dinamicamente Pontos de Interesse (POIs) dentro de uma caixa de delimitação geográfica.
  ///
  /// Filtra estabelecimentos comerciais, farmácias, mercados e bicicletários usando consultas Overpass QL
  /// otimizadas para centróides de polígonos e nodes estruturados.
  ///
  /// Parâmetros:
  /// - [bbox]: Os limites geográficos retangulares de busca (`LatLngBounds`).
  /// - [maxDegreeSpan]: A tolerância máxima de amplitude angular para evitar abusos na API (`double`).
  /// - [limitTotal]: O número máximo de registros a serem retornados na consulta (`int`).
  ///
  /// Retorna:
  /// - Uma lista contendo os POIs descobertos (`List<PoiResult>`).
  Future<List<PoiResult>> fetchInBbox({
    required LatLngBounds bbox,
    double maxDegreeSpan = 0.60, // ~66 km — cobre o raio base de 10km com folga
    int limitTotal = 150,
  }) async {
    final latSpan = bbox.north - bbox.south;
    final lonSpan = bbox.east - bbox.west;

    if (latSpan > maxDegreeSpan || lonSpan > maxDegreeSpan) {
      debugPrint('POI: bbox muito grande — ignorando');
      return [];
    }

    final s = bbox.south.toStringAsFixed(6);
    final w = bbox.west.toStringAsFixed(6);
    final n = bbox.north.toStringAsFixed(6);
    final e = bbox.east.toStringAsFixed(6);
    final bb = '$s,$w,$n,$e';

    // Query Overpass QL: nodes + ways, múltiplas categorias de amenity/shop
    // "out center" para ways retorna o centróide (lat/lon calculado pelo Overpass)
    final query = '''
[out:json][timeout:25];
(
  node["amenity"~"^(restaurant|fast_food|food_court|cafe|bar|pub|biergarten|ice_cream)\$"]($bb);
  way["amenity"~"^(restaurant|fast_food|food_court|cafe|bar|pub|biergarten|ice_cream)\$"]($bb);
  node["amenity"~"^(hospital|clinic|doctors|dentist|pharmacy|veterinary)\$"]($bb);
  way["amenity"~"^(hospital|clinic|doctors|dentist|pharmacy|veterinary)\$"]($bb);
  node["shop"~"^(bicycle|bakery|supermarket|convenience|greengrocer)\$"]($bb);
  way["shop"~"^(bicycle|bakery|supermarket|convenience|greengrocer)\$"]($bb);
);
out center $limitTotal;
''';

    for (final endpoint in _endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          body: {'data': query},
          headers: {'User-Agent': 'rastro_app_ihc_project/1.0 (academic_prototype)'},
        ).timeout(const Duration(seconds: 28));

        if (response.statusCode != 200) {
          debugPrint('Overpass [$endpoint] HTTP ${response.statusCode}');
          continue; // tenta próximo endpoint
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = (json['elements'] as List?) ?? [];

        final results = <PoiResult>[];

        for (final el in elements) {
          final tags = el['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] as String?
              ?? tags['brand'] as String?
              ?? tags['operator'] as String?
              ?? '';
          if (name.isEmpty) continue;

          // nodes têm lat/lon direto; ways têm center.lat/center.lon
          final elLat = (el['lat'] as num?)?.toDouble()
              ?? (el['center']?['lat'] as num?)?.toDouble();
          final elLon = (el['lon'] as num?)?.toDouble()
              ?? (el['center']?['lon'] as num?)?.toDouble();
          if (elLat == null || elLon == null) continue;

          final amenity = tags['amenity'] as String? ?? '';
          final shop    = tags['shop']    as String? ?? '';

          final PoiCategory cat;
          if (amenity == 'restaurant' || amenity == 'fast_food' || amenity == 'food_court') {
            cat = PoiCategory.restaurant;
          } else if (amenity == 'cafe' || amenity == 'ice_cream') {
            cat = PoiCategory.cafe;
          } else if (amenity == 'bar' || amenity == 'pub' || amenity == 'biergarten') {
            cat = PoiCategory.bar;
          } else if (amenity == 'hospital' || amenity == 'clinic' || amenity == 'doctors' || amenity == 'dentist' || amenity == 'veterinary') {
            cat = PoiCategory.hospital;
          } else if (amenity == 'pharmacy') {
            cat = PoiCategory.pharmacy;
          } else if (shop == 'bicycle') {
            cat = PoiCategory.bikeShop;
          } else if (shop == 'bakery') {
            cat = PoiCategory.bakery;
          } else if (shop == 'supermarket' || shop == 'convenience' || shop == 'greengrocer') {
            cat = PoiCategory.supermarket;
          } else {
            continue;
          }

          results.add(PoiResult(
            name: name,
            point: LatLng(elLat, elLon),
            category: cat,
          ));
        }

        debugPrint('POI: ${results.length} resultados de $endpoint');
        return results;
      } catch (e) {
        debugPrint('Overpass [$endpoint] erro: $e');
        // tenta próximo endpoint
      }
    }

    return [];
  }
}
