import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/app_localizations.dart';
import '../constants/home_colors.dart';
import '../widgets/fav_badge.dart';
import 'dart:ui';

const int tabHome      = 0;
const int tabChat      = 1;
const int tabMap       = 2;
const int tabFavorites = 3;
const int tabSettings  = 4;

class HomeBottomNav extends StatelessWidget {
  final int currentTab;
  final bool isVisible;
  final int totalUnreadChat;
  final int favCount;
  final double bottomPadding;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNav({
    super.key,
    required this.currentTab,
    required this.isVisible,
    required this.totalUnreadChat,
    required this.favCount,
    required this.bottomPadding,
    required this.onTabSelected,
  });

  static const double navHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor(int tab) =>
    currentTab == tab
        ? AppColors.primary
        : (isDark ? AppColors.grey400 : AppColors.grey600);

TextStyle labelStyle(int tab) => TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: currentTab == tab
          ? AppColors.primary
          : (isDark ? AppColors.grey400 : AppColors.grey600),
    );
    return AnimatedPositioned(
      duration: isVisible
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: isVisible ? 0 : -(navHeight + bottomPadding),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? HomeColors.navBg : Colors.white)
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? HomeColors.navBorder : const Color(0xFFEEEEEE),
                  width: 0.8,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
              ),
              child: SizedBox(
                height: navHeight,
                child: Row(
                  children: [
                    _NavItem(
                      icon:       Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label:      loc.get('home'),
                      isActive:   currentTab == tabHome,
                      onTap:      () => onTabSelected(tabHome),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(tabChat),
                       
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ChatBadgeIcon(
                              unreadCount: totalUnreadChat,
                              color: iconColor(tabChat),
                            ),
                            const SizedBox(height: 4),
                            Text(loc.get('chat'), style: labelStyle(tabChat)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(tabMap),
                        
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 24, color: iconColor(tabMap)),
                            const SizedBox(height: 4),
                            Text(
                              loc.get('map_title'),
                              style: labelStyle(tabMap).copyWith(fontSize: 9),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabSelected(tabFavorites),
                        
                       
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FavBadge(
                              count:  favCount,
                              active: currentTab == tabFavorites,
                            ),
                            const SizedBox(height: 4),
                            Text(loc.get('favorites'), style: labelStyle(tabFavorites)),
                          ],
                        ),
                      ),
                    ),
                    _NavItem(
                      icon:       Icons.settings_outlined,
                      
                      activeIcon: Icons.settings_rounded,
                      label:      loc.get('settings'),
                      isActive:   currentTab == tabSettings,
                      onTap:      () => onTabSelected(tabSettings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; 
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
         behavior: HitTestBehavior.opaque,  
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
  isActive ? activeIcon : icon,
  size: 24,
  color: isActive
      ? AppColors.primary
      : (isDark ? AppColors.grey400 : AppColors.grey600),
),
Text(
  label,
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: isActive
        ? AppColors.primary
        : (isDark ? AppColors.grey400 : AppColors.grey600),
  ),
),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
class _ChatBadgeIcon extends StatelessWidget {
  final int unreadCount;
  final Color color;

  const _ChatBadgeIcon({required this.unreadCount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 24, color: color),
        if (unreadCount > 0)
          Positioned(
            top: -5,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}