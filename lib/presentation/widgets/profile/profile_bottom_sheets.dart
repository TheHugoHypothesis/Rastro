import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/bike_type.dart';
import '../../../domain/models/route_preference.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_profile_provider.dart';

void showBikeTypeSelector(BuildContext context, WidgetRef ref, BikeType current,
    bool isDark, Color surfaceColor, Color textColor, Color subtextColor, Color primaryLight) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.border : AppColors.lightBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Escolher Veículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 8),
          ...BikeType.values.map((type) => ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: type == current ? (isDark ? AppColors.purpleGradient : null) : null,
                color: type == current ? (isDark ? null : AppColors.lightPrimary) : (isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated),
              ),
              child: Icon(type.icon, color: type == current ? Colors.white : subtextColor, size: 20),
            ),
            title: Text(type.label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
            trailing: type == current ? Icon(Icons.check_circle_rounded, color: primaryLight) : null,
            onTap: () { ref.read(bikeTypeProvider.notifier).updateBikeType(type); Navigator.pop(context); },
          )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void showRouteStrategySelector(BuildContext context, WidgetRef ref, RouteStrategy current,
    bool isDark, Color surfaceColor, Color textColor, Color subtextColor, Color primaryLight) {
  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.border : AppColors.lightBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Escolher Estratégia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 8),
          ...RouteStrategy.values.map((strategy) => ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: strategy == current ? (isDark ? AppColors.purpleGradient : null) : null,
                color: strategy == current ? (isDark ? null : AppColors.lightPrimary) : (isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated),
              ),
              child: Icon(Icons.alt_route_rounded, color: strategy == current ? Colors.white : subtextColor, size: 20),
            ),
            title: Text(strategy.label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
            trailing: strategy == current ? Icon(Icons.check_circle_rounded, color: primaryLight) : null,
            onTap: () { ref.read(routeStrategyProvider.notifier).updateStrategy(strategy); Navigator.pop(context); },
          )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

void showEditProfileSheet(BuildContext context, WidgetRef ref, dynamic profile,
    bool isDark, Color surfaceColor, Color textColor, Color subtextColor, Color borderColor, Color primaryColor, Color primaryLight) {
  final nameCtrl = TextEditingController(text: profile.name);
  final ageCtrl = TextEditingController(text: profile.age.toString());

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.border : AppColors.lightBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Editar Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 20),
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Nome',
              labelStyle: TextStyle(color: subtextColor),
              prefixIcon: Icon(Icons.person_rounded, color: isDark ? AppColors.primaryLight : primaryColor),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.primaryLight : primaryColor, width: 2)),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Idade',
              labelStyle: TextStyle(color: subtextColor),
              prefixIcon: Icon(Icons.cake_rounded, color: isDark ? AppColors.primaryLight : primaryColor),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.primaryLight : primaryColor, width: 2)),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : AppColors.lightSurfaceElevated,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.purpleGradient : null,
                color: isDark ? null : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDark ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)] : [],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  final newAge = int.tryParse(ageCtrl.text) ?? profile.age;
                  ref.read(userProfileProvider.notifier).updateProfile(profile.copyWith(name: nameCtrl.text, age: newAge));
                  Navigator.pop(ctx);
                },
                child: const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    ),
  );
}
