import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
import '../../../core/app_localizations.dart';
import '../../../core/theme_provider.dart';
import '../../../main.dart';

class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ThemeScope.of(context);
    final loc      = AppLocalizations.of(context);
    final current  = provider.mode;
    final _tp      = DDPalette.of(context);
    final isDark   = _tp.isDark;

    String currentIconPath() {
      switch (current) {
        case AppThemeMode.light:  return 'assets/icons/settings/ic_sun.png';
        case AppThemeMode.dark:   return 'assets/icons/settings/ic_moon.png';
        case AppThemeMode.system: return 'assets/icons/settings/ic_system_theme.png';
      }
    }

    String currentLabel() {
      switch (current) {
        case AppThemeMode.light:  return loc.get('theme_light');
        case AppThemeMode.dark:   return loc.get('theme_dark');
        case AppThemeMode.system: return loc.get('theme_system');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/settings/ic_theme.png',
            width: 36, height: 36, fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(loc.get('theme_mode'), style: AppTextStyles.bodyMedium),
          ),

          // ── Учурдагы режим ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                currentIconPath(),
                width: 16, height: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                currentLabel(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),

          // ── 3 точка баскычы (Тунук Меню менен) ──
          PopupMenuButton<AppThemeMode>(
            onSelected: (mode) => provider.setMode(mode),
            color: isDark
                ? Colors.black.withOpacity(0.65)
                : Colors.white.withOpacity(0.75),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.50),
              ),
            ),
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: _tp.subText,
            ),
            itemBuilder: (_) => [
              _buildItem(
                mode: AppThemeMode.light,
                iconPath: 'assets/icons/settings/ic_sun.png',
                label: loc.get('theme_light'),
                current: current,
                isDark: isDark,
              ),
              _buildItem(
                mode: AppThemeMode.dark,
                iconPath: 'assets/icons/settings/ic_moon.png',
                label: loc.get('theme_dark'),
                current: current,
                isDark: isDark,
              ),
              _buildItem(
                mode: AppThemeMode.system,
                iconPath: 'assets/icons/settings/ic_system_theme.png',
                label: loc.get('theme_system'),
                current: current,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<AppThemeMode> _buildItem({
    required AppThemeMode mode,
    required String iconPath,
    required String label,
    required AppThemeMode current,
    required bool isDark,
  }) {
    final isSelected = current == mode;
    final color = isSelected
        ? AppColors.primary
        : (isDark ? Colors.white70 : AppColors.black);

    return PopupMenuItem<AppThemeMode>(
      value: mode,
      child: Row(
        children: [
          Image.asset(iconPath, width: 18, height: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }
}
