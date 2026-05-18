import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class LocationFab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;

  const LocationFab({
    super.key,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF13131A) : Colors.white,
          border: Border.all(color: isDark ? AppColors.primary.withOpacity(0.6) : AppColors.lightBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
        ),
        child: Icon(Icons.my_location_rounded, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 22),
      ),
    );
  }
}
