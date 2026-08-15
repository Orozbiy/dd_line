import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

enum ChatBgTheme {
  classic,   // Классикалык
  floral,    // Гүлдөр
  nature,    // Жаратылыш
  sunset,    // Күн батышы
  galaxy,    // Галактика
  ocean,     // Деңиз 🌊
  aurora,    // Аврора 🌌
  desert,    // Чөл 🏜
  cyberpunk, // Киберпанк 🤖
  sakura,    // Сакура 🌸
}

extension ChatBgThemeExt on ChatBgTheme {
  String get label {
    switch (this) {
      case ChatBgTheme.classic:   return 'Классикалык';
      case ChatBgTheme.floral:    return 'Гүлдөр 🌸';
      case ChatBgTheme.nature:    return 'Жаратылыш 🌿';
      case ChatBgTheme.sunset:    return 'Күн батышы 🌅';
      case ChatBgTheme.galaxy:    return 'Галактика 🌌';
      case ChatBgTheme.ocean:     return 'Деңиз 🌊';
      case ChatBgTheme.aurora:    return 'Аврора 🌠';
      case ChatBgTheme.desert:    return 'Чөл 🏜️';
      case ChatBgTheme.cyberpunk: return 'Киберпанк 🤖';
      case ChatBgTheme.sakura:    return 'Сакура 🌸';
    }
  }

  String localizedLabel(BuildContext context) => label;

  Color get previewColor {
    switch (this) {
      case ChatBgTheme.classic:   return const Color(0xFFF0F2F5);
      case ChatBgTheme.floral:    return const Color(0xFFFFE4F0);
      case ChatBgTheme.nature:    return const Color(0xFFD4EDDA);
      case ChatBgTheme.sunset:    return const Color(0xFFFFD4A8);
      case ChatBgTheme.galaxy:    return const Color(0xFF1A1040);
      case ChatBgTheme.ocean:     return const Color(0xFF006994);
      case ChatBgTheme.aurora:    return const Color(0xFF0D2137);
      case ChatBgTheme.desert:    return const Color(0xFFD4A256);
      case ChatBgTheme.cyberpunk: return const Color(0xFF0A0A1A);
      case ChatBgTheme.sakura:    return const Color(0xFFFFB7C5);
    }
  }

  Widget buildBackground(bool isDark) {
    switch (this) {
      case ChatBgTheme.classic:
        return Container(color: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5));
      case ChatBgTheme.floral:
        return _FloralBackground(isDark: isDark);
      case ChatBgTheme.nature:
        return _NatureBackground(isDark: isDark);
      case ChatBgTheme.sunset:
        return _SunsetBackground();
      case ChatBgTheme.galaxy:
        return const _GalaxyBackground();
      case ChatBgTheme.ocean:
        return const _OceanBackground();
      case ChatBgTheme.aurora:
        return const _AuroraBackground();
      case ChatBgTheme.desert:
        return const _DesertBackground();
      case ChatBgTheme.cyberpunk:
        return const _CyberpunkBackground();
      case ChatBgTheme.sakura:
        return _SakuraBackground(isDark: isDark);
    }
  }

  BoxDecoration backgroundDecoration(bool isDark) {
    switch (this) {
      case ChatBgTheme.classic:
        return BoxDecoration(color: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5));
      case ChatBgTheme.floral:
        return BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D1020), const Color(0xFF1A0A18), const Color(0xFF2D1020)]
              : [const Color(0xFFFFF0F5), const Color(0xFFFFD6E8), const Color(0xFFFFF0F5)],
        ));
      case ChatBgTheme.nature:
        return BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A1F0F), const Color(0xFF0D2B14), const Color(0xFF0A1F0F)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFE8F5E9)],
        ));
      case ChatBgTheme.sunset:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53), Color(0xFFFFB347), Color(0xFFFFD700)],
        ));
      case ChatBgTheme.galaxy:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D0221), Color(0xFF1A0845), Color(0xFF0D1B2A)],
        ));
      case ChatBgTheme.ocean:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF001E3C), Color(0xFF006994), Color(0xFF0099CC)],
        ));
      case ChatBgTheme.aurora:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF1A3A2A), Color(0xFF0D2137)],
        ));
      case ChatBgTheme.desert:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFE8B86D), Color(0xFFD4855A), Color(0xFFA0522D)],
        ));
      case ChatBgTheme.cyberpunk:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF1A0A2E), Color(0xFF0A1A0A)],
        ));
      case ChatBgTheme.sakura:
        return BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF2D1020), const Color(0xFF1A0518)]
              : [const Color(0xFFFFF0F8), const Color(0xFFFFD6E8)],
        ));
    }
  }
}

// ════════════════════════════════════════════════════
// ГҮЛДӨР
// ════════════════════════════════════════════════════
class _FloralBackground extends StatelessWidget {
  final bool isDark;
  const _FloralBackground({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF2D1020), const Color(0xFF1A0A18)]
            : [const Color(0xFFFFF0F5), const Color(0xFFFFD6E8)],
      )),
      child: CustomPaint(painter: _FloralPainter(isDark: isDark), child: const SizedBox.expand()),
    );
  }
}

class _FloralPainter extends CustomPainter {
  final bool isDark;
  _FloralPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final petalColor = isDark
        ? const Color(0xFFFF69B4).withOpacity(0.15)
        : const Color(0xFFFF69B4).withOpacity(0.25);
    final leafColor = isDark
        ? const Color(0xFF90EE90).withOpacity(0.10)
        : const Color(0xFF90EE90).withOpacity(0.20);
    final paint = Paint()..style = PaintingStyle.fill;
    void drawFlower(double cx, double cy, double r) {
      paint.color = petalColor;
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)), r * 0.6, paint);
      }
      paint.color = petalColor.withOpacity(petalColor.opacity * 1.5);
      canvas.drawCircle(Offset(cx, cy), r * 0.4, paint);
    }
    void drawLeaf(double cx, double cy, double w, double h, double angle) {
      paint.color = leafColor;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -h / 2)
        ..quadraticBezierTo(w / 2, 0, 0, h / 2)
        ..quadraticBezierTo(-w / 2, 0, 0, -h / 2);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    drawFlower(size.width * 0.15, size.height * 0.12, 28);
    drawFlower(size.width * 0.80, size.height * 0.08, 22);
    drawFlower(size.width * 0.50, size.height * 0.25, 18);
    drawFlower(size.width * 0.10, size.height * 0.55, 24);
    drawFlower(size.width * 0.88, size.height * 0.45, 30);
    drawFlower(size.width * 0.60, size.height * 0.75, 20);
    drawFlower(size.width * 0.30, size.height * 0.85, 26);
    drawFlower(size.width * 0.75, size.height * 0.90, 18);
    drawLeaf(size.width * 0.25, size.height * 0.20, 20, 40, 0.5);
    drawLeaf(size.width * 0.70, size.height * 0.60, 18, 36, -0.8);
    drawLeaf(size.width * 0.45, size.height * 0.80, 22, 44, 1.2);
  }
  @override
  bool shouldRepaint(_FloralPainter old) => false;
}

// ════════════════════════════════════════════════════
// ЖАРАТЫЛЫШ
// ════════════════════════════════════════════════════
class _NatureBackground extends StatelessWidget {
  final bool isDark;
  const _NatureBackground({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0A1F0F), const Color(0xFF0D2B14)]
            : [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)],
      )),
      child: CustomPaint(painter: _NaturePainter(isDark: isDark), child: const SizedBox.expand()),
    );
  }
}

class _NaturePainter extends CustomPainter {
  final bool isDark;
  _NaturePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final treePaint = Paint()
      ..color = isDark
          ? const Color(0xFF1B4D1B).withOpacity(0.6)
          : const Color(0xFF2E7D32).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    void drawTree(double x, double y, double h) {
      final w = h * 0.4;
      final path = Path()
        ..moveTo(x, y - h)
        ..lineTo(x + w, y)
        ..lineTo(x - w, y)
        ..close();
      canvas.drawPath(path, treePaint);
      final path2 = Path()
        ..moveTo(x, y - h * 1.3)
        ..lineTo(x + w * 0.8, y - h * 0.4)
        ..lineTo(x - w * 0.8, y - h * 0.4)
        ..close();
      canvas.drawPath(path2, treePaint);
    }
    drawTree(size.width * 0.05, size.height, size.height * 0.35);
    drawTree(size.width * 0.18, size.height, size.height * 0.28);
    drawTree(size.width * 0.82, size.height, size.height * 0.32);
    drawTree(size.width * 0.95, size.height, size.height * 0.25);
    drawTree(size.width * 0.60, size.height, size.height * 0.20);

    // Жердин сызыгы
    final groundPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1B4D1B).withOpacity(0.4)
          : const Color(0xFF4CAF50).withOpacity(0.25);
    final groundPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.78, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(groundPath, groundPaint);
  }
  @override
  bool shouldRepaint(_NaturePainter old) => false;
}

// ════════════════════════════════════════════════════
// КҮН БАТЫШЫ
// ════════════════════════════════════════════════════
class _SunsetBackground extends StatelessWidget {
  const _SunsetBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0533), Color(0xFF8B1A4A), Color(0xFFFF6B35), Color(0xFFFFD700)],
      )),
      child: CustomPaint(painter: _SunsetPainter(), child: const SizedBox.expand()),
    );
  }
}

class _SunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Күн
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFAA), Color(0xFFFFD700), Color(0xFFFF8C00)],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.55), radius: 40));
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.55), 38, sunPaint);

    // Суу чагылышы
    final reflectPaint = Paint()
      ..color = const Color(0xFFFF6B35).withOpacity(0.25)
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final y = size.height * 0.65 + i * 8.0;
      final w = 60.0 + i * 15;
      canvas.drawLine(
        Offset(size.width / 2 - w / 2, y),
        Offset(size.width / 2 + w / 2, y),
        reflectPaint,
      );
    }

    // Тоолор
    final mountainPaint = Paint()
      ..color = const Color(0xFF1A0533).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final mPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.20, size.height * 0.38)
      ..lineTo(size.width * 0.40, size.height * 0.58)
      ..lineTo(size.width * 0.60, size.height * 0.35)
      ..lineTo(size.width * 0.80, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height * 0.65)
      ..close();
    canvas.drawPath(mPath, mountainPaint);
  }
  @override
  bool shouldRepaint(_SunsetPainter old) => false;
}

// ════════════════════════════════════════════════════
// ГАЛАКТИКА
// ════════════════════════════════════════════════════
class _GalaxyBackground extends StatelessWidget {
  const _GalaxyBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0D0221), Color(0xFF1A0845), Color(0xFF0D1B2A)],
      )),
      child: CustomPaint(painter: _GalaxyPainter(), child: const SizedBox.expand()),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.8 + 0.3;
      final opacity = rng.nextDouble() * 0.7 + 0.3;
      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF7B2FBE).withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.3), radius: size.width * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula);
  }
  @override
  bool shouldRepaint(_GalaxyPainter old) => false;
}

// ════════════════════════════════════════════════════
// ДЕҢИЗ 🌊  (ЖАҢЫ)
// ════════════════════════════════════════════════════
class _OceanBackground extends StatelessWidget {
  const _OceanBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF001E3C), Color(0xFF003D6B), Color(0xFF006994), Color(0xFF0099CC)],
      )),
      child: CustomPaint(painter: _OceanPainter(), child: const SizedBox.expand()),
    );
  }
}

class _OceanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.06);

    // Толкундар
    for (int w = 0; w < 5; w++) {
      final offsetY = size.height * (0.3 + w * 0.12);
      final path = Path();
      path.moveTo(0, offsetY);
      for (double x = 0; x <= size.width; x += 1) {
        final y = offsetY + math.sin((x / size.width) * 4 * math.pi + w) * (10 - w * 1.5);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      wavePaint.color = Colors.white.withOpacity(0.04 + w * 0.015);
      canvas.drawPath(path, wavePaint);
    }

    // Жарык нурлар
    final rayPaint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final cx = size.width * 0.5;
      final angle = (-0.3 + i * 0.12);
      path.moveTo(cx, 0);
      path.lineTo(cx + math.sin(angle - 0.05) * size.height * 1.5, size.height);
      path.lineTo(cx + math.sin(angle + 0.05) * size.height * 1.5, size.height);
      path.close();
      canvas.drawPath(path, rayPaint);
    }

    // Балыктар / көбүкчөлөр
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rng = math.Random(7);
    for (int i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.5 + rng.nextDouble() * size.height * 0.5;
      final r = rng.nextDouble() * 5 + 2;
      canvas.drawCircle(Offset(x, y), r, bubblePaint);
    }
  }
  @override
  bool shouldRepaint(_OceanPainter old) => false;
}

// ════════════════════════════════════════════════════
// АВРОРА 🌠  (ЖАҢЫ)
// ════════════════════════════════════════════════════
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF020818), Color(0xFF0D2137), Color(0xFF071A2F)],
      )),
      child: CustomPaint(painter: _AuroraPainter(), child: const SizedBox.expand()),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Жылдыздар
    final starPaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(13);
    for (int i = 0; i < 80; i++) {
      starPaint.color = Colors.white.withOpacity(rng.nextDouble() * 0.6 + 0.2);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.5),
        rng.nextDouble() * 1.2 + 0.3,
        starPaint,
      );
    }

    // Аврора лентасы — жашыл
    void drawAuroraStrip(List<Color> colors, double baseY, double amplitude, int seed) {
      final r = math.Random(seed);
      final paint = Paint()..style = PaintingStyle.fill;
      for (int layer = 0; layer < 3; layer++) {
        final path = Path();
        path.moveTo(0, size.height);
        for (double x = 0; x <= size.width; x += 2) {
          final t = x / size.width;
          final y = baseY * size.height +
              math.sin(t * 3 * math.pi + layer * 0.8) * amplitude +
              math.sin(t * 5 * math.pi + r.nextDouble()) * amplitude * 0.4;
          if (x == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        paint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors[layer % colors.length].withOpacity(0.18 - layer * 0.04), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawPath(path, paint);
      }
    }

    drawAuroraStrip([const Color(0xFF00FF88), const Color(0xFF00DDAA), const Color(0xFF00CC77)], 0.35, 30, 1);
    drawAuroraStrip([const Color(0xFF7B2FBE), const Color(0xFF9B4FDE), const Color(0xFF6B1FAE)], 0.50, 25, 2);
    drawAuroraStrip([const Color(0xFF00BFFF), const Color(0xFF0088CC), const Color(0xFF005599)], 0.42, 20, 3);
  }
  @override
  bool shouldRepaint(_AuroraPainter old) => false;
}

// ════════════════════════════════════════════════════
// ЧӨЛ 🏜️  (ЖАҢЫ)
// ════════════════════════════════════════════════════
class _DesertBackground extends StatelessWidget {
  const _DesertBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0A00), Color(0xFF8B4513), Color(0xFFD4855A), Color(0xFFE8B86D)],
      )),
      child: CustomPaint(painter: _DesertPainter(), child: const SizedBox.expand()),
    );
  }
}

class _DesertPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Кум дөңдөрү
    final dunePaint = Paint()..style = PaintingStyle.fill;

    void drawDune(double cx, double baseY, double w, double h, Color color) {
      dunePaint.color = color;
      final path = Path()
        ..moveTo(cx - w / 2, baseY)
        ..quadraticBezierTo(cx - w * 0.1, baseY - h, cx, baseY - h * 0.95)
        ..quadraticBezierTo(cx + w * 0.15, baseY - h * 0.85, cx + w / 2, baseY)
        ..close();
      canvas.drawPath(path, dunePaint);
    }

    drawDune(size.width * 0.2, size.height, size.width * 0.7, size.height * 0.30, const Color(0xFFC0732A).withOpacity(0.6));
    drawDune(size.width * 0.75, size.height, size.width * 0.6, size.height * 0.22, const Color(0xFFB8651E).withOpacity(0.5));
    drawDune(size.width * 0.5, size.height, size.width * 0.9, size.height * 0.18, const Color(0xFFD4855A).withOpacity(0.4));

    // Жылдыздар / кум бөлүкчөлөрү
    final dotPaint = Paint()..color = const Color(0xFFFFD700).withOpacity(0.15);
    final rng = math.Random(5);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.4),
        rng.nextDouble() * 1.5 + 0.5,
        dotPaint,
      );
    }

    // Ай
    final moonPaint = Paint()
      ..color = const Color(0xFFFFF8DC).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.12), 18, moonPaint);
    final moonCut = Paint()
      ..color = const Color(0xFF1A0A00).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8 + 8, size.height * 0.12), 15, moonCut);

    // Кактус
    final cactusPaint = Paint()
      ..color = const Color(0xFF2D5A27).withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    final cactusStroke = Paint()
      ..color = const Color(0xFF2D5A27).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    // Туловище
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.15, size.height * 0.72), width: 10, height: 55),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, cactusPaint);
    // Колдор
    final armPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.60)
      ..lineTo(size.width * 0.09, size.height * 0.60)
      ..lineTo(size.width * 0.09, size.height * 0.54);
    canvas.drawPath(armPath, cactusStroke);
    final armPath2 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.64)
      ..lineTo(size.width * 0.21, size.height * 0.64)
      ..lineTo(size.width * 0.21, size.height * 0.58);
    canvas.drawPath(armPath2, cactusStroke);
  }
  @override
  bool shouldRepaint(_DesertPainter old) => false;
}

// ════════════════════════════════════════════════════
// КИБЕРПАНК 🤖  (ЖАҢЫ)
// ════════════════════════════════════════════════════
class _CyberpunkBackground extends StatelessWidget {
  const _CyberpunkBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0A0A1A), Color(0xFF1A0A2E), Color(0xFF000A1A)],
      )),
      child: CustomPaint(painter: _CyberpunkPainter(), child: const SizedBox.expand()),
    );
  }
}

class _CyberpunkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Тор сызыктар
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Горизонталдык
    for (int i = 0; i < 20; i++) {
      final y = size.height * i / 20;
      final perspective = 1 - (y / size.height) * 0.6;
      gridPaint.color = const Color(0xFF00FF88).withOpacity(0.06 * perspective);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Перспектива торчу
    for (int i = -8; i <= 8; i++) {
      gridPaint.color = const Color(0xFF00FF88).withOpacity(0.08);
      canvas.drawLine(
        Offset(size.width / 2 + i * 30, size.height * 0.4),
        Offset(size.width / 2 + i * size.width * 0.15, size.height),
        gridPaint,
      );
    }

    // Неон жарыктар
    void drawNeonLine(Offset start, Offset end, Color color, double width) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = width * 4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, glowPaint);
      final corePaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, corePaint);
    }

    drawNeonLine(
      Offset(0, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.3),
      const Color(0xFF00FFFF), 1.5,
    );
    drawNeonLine(
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      const Color(0xFFFF00FF), 1.5,
    );
    drawNeonLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height * 0.2),
      const Color(0xFF00FF88), 1.0,
    );
    drawNeonLine(
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.75, size.height),
      const Color(0xFFFF4500), 1.0,
    );

    // Тексттер (маалымат бөлүкчөлөрү)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final fragments = ['01', '10', 'FF', 'A3', '7E', '00', 'C9', 'B1'];
    final rng = math.Random(9);
    for (int i = 0; i < 14; i++) {
      textPainter.text = TextSpan(
        text: fragments[i % fragments.length],
        style: TextStyle(
          color: const Color(0xFF00FF88).withOpacity(rng.nextDouble() * 0.2 + 0.05),
          fontSize: rng.nextDouble() * 8 + 7,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
      );
    }
  }
  @override
  bool shouldRepaint(_CyberpunkPainter old) => false;
}

// ════════════════════════════════════════════════════
// САКУРА 🌸  (ЖАҢЫ)
// ════════════════════════════════════════════════════
class _SakuraBackground extends StatelessWidget {
  final bool isDark;
  const _SakuraBackground({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1A0510), const Color(0xFF2D0A20), const Color(0xFF1A0510)]
            : [const Color(0xFFFFF0F8), const Color(0xFFFFD6E8), const Color(0xFFFCE4EC)],
      )),
      child: CustomPaint(painter: _SakuraPainter(isDark: isDark), child: const SizedBox.expand()),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final bool isDark;
  _SakuraPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(21);
    final petalPaint = Paint()..style = PaintingStyle.fill;

    void drawPetal(double cx, double cy, double size_, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      petalPaint.shader = RadialGradient(
        colors: isDark
            ? [const Color(0xFFFF69B4).withOpacity(0.25), const Color(0xFFFF1493).withOpacity(0.08)]
            : [const Color(0xFFFFB7C5).withOpacity(0.7), const Color(0xFFFF69B4).withOpacity(0.2)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size_));
      final path = Path()
        ..moveTo(0, -size_)
        ..cubicTo(size_ * 0.6, -size_ * 0.6, size_ * 0.6, size_ * 0.2, 0, size_ * 0.4)
        ..cubicTo(-size_ * 0.6, size_ * 0.2, -size_ * 0.6, -size_ * 0.6, 0, -size_);
      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }

    void drawFlower(double cx, double cy, double r) {
      for (int i = 0; i < 5; i++) {
        final angle = i * 2 * math.pi / 5;
        drawPetal(cx + math.cos(angle) * r * 0.5, cy + math.sin(angle) * r * 0.5, r * 0.6, angle);
      }
      // Борбор
      petalPaint.shader = null;
      petalPaint.color = isDark
          ? const Color(0xFFFFD700).withOpacity(0.3)
          : const Color(0xFFFFD700).withOpacity(0.6);
      canvas.drawCircle(Offset(cx, cy), r * 0.2, petalPaint);
    }

    // Чоң гүлдөр
    drawFlower(size.width * 0.12, size.height * 0.08, 22);
    drawFlower(size.width * 0.85, size.height * 0.05, 18);
    drawFlower(size.width * 0.55, size.height * 0.15, 15);
    drawFlower(size.width * 0.08, size.height * 0.45, 20);
    drawFlower(size.width * 0.90, size.height * 0.38, 24);
    drawFlower(size.width * 0.40, size.height * 0.70, 16);
    drawFlower(size.width * 0.72, size.height * 0.80, 20);
    drawFlower(size.width * 0.20, size.height * 0.88, 14);

    // Учуп жүргөн лепесткалар
    for (int i = 0; i < 25; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = rng.nextDouble() * 7 + 4;
      final angle = rng.nextDouble() * math.pi * 2;
      drawPetal(x, y, s, angle);
    }

    // Бутак
    final branchPaint = Paint()
      ..color = isDark
          ? const Color(0xFF6D3B2E).withOpacity(0.3)
          : const Color(0xFF8B4513).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final branchPath = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.3, size.width * 0.6, size.height * 0.1);
    canvas.drawPath(branchPath, branchPaint);
    branchPaint.strokeWidth = 3;
    final branch2 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.25, size.width * 0.5, size.height * 0.18);
    canvas.drawPath(branch2, branchPaint);
  }
  @override
  bool shouldRepaint(_SakuraPainter old) => false;
}

// ════════════════════════════════════════════════════
// PROVIDER
// ════════════════════════════════════════════════════
class ChatBackgroundProvider extends ChangeNotifier {
  static const _key = 'chat_bg_theme';
  static final ChatBackgroundProvider instance = ChatBackgroundProvider._internal();
  ChatBackgroundProvider._internal();

  ChatBgTheme _theme = ChatBgTheme.classic;
  ChatBgTheme get theme => _theme;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _theme = ChatBgTheme.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ChatBgTheme.classic,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(ChatBgTheme t) async {
    _theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, t.name);
  }
}