import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/poi_service.dart';
import '../../providers/app_state_provider.dart';

/// Mixin responsável apenas pelo carregamento e cache de POIs.
/// O desenho no mapa é feito nativamente pela MarkerLayer através de uma função Builder,
/// que lê a lista [pois] e escala os ícones proporcionalmente ao zoom.
mixin MapPoiMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool get isDarkTheme;

  // ── estado público ────────────────────────────────────────────────────────
  final PoiService poiService = PoiService();
  List<PoiResult> pois = [];
  bool poisLoaded = false;
  Timer? poiDebounce;
  double currentZoom = 18.0;

  /// Áreas (BoundingBoxes) que já foram buscadas no servidor, para evitar requisições repetidas.
  final List<LatLngBounds> _fetchedAreas = [];
  bool isFetchingPois = false;

  /// Keys de POIs já presentes na lista [pois] — evita duplicatas.
  final Set<String> _knownPoiKeys = {};

  @override
  void initState() {
    super.initState();
    pois = ref.read(preferencesServiceProvider).loadPois();
    if (pois.isNotEmpty) poisLoaded = true;
    for (final p in pois) {
      _knownPoiKeys.add(poiKey(p));
    }
  }

  // ── helpers de chave ─────────────────────────────────────────────────────

  String poiKey(PoiResult poi) =>
      '${poi.point.latitude.toStringAsFixed(5)}_'
      '${poi.point.longitude.toStringAsFixed(5)}';

  bool _isCovered(LatLngBounds bbox) {
    for (final area in _fetchedAreas) {
      if (area.contains(bbox.southWest) && area.contains(bbox.northEast)) return true;
    }
    return false;
  }

  // ── carregamento de POIs ─────────────────────────────────────────────────

  Future<void> loadPoisForBbox(LatLngBounds bbox) async {
    if (currentZoom < 13.0) return; // não carrega no zoom baixo

    if (_isCovered(bbox)) return; // A área atual já está contida num fetch anterior

    // Expande a área para cobrir os arredores e reduzir chamadas durante o arrasto
    final fetchBbox = expandBboxMinimum(bbox);
    
    if (mounted) setState(() => isFetchingPois = true);
    
    try {
      final allFromTile = await poiService.fetchInBbox(bbox: fetchBbox);
      _fetchedAreas.add(fetchBbox);

      final toAdd =
          allFromTile.where((p) => p.point.latitude.isFinite && p.point.longitude.isFinite && !_knownPoiKeys.contains(poiKey(p))).toList();
          
      if (mounted) {
        setState(() {
          isFetchingPois = false;
          if (toAdd.isNotEmpty) {
            for (final p in toAdd) {
              _knownPoiKeys.add(poiKey(p));
            }
            pois = [...pois, ...toAdd];
            poisLoaded = true;
          }
        });
        
        if (toAdd.isNotEmpty) {
          // Mantém no máximo os 150 POIs mais recentes para evitar lentidão e peso
          final toSave = pois.length > 150 ? pois.sublist(pois.length - 150) : pois;
          ref.read(preferencesServiceProvider).savePois(toSave);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isFetchingPois = false);
    }
  }

  LatLngBounds expandBboxMinimum(LatLngBounds bbox) {
    double n = bbox.north, s = bbox.south, e = bbox.east, w = bbox.west;
    
    if (!n.isFinite || !s.isFinite || !e.isFinite || !w.isFinite) {
      return bbox;
    }

    final latDiff = (n - s).abs();
    final lonDiff = (e - w).abs();
    if (latDiff < 0.09) {
      final pad = (0.09 - latDiff) / 2;
      n += pad; s -= pad;
    }
    if (lonDiff < 0.12) {
      final pad = (0.12 - lonDiff) / 2;
      e += pad; w -= pad;
    }
    
    // Clampa nos limites físicos da Terra para evitar exceções do LatLng Bounds
    s = s.clamp(-90.0, 90.0);
    n = n.clamp(-90.0, 90.0);
    w = w.clamp(-180.0, 180.0);
    e = e.clamp(-180.0, 180.0);
    
    return LatLngBounds(LatLng(s, w), LatLng(n, e));
  }

  // ── callback de movimento do mapa ─────────────────────────────────────────

  /// Chamado pelo `onPositionChanged` do flutter_map.
  /// Atualiza [currentZoom] e carrega novos POIs com debounce.
  Future<void> onPoiMapMoved(MapCamera camera) async {
    currentZoom = camera.zoom;
    if (poiDebounce?.isActive ?? false) poiDebounce!.cancel();
    if (camera.zoom < 13.0) return;

    poiDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final bounds = camera.visibleBounds;
        if (!bounds.southWest.latitude.isFinite || !bounds.southWest.longitude.isFinite ||
            !bounds.northEast.latitude.isFinite || !bounds.northEast.longitude.isFinite) {
          return; // Ignora se o mapa retornou limites matematicamente inválidos
        }
        await loadPoisForBbox(bounds);
      } catch (e) {
        // Silenciosamente ignora erros de projeção de bordas matemáticas do mapa 
        // (por exemplo, ao girar ou dar zoom muito rápido nas beiradas da projeção do globo)
        debugPrint('Erro ao obter limites visíveis (visibleBounds): $e');
      }
    });
  }

  // ── helpers de categoria (usados pelo PoiOverlayLayer) ───────────────────

  Color getPoiColor(PoiCategory cat) {
    switch (cat) {
      case PoiCategory.restaurant:  return const Color(0xFFE65100);
      case PoiCategory.cafe:        return const Color(0xFF6D4C41);
      case PoiCategory.bar:         return const Color(0xFF8E24AA);
      case PoiCategory.hospital:    return const Color(0xFFD32F2F);
      case PoiCategory.pharmacy:    return const Color(0xFF2E7D32);
      case PoiCategory.bikeShop:    return const Color(0xFF1565C0);
      case PoiCategory.bakery:      return const Color(0xFFF57F17);
      case PoiCategory.supermarket: return const Color(0xFF00695C);
    }
  }

  IconData getPoiIcon(PoiCategory cat) {
    switch (cat) {
      case PoiCategory.restaurant:  return Icons.restaurant_rounded;
      case PoiCategory.cafe:        return Icons.local_cafe_rounded;
      case PoiCategory.bar:         return Icons.sports_bar_rounded;
      case PoiCategory.hospital:    return Icons.local_hospital_rounded;
      case PoiCategory.pharmacy:    return Icons.local_pharmacy_rounded;
      case PoiCategory.bikeShop:    return Icons.pedal_bike_rounded;
      case PoiCategory.bakery:      return Icons.bakery_dining_rounded;
      case PoiCategory.supermarket: return Icons.shopping_cart_rounded;
    }
  }

  // ── hit-test legado (mantido para compatibilidade) ────────────────────────

  PoiResult? findPoiNear(LatLng clickPoint) {
    if (pois.isEmpty) return null;
    const radiusKm = 0.15;

    double distKm(LatLng a, LatLng b) {
      const distance = Distance();
      return distance.as(LengthUnit.Meter, a, b) / 1000.0;
    }

    PoiResult? closest;
    double minD = double.infinity;
    for (final p in pois) {
      final d = distKm(clickPoint, p.point);
      if (d < radiusKm && d < minD) { minD = d; closest = p; }
    }
    return closest;
  }
}
