import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/bike_type.dart';
import '../../../domain/models/route_preference.dart';
import '../../providers/app_state_provider.dart';

class CollapsiblePanel extends ConsumerStatefulWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textColor;
  final Color subtextColor;
  final LatLng? destinationPoint;
  final Future<void> Function() onTraceRoute;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final double previewDistance;
  final double previewDuration;

  const CollapsiblePanel({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryColor,
    required this.textColor,
    required this.subtextColor,
    required this.destinationPoint,
    required this.onTraceRoute,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.previewDistance,
    required this.previewDuration,
  });

  @override
  ConsumerState<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends ConsumerState<CollapsiblePanel> {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final selectedBike = ref.watch(bikeTypeProvider);
    final selectedStrategy = ref.watch(routeStrategyProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, -4))],
      ),
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
            widget.onExpansionChanged(false);
          }
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            widget.onExpansionChanged(true);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle + toggle
            GestureDetector(
              onTap: () => widget.onExpansionChanged(!widget.isExpanded),
              behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: widget.isDark ? AppColors.border : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (widget.previewDistance > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: widget.isDark ? AppColors.border : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.map_rounded, size: 14, color: widget.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                '${(widget.previewDistance / 1000).toStringAsFixed(1)} km',
                                style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: widget.isDark ? AppColors.border : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_rounded, size: 14, color: widget.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                '${(widget.previewDuration / 60).toStringAsFixed(0)} min',
                                style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!widget.isExpanded) ...[  
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: widget.subtextColor),
                        const SizedBox(width: 4),
                        Text('Opções de rota', style: TextStyle(color: widget.subtextColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (widget.isExpanded) ...[  
            // Bike type
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 6),
              child: Align(
                alignment: Alignment.center,
                child: Text('Tipo de bicicleta', style: TextStyle(color: widget.subtextColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: BikeType.values.map((type) {
                  final isSelected = selectedBike == type;
                  return GestureDetector(
                    onTap: () => ref.read(bikeTypeProvider.notifier).updateBikeType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected && widget.isDark ? AppColors.purpleGradient : null,
                        color: isSelected
                            ? (widget.isDark ? null : widget.primaryColor)
                            : (widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (widget.isDark ? AppColors.primaryLight : widget.primaryColor)
                              : (widget.isDark ? AppColors.border : AppColors.lightBorder),
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon, size: 26, color: isSelected ? Colors.white : widget.subtextColor),
                          const SizedBox(height: 4),
                          Text(type.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : widget.subtextColor)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Strategy chips
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 6),
              child: Align(
                alignment: Alignment.center,
                child: Text('Estratégia', style: TextStyle(color: widget.subtextColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: RouteStrategy.values.map((strategy) {
                  final isSelected = selectedStrategy == strategy;
                  return GestureDetector(
                    onTap: () => ref.read(routeStrategyProvider.notifier).updateStrategy(strategy),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: isSelected && widget.isDark ? AppColors.purpleGradient : null,
                        color: isSelected
                            ? (widget.isDark ? null : widget.primaryColor)
                            : (widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (widget.isDark ? AppColors.primaryLight : widget.primaryColor)
                              : (widget.isDark ? AppColors.border : AppColors.lightBorder),
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        strategy.label,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : widget.subtextColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // CTA button
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPad + 16, top: widget.isExpanded ? 0 : 4),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: widget.isDark ? AppColors.purpleGlowGradient : null,
                  color: widget.isDark ? null : widget.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.isDark ? AppColors.primaryLight : widget.primaryColor,
                    width: 0,
                  ),
                  boxShadow: widget.isDark
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 1)]
                      : [],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () async {
                    await widget.onTraceRoute();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Traçar Rota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
