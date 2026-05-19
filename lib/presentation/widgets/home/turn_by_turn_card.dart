import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/route_instruction.dart';

class TurnByTurnCard extends StatelessWidget {
  final bool isDark;
  final RouteInstruction step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onSpeak;
  final VoidCallback onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isTtsEnabled;
  final VoidCallback onToggleTts;

  const TurnByTurnCard({
    super.key,
    required this.isDark,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onSpeak,
    required this.onClose,
    required this.isTtsEnabled,
    required this.onToggleTts,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? const Color(0xFF1C1C26) : Colors.white;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final subtextColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.primary.withValues(alpha: 0.4) : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(color: isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.12), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.purpleGradient : null,
              color: isDark ? null : primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.turn_right_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(step.instruction, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white))),
                IconButton(
                  icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 22),
                  onPressed: onSpeak,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                IconButton(
                  icon: Icon(
                    isTtsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: isTtsEnabled ? Colors.white : Colors.white54,
                    size: 22,
                  ),
                  onPressed: onToggleTts,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                  onPressed: onClose,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten_rounded, size: 16, color: subtextColor),
                    const SizedBox(width: 6),
                    Text('${step.distance.toStringAsFixed(0)} m', style: TextStyle(color: subtextColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    
                    // Controles de Navegação de Rota Manuais (RF014)
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, size: 24, color: stepIndex > 0 ? subtextColor : subtextColor.withValues(alpha: 0.3)),
                      onPressed: stepIndex > 0 ? onPrevious : null,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    Text(
                      '${stepIndex + 1} / $totalSteps',
                      style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, size: 24, color: stepIndex < totalSteps - 1 ? subtextColor : subtextColor.withValues(alpha: 0.3)),
                      onPressed: stepIndex < totalSteps - 1 ? onNext : null,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

