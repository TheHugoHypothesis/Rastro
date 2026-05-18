import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/user_profile.dart';
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
              GestureDetector(
                onTap: () => _showPhotoPickerSheet(context, ref, userProfile),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDark ? AppColors.purpleGradient : null,
                        color: isDark ? null : AppColors.lightPrimary,
                        border: Border.all(
                          color: isDark ? AppColors.primaryLight : Colors.white,
                          width: 2,
                        ),
                        boxShadow: isDark
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4)]
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16)],
                      ),
                      child: ClipOval(
                        child: userProfile.photoPath != null
                            ? Image.file(
                                File(userProfile.photoPath!),
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (c, e, s) => Container(
                                  color: isDark ? const Color(0xFF1F1135) : AppColors.lightPrimary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.primary : AppColors.lightPrimary,
                          border: Border.all(color: isDark ? AppColors.background : Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
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

  void _showPhotoPickerSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.border : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto de Perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
                ),
                child: Icon(Icons.photo_library_rounded, color: isDark ? AppColors.primaryLight : AppColors.lightPrimary),
              ),
              title: Text('Escolher da Galeria', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (picked != null) {
                  ref.read(userProfileProvider.notifier).updateProfile(
                    profile.copyWith(photoPath: picked.path),
                  );
                }
              },
            ),
            if (profile.photoPath != null)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
                title: const Text('Remover Foto Atual', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(userProfileProvider.notifier).updateProfile(
                    profile.copyWith(removePhoto: true),
                  );
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
