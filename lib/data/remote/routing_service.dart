import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../domain/models/route_instruction.dart';
import '../../domain/models/cached_route.dart';
import '../local/preferences_service.dart';

class RoutingService {
  final PreferencesService _prefsService;

  RoutingService(this._prefsService);

  /// Obtém o caminho de rota detalhado da API OSRM com suporte dinâmico a RF003 e RF004
  Future<({List<LatLng> points, List<RouteInstruction> instructions, double distance, double duration})> getRoutePath({
    required LatLng start,
    required LatLng end,
    required BikeType bikeType,
    required RouteStrategy strategy,
  }) async {
    // 1. Determina velocidade média estimada (em m/s) por tipo de bicicleta (RF004)
    final double speedMps;
    switch (bikeType) {
      case BikeType.comum:
        speedMps = 18.0 / 3.6; // 18 km/h -> 5.0 m/s
        break;
      case BikeType.corrida:
        speedMps = 25.0 / 3.6; // 25 km/h -> 6.94 m/s
        break;
      case BikeType.dobravel:
        speedMps = 14.0 / 3.6; // 14 km/h -> 3.88 m/s
        break;
      case BikeType.eletrica:
        speedMps = 22.0 / 3.6; // 22 km/h -> 6.11 m/s
        break;
    }

    // 2. Determina o perfil/endpoint de roteamento ideal (RF004)
    // Bicicleta de Corrida prioriza asfalto liso e vias estruturadas (típicas de carros)
    final String endpoint = (bikeType == BikeType.corrida) ? 'routed-car' : 'routed-bike';

    // 3. Monta a requisição solicitando rotas alternativas para comparação (RF003)
    final url = Uri.parse(
        'https://routing.openstreetmap.de/$endpoint/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=true&alternatives=true');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final List<dynamic> routesList = data['routes'];
          
          // 4. Seleção inteligente baseada no esforço e estratégia (RF003 / RF004)
          var bestRoute = routesList[0];
          double bestScore = double.negativeInfinity;

          for (final route in routesList) {
            final double distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
            final double duration = (route['duration'] as num?)?.toDouble() ?? 0.0;
            
            // Densidade de manobras por km (reflete o ritmo/fluxo constante do trajeto)
            final legs = route['legs'] as List? ?? [];
            int stepsCount = 0;
            if (legs.isNotEmpty) {
              stepsCount = (legs[0]['steps'] as List? ?? []).length;
            }
            final double maneuverDensity = distance > 0 ? (stepsCount / (distance / 1000.0)) : 0.0;

            double score = 0.0;

            if (strategy == RouteStrategy.menorEsforco) {
              if (bikeType == BikeType.eletrica) {
                // Bicicleta Elétrica desconsidera inclinação/esforço físico. Prioriza caminho mais rápido e direto.
                score = -distance;
              } else {
                // Menor esforço prioriza ritmos constantes (menos manobras/curvas de desaceleração/aceleração)
                // e prefere evitar percursos truncados, aceitando leves acréscimos de distância se mantiver o fluxo linear.
                score = -(maneuverDensity * 40.0) - (distance * 0.1);
              }
            } else if (strategy == RouteStrategy.maiorEsforco) {
              // Maior esforço prioriza a rota mais direta (menor distância), aceitando paradas, curvas e subidas
              score = -distance;
            } else if (strategy == RouteStrategy.seguranca) {
              // Segurança prioriza menos cruzamentos e manobras complicadas
              score = -(maneuverDensity * 30.0) - (distance * 0.5);
            } else {
              // Rapidez
              score = -duration;
            }

            if (score > bestScore) {
              bestScore = score;
              bestRoute = route;
            }
          }

          // 5. Extração de pontos de coordenada da rota selecionada
          final List<LatLng> points = [];
          final geometry = bestRoute['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final List<dynamic> coords = geometry['coordinates'];
            for (var coord in coords) {
              if (coord is List && coord.length >= 2) {
                points.add(LatLng(
                  (coord[1] as num).toDouble(),
                  (coord[0] as num).toDouble(),
                ));
              }
            }
          }

          // 6. Extração de instruções de manobra da rota selecionada
          final List<RouteInstruction> instructions = [];
          final legs = bestRoute['legs'];
          if (legs != null && (legs as List).isNotEmpty) {
            final steps = legs[0]['steps'];
            if (steps != null) {
              for (var step in steps) {
                instructions.add(RouteInstruction.fromOSRM(step as Map<String, dynamic>));
              }
            }
          }

          // 7. Ajusta a distância e calcula a duração adaptada para o ciclista
          final double distance = (bestRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final double duration = distance / speedMps;

          // Salva a rota obtida no cache local
          final cachedRoute = CachedRoute(
            start: start,
            end: end,
            bikeType: bikeType,
            strategy: strategy,
            points: points,
            instructions: instructions,
            distance: distance,
            duration: duration,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          _prefsService.addRouteToCache(cachedRoute);

          return (
            points: points,
            instructions: instructions,
            distance: distance,
            duration: duration,
          );
        }
      }
    } catch (e) {
      debugPrint('Erro de requisição no OSRM FOSSGIS, buscando cache local: $e');
    }

    // Fallback inteligente: buscar do cache local se estiver offline
    final cached = _prefsService.findCachedRoute(
      start: start,
      end: end,
      bikeType: bikeType,
      strategy: strategy,
    );

    if (cached != null) {
      debugPrint('Rota recuperada do cache offline com sucesso!');
      return (
        points: cached.points,
        instructions: cached.instructions,
        distance: cached.distance,
        duration: cached.duration,
      );
    }

    // Fallback amigável: linha reta caso a API do OSRM esteja fora do ar e sem cache
    final distanceCalculator = const Distance();
    final dist = distanceCalculator.as(LengthUnit.Meter, start, end);
    final duration = dist / 5.0; // Assume 18 km/h (5 m/s)

    return (
      points: [start, end],
      instructions: [
        RouteInstruction(instruction: 'Siga na direção do seu destino (Sem conexão)', distance: dist, name: 'Destino'),
        RouteInstruction(instruction: 'Você chegou ao seu destino!', distance: 0, name: 'Destino'),
      ],
      distance: dist,
      duration: duration,
    );
  }

  /// Busca endereços por texto na API Nominatim
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&countrycodes=br');

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'RastroAppCiclismo/1.0.0 (contato@rastroapp.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          final displayName = item['display_name'] as String? ?? '';
          final parts = displayName.split(',');
          final shortName = parts.isNotEmpty ? parts[0].trim() : displayName;
          return {
            'title': shortName,
            'subtitle': displayName,
            'lat': item['lat'],
            'lon': item['lon'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Erro na busca customizada do Nominatim: $e');
    }
    return [];
  }

  /// Geocodificação reversa para traduzir uma coordenada em endereço legível
  Future<String> reverseGeocode(LatLng point) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json');

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'RastroAppCiclismo/1.0.0 (contato@rastroapp.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'] as Map<String, dynamic>;
          final road = address['road'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String? ?? address['town'] as String? ?? address['village'] as String?;
          
          if (road != null) {
            if (suburb != null) {
              return '$road, $suburb';
            }
            return road;
          }
          if (city != null) return city;
        }
        return data['display_name'] as String? ?? 'Localização no Mapa';
      }
    } catch (e) {
      debugPrint('Erro de geocodificação reversa no Nominatim: $e');
    }
    return 'Ponto no Mapa';
  }
}
