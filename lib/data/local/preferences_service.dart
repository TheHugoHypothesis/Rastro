import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/activity_record.dart';
import '../../domain/models/cached_route.dart';
import '../../domain/models/safety_evaluation.dart';
import '../../domain/models/partner_establishment.dart';
import '../remote/poi_service.dart';

/// **PreferencesService (Model/Data)**
///
/// Serviço de persistência local de baixo nível acoplado ao `SharedPreferences`.
/// Responsável pela leitura e escrita síncrona/assíncrona de preferências globais,
/// perfis de ciclistas, caches de POIs/rotas e avaliações de segurança de tráfego.
class PreferencesService {
  /// Instância concreta do mecanismo de persistência chave-valor nativo do Flutter.
  final SharedPreferences prefs;

  /// Inicializa o serviço injetando a dependência do `SharedPreferences`.
  PreferencesService(this.prefs);

  /// Chave de persistência do tipo de bicicleta do ciclista.
  static const String keyBikeType = 'bike_type_pref';

  /// Chave de persistência da estratégia de roteamento padrão.
  static const String keyRouteStrategy = 'route_strategy_pref';

  /// Chave de persistência do nome de exibição do usuário.
  static const String keyUserName = 'user_name_pref';

  /// Chave de persistência da idade declarada do usuário.
  static const String keyUserAge = 'user_age_pref';

  /// Chave de persistência da escolha de tema visual (Claro/Escuro).
  static const String keyThemeMode = 'theme_mode_pref';

  /// Chave de persistência do cache offline de pontos de interesse (POIs).
  static const String keyPoisCache = 'pois_cache_pref';

  /// Chave de persistência para o caminho da imagem de perfil local.
  static const String keyUserPhotoPath = 'user_photo_path_pref';

  /// Chave de persistência dos registros de atividade física acumulados.
  static const String keyActivityRecords = 'activity_records_pref';

  /// Chave de persistência do cache offline de rotas calculadas.
  static const String keyRouteCache = 'route_cache_pref';

  /// Chave de persistência dos endereços e destinos preferidos.
  static const String keyFrequentAddresses = 'frequent_addresses_pref';

  /// Chave de persistência dos relatórios P2P de segurança de vias.
  static const String keySafetyEvaluations = 'safety_evaluations_pref';

  /// Chave de persistência dos estabelecimentos comerciais parceiros.
  static const String keyPartnerEstablishments = 'partner_establishments_pref';

  /// Salva a preferência de tipo de bicicleta do usuário.
  ///
  /// Parâmetros:
  /// - [type]: O modelo/categoria da bicicleta (`BikeType`).
  void saveBikeType(BikeType type) {
    prefs.setString(keyBikeType, type.name);
  }

  /// Recupera o tipo de bicicleta configurado pelo ciclista. Retorna `null` se não houver registro.
  BikeType? loadBikeType() {
    final name = prefs.getString(keyBikeType);
    if (name != null) {
      return BikeType.values.firstWhere((e) => e.name == name, orElse: () => BikeType.comum);
    }
    return null;
  }

  /// Grava a estratégia padrão de cálculo de rotas (Segurança/Esforço/Mista).
  ///
  /// Parâmetros:
  /// - [strategy]: O algoritmo/critério escolhido (`RouteStrategy`).
  void saveRouteStrategy(RouteStrategy strategy) {
    prefs.setString(keyRouteStrategy, strategy.name);
  }

  /// Recupera a estratégia padrão de cálculo de rotas. Retorna `null` se não houver registro.
  RouteStrategy? loadRouteStrategy() {
    final name = prefs.getString(keyRouteStrategy);
    if (name != null) {
      return RouteStrategy.values.firstWhere((e) => e.name == name, orElse: () => RouteStrategy.seguranca);
    }
    return null;
  }

  /// Grava o perfil de usuário unificado contendo nome, idade e foto.
  ///
  /// Parâmetros:
  /// - [profile]: Instância do modelo de perfil de usuário (`UserProfile`).
  void saveUserProfile(UserProfile profile) {
    prefs.setString(keyUserName, profile.name);
    prefs.setInt(keyUserAge, profile.age);
    if (profile.photoPath != null) {
      prefs.setString(keyUserPhotoPath, profile.photoPath!);
    } else {
      prefs.remove(keyUserPhotoPath);
    }
  }

  /// Recupera o perfil de usuário salvo. Retorna `null` se os campos essenciais não existirem.
  UserProfile? loadUserProfile() {
    final name = prefs.getString(keyUserName);
    final age = prefs.getInt(keyUserAge);
    final photoPath = prefs.getString(keyUserPhotoPath);
    if (name != null && age != null) {
      return UserProfile(name: name, age: age, photoPath: photoPath);
    }
    return null;
  }

  /// Persiste a escolha do modo do tema visual (Claro/Escuro/Sistema).
  ///
  /// Parâmetros:
  /// - [mode]: Modo do tema de interface do Flutter (`ThemeMode`).
  void saveThemeMode(ThemeMode mode) {
    prefs.setString(keyThemeMode, mode.name);
  }

  /// Retorna o modo de tema de interface persistido. Por padrão, adota `ThemeMode.dark`.
  ThemeMode loadThemeMode() {
    final name = prefs.getString(keyThemeMode);
    if (name != null) {
      return ThemeMode.values.firstWhere((e) => e.name == name, orElse: () => ThemeMode.dark);
    }
    return ThemeMode.dark;
  }

  /// Salva em formato JSON serializado os pontos de interesse (POIs) retornados de consultas remotas.
  ///
  /// Parâmetros:
  /// - [pois]: Lista de objetos resultado de POI (`List<PoiResult>`).
  void savePois(List<PoiResult> pois) {
    final jsonList = pois.map((p) => p.toJson()).toList();
    prefs.setString(keyPoisCache, jsonEncode(jsonList));
  }

  /// Recupera o cache de pontos de interesse persistido localmente. Retorna lista vazia em caso de falha.
  List<PoiResult> loadPois() {
    final jsonString = prefs.getString(keyPoisCache);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => PoiResult.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Salva o histórico recente de consultas e buscas de endereços.
  ///
  /// Parâmetros:
  /// - [history]: Lista de mapas de atributos e coordenadas de destinos buscados.
  void saveSearchHistory(List<Map<String, dynamic>> history) {
    prefs.setString('search_history_pref', jsonEncode(history));
  }

  /// Carrega o histórico recente de buscas e endereços. Retorna lista vazia se inexistente.
  List<Map<String, dynamic>> loadSearchHistory() {
    final jsonString = prefs.getString('search_history_pref');
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Adiciona uma nova busca recente de localidade à pilha de histórico, mantendo no máximo 5 registros.
  ///
  /// Parâmetros:
  /// - [title]: Nome da localidade ou estabelecimento (`String`).
  /// - [subtitle]: Endereço resumido formatado (`String`).
  /// - [lat]: Latitude geográfica decimal (`double`).
  /// - [lon]: Longitude geográfica decimal (`double`).
  void addRecentSearch(String title, String subtitle, double lat, double lon) {
    final history = loadSearchHistory();
    history.removeWhere((item) => item['title'] == title || (item['lat'] == lat && item['lon'] == lon));
    history.insert(0, {
      'title': title,
      'subtitle': subtitle,
      'lat': lat,
      'lon': lon,
    });
    if (history.length > 5) {
      history.removeRange(5, history.length);
    }
    saveSearchHistory(history);
  }

  /// Salva todos os registros de atividade de locomoção ciclista persistidos localmente.
  ///
  /// Parâmetros:
  /// - [records]: Coleção completa de atividades registradas (`List<ActivityRecord>`).
  void saveActivityRecords(List<ActivityRecord> records) {
    final jsonList = records.map((r) => r.toJson()).toList();
    prefs.setString(keyActivityRecords, jsonEncode(jsonList));
  }

  /// Carrega a coleção completa de atividades físicas salvas do ciclista.
  List<ActivityRecord> loadActivityRecords() {
    final jsonString = prefs.getString(keyActivityRecords);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => ActivityRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Insere e anexa um novo registro de atividade física ao final do armazenamento local.
  ///
  /// Parâmetros:
  /// - [record]: Nova atividade realizada (`ActivityRecord`).
  void addActivityRecord(ActivityRecord record) {
    final records = loadActivityRecords();
    records.add(record);
    saveActivityRecords(records);
  }

  /// Registra um segmento recente de locomoção estimando o gasto energético (calorias) de ciclismo moderado.
  ///
  /// Parâmetros:
  /// - [distanceMeters]: Distância percorrida em metros (`double`).
  /// - [durationSeconds]: Tempo transcorrido em segundos (`double`).
  void recordLocomotionSegment(double distanceMeters, double durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return;
    
    // Calcula as calorias com base em ciclismo moderado (~0.035 kcal por metro)
    final calories = distanceMeters * 0.035;

    final record = ActivityRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      calories: calories,
    );
    addActivityRecord(record);
  }

  /// Limpa e redefine por completo todos os registros de atividade física acumulados.
  void clearActivityRecords() {
    prefs.remove(keyActivityRecords);
  }

  /// Salva no cache físico a lista de rotas recentes calculadas.
  ///
  /// Parâmetros:
  /// - [routes]: Lista de rotas estruturadas (`List<CachedRoute>`).
  void saveCachedRoutes(List<CachedRoute> routes) {
    final jsonList = routes.map((r) => r.toJson()).toList();
    prefs.setString(keyRouteCache, jsonEncode(jsonList));
  }

  /// Carrega todas as rotas cacheadas e salvas. Retorna lista vazia se nenhuma estiver disponível.
  List<CachedRoute> loadCachedRoutes() {
    final jsonString = prefs.getString(keyRouteCache);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => CachedRoute.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Adiciona uma nova rota ao cache físico do aplicativo, assegurando um limite máximo saudável de 30 itens.
  ///
  /// Parâmetros:
  /// - [route]: Nova rota a ser cacheada (`CachedRoute`).
  void addRouteToCache(CachedRoute route) {
    final routes = loadCachedRoutes();

    // Evita duplicados exatos
    routes.removeWhere((r) =>
        r.start.latitude == route.start.latitude &&
        r.start.longitude == route.start.longitude &&
        r.end.latitude == route.end.latitude &&
        r.end.longitude == route.end.longitude &&
        r.bikeType == route.bikeType &&
        r.strategy == route.strategy);

    routes.insert(0, route);

    // Mantém limite de 30 rotas em cache
    if (routes.length > 30) {
      routes.removeRange(30, routes.length);
    }
    saveCachedRoutes(routes);
  }

  /// Busca de forma extremamente eficiente se existe alguma rota salva correspondente no raio de 50 metros.
  ///
  /// Parâmetros:
  /// - [start]: Coordenadas de partida desejada (`LatLng`).
  /// - [end]: Coordenadas de chegada/destino final desejada (`LatLng`).
  /// - [bikeType]: O tipo de bicicleta configurado (`BikeType`).
  /// - [strategy]: A estratégia de cálculo adotada (`RouteStrategy`).
  CachedRoute? findCachedRoute({
    required LatLng start,
    required LatLng end,
    required BikeType bikeType,
    required RouteStrategy strategy,
  }) {
    final routes = loadCachedRoutes();
    const distanceCalculator = Distance();

    for (var route in routes) {
      if (route.bikeType == bikeType && route.strategy == strategy) {
        final startDist = distanceCalculator.as(LengthUnit.Meter, start, route.start);
        final endDist = distanceCalculator.as(LengthUnit.Meter, end, route.end);

        // Raio de proximidade de 50 metros para hit no cache
        if (startDist <= 50 && endDist <= 50) {
          return route;
        }
      }
    }
    return null;
  }

  /// Persiste as configurações e atributos estruturados de endereços frequentes.
  ///
  /// Parâmetros:
  /// - [addresses]: Coleção de mapas com atributos textuais e geográficos dos locais.
  void saveFrequentAddresses(List<Map<String, dynamic>> addresses) {
    prefs.setString(keyFrequentAddresses, jsonEncode(addresses));
  }

  /// Recupera a lista estruturada de endereços frequentes.
  List<Map<String, dynamic>> loadFrequentAddresses() {
    final jsonString = prefs.getString(keyFrequentAddresses);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Persiste a base local completa de avaliações de segurança recebidas via rede P2P ou local.
  ///
  /// Parâmetros:
  /// - [evaluations]: Lista de avaliações de segurança de vias (`List<SafetyEvaluation>`).
  void saveSafetyEvaluations(List<SafetyEvaluation> evaluations) {
    final jsonList = evaluations.map((e) => e.toJson()).toList();
    prefs.setString(keySafetyEvaluations, jsonEncode(jsonList));
  }

  /// Carrega as avaliações de segurança física e tráfego. Retorna dados mockados padrão se for a primeira inicialização.
  List<SafetyEvaluation> loadSafetyEvaluations() {
    final jsonString = prefs.getString(keySafetyEvaluations);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => SafetyEvaluation.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    // Retorna dados iniciais simulados para a rede P2P local (Av. Paulista, Elevado, Av. Consolação)
    final mockEvaluations = [
      SafetyEvaluation(
        segmentId: 'Av. Paulista',
        latitude: -23.556520,
        longitude: -46.662308,
        safetyScore: 5,
        lightingScore: 5,
        trafficScore: 2,
        accidentScore: 1,
        hasCycleway: true,
        safeTimePeriod: 'sempre',
        timestamp: DateTime.now().millisecondsSinceEpoch - 86400000,
        creatorPublicKey: 'rastro_pub_mock_paulista',
        signature: 'sig_mock_1',
      ),
      SafetyEvaluation(
        segmentId: 'Elevado Presidente João Goulart',
        latitude: -23.541520,
        longitude: -46.643308,
        safetyScore: 1,
        lightingScore: 1,
        trafficScore: 4,
        accidentScore: 5,
        hasCycleway: false,
        safeTimePeriod: 'dia',
        timestamp: DateTime.now().millisecondsSinceEpoch - 172800000,
        creatorPublicKey: 'rastro_pub_mock_elevado',
        signature: 'sig_mock_2',
      ),
      SafetyEvaluation(
        segmentId: 'Avenida Consolação',
        latitude: -23.561520,
        longitude: -46.655308,
        safetyScore: 4,
        lightingScore: 4,
        trafficScore: 3,
        accidentScore: 2,
        hasCycleway: true,
        safeTimePeriod: 'evitar_noite',
        timestamp: DateTime.now().millisecondsSinceEpoch - 43200000,
        creatorPublicKey: 'rastro_pub_mock_consolacao',
        signature: 'sig_mock_3',
      ),
    ];
    saveSafetyEvaluations(mockEvaluations);
    return mockEvaluations;
  }

  /// Adiciona e anexa um novo relatório P2P de segurança de via recebido ou gerado localmente.
  ///
  /// Parâmetros:
  /// - [evaluation]: Nova avaliação estruturada de segurança (`SafetyEvaluation`).
  void addSafetyEvaluation(SafetyEvaluation evaluation) {
    final evaluations = loadSafetyEvaluations();
    evaluations.add(evaluation);
    saveSafetyEvaluations(evaluations);
  }

  /// Grava a lista atualizada de estabelecimentos comerciais patrocinados e chancelados.
  ///
  /// Parâmetros:
  /// - [establishments]: Coleção completa de parceiros comerciais chancelados (`List<PartnerEstablishment>`).
  void savePartnerEstablishments(List<PartnerEstablishment> establishments) {
    final jsonList = establishments.map((e) => e.toJson()).toList();
    prefs.setString(keyPartnerEstablishments, jsonEncode(jsonList));
  }

  /// Retorna a coleção local de estabelecimentos comerciais patrocinados. Inicializa com mocks chancelados se vazia.
  List<PartnerEstablishment> loadPartnerEstablishments() {
    final jsonString = prefs.getString(keyPartnerEstablishments);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => PartnerEstablishment.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    // Dados iniciais mockados de estabelecimentos parceiros
    final mockPartners = [
      PartnerEstablishment(
        id: 'partner_1',
        name: 'Bike Café Paulista & Shop',
        latitude: -23.559520,
        longitude: -46.658308,
        isBikeFriendly: true,
        amenities: ['Bicicletário Seguro', 'Bomba de ar', 'Água Grátis', 'Tomada para E-Bike'],
        adminSignature: 'admin_sig_mock_1',
      ),
      PartnerEstablishment(
        id: 'partner_2',
        name: 'Oficina Rápida Consolação',
        latitude: -23.552520,
        longitude: -46.660308,
        isBikeFriendly: true,
        amenities: ['Ferramentas gratuitas', 'Remendo de Pneu', 'Venda de Acessórios'],
        adminSignature: 'admin_sig_mock_2',
      ),
    ];
    savePartnerEstablishments(mockPartners);
    return mockPartners;
  }

  /// Insere ou atualiza os dados cadastrais de um estabelecimento parceiro, identificando pelo identificador único.
  ///
  /// Parâmetros:
  /// - [establishment]: O parceiro comercial chancelado (`PartnerEstablishment`).
  void addPartnerEstablishment(PartnerEstablishment establishment) {
    final list = loadPartnerEstablishments();
    list.removeWhere((e) => e.id == establishment.id);
    list.add(establishment);
    savePartnerEstablishments(list);
  }
}
