import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../screens/profile_screen.dart';

class AvatarButton extends StatelessWidget {
  final bool isDark;

  const AvatarButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDark ? AppColors.purpleGradient : null,
          color: isDark ? null : AppColors.lightPrimary,
          boxShadow: isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)] : [],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
