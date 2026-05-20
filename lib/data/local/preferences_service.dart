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

class PreferencesService {
  final SharedPreferences prefs;
  PreferencesService(this.prefs);

  static const String keyBikeType = 'bike_type_pref';
  static const String keyRouteStrategy = 'route_strategy_pref';
  static const String keyUserName = 'user_name_pref';
  static const String keyUserAge = 'user_age_pref';
  static const String keyThemeMode = 'theme_mode_pref';
  static const String keyPoisCache = 'pois_cache_pref';

  void saveBikeType(BikeType type) {
    prefs.setString(keyBikeType, type.name);
  }

  BikeType? loadBikeType() {
    final name = prefs.getString(keyBikeType);
    if (name != null) {
      return BikeType.values.firstWhere((e) => e.name == name, orElse: () => BikeType.comum);
    }
    return null;
  }

  void saveRouteStrategy(RouteStrategy strategy) {
    prefs.setString(keyRouteStrategy, strategy.name);
  }

  RouteStrategy? loadRouteStrategy() {
    final name = prefs.getString(keyRouteStrategy);
    if (name != null) {
      return RouteStrategy.values.firstWhere((e) => e.name == name, orElse: () => RouteStrategy.seguranca);
    }
    return null;
  }

  static const String keyUserPhotoPath = 'user_photo_path_pref';

  void saveUserProfile(UserProfile profile) {
    prefs.setString(keyUserName, profile.name);
    prefs.setInt(keyUserAge, profile.age);
    if (profile.photoPath != null) {
      prefs.setString(keyUserPhotoPath, profile.photoPath!);
    } else {
      prefs.remove(keyUserPhotoPath);
    }
  }

  UserProfile? loadUserProfile() {
    final name = prefs.getString(keyUserName);
    final age = prefs.getInt(keyUserAge);
    final photoPath = prefs.getString(keyUserPhotoPath);
    if (name != null && age != null) {
      return UserProfile(name: name, age: age, photoPath: photoPath);
    }
    return null;
  }

  void saveThemeMode(ThemeMode mode) {
    prefs.setString(keyThemeMode, mode.name);
  }

  ThemeMode loadThemeMode() {
    final name = prefs.getString(keyThemeMode);
    if (name != null) {
      return ThemeMode.values.firstWhere((e) => e.name == name, orElse: () => ThemeMode.dark);
    }
    return ThemeMode.dark;
  }

  void savePois(List<PoiResult> pois) {
    final jsonList = pois.map((p) => p.toJson()).toList();
    prefs.setString(keyPoisCache, jsonEncode(jsonList));
  }

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

  void saveSearchHistory(List<Map<String, dynamic>> history) {
    prefs.setString('search_history_pref', jsonEncode(history));
  }

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

  // Activity Tracking Persistence
  static const String keyActivityRecords = 'activity_records_pref';

  void saveActivityRecords(List<ActivityRecord> records) {
    final jsonList = records.map((r) => r.toJson()).toList();
    prefs.setString(keyActivityRecords, jsonEncode(jsonList));
  }

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

  void addActivityRecord(ActivityRecord record) {
    final records = loadActivityRecords();
    records.add(record);
    saveActivityRecords(records);
  }

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

  void clearActivityRecords() {
    prefs.remove(keyActivityRecords);
  }

  static const String keyRouteCache = 'route_cache_pref';

  void saveCachedRoutes(List<CachedRoute> routes) {
    final jsonList = routes.map((r) => r.toJson()).toList();
    prefs.setString(keyRouteCache, jsonEncode(jsonList));
  }

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

  static const String keyFrequentAddresses = 'frequent_addresses_pref';

  void saveFrequentAddresses(List<Map<String, dynamic>> addresses) {
    prefs.setString(keyFrequentAddresses, jsonEncode(addresses));
  }

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

  static const String keySafetyEvaluations = 'safety_evaluations_pref';

  void saveSafetyEvaluations(List<SafetyEvaluation> evaluations) {
    final jsonList = evaluations.map((e) => e.toJson()).toList();
    prefs.setString(keySafetyEvaluations, jsonEncode(jsonList));
  }

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

  void addSafetyEvaluation(SafetyEvaluation evaluation) {
    final evaluations = loadSafetyEvaluations();
    evaluations.add(evaluation);
    saveSafetyEvaluations(evaluations);
  }

  static const String keyPartnerEstablishments = 'partner_establishments_pref';

  void savePartnerEstablishments(List<PartnerEstablishment> establishments) {
    final jsonList = establishments.map((e) => e.toJson()).toList();
    prefs.setString(keyPartnerEstablishments, jsonEncode(jsonList));
  }

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

  void addPartnerEstablishment(PartnerEstablishment establishment) {
    final list = loadPartnerEstablishments();
    list.removeWhere((e) => e.id == establishment.id);
    list.add(establishment);
    savePartnerEstablishments(list);
  }
}
