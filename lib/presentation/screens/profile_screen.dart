import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/theme/colors.dart';

// Profile Widgets
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/stat_card.dart';
import '../widgets/profile/preference_card.dart';
import '../widgets/profile/appearance_section.dart';
import '../widgets/profile/profile_bottom_sheets.dart';

import '../widgets/profile/activity_report_widget.dart';
import '../../domain/models/activity_record.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final bikeType = ref.watch(bikeTypeProvider);
    final routeStrategy = ref.watch(routeStrategyProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final Color bgColor = isDark ? AppColors.background : AppColors.lightBackground;
    final Color surfaceColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final Color textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final Color subtextColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final Color borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final Color primaryColor = isDark ? AppColors.primary : AppColors.lightPrimary;
    final Color primaryLight = isDark ? AppColors.primaryLight : AppColors.lightPrimary;

    final prefService = ref.watch(preferencesServiceProvider);
    final List<ActivityRecord> records = prefService.loadActivityRecords();

    double totalDistanceMeters = 0.0;
    double totalDurationSeconds = 0.0;
    double totalCalories = 0.0;
    for (var r in records) {
      totalDistanceMeters += r.distanceMeters;
      totalDurationSeconds += r.durationSeconds;
      totalCalories += r.calories;
    }

    final totalHours = totalDurationSeconds / 3600;
    final totalHoursStr = totalHours < 1.0 
        ? '${(totalDurationSeconds / 60).toStringAsFixed(0)}m' 
        : '${totalHours.toStringAsFixed(1)}h';

    final odometerStr = '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    final caloriesStr = totalCalories.toStringAsFixed(0);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          ProfileHeader(
            isDark: isDark,
            bgColor: bgColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção: Estatísticas
                  Row(
                    children: [
                      StatCard(
                        isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                        subtextColor: subtextColor, primaryLight: primaryLight,
                        icon: Icons.timer_rounded, value: totalHoursStr, label: 'Tempo total',
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                        subtextColor: subtextColor, primaryLight: primaryLight,
                        icon: Icons.map_rounded, value: odometerStr, label: 'Odômetro',
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                        subtextColor: subtextColor, primaryLight: primaryLight,
                        icon: Icons.local_fire_department_rounded, value: caloriesStr, label: 'Cal. queimas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Seção: Relatório de Atividades (RF013)
                  ActivityReportWidget(
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    primaryColor: primaryLight,
                  ),
                  const SizedBox(height: 24),

                  // Seção: Preferências
                  Text('Preferências', style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),

                  PreferenceCard(
                    isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                    subtextColor: subtextColor, borderColor: borderColor,
                    primaryColor: primaryColor, primaryLight: primaryLight,
                    icon: Icons.pedal_bike_rounded, title: 'Veículo atual', value: bikeType.label,
                    onTap: () => showBikeTypeSelector(context, ref, bikeType, isDark, surfaceColor, textColor, subtextColor, primaryLight),
                  ),
                  const SizedBox(height: 10),
                  PreferenceCard(
                    isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                    subtextColor: subtextColor, borderColor: borderColor,
                    primaryColor: primaryColor, primaryLight: primaryLight,
                    icon: Icons.alt_route_rounded, title: 'Estratégia padrão', value: routeStrategy.label,
                    onTap: () => showRouteStrategySelector(context, ref, routeStrategy, isDark, surfaceColor, textColor, subtextColor, primaryLight),
                  ),
                  const SizedBox(height: 24),

                  // Seção: Modo de visualização
                  Text('Aparência', style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),

                  AppearanceSection(
                    isDark: isDark, surfaceColor: surfaceColor, textColor: textColor,
                    subtextColor: subtextColor, borderColor: borderColor, primaryLight: primaryLight,
                  ),
                  const SizedBox(height: 24),

                  // Botão editar perfil
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isDark ? AppColors.purpleGradient : null,
                        color: isDark ? null : AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16)]
                            : [],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => showEditProfileSheet(context, ref, userProfile, isDark, surfaceColor, textColor, subtextColor, borderColor, primaryColor, primaryLight),
                        icon: const Icon(Icons.edit_rounded, color: Colors.white),
                        label: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
