import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../providers/app_state_provider.dart';
import '../../../data/remote/poi_service.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color routeColor;
  final Function(LatLng) onAddressSelected;
  final SearchController searchController;
  final LatLng? userLocation;

  const SearchBarWidget({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.routeColor,
    required this.onAddressSelected,
    required this.searchController,
    this.userLocation,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  Timer? _debounce;
  Completer<Iterable<Widget>>? _completer;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subtextColor = widget.isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return SearchAnchor(
      searchController: widget.searchController,
      builder: (context, controller) {
        return GestureDetector(
          onTap: () => controller.openView(),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.surfaceColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.isDark ? AppColors.border : AppColors.lightBorder),
              boxShadow: widget.isDark
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 1)]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.searchController.text.isEmpty ? 'Para onde?' : widget.searchController.text,
                    style: TextStyle(
                      color: widget.searchController.text.isEmpty ? subtextColor : textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isSearching)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.routeColor)),
              ],
            ),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        final primaryColor = widget.isDark ? AppColors.primaryLight : AppColors.primary;
        final textColor = widget.isDark ? Colors.white : Colors.black87;
        final subtextColor = widget.isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

        if (controller.text.isEmpty) {
          final history = ref.read(preferencesServiceProvider).loadSearchHistory();
          final pois = ref.read(preferencesServiceProvider).loadPois();
          final List<Widget> items = [];

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
                title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: subtextColor)) : null,
                onTap: () {
                  controller.closeView(title);
                  widget.onAddressSelected(LatLng(lat, lon));
                },
              );
            }));
          }

          if (pois.isNotEmpty) {
            final List<PoiResult> sortedPois = List.from(pois);
            if (widget.userLocation != null) {
              const distanceCalculator = Distance();
              sortedPois.sort((a, b) {
                final distA = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, a.point);
                final distB = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, b.point);
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
              if (widget.userLocation != null) {
                const distanceCalculator = Distance();
                final meters = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, poi.point);
                if (meters < 1000) {
                  distanceText = '${meters.toStringAsFixed(0)} m';
                } else {
                  final km = meters / 1000.0;
                  distanceText = '${km.toStringAsFixed(1)} km';
                }
              }

              return ListTile(
                leading: Icon(Icons.explore_outlined, color: primaryColor),
                title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
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
                  widget.onAddressSelected(poi.point);
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

        if (_debounce?.isActive ?? false) _debounce!.cancel();
        if (_completer != null && !_completer!.isCompleted) _completer!.complete(const Iterable<Widget>.empty());
        _completer = Completer<Iterable<Widget>>();
        _debounce = Timer(const Duration(milliseconds: 800), () async {
          if (controller.text.isEmpty) { if (!_completer!.isCompleted) _completer!.complete(const Iterable<Widget>.empty()); return; }
          if (mounted) setState(() => _isSearching = true);
          try {
            final suggestions = await ref.read(routingServiceProvider).searchAddress(controller.text);
            if (mounted) setState(() => _isSearching = false);
            if (suggestions.isEmpty) {
              if (!_completer!.isCompleted) _completer!.complete([const ListTile(title: Text('Nenhum local encontrado.'))]);
              return;
            }

            List<Map<String, dynamic>> sortedSuggestions = List.from(suggestions);
            if (widget.userLocation != null) {
              const distanceCalculator = Distance();
              sortedSuggestions.sort((a, b) {
                final latA = double.tryParse(a['lat']?.toString() ?? '') ?? 0.0;
                final lonA = double.tryParse(a['lon']?.toString() ?? '') ?? 0.0;
                final latB = double.tryParse(b['lat']?.toString() ?? '') ?? 0.0;
                final lonB = double.tryParse(b['lon']?.toString() ?? '') ?? 0.0;

                final distA = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, LatLng(latA, lonA));
                final distB = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, LatLng(latB, lonB));
                return distA.compareTo(distB);
              });
            }

            final widgets = sortedSuggestions.map((info) {
              final addressObj = info['address'] as Map<String, dynamic>? ?? {};
              final title = info['name']?.toString() ?? addressObj['road']?.toString() ?? 'Local';
              final city = addressObj['city'] ?? addressObj['town'] ?? addressObj['municipality'];
              final state = addressObj['state'];
              final sub = [city, state].where((e) => e != null).join(', ');
              final lat = double.tryParse(info['lat']?.toString() ?? '') ?? 0.0;
              final lon = double.tryParse(info['lon']?.toString() ?? '') ?? 0.0;

              String? distanceText;
              if (widget.userLocation != null) {
                const distanceCalculator = Distance();
                final meters = distanceCalculator.as(LengthUnit.Meter, widget.userLocation!, LatLng(lat, lon));
                if (meters < 1000) {
                  distanceText = '${meters.toStringAsFixed(0)} m';
                } else {
                  final km = meters / 1000.0;
                  distanceText = '${km.toStringAsFixed(1)} km';
                }
              }

              return ListTile(
                leading: Icon(Icons.location_on_rounded, color: widget.routeColor),
                title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                subtitle: sub.isNotEmpty ? Text(sub, style: TextStyle(color: subtextColor)) : null,
                trailing: distanceText != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.routeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          distanceText,
                          style: TextStyle(
                            color: widget.routeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  ref.read(preferencesServiceProvider).addRecentSearch(title, sub, lat, lon);
                  controller.closeView(title);
                  widget.onAddressSelected(LatLng(lat, lon));
                },
              );
            });
            if (!_completer!.isCompleted) _completer!.complete(widgets.toList());
          } catch (e) {
            if (mounted) setState(() => _isSearching = false);
            if (!_completer!.isCompleted) _completer!.complete([ListTile(title: Text('Erro: $e'))]);
          }
        });
        return _completer!.future;
      },
    );
  }
}
