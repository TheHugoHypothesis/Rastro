import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class PreferenceCard extends StatelessWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color primaryColor;
  final Color primaryLight;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const PreferenceCard({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.primaryColor,
    required this.primaryLight,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.lightSurfaceElevated,
              ),
              child: Icon(icon, color: primaryLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subtextColor, size: 20),
          ],
        ),
      ),
    );
  }
}
