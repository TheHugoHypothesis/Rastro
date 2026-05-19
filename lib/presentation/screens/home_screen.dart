import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Providers & Models
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../../domain/models/route_instruction.dart';
import '../../core/theme/colors.dart';


// Services & Mixins
import '../../core/services/tts_service.dart';
import 'home/map_poi_mixin.dart';
import '../../data/remote/poi_service.dart';

import '../../core/services/notification_service.dart';

// UI Widgets
import '../widgets/home/search_bar_widget.dart';
import '../widgets/home/avatar_button.dart';
import '../widgets/home/location_fab.dart';
import '../widgets/home/collapsible_panel.dart';
import '../widgets/home/turn_by_turn_card.dart';
import '../widgets/home/cancel_route_bar.dart';
import '../widgets/home/poi_details_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with MapPoiMixin {
  final MapController _mapController = MapController();
  final SearchController _searchController = SearchController();
  final SearchController _originSearchController = SearchController();
  
  // Routing State
  List<RouteInstruction> _currentSteps = [];
  int _currentStepIndex = 0;
  bool _routeAccepted = false;
  LatLng? _destinationPoint;
  LatLng? _originPoint;
  List<LatLng> _routePoints = [];
  double _previewDistance = 0.0;
  double _previewDuration = 0.0;
  DateTime? _lastLocationTime;
  
  bool _isDark = true;
  bool _panelExpanded = false;
  bool _isMapReady = false;
  LatLng? _lastKnownPosition;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  double _gyroSpeed = 0.0;
  double _deviceHeading = 0.0;
  double _sinSum = 0.0;
  double _cosSum = 1.0;
  bool _lockRotation = true;
  
  // Marker Cache para evitar re-clusterização e flickering
  List<Marker> _cachedPoiMarkers = [];
  int _lastPoisCount = -1;
  bool _lastIsDarkCache = false;

  // Mixin Implementations
  @override
  bool get isDarkTheme => _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = true;
    TtsService().init();
    _initLocation();
    _initCompass();
  }

  void _initCompass() {
    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      if (mounted) {
        setState(() {
          // Calcula a magnitude da velocidade angular (rad/s) em 3D
          _gyroSpeed = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        });
      }
    });

    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      // O magnetômetro mede campos magnéticos. Em um plano 2D, atan2(x, y) 
      // nos dá o ângulo em radianos relativo ao norte magnético do dispositivo.
      final heading = math.atan2(event.x, event.y);
      double degrees = heading * 180 / math.pi;

      // Inverte e normaliza o rumo magnético
      double adjustedDegrees = -degrees;
      if (adjustedDegrees < 0) {
        adjustedDegrees += 360;
      }

      // Filtro passa-baixa adaptativo baseado no giroscópio:
      // Se o celular está parado (gyroSpeed < 0.05), o coeficiente é 0.998 para eliminar 100% de ruído.
      // Se está se movendo, o coeficiente é 0.85 para reação instantânea.
      final rad = adjustedDegrees * math.pi / 180.0;
      if (mounted) {
        setState(() {
          final double coeff = _gyroSpeed < 0.05 ? 0.998 : 0.85;
          _sinSum = _sinSum * coeff + math.sin(rad) * (1.0 - coeff);
          _cosSum = _cosSum * coeff + math.cos(rad) * (1.0 - coeff);
          _deviceHeading = math.atan2(_sinSum, _cosSum) * 180.0 / math.pi;
        });
      }
    });
  }
  
  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    
    // Get initial position
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _lastKnownPosition = LatLng(pos.latitude, pos.longitude);
        _lastLocationTime = DateTime.now();
      });
      if (_isMapReady) {
        _mapController.move(_lastKnownPosition!, 18.0);
      }
    }
    
    // Start tracking
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      )
    ).listen((Position position) {
      if (mounted) {
        final newPos = LatLng(position.latitude, position.longitude);
        if (_lastKnownPosition != null && _lastLocationTime != null) {
          final distanceMeters = Geolocator.distanceBetween(
            _lastKnownPosition!.latitude,
            _lastKnownPosition!.longitude,
            newPos.latitude,
            newPos.longitude,
          );

          final elapsedSeconds = DateTime.now().difference(_lastLocationTime!).inSeconds.toDouble();
          
          // Filtros inteligentes para evitar ruídos de drift do GPS ou viagens em carro/ônibus
          if (distanceMeters > 3.0 && distanceMeters < 150.0 && elapsedSeconds > 0 && elapsedSeconds < 60) {
            final speedMps = distanceMeters / elapsedSeconds;
            // Velocidade típica de bike: entre 1.8 km/h (0.5 m/s) e 54 km/h (15 m/s)
            if (speedMps >= 0.5 && speedMps <= 15.0) {
              ref.read(preferencesServiceProvider).recordLocomotionSegment(distanceMeters, elapsedSeconds);
            }
          }
        }

        setState(() {
          _lastKnownPosition = newPos;
          _lastLocationTime = DateTime.now();
        });
        
        // Auto follow if route is accepted
        if (_routeAccepted && _isMapReady) {
          _mapController.move(_lastKnownPosition!, _mapController.camera.zoom);
        }
      }
    });
  }

  void _onMapReady() {
    setState(() {
      _isMapReady = true;
    });
    if (_lastKnownPosition != null) {
      _mapController.move(_lastKnownPosition!, 18.0);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    onPoiMapMoved(camera);
    if (!_lockRotation && mounted) {
      setState(() {});
    }
  }

  Widget _buildCompassButton() {
    final primaryColor = _isDark ? AppColors.primaryLight : AppColors.primary;
    final surfaceColor = _isDark ? AppColors.surface : Colors.white;
    final border = _isDark ? AppColors.border : AppColors.lightBorder;
    
    // Rotação em radianos obtida da câmera do mapa
    final double currentRotationRad = _isMapReady ? (_mapController.camera.rotation * math.pi / 180.0) : 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _lockRotation = !_lockRotation;
          if (_lockRotation && _isMapReady) {
            _mapController.rotate(0.0);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.90),
          shape: BoxShape.circle,
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Transform.rotate(
            angle: -currentRotationRad,
            child: Icon(
              _lockRotation ? Icons.explore_rounded : Icons.explore_outlined,
              color: _lockRotation ? primaryColor : (_isDark ? Colors.white70 : Colors.black54),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationMarkerWidget() {
    final pinColor = _isDark ? AppColors.primaryLight : AppColors.primary;
    final surfaceColor = _isDark ? AppColors.surface : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Sombra de rastro no chão com pulso de opacidade para elegância extra
        Positioned(
          bottom: 2,
          child: Container(
            width: 20,
            height: 10,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Corpo do Pin de navegação elegante estilo Neo-Brutalista
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pinColor,
                shape: BoxShape.circle,
                border: Border.all(color: surfaceColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.flag_rounded, // Bandeira de chegada/destino estilizada
                  color: surfaceColor,
                  size: 20,
                ),
              ),
            ),
            // Triângulo ponteiro de vetor
            CustomPaint(
              size: const Size(10, 7),
              painter: _TrianglePainter(color: pinColor),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onAddressSelected(LatLng dest, {String? title, String? subtitle}) async {
    try {
      if (title != null && subtitle != null) {
        ref.read(preferencesServiceProvider).addRecentSearch(title, subtitle, dest.latitude, dest.longitude);
      }
      setState(() { 
        _destinationPoint = dest; 
        _currentSteps.clear(); 
        _currentStepIndex = 0; 
        _routeAccepted = false; 
        _routePoints.clear();
        _previewDistance = 0.0;
        _previewDuration = 0.0;
      });
      _mapController.move(dest, 18.0);
      _updateRoutePreview();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _updateRoutePreview() async {
    final startLatLng = _originPoint ?? _lastKnownPosition;
    final endLatLng = _destinationPoint;
    if (startLatLng == null || endLatLng == null) return;

    final selectedBike = ref.read(bikeTypeProvider);
    final selectedStrategy = ref.read(routeStrategyProvider);

    try {
      final routeData = await ref.read(routingServiceProvider).getRoutePath(
        start: startLatLng,
        end: endLatLng,
        bikeType: selectedBike,
        strategy: selectedStrategy,
      );
      
      if (mounted && 
          _destinationPoint == endLatLng && 
          (_originPoint ?? _lastKnownPosition) == startLatLng) {
        setState(() {
          _previewDistance = routeData.distance;
          _previewDuration = routeData.duration;
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar preview de rota: $e');
    }
  }

  Future<void> _tracarRotaSelecionada() async {
    if (_destinationPoint == null) return;
    final selectedBike = ref.read(bikeTypeProvider);
    final selectedStrategy = ref.read(routeStrategyProvider);
    
    final startLatLng = _originPoint ?? _lastKnownPosition;
    if (startLatLng == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ative o GPS ou selecione uma origem.')));
      return;
    }
    
    try {
      final routeData = await ref.read(routingServiceProvider).getRoutePath(
        start: startLatLng, end: _destinationPoint!, bikeType: selectedBike, strategy: selectedStrategy,
      );
      
      if (routeData.points.isNotEmpty) {
        setState(() { 
          _currentSteps = routeData.instructions; 
          _currentStepIndex = 0; 
          _routeAccepted = true; 
          _routePoints = routeData.points;
        });
        
        // Fit bounds
        final bounds = LatLngBounds.fromPoints(routeData.points);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        
        TtsService().speak('${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)} metros');

        // Enviar notificação de início de rota no sistema (RF014)
        ref.read(notificationServiceProvider).showNotification(
          id: 99,
          title: 'Rastro - Rota Iniciada!',
          body: 'Destino a ${(routeData.distance / 1000).toStringAsFixed(1)} km (~${(routeData.duration / 60).toStringAsFixed(0)} min). Boa pedalada!',
          ongoing: true,
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma rota encontrada.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  void dispose() {
    poiDebounce?.cancel();
    _searchController.dispose();
    _originSearchController.dispose();
    _positionStream?.cancel();
    _magnetometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    TtsService().stop();
    super.dispose();
  }

  // Theme Helpers
  Color get _routeColor => _isDark ? AppColors.routeColorDark : AppColors.routeColorLight;
  Color get _primaryColor => _isDark ? AppColors.primary : AppColors.lightPrimary;
  Color get _bgColor => _isDark ? AppColors.background : AppColors.lightBackground;
  Color get _surfaceColor => _isDark ? AppColors.surface : AppColors.lightSurface;
  Color get _textColor => _isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get _subtextColor => _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

  double _iconSize(double zoom) {
    if (zoom < 13.0) return 0.0;
    return ((zoom - 10.0) * 5.5).clamp(18.0, 72.0);
  }

  double _fontSize(double zoom) {
    if (zoom < 15.0) return 0.0;
    return ((zoom - 15.0) * 3.5).clamp(10.0, 26.0);
  }

  void _updatePoiMarkersCache() {
    _cachedPoiMarkers = pois.map((poi) {
      final color = getPoiColor(poi.category);
      final iconData = getPoiIcon(poi.category);
      final bgColor = _isDark ? const Color(0xFF13131A) : Colors.white;
      
      return Marker(
        point: poi.point,
        width: 120, // Bounds fixos amplos o suficiente para texto e ícone no maior zoom
        height: 120,
        alignment: Alignment.center,
        child: Builder(
          builder: (ctx) {
            final camera = MapCamera.of(ctx);
            if (camera.zoom < 13.0) return const SizedBox.shrink();

            final iconSz = _iconSize(camera.zoom);
            final fontSz = _fontSize(camera.zoom);

            return AnimatedPoiMarker(
              child: GestureDetector(
                onTap: () => showPoiDetailsSheet(
                  context: context,
                  poi: poi,
                  isDark: _isDark,
                  surfaceColor: _surfaceColor,
                  textColor: _textColor,
                  poiColor: color,
                  poiIconData: iconData,
                  onAddressSelected: _onAddressSelected,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconSz,
                      height: iconSz,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: (iconSz * 0.055).clamp(2.0, 5.0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Icon(iconData, color: color, size: iconSz * 0.52),
                      ),
                    ),
                    if (fontSz > 0) ...[
                      const SizedBox(height: 2),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            poi.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSz,
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = (fontSz * 0.25).clamp(1.5, 4.0)
                              ..color = _isDark ? Colors.black : Colors.white,
                          ),
                          ),
                          Text(
                            poi.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSz,
                              fontWeight: FontWeight.w800,
                              color: _isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
        ),
      );
    }).toList();
    _lastPoisCount = pois.length;
    _lastIsDarkCache = _isDark;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final newIsDark = themeMode == ThemeMode.dark;
    final isOnline = ref.watch(connectivityProvider);
    final isTtsEnabled = ref.watch(ttsEnabledProvider);
    
    if (newIsDark != _isDark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() { _isDark = newIsDark; });
      });
    }

    // Atualiza o cache de POIs somente se houver mudança nos dados ou no tema
    if (_lastPoisCount != pois.length || _lastIsDarkCache != _isDark) {
      _updatePoiMarkersCache();
    }

    return PopScope(
      canPop: _destinationPoint == null && !_routeAccepted,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _destinationPoint = null;
          _originPoint = null;
          _routeAccepted = false;
          _currentSteps.clear();
          _routePoints.clear();
          _panelExpanded = false;
        });
        _searchController.clear();
        _originSearchController.clear();
      },
      child: Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lastKnownPosition ?? const LatLng(-23.550520, -46.633308),
              initialZoom: 18.0,
              minZoom: 5.0,
              maxZoom: 19.0,
              cameraConstraint: SafeCameraConstraint(
                CameraConstraint.contain(
                  bounds: LatLngBounds(
                    const LatLng(-85.05, -180.0),
                    const LatLng(85.05, 180.0),
                  ),
                ),
              ),
              interactionOptions: InteractionOptions(
                flags: _lockRotation ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.all,
              ),
              onPositionChanged: _onPositionChanged,
              onMapReady: _onMapReady,
              onLongPress: (tapPosition, point) {
                final addressFuture = ref.read(routingServiceProvider).reverseGeocode(point);
                showCoordinateDetailsSheet(
                  context: context,
                  point: point,
                  addressFuture: addressFuture,
                  isDark: _isDark,
                  surfaceColor: _surfaceColor,
                  textColor: _textColor,
                  accentColor: _primaryColor,
                  onAddressSelected: _onAddressSelected,
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isDark 
                    ? "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
                    : "https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.rastro.app',
              ),
              
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: _routeColor,
                      strokeWidth: 8.0,
                    ),
                  ],
                ),
                
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(50, 50),
                  markers: _cachedPoiMarkers,
                  builder: (context, markers) {
                    final int count = markers.length;
                    final double clusterSize = count < 10 ? 34.0 : (count < 50 ? 40.0 : 48.0);
                    
                    return Center(
                      child: Container(
                        width: clusterSize,
                        height: clusterSize,
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF13131A) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primaryColor, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withAlpha(90), 
                              blurRadius: 8, 
                              spreadRadius: 1
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: _isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: count < 50 ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
                
              MarkerLayer(
                markers: [
                  // Destination Marker (Continua aparecendo com visual elegante durante todo o percurso)
                  if (_destinationPoint != null)
                    Marker(
                      point: _destinationPoint!,
                      width: 60,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: _buildDestinationMarkerWidget(),
                    ),
                    
                  // Origin Marker (Aparece se for uma localização customizada diferente da atual)
                  if (_originPoint != null)
                    Marker(
                      point: _originPoint!,
                      width: 60,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: _buildOriginMarkerWidget(),
                    ),
                    
                  // User Location Marker com indicador de direção (cone de visão baseado no magnetômetro)
                  if (_lastKnownPosition != null)
                    Marker(
                      point: _lastKnownPosition!,
                      width: 80,
                      height: 80,
                      child: Transform.rotate(
                        angle: _deviceHeading * math.pi / 180.0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Feixe de luz / Cone de visão translúcido indicando a direção apontada pelo topo do aparelho
                            Positioned(
                              top: 4,
                              child: Opacity(
                                opacity: 0.28,
                                child: Icon(
                                  Icons.navigation_rounded,
                                  color: _isDark ? _routeColor : Colors.black,
                                  size: 46,
                                ),
                              ),
                            ),
                            // Borda branca externa para dar alto contraste e legibilidade tanto no mapa escuro quanto claro
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Ponto indicador central
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isDark ? _routeColor : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Bar Overlay
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgColor.withAlpha(240), _bgColor.withAlpha(0)],
                ),
              ),
              child: !_routeAccepted
                  ? (_destinationPoint == null
                      ? Row(
                          children: [
                            AvatarButton(isDark: _isDark),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SearchBarWidget(
                                isDark: _isDark,
                                surfaceColor: _surfaceColor,
                                routeColor: _routeColor,
                                searchController: _searchController,
                                onAddressSelected: _onAddressSelected,
                                userLocation: _lastKnownPosition,
                              ),
                            ),
                          ],
                        )
                      : _buildUnifiedRoutingPanel())
                  : const SizedBox.shrink(),
            ),
          ),

          // Buttons Column (Compass/Rotation Lock + Location FAB)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            right: 16,
            bottom: !_routeAccepted
                ? (_destinationPoint != null
                    ? (_panelExpanded ? 390 : 190)
                    : 32)
                : 32,
            child: AnimatedOpacity(
              opacity: !_routeAccepted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _routeAccepted,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompassButton(),
                    const SizedBox(height: 12),
                    LocationFab(
                      isDark: _isDark,
                      onPressed: () async {
                        if (_lastKnownPosition != null) {
                          _mapController.move(_lastKnownPosition!, 18.0);
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buscando localização...')));
                          _initLocation();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Turn-by-Turn Card
          if (_routeAccepted && _currentSteps.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 16, right: 16,
              child: TurnByTurnCard(
                isDark: _isDark,
                step: _currentSteps[_currentStepIndex],
                stepIndex: _currentStepIndex,
                totalSteps: _currentSteps.length,
                onSpeak: () => TtsService().speak('${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)} metros'),
                onClose: () async {
                  setState(() { _routeAccepted = false; _currentSteps.clear(); _routePoints.clear(); });
                  ref.read(notificationServiceProvider).cancelAll();
                },
                isTtsEnabled: isTtsEnabled,
                onToggleTts: () => ref.read(ttsEnabledProvider.notifier).toggle(),
                onNext: () {
                  if (_currentStepIndex < _currentSteps.length - 1) {
                    setState(() {
                      _currentStepIndex++;
                    });
                    TtsService().speak('${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)} metros');
                    ref.read(notificationServiceProvider).showNotification(
                      id: 99,
                      title: 'Rastro - Próxima Instrução',
                      body: '${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)}m.',
                      ongoing: true,
                    );
                  }
                },
                onPrevious: () {
                  if (_currentStepIndex > 0) {
                    setState(() {
                      _currentStepIndex--;
                    });
                    TtsService().speak('${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)} metros');
                    ref.read(notificationServiceProvider).showNotification(
                      id: 99,
                      title: 'Rastro - Instrução Anterior',
                      body: '${_currentSteps[_currentStepIndex].instruction} em ${_currentSteps[_currentStepIndex].distance.toStringAsFixed(0)}m.',
                      ongoing: true,
                    );
                  }
                },
              ),
            ),

          // POI Loading Indicator
          Positioned(
            bottom: _destinationPoint != null ? 100 : 32,
            left: 0, right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: isFetchingPois ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDark ? AppColors.surface.withAlpha(220) : Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isDark ? Colors.white12 : Colors.black12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buscando locais na região...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Content (Cancel Bar OR Collapsible Panel)
          if (_routeAccepted)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CancelRouteBar(
                surfaceColor: _surfaceColor,
                onCancel: () async {
                  setState(() { 
                    _routeAccepted = false; 
                    _currentSteps.clear(); 
                    _destinationPoint = null; 
                    _originPoint = null;
                    _routePoints.clear(); 
                    _panelExpanded = false;
                  });
                  _searchController.clear();
                  _originSearchController.clear();
                  if (_lastKnownPosition != null) _mapController.move(_lastKnownPosition!, 18.0);
                  
                  ref.read(notificationServiceProvider).cancelAll();
                },
              ),
            )
          else if (_destinationPoint != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: CollapsiblePanel(
                isDark: _isDark,
                surfaceColor: _surfaceColor,
                primaryColor: _primaryColor,
                textColor: _textColor,
                subtextColor: _subtextColor,
                destinationPoint: _destinationPoint,
                onTraceRoute: _tracarRotaSelecionada,
                isExpanded: _panelExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _panelExpanded = expanded;
                  });
                },
                previewDistance: _previewDistance,
                previewDuration: _previewDuration,
              ),
            ),

            // Connectivity Status Indicator
            if (!isOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + (_routeAccepted ? 16 : (_destinationPoint == null ? 76 : 148)),
                left: 24, right: 24,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF2C1E45) : const Color(0xFFFFF6E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDark ? AppColors.primary : const Color(0xFFFFA500),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isDark ? AppColors.primary : const Color(0xFFFFA500)).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: _isDark ? AppColors.primaryLight : const Color(0xFFD48800),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sem Conexão • Usando Rotas em Cache',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _isDark ? Colors.white : const Color(0xFF873800),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
        ],
      ),
    ));
  }

  Widget _buildUnifiedRoutingPanel() {
    final border = _isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Conector visual esquerdo (círculo azul -> linha pontilhada -> pin de destino)
          Column(
            children: [
              const Icon(Icons.circle, color: Colors.blue, size: 10),
              Container(
                width: 2,
                height: 28,
                color: _isDark ? Colors.white24 : Colors.black12,
              ),
              Icon(Icons.location_on_rounded, color: _primaryColor, size: 14),
            ],
          ),
          const SizedBox(width: 12),
          // Campos de busca empilhados
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOriginSearchAnchor(),
                const SizedBox(height: 8),
                _buildDestinationSearchAnchor(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Botão inverter
          IconButton(
            onPressed: _swapOriginAndDestination,
            icon: Icon(Icons.swap_vert_rounded, color: _textColor, size: 24),
            tooltip: 'Inverter origem e destino',
          ),
        ],
      ),
    );
  }

  Widget _buildOriginSearchAnchor() {
    final subtextColor = _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return SearchAnchor(
      searchController: _originSearchController,
      builder: (context, controller) {
        final displayName = controller.text.isEmpty ? 'Minha localização atual' : controller.text;
        return GestureDetector(
          onTap: () => controller.openView(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: controller.text.isEmpty ? subtextColor : _textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.my_location_rounded, color: _isDark ? Colors.white30 : Colors.black38, size: 15),
              ],
            ),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        return _buildAddressSuggestions(controller, (LatLng point, String addressTitle) {
          setState(() {
            _originPoint = point;
            _originSearchController.text = addressTitle;
            _previewDistance = 0.0;
            _previewDuration = 0.0;
          });
          _mapController.move(point, 18.0);
          _updateRoutePreview();
        });
      },
    );
  }

  Widget _buildDestinationSearchAnchor() {
    final subtextColor = _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return SearchAnchor(
      searchController: _searchController,
      builder: (context, controller) {
        final displayName = controller.text.isEmpty ? 'Defina o destino' : controller.text;
        return GestureDetector(
          onTap: () => controller.openView(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _isDark ? Colors.white12 : Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: controller.text.isEmpty ? subtextColor : _textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search_rounded, color: _primaryColor, size: 15),
              ],
            ),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        return _buildAddressSuggestions(controller, (LatLng point, String addressTitle) {
          setState(() {
            _destinationPoint = point;
            _searchController.text = addressTitle;
            _previewDistance = 0.0;
            _previewDuration = 0.0;
          });
          _mapController.move(point, 18.0);
          _updateRoutePreview();
        });
      },
    );
  }

  Future<Iterable<Widget>> _buildAddressSuggestions(
    SearchController controller,
    void Function(LatLng point, String addressTitle) onSelect,
  ) async {
    final subtextColor = _isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    if (controller.text.isEmpty) {
      final history = ref.read(preferencesServiceProvider).loadSearchHistory();
      final pois = ref.read(preferencesServiceProvider).loadPois();
      final List<Widget> items = [];
      final primaryColor = _isDark ? AppColors.primaryLight : _primaryColor;

      if (history.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 6),
            child: Text(
              'Locais Recentes',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
        items.addAll(history.map((item) {
          final title = item['title']?.toString() ?? 'Sem título';
          final subtitle = item['subtitle']?.toString() ?? '';
          final lat = (item['lat'] as num?)?.toDouble() ?? 0.0;
          final lon = (item['lon'] as num?)?.toDouble() ?? 0.0;

          return ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.blueAccent),
            title: Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
            subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: subtextColor)) : null,
            onTap: () {
              controller.closeView(title);
              onSelect(LatLng(lat, lon), title);
            },
          );
        }));
      }

      if (pois.isNotEmpty) {
        final List<PoiResult> sortedPois = List.from(pois);
        final LatLng? referenceLocation = _lastKnownPosition;
        if (referenceLocation != null) {
          const distanceCalculator = Distance();
          sortedPois.sort((a, b) {
            final distA = distanceCalculator.as(LengthUnit.Meter, referenceLocation, a.point);
            final distB = distanceCalculator.as(LengthUnit.Meter, referenceLocation, b.point);
            return distA.compareTo(distB);
          });
        }

        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
            child: Text(
              'Sugestões de Rotas Próximas',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );

        items.addAll(sortedPois.take(3).map((PoiResult poi) {
          final title = poi.name;
          final subtitle = poi.category.name;
          
          String? distanceText;
          if (referenceLocation != null) {
            const distanceCalculator = Distance();
            final meters = distanceCalculator.as(LengthUnit.Meter, referenceLocation, poi.point);
            if (meters < 1000) {
              distanceText = '${meters.toStringAsFixed(0)} m';
            } else {
              final km = meters / 1000.0;
              distanceText = '${km.toStringAsFixed(1)} km';
            }
          }

          return ListTile(
            leading: Icon(Icons.explore_outlined, color: primaryColor),
            title: Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: TextStyle(color: subtextColor)),
            trailing: distanceText != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      distanceText,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              controller.closeView(title);
              onSelect(poi.point, title);
            },
          );
        }));
      }

      if (items.isEmpty) {
        items.add(
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Digite para buscar locais e traçar rotas'),
          ),
        );
      }

      return items;
    }

    try {
      final suggestions = await ref.read(routingServiceProvider).searchAddress(controller.text);
      if (suggestions.isEmpty) {
        return [const ListTile(title: Text('Nenhum local encontrado.'))];
      }

      List<Map<String, dynamic>> sortedSuggestions = List.from(suggestions);
      final LatLng? referenceLocation = _lastKnownPosition;
      if (referenceLocation != null) {
        const distanceCalculator = Distance();
        sortedSuggestions.sort((a, b) {
          final latA = double.tryParse(a['lat']?.toString() ?? '') ?? 0.0;
          final lonA = double.tryParse(a['lon']?.toString() ?? '') ?? 0.0;
          final latB = double.tryParse(b['lat']?.toString() ?? '') ?? 0.0;
          final lonB = double.tryParse(b['lon']?.toString() ?? '') ?? 0.0;

          final distA = distanceCalculator.as(LengthUnit.Meter, referenceLocation, LatLng(latA, lonA));
          final distB = distanceCalculator.as(LengthUnit.Meter, referenceLocation, LatLng(latB, lonB));
          return distA.compareTo(distB);
        });
      }

      return sortedSuggestions.map((info) {
        final title = info['title']?.toString() ?? 'Local';
        final sub = info['subtitle']?.toString() ?? '';
        final lat = double.tryParse(info['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(info['lon']?.toString() ?? '') ?? 0.0;

        String? distanceText;
        if (referenceLocation != null) {
          const distanceCalculator = Distance();
          final meters = distanceCalculator.as(LengthUnit.Meter, referenceLocation, LatLng(lat, lon));
          if (meters < 1000) {
            distanceText = '${meters.toStringAsFixed(0)} m';
          } else {
            final km = meters / 1000.0;
            distanceText = '${km.toStringAsFixed(1)} km';
          }
        }

        return ListTile(
          leading: Icon(Icons.location_on_rounded, color: _primaryColor),
          title: Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
          subtitle: sub.isNotEmpty ? Text(sub, style: TextStyle(color: subtextColor)) : null,
          trailing: distanceText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    distanceText,
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
          onTap: () {
            ref.read(preferencesServiceProvider).addRecentSearch(title, sub, lat, lon);
            controller.closeView(title);
            onSelect(LatLng(lat, lon), title);
          },
        );
      }).toList();
    } catch (e) {
      return [ListTile(title: Text('Erro ao buscar: $e'))];
    }
  }

  void _swapOriginAndDestination() {
    setState(() {
      final tempPoint = _originPoint ?? _lastKnownPosition;
      _originPoint = _destinationPoint;
      _destinationPoint = tempPoint;

      final tempText = _originSearchController.text.isEmpty ? 'Minha localização atual' : _originSearchController.text;
      _originSearchController.text = _searchController.text.isEmpty ? 'Defina o destino' : _searchController.text;
      _searchController.text = tempText;
      _previewDistance = 0.0;
      _previewDuration = 0.0;
    });
    _updateRoutePreview();
  }

  Widget _buildOriginMarkerWidget() {
    const pinColor = Colors.blue;
    final surfaceColor = _isDark ? AppColors.surface : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 2,
          child: Container(
            width: 20,
            height: 10,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pinColor,
                shape: BoxShape.circle,
                border: Border.all(color: surfaceColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: surfaceColor,
                  size: 24,
                ),
              ),
            ),
            CustomPaint(
              size: const Size(10, 7),
              painter: _TrianglePainter(color: pinColor),
            ),
          ],
        ),
      ],
    );
  }
}

class AnimatedPoiMarker extends StatefulWidget {
  final Widget child;
  const AnimatedPoiMarker({super.key, required this.child});

  @override
  State<AnimatedPoiMarker> createState() => _AnimatedPoiMarkerState();
}

class _AnimatedPoiMarkerState extends State<AnimatedPoiMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class SafeCameraConstraint extends CameraConstraint {
  final CameraConstraint inner;
  const SafeCameraConstraint(this.inner);

  @override
  MapCamera? constrain(MapCamera camera) {
    if (!camera.center.latitude.isFinite || 
        !camera.center.longitude.isFinite || 
        !camera.zoom.isFinite) {
      return null;
    }
    try {
      final result = inner.constrain(camera);
      if (result != null && 
          (!result.center.latitude.isFinite || 
           !result.center.longitude.isFinite || 
           !result.zoom.isFinite)) {
        return null;
      }
      return result;
    } catch (e) {
      debugPrint('SafeCameraConstraint engoliu erro de projeção: $e');
      return null;
    }
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
