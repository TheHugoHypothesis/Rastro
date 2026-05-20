import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/bike_type.dart';
import '../../../domain/models/route_preference.dart';
import '../../../domain/models/safety_evaluation.dart';
import '../../providers/app_state_provider.dart';
import '../../../core/services/haptic_service.dart';

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
  final List<LatLng>? routePoints;
  final List<String>? routeStreetNames;

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
    this.routePoints,
    this.routeStreetNames,
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
    final safetyEvaluations = ref.watch(safetyEvaluationsProvider);
    final routePoints = widget.routePoints;
    
    double avgSafety = 0.0;
    int matchedCount = 0;
    bool hasLowSafety = false;

    if (routePoints != null && routePoints.isNotEmpty) {
      const distanceCalc = Distance();
      final Set<String> counted = {};
      double safetySum = 0.0;

      // 1. Match por nome da rua para a rua inteira
      for (final eval in safetyEvaluations) {
        final key = '${eval.segmentId}_${eval.timestamp}';
        if (counted.contains(key)) continue;

        if (_isStreetNameMatch(eval.segmentId, widget.routeStreetNames)) {
          counted.add(key);
          safetySum += eval.safetyScore;
          matchedCount++;
        }
      }

      // 2. Match por proximidade geográfica (raio ampliado para 250 metros)
      for (final pt in routePoints) {
        for (final eval in safetyEvaluations) {
          final key = '${eval.segmentId}_${eval.timestamp}';
          if (counted.contains(key)) continue;

          final meters = distanceCalc.as(LengthUnit.Meter, pt, eval.point);
          if (meters <= 250.0) {
            counted.add(key);
            safetySum += eval.safetyScore;
            matchedCount++;
          }
        }
      }

      if (matchedCount > 0) {
        avgSafety = safetySum / matchedCount;
        hasLowSafety = avgSafety < 3.0;
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final maxPanelHeight = screenHeight - statusBarHeight - 16;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      constraints: BoxConstraints(
        maxHeight: widget.isExpanded ? maxPanelHeight : 300,
      ),
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
              onTap: () {
                HapticService().selectionClick();
                widget.onExpansionChanged(!widget.isExpanded);
              },
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
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: matchedCount > 0
                                  ? (hasLowSafety ? Colors.redAccent : Colors.greenAccent)
                                  : (widget.isDark ? AppColors.border : AppColors.lightBorder),
                              width: matchedCount > 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                matchedCount > 0
                                    ? (hasLowSafety ? Icons.warning_amber_rounded : Icons.verified_user_rounded)
                                    : Icons.shield_outlined,
                                size: 14,
                                color: matchedCount > 0
                                    ? (hasLowSafety ? Colors.redAccent : Colors.greenAccent)
                                    : widget.subtextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                matchedCount > 0
                                    ? '${avgSafety.toStringAsFixed(1)}★'
                                    : 'Sem relatos P2P',
                                style: TextStyle(
                                  color: matchedCount > 0
                                      ? (hasLowSafety ? Colors.redAccent : (widget.isDark ? Colors.white : Colors.black87))
                                      : widget.subtextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!widget.isExpanded) ...[  
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticService().selectionClick();
                        widget.onExpansionChanged(true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: matchedCount > 0 
                              ? widget.primaryColor.withValues(alpha: 0.15) 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: matchedCount > 0 
                                ? widget.primaryColor.withValues(alpha: 0.3) 
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              matchedCount > 0 ? Icons.verified_user_rounded : Icons.tune_rounded, 
                              size: 14, 
                              color: matchedCount > 0 ? widget.primaryColor : widget.subtextColor
                            ),
                            const SizedBox(width: 6),
                            Text(
                              matchedCount > 0 
                                  ? 'Esta rota tem $matchedCount avaliações! Toque para ver detalhes'
                                  : 'Opções de rota (deslize para cima)',
                              style: TextStyle(
                                color: matchedCount > 0 ? widget.primaryColor : widget.subtextColor, 
                                fontSize: matchedCount > 0 ? 11.5 : 12, 
                                fontWeight: FontWeight.w800
                              ),
                            ),
                            if (matchedCount > 0) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: widget.primaryColor),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (widget.isExpanded)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            onTap: () {
                              HapticService().selectionClick();
                              ref.read(bikeTypeProvider.notifier).updateBikeType(type);
                            },
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
                            onTap: () {
                              HapticService().selectionClick();
                              ref.read(routeStrategyProvider.notifier).updateStrategy(strategy);
                            },
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
                                      : (strategy == RouteStrategy.seguranca
                                          ? (widget.isDark ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5))
                                          : (widget.isDark ? AppColors.border : AppColors.lightBorder)),
                                  width: (strategy == RouteStrategy.seguranca || isSelected) ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (strategy == RouteStrategy.seguranca) ...[
                                    Icon(
                                      Icons.verified_user_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : (widget.isDark ? Colors.greenAccent : Colors.green),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    strategy.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : (strategy == RouteStrategy.seguranca
                                              ? (widget.isDark ? Colors.greenAccent : Colors.green)
                                              : widget.subtextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (selectedStrategy == RouteStrategy.seguranca) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: widget.isDark ? Colors.greenAccent : Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'Rotas Seguras P2P: Otimizado para ciclovias, iluminação e baixo tráfego.',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.greenAccent : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    if (widget.previewDistance > 0 && widget.routePoints != null && widget.routePoints!.isNotEmpty) ...[
                      _buildRouteReputationCard(),
                      const SizedBox(height: 12),
                    ],

                    // CTA button
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPad + 16, top: 4),
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
                              HapticService().selectionClick();
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
            ),
        ],
        ),
      ),
    );
  }

  bool _isStreetNameMatch(String segmentId, List<String>? routeStreetNames) {
    if (routeStreetNames == null || routeStreetNames.isEmpty || segmentId.isEmpty) return false;
    
    final normalizedSeg = _normalize(segmentId);
    
    for (final street in routeStreetNames) {
      if (street.isEmpty) continue;
      final normalizedStreet = _normalize(street);
      if (normalizedSeg.contains(normalizedStreet) || normalizedStreet.contains(normalizedSeg)) {
        return true;
      }
    }
    return false;
  }

  String _normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ç]'), 'c')
        .trim();
  }

  Widget _buildRouteReputationCard() {
    final safetyEvaluations = ref.watch(safetyEvaluationsProvider);
    final points = widget.routePoints!;
    const distanceCalc = Distance();
    
    final matchedEvaluations = <SafetyEvaluation>[];
    final Set<String> counted = {};

    // 1. Match por nome de rua (integração de rua inteira)
    for (final eval in safetyEvaluations) {
      final key = '${eval.segmentId}_${eval.timestamp}';
      if (counted.contains(key)) continue;

      if (_isStreetNameMatch(eval.segmentId, widget.routeStreetNames)) {
        counted.add(key);
        matchedEvaluations.add(eval);
      }
    }

    // 2. Match por proximidade geográfica (com raio ampliado de 250 metros)
    for (final pt in points) {
      for (final eval in safetyEvaluations) {
        final key = '${eval.segmentId}_${eval.timestamp}';
        if (counted.contains(key)) continue;

        final meters = distanceCalc.as(LengthUnit.Meter, pt, eval.point);
        if (meters <= 250.0) {
          counted.add(key);
          matchedEvaluations.add(eval);
        }
      }
    }

    if (matchedEvaluations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.isDark ? AppColors.border : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: widget.subtextColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nenhuma avaliação colaborativa (P2P) registrada para este trecho da rota.',
                style: TextStyle(color: widget.subtextColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    double avgSafety = 0.0;
    double avgLighting = 0.0;
    double avgTraffic = 0.0;
    double avgAccident = 0.0;
    int cyclewayCount = 0;

    for (final eval in matchedEvaluations) {
      avgSafety += eval.safetyScore;
      avgLighting += eval.lightingScore;
      avgTraffic += eval.trafficScore;
      avgAccident += eval.accidentScore;
      if (eval.hasCycleway) cyclewayCount++;
    }

    avgSafety /= matchedEvaluations.length;
    avgLighting /= matchedEvaluations.length;
    avgTraffic /= matchedEvaluations.length;
    avgAccident /= matchedEvaluations.length;
    double cyclewayPct = (cyclewayCount / matchedEvaluations.length) * 100;

    final hasLowSafety = avgSafety < 3.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLowSafety ? Colors.redAccent : (widget.isDark ? AppColors.border : AppColors.lightBorder),
          width: hasLowSafety ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasLowSafety ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: hasLowSafety ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ficha de Reputação da Rota (P2P)',
                    style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${matchedEvaluations.length} avaliações',
                  style: TextStyle(color: widget.primaryColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRepItem('Segurança', '${avgSafety.toStringAsFixed(1)}★', Colors.amber),
              _buildRepItem('Iluminação', '${avgLighting.toStringAsFixed(1)}★', Colors.amber),
              _buildRepItem('Trânsito', '${avgTraffic.toStringAsFixed(1)}/5', widget.textColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildRepItem('Risco Crime', '${avgAccident.toStringAsFixed(1)}/5', Colors.redAccent),
              _buildRepItem('Ciclovia', '${cyclewayPct.toStringAsFixed(0)}%', Colors.greenAccent),
              _buildRepItem('Identidade WoT', 'Assinada', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: widget.isDark ? AppColors.border : AppColors.lightBorder, height: 1),
          const SizedBox(height: 12),
          Text(
            'Avaliações individuais da comunidade:',
            style: TextStyle(color: widget.textColor, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: matchedEvaluations.length,
                itemBuilder: (context, index) {
                  final eval = matchedEvaluations[index];
                  final keyAbbrev = eval.creatorPublicKey.length > 8
                      ? '${eval.creatorPublicKey.substring(0, 4)}...${eval.creatorPublicKey.substring(eval.creatorPublicKey.length - 4)}'
                      : eval.creatorPublicKey;
                  final dateStr = DateTime.fromMillisecondsSinceEpoch(eval.timestamp).toLocal().toString().substring(0, 16);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10, right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 13, color: widget.isDark ? Colors.greenAccent : Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  eval.segmentId.length > 24 ? '${eval.segmentId.substring(0, 21)}...' : eval.segmentId,
                                  style: TextStyle(
                                    color: widget.textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(color: widget.subtextColor, fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            _buildMiniAttr(Icons.verified_user_rounded, 'Segurança: ${eval.safetyScore}★'),
                            _buildMiniAttr(Icons.lightbulb_outline_rounded, 'Iluminação: ${eval.lightingScore}★'),
                            _buildMiniAttr(Icons.directions_bike_rounded, 'Ciclovia: ${eval.hasCycleway ? "Sim" : "Não"}'),
                            _buildMiniAttr(Icons.traffic_rounded, 'Tráfego: ${eval.trafficScore}/5'),
                            _buildMiniAttr(Icons.warning_amber_rounded, 'Risco: ${eval.accidentScore}/5'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 10, color: Colors.cyanAccent),
                            const SizedBox(width: 4),
                            Text(
                              'Assinatura WoT: $keyAbbrev (Período: ${eval.safeTimePeriod})',
                              style: TextStyle(
                                color: widget.isDark ? Colors.cyanAccent : Colors.cyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAttr(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: widget.subtextColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: widget.textColor, fontSize: 9.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildRepItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: widget.subtextColor, fontSize: 9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
