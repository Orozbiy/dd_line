// ignore_for_file: unnecessary_import

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/dd_design.dart';
import '../../../core/app_localizations.dart';
import '../widgets/fav_badge.dart';

const int tabHome      = 0;
const int tabChat      = 1;
const int tabMap       = 2;
const int tabFavorites = 3;
const int tabSettings  = 4;
const int _tabCount    = 5;

/// Төмөнкү 5 баскыч — WhatsApp сыяктуу сүзүп жүрүүчү айнек капсула.
///
/// ✦ Капсула экрандын четинен 20px, астынан (safe-area − 14px) бийиктикте.
/// ✦ Активдүү баскычтын астында мандарин (80% тунук) айнек "тамчы" —
///   тандоо өзгөргөндө пружина менен жылат жана ылдамдыкка жараша созулат.
/// ✦ Басканда ошол замат (кармабай) башка баскычтарга сүрүүгө болот —
///   сүрүп жатканда экран алмашпайт, колду көтөргөндө манжа турган
///   баскычтын экраны ачылат.
class HomeBottomNav extends StatefulWidget {
  final int currentTab;
  final bool isVisible;
  final int totalUnreadChat;
  final int favCount;
  final double bottomPadding;
  final ValueChanged<int> onTabSelected;

  /// Ар бир чыныгы тийүүдө (ошол эле табга кайра басканда да) чакырылат.
  final ValueChanged<int>? onTabTapped;

  const HomeBottomNav({
    super.key,
    required this.currentTab,
    required this.isVisible,
    required this.totalUnreadChat,
    required this.favCount,
    required this.bottomPadding,
    required this.onTabSelected,
    this.onTabTapped,
  });

  /// Капсуланын бийиктиги.
  static const double navHeight = 62.0;

  /// Капсуланын четтеринен аралыгы.
  static const double sideMargin = 20.0;

  /// Капсуланын экрандын астынан аралыгы (safe-area дан 14px төмөн).
  static double bottomGap(double bottomPadding) =>
      (bottomPadding - 14).clamp(10.0, 60.0).toDouble();

  /// Капсула экрандын астынан канчалык бийиктикти ээлейт (FAB ж.б. үчүн).
  static double footprint(double bottomPadding) =>
      navHeight + bottomGap(bottomPadding);

  @override
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav>
    with SingleTickerProviderStateMixin {
  // ── Учурда манжа/басуу астында турган индекс (визуалдык гана) ──
  int? _touchedIndex;
  int _downIndex = -1;
  bool _slid = false;

  // ── Тамчынын позициясы (таб бирдигинде, 0..4) — пружина башкарат ──
  late final AnimationController _pos;
  int _targetIdx = 0;

  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 27,
  );

  @override
  void initState() {
    super.initState();
    _targetIdx = widget.currentTab;
    _pos = AnimationController.unbounded(
      vsync: this,
      value: widget.currentTab.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant HomeBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentTab != widget.currentTab && _touchedIndex == null) {
      _moveTo(widget.currentTab);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _moveTo(int idx) {
    if (idx == _targetIdx) return;
    _targetIdx = idx;
    _pos.animateWith(
      SpringSimulation(_spring, _pos.value, idx.toDouble(), _pos.velocity),
    );
  }

  int _indexAtDx(double dx, double totalWidth) {
    if (totalWidth <= 0) return widget.currentTab;
    final segment = totalWidth / _tabCount;
    final idx = (dx / segment).floor();
    return idx.clamp(0, _tabCount - 1);
  }

  void _touch(double dx, double totalWidth) {
    final idx = _indexAtDx(dx, totalWidth);
    if (_touchedIndex == idx) return;
    if (_touchedIndex != null) _slid = true; // башка баскычка жылды
    HapticFeedback.selectionClick();
    setState(() => _touchedIndex = idx);
    _moveTo(idx);
  }

  void _release(double dx, double totalWidth) {
    final idx = _indexAtDx(dx, totalWidth);
    final wasTap = !_slid && idx == _downIndex;
    setState(() => _touchedIndex = null);
    _moveTo(idx);
    // Экран колду көтөргөндө гана алмашат (сүрүп жатканда эмес)
    if (widget.currentTab != idx) widget.onTabSelected(idx);
    if (wasTap) widget.onTabTapped?.call(idx);
  }

  void _endTouch() {
    if (_touchedIndex != null) {
      setState(() => _touchedIndex = null);
    }
    _moveTo(widget.currentTab);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final p = DDPalette.of(context);
    final shownTab = _touchedIndex ?? widget.currentTab;
    final gap = HomeBottomNav.bottomGap(widget.bottomPadding);

    return AnimatedPositioned(
      duration: widget.isVisible
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      left: HomeBottomNav.sideMargin,
      right: HomeBottomNav.sideMargin,
      bottom: widget.isVisible
          ? gap
          : -(HomeBottomNav.navHeight + gap + 40),
      child: Container(
        height: HomeBottomNav.navHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeBottomNav.navHeight / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(p.isDark ? 0.45 : 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeBottomNav.navHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: p.isDark
                    ? const Color(0xFF1A1A1A).withOpacity(0.72)
                    : Colors.white.withOpacity(0.72),
                borderRadius:
                    BorderRadius.circular(HomeBottomNav.navHeight / 2),
                border: Border.all(
                  color: p.isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.07),
                  width: 0.8,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final tabW = totalWidth / _tabCount;

                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) {
                      _slid = false;
                      _downIndex = _indexAtDx(e.localPosition.dx, totalWidth);
                      _touch(e.localPosition.dx, totalWidth);
                    },
                    onPointerMove: (e) =>
                        _touch(e.localPosition.dx, totalWidth),
                    onPointerUp: (e) =>
                        _release(e.localPosition.dx, totalWidth),
                    onPointerCancel: (_) => _endTouch(),
                    child: Stack(
                      children: [
                        // ── Мандарин айнек тамчы ──
                        AnimatedBuilder(
                          animation: _pos,
                          builder: (context, _) {
                            final v = _pos.velocity; // таб/сек
                            final stretch =
                                (v.abs() * 0.045).clamp(0.0, 0.7).toDouble();
                            final w = tabW * (0.80 + stretch);
                            final h = HomeBottomNav.navHeight -
                                14 -
                                (stretch * 6);
                            final cx = (_pos.value + 0.5) * tabW;
                            return Positioned(
                              left: cx - w / 2,
                              top: (HomeBottomNav.navHeight - h) / 2,
                              width: w,
                              height: h,
                              child: _DropletPill(
                                  isDark: p.isDark, pressed: _touchedIndex != null),
                            );
                          },
                        ),

                        // ── Иконкалар ──
                        Positioned.fill(
                          child: Row(
                            children: [
                              _NavButton(
                                icon: Icon(
                                  shownTab == tabHome
                                      ? Icons.home_rounded
                                      : Icons.home_outlined,
                                  size: 23,
                                  color: shownTab == tabHome
                                      ? DD.accent
                                      : p.subText,
                                ),
                                label: loc.get('home'),
                                isActive: shownTab == tabHome,
                                palette: p,
                              ),
                              _NavButton(
                                icon: _ChatBadgeIcon(
                                  unreadCount: widget.totalUnreadChat,
                                  isActive: shownTab == tabChat,
                                  palette: p,
                                ),
                                label: loc.get('chat'),
                                isActive: shownTab == tabChat,
                                palette: p,
                              ),
                              _NavButton(
                                icon: Icon(
                                  shownTab == tabMap
                                      ? Icons.storefront_rounded
                                      : Icons.storefront_outlined,
                                  size: 23,
                                  color: shownTab == tabMap
                                      ? DD.accent
                                      : p.subText,
                                ),
                                label: loc.get('map_title'),
                                isActive: shownTab == tabMap,
                                palette: p,
                              ),
                              _NavButton(
                                icon: FavBadge(
                                  count: widget.favCount,
                                  active: shownTab == tabFavorites,
                                ),
                                label: loc.get('favorites'),
                                isActive: shownTab == tabFavorites,
                                palette: p,
                              ),
                              _NavButton(
                                icon: Icon(
                                  shownTab == tabSettings
                                      ? Icons.settings_rounded
                                      : Icons.settings_outlined,
                                  size: 23,
                                  color: shownTab == tabSettings
                                      ? DD.accent
                                      : p.subText,
                                ),
                                label: loc.get('settings'),
                                isActive: shownTab == tabSettings,
                                palette: p,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Мандарин айнек тамчы (80% тунук)
// ══════════════════════════════════════════════════════
class _DropletPill extends StatelessWidget {
  final bool isDark;
  final bool pressed;
  const _DropletPill({required this.isDark, required this.pressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DD.accent.withOpacity(isDark ? 0.34 : 0.28),
              DD.accent.withOpacity(isDark ? 0.18 : 0.14),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.22 : 0.55),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: DD.accent.withOpacity(0.28),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// БИРДИКТЕЙ БАСКЫЧ — таза көрсөтмө гана (gesture жогорудан
// Listener аркылуу башкарылат). Бардыгы бирдей кендикте.
// ══════════════════════════════════════════════════════
class _NavButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final DDPalette palette;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Expanded(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? DD.accent : p.subText,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Чат иконкасы + окулбаган санагыч
// ══════════════════════════════════════════════════════
class _ChatBadgeIcon extends StatelessWidget {
  final int unreadCount;
  final bool isActive;
  final DDPalette palette;

  const _ChatBadgeIcon({
    required this.unreadCount,
    required this.isActive,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive
              ? Icons.chat_bubble_rounded
              : Icons.chat_bubble_outline_rounded,
          size: 23,
          color: isActive ? DD.accent : palette.subText,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: DD.accent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: palette.isDark
                      ? const Color(0xFF15120F)
                      : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}