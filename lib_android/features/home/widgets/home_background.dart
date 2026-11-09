import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════
// HomeBackground — iOS стилиндеги сурот фон
// Колдонуу (home_screen.dart Stack ичинде):
//   HomeBackground(isDark: isDark),
// ══════════════════════════════════════════════════════
class HomeBackground extends StatelessWidget {
  final bool isDark;

  const HomeBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        isDark
            ? 'assets/backgrounds/bg_dark.png'
            : 'assets/backgrounds/bg_light.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
