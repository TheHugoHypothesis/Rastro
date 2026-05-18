import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final bool isDark;
  final Color bgColor;
  final Color textColor;
  final Color subtextColor;

  const ProfileHeader({
    super.key,
    required this.isDark,
    required this.bgColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: bgColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Toggle tema noturno/claro
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.primary.withValues(alpha: 0.5) : AppColors.lightBorder),
                boxShadow: isDark
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8)]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: isDark ? AppColors.primaryLight : AppColors.lightPrimary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isDark ? 'Noturno' : 'Claro',
                    style: TextStyle(
                      color: isDark ? AppColors.primaryLight : AppColors.lightPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A0A2E), Color(0xFF0D0D0F)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lightSurface, AppColors.lightBackground],
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDark ? AppColors.purpleGradient : null,
                  color: isDark ? null : AppColors.lightPrimary,
                  boxShadow: isDark
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4)]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16)],
                ),
                child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(userProfile.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('${userProfile.age} anos • Ciclista Urbano',
                  style: TextStyle(fontSize: 13, color: subtextColor, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
