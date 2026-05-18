import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../../data/remote/poi_service.dart';

class PoiDetailsSheet extends StatelessWidget {
  final PoiResult poi;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color poiColor;
  final IconData poiIconData;
  final Function(LatLng) onAddressSelected;

  const PoiDetailsSheet({
    super.key,
    required this.poi,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.poiColor,
    required this.poiIconData,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.border : AppColors.lightBorder, 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          // Cabeçalho com ícone + nome
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: poiColor),
                child: Icon(poiIconData, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: poiColor.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                      child: Text(poi.category.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: poiColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botão Traçar Rota
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.purpleGradient : null,
                color: isDark ? null : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 14)]
                    : [],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAddressSelected(poi.point);
                },
                icon: const Icon(Icons.directions_bike_rounded, color: Colors.white),
                label: const Text('Traçar Rota até aqui',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showPoiDetailsSheet({
  required BuildContext context,
  required PoiResult poi,
  required bool isDark,
  required Color surfaceColor,
  required Color textColor,
  required Color poiColor,
  required IconData poiIconData,
  required Function(LatLng) onAddressSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => PoiDetailsSheet(
      poi: poi,
      isDark: isDark,
      surfaceColor: surfaceColor,
      textColor: textColor,
      poiColor: poiColor,
      poiIconData: poiIconData,
      onAddressSelected: onAddressSelected,
    ),
  );
}

class CoordinateDetailsSheet extends StatelessWidget {
  final LatLng point;
  final Future<String> addressFuture;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final Function(LatLng) onAddressSelected;

  const CoordinateDetailsSheet({
    super.key,
    required this.point,
    required this.addressFuture,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.border : AppColors.lightBorder, 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          // Cabeçalho com ícone de pin + nome/endereço
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Local Marcado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black54)),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: addressFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Text('Coordenadas Marcadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor));
                        }
                        return Text(
                          snapshot.data!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botão Traçar Rota
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.purpleGradient : null,
                color: isDark ? null : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 14)]
                    : [],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onAddressSelected(point);
                },
                icon: const Icon(Icons.directions_bike_rounded, color: Colors.white),
                label: const Text('Traçar Rota até aqui',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCoordinateDetailsSheet({
  required BuildContext context,
  required LatLng point,
  required Future<String> addressFuture,
  required bool isDark,
  required Color surfaceColor,
  required Color textColor,
  required Color accentColor,
  required Function(LatLng) onAddressSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => CoordinateDetailsSheet(
      point: point,
      addressFuture: addressFuture,
      isDark: isDark,
      surfaceColor: surfaceColor,
      textColor: textColor,
      accentColor: accentColor,
      onAddressSelected: onAddressSelected,
    ),
  );
}

