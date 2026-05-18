import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/profile_screen.dart';

class AvatarButton extends ConsumerWidget {
  final bool isDark;

  const AvatarButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isDark ? AppColors.purpleGradient : null,
          color: isDark ? null : AppColors.lightPrimary,
          border: Border.all(
            color: isDark ? AppColors.primaryLight : Colors.white,
            width: 1.5,
          ),
          boxShadow: isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)] : [],
        ),
        child: ClipOval(
          child: userProfile.photoPath != null
              ? Image.file(
                  File(userProfile.photoPath!),
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                  errorBuilder: (c, e, s) => Container(
                    color: isDark ? const Color(0xFF1F1135) : AppColors.lightPrimary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                  ),
                )
              : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
