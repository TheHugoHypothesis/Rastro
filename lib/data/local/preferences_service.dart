import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/bike_type.dart';
import '../../domain/models/route_preference.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/activity_record.dart';
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
}
