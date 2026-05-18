import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../providers/theme_provider.dart';

class AppearanceSection extends ConsumerWidget {
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final Color primaryLight;

  const AppearanceSection({
    super.key,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    required this.primaryLight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.lightSurfaceElevated,
            ),
            child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: primaryLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo de visualização', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(isDark ? 'Noturno (Roxo & Preto)' : 'Claro (Branco & Preto)',
                    style: TextStyle(color: subtextColor, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: isDark ? AppColors.purpleGradient : null,
                color: isDark ? null : AppColors.lightBorder,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
