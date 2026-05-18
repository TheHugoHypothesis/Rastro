import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class StatCard extends StatelessWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryLight;
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryLight,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
          boxShadow: isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryLight, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: subtextColor, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
