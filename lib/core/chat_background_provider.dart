import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatBgTheme {
  classic,   // Демейки
  floral,    // Гүлдөр
  nature,    // Жаратылыш
  sunset,    // Күн батышы
  galaxy,    // Галактика
}

extension ChatBgThemeExt on ChatBgTheme {
  String get label {
    switch (this) {
      case ChatBgTheme.classic:  return 'Классикалык';
      case ChatBgTheme.floral:   return 'Гүлдөр 🌸';
      case ChatBgTheme.nature:   return 'Жаратылыш 🌿';
      case ChatBgTheme.sunset:   return 'Күн батышы 🌅';
      case ChatBgTheme.galaxy:   return 'Галактика 🌌';
    }
  }

  Color get previewColor {
    switch (this) {
      case ChatBgTheme.classic:  return const Color(0xFFF0F2F5);
      case ChatBgTheme.floral:   return const Color(0xFFFFE4F0);
      case ChatBgTheme.nature:   return const Color(0xFFD4EDDA);
      case ChatBgTheme.sunset:   return const Color(0xFFFFD4A8);
      case ChatBgTheme.galaxy:   return const Color(0xFF1A1040);
    }
  }

  // Фон виджети
  Widget buildBackground(bool isDark) {
    switch (this) {
      case ChatBgTheme.classic:
        return Container(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5),
        );
      case ChatBgTheme.floral:
        return _FloralBackground(isDark: isDark);
      case ChatBgTheme.nature:
        return _NatureBackground(isDark: isDark);
      case ChatBgTheme.sunset:
        return _SunsetBackground(isDark: isDark);
      case ChatBgTheme.galaxy:
        return const _GalaxyBackground();
    }
  }

  // BoxDecoration — chat_screen Stack үчүн (жөнөкөй версия)
  BoxDecoration backgroundDecoration(bool isDark) {
    switch (this) {
      case ChatBgTheme.classic:
        return BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5),
        );
      case ChatBgTheme.floral:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2D1020), const Color(0xFF1A0A18), const Color(0xFF2D1020)]
                : [const Color(0xFFFFF0F5), const Color(0xFFFFD6E8), const Color(0xFFFFF0F5)],
          ),
        );
      case ChatBgTheme.nature:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A1F0F), const Color(0xFF0D2B14), const Color(0xFF0A1F0F)]
                : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFE8F5E9)],
          ),
        );
      case ChatBgTheme.sunset:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53), Color(0xFFFFB347), Color(0xFFFFD700)],
          ),
        );
      case ChatBgTheme.galaxy:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0221), Color(0xFF1A0845), Color(0xFF0D1B2A)],
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════
// ГҮЛДӨР ФОНУ
// ════════════════════════════════════════════════════
class _FloralBackground extends StatelessWidget {
  final bool isDark;
  const _FloralBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2D1020), const Color(0xFF1A0A18)]
              : [const Color(0xFFFFF0F5), const Color(0xFFFFD6E8)],
        ),
      ),
      child: CustomPaint(
        painter: _FloralPainter(isDark: isDark),
        child: const SizedBox.expand(),
      ),
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
        ? const Color(0xFF4CAF50).withOpacity(0.12)
        : const Color(0xFF81C784).withOpacity(0.30);

    _drawFlower(canvas, Offset(size.width * 0.15, size.height * 0.12), 28, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.80, size.height * 0.08), 22, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.05, size.height * 0.45), 18, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.90, size.height * 0.38), 24, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.50, size.height * 0.05), 20, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.25, size.height * 0.85), 26, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.75, size.height * 0.80), 20, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.92, size.height * 0.70), 16, petalColor, leafColor);
    _drawFlower(canvas, Offset(size.width * 0.10, size.height * 0.75), 22, petalColor, leafColor);
  }

  void _drawFlower(Canvas canvas, Offset center, double r, Color petalColor, Color leafColor) {
    final paint = Paint()..color = petalColor..style = PaintingStyle.fill;
    // 6 лепесток
    for (int i = 0; i < 6; i++) {
      final angle = i * 3.14159 / 3;
      final ox = center.dx + r * 0.6 * _cos(angle);
      final oy = center.dy + r * 0.6 * _sin(angle);
      canvas.drawCircle(Offset(ox, oy), r * 0.55, paint);
    }
    // Борбор
    final centerPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFD700).withOpacity(0.4)
          : const Color(0xFFFFD700).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.35, centerPaint);
    // Жалбырак
    final leafPaint = Paint()..color = leafColor..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy + r);
    path.quadraticBezierTo(
        center.dx + r * 0.8, center.dy + r * 1.5,
        center.dx, center.dy + r * 2.0);
    path.quadraticBezierTo(
        center.dx - r * 0.8, center.dy + r * 1.5,
        center.dx, center.dy + r);
    canvas.drawPath(path, leafPaint);
  }

  double _cos(double a) => (a == 0) ? 1 : (a == 3.14159 / 2) ? 0 : (a == 3.14159) ? -1 : (a == 3 * 3.14159 / 2) ? 0 : _cosApprox(a);
  double _sin(double a) => _cosApprox(3.14159 / 2 - a);
  double _cosApprox(double a) {
    double x = a % (2 * 3.14159265);
    double t = 1, sum = 1;
    for (int i = 1; i <= 8; i++) {
      t *= -x * x / ((2 * i - 1) * (2 * i));
      sum += t;
    }
    return sum;
  }

  @override
  bool shouldRepaint(_FloralPainter old) => false;
}

// ════════════════════════════════════════════════════
// ЖАРАТЫЛЫШ ФОНУ
// ════════════════════════════════════════════════════
class _NatureBackground extends StatelessWidget {
  final bool isDark;
  const _NatureBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A1F0F), const Color(0xFF0D2B14)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
        ),
      ),
      child: CustomPaint(
        painter: _NaturePainter(isDark: isDark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NaturePainter extends CustomPainter {
  final bool isDark;
  _NaturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final leafColor = isDark
        ? const Color(0xFF4CAF50).withOpacity(0.20)
        : const Color(0xFF388E3C).withOpacity(0.22);
    final stemColor = isDark
        ? const Color(0xFF2E7D32).withOpacity(0.25)
        : const Color(0xFF2E7D32).withOpacity(0.30);

    _drawBranch(canvas, Offset(0, size.height * 0.3), size.width * 0.35, -0.4, leafColor, stemColor);
    _drawBranch(canvas, Offset(size.width, size.height * 0.15), size.width * 0.30, 3.14 + 0.4, leafColor, stemColor);
    _drawBranch(canvas, Offset(0, size.height * 0.75), size.width * 0.28, -0.2, leafColor, stemColor);
    _drawBranch(canvas, Offset(size.width, size.height * 0.65), size.width * 0.25, 3.14 + 0.2, leafColor, stemColor);

    // Чөп
    final grassPaint = Paint()..color = stemColor..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.12);
      final h = size.height * (0.06 + (i % 3) * 0.03);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + (i % 2 == 0 ? 8.0 : -8.0), size.height - h),
        grassPaint,
      );
    }
  }

  void _drawBranch(Canvas canvas, Offset start, double len, double angle, Color leafColor, Color stemColor) {
    final stemPaint = Paint()..color = stemColor..strokeWidth = 2..style = PaintingStyle.stroke;
    final leafPaint = Paint()..color = leafColor..style = PaintingStyle.fill;

    final endX = start.dx + len * _cosA(angle);
    final endY = start.dy + len * _sinA(angle);
    final end = Offset(endX, endY);
    canvas.drawLine(start, end, stemPaint);

    for (int i = 1; i <= 4; i++) {
      final t = i / 5.0;
      final mx = start.dx + (end.dx - start.dx) * t;
      final my = start.dy + (end.dy - start.dy) * t;
      for (int side in [-1, 1]) {
        final la = angle + side * 0.7;
        final ll = len * 0.20;
        final lx = mx + ll * _cosA(la);
        final ly = my + ll * _sinA(la);
        final path = Path();
        path.moveTo(mx, my);
        path.quadraticBezierTo(
            (mx + lx) / 2 + side * ll * 0.3, (my + ly) / 2 - ll * 0.3,
            lx, ly);
        path.quadraticBezierTo(
            (mx + lx) / 2 - side * ll * 0.1, (my + ly) / 2 + ll * 0.1,
            mx, my);
        canvas.drawPath(path, leafPaint);
      }
    }
  }

  double _cosA(double a) => _cosApprox(a);
  double _sinA(double a) => _cosApprox(3.14159265 / 2 - a);
  double _cosApprox(double a) {
    double x = a % (2 * 3.14159265);
    double t = 1, s = 1;
    for (int i = 1; i <= 8; i++) {
      t *= -x * x / ((2 * i - 1) * (2 * i));
      s += t;
    }
    return s;
  }

  @override
  bool shouldRepaint(_NaturePainter old) => false;
}

// ════════════════════════════════════════════════════
// КҮН БАТЫШЫ ФОНУ
// ════════════════════════════════════════════════════
class _SunsetBackground extends StatelessWidget {
  final bool isDark;
  const _SunsetBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SunsetPainter(isDark: isDark),
      child: const SizedBox.expand(),
    );
  }
}

class _SunsetPainter extends CustomPainter {
  final bool isDark;
  _SunsetPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Асман градиенти
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0D0221), const Color(0xFF2D0845), const Color(0xFFB22222)]
            : [const Color(0xFF87CEEB), const Color(0xFFFF8C69), const Color(0xFFFF6347)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Күн
    final sunY = size.height * (isDark ? 0.55 : 0.40);
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [const Color(0xFFFF4500), const Color(0xFFFF6347).withOpacity(0)]
            : [const Color(0xFFFFD700), const Color(0xFFFF8C00).withOpacity(0)],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, sunY), radius: size.width * 0.22));
    canvas.drawCircle(Offset(size.width * 0.5, sunY), size.width * 0.22, sunPaint);

    // Тоолор / үйлөр силуэти
    final mountainPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1A0845).withOpacity(0.9)
          : const Color(0xFF8B4513).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.62);
    path.lineTo(size.width * 0.12, size.height * 0.42);
    path.lineTo(size.width * 0.22, size.height * 0.58);
    path.lineTo(size.width * 0.35, size.height * 0.35);
    path.lineTo(size.width * 0.50, size.height * 0.55);
    path.lineTo(size.width * 0.62, size.height * 0.40);
    path.lineTo(size.width * 0.75, size.height * 0.58);
    path.lineTo(size.width * 0.88, size.height * 0.45);
    path.lineTo(size.width, size.height * 0.60);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, mountainPaint);

    // Суу / жер
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1A0845), const Color(0xFF0D0221)]
            : [const Color(0xFFFF7043), const Color(0xFFFF5722)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        waterPaint);

    // Күндүн чагылышы суудан
    final reflPaint = Paint()
      ..color = (isDark ? const Color(0xFFFF4500) : const Color(0xFFFFD700)).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final w = size.width * (0.05 - i * 0.008);
      final y = size.height * (0.74 + i * 0.04);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(size.width * 0.5, y), width: w * 2, height: 3),
          reflPaint);
    }

    // Жылдыздар (кечки)
    if (isDark) {
      final starPaint = Paint()..color = Colors.white.withOpacity(0.6);
      final stars = [
        [0.1, 0.05], [0.25, 0.10], [0.45, 0.03], [0.65, 0.08],
        [0.80, 0.04], [0.90, 0.12], [0.55, 0.15], [0.70, 0.20],
      ];
      for (final s in stars) {
        canvas.drawCircle(Offset(size.width * s[0], size.height * s[1]), 1.5, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SunsetPainter old) => false;
}

// ════════════════════════════════════════════════════
// ГАЛАКТИКА ФОНУ
// ════════════════════════════════════════════════════
class _GalaxyBackground extends StatelessWidget {
  const _GalaxyBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GalaxyPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Фон
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [const Color(0xFF1A0845), const Color(0xFF0D0221)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Жылдыздар
    final stars = [
      [0.05,0.10,1.5],[0.15,0.05,1.0],[0.25,0.18,2.0],[0.35,0.08,1.2],
      [0.50,0.03,1.8],[0.60,0.12,1.0],[0.72,0.07,2.2],[0.85,0.15,1.5],
      [0.92,0.04,1.0],[0.10,0.30,1.3],[0.20,0.42,1.8],[0.40,0.25,1.0],
      [0.55,0.35,2.5],[0.70,0.28,1.2],[0.88,0.38,1.8],[0.03,0.55,1.0],
      [0.18,0.65,2.0],[0.32,0.58,1.5],[0.48,0.70,1.0],[0.65,0.62,2.2],
      [0.80,0.55,1.3],[0.95,0.65,1.8],[0.08,0.80,1.5],[0.22,0.88,1.0],
      [0.42,0.82,2.0],[0.58,0.90,1.2],[0.75,0.85,1.8],[0.90,0.78,1.0],
      [0.30,0.72,1.5],[0.62,0.45,1.0],[0.78,0.42,2.0],[0.45,0.50,1.3],
    ];
    for (final s in stars) {
      final opacity = 0.4 + (s[2] / 3.0) * 0.6;
      final starPaint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(size.width * s[0], size.height * s[1]), s[2], starPaint);
    }

    // Галактика туманы
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.3),
        colors: [
          const Color(0xFF9C27B0).withOpacity(0.15),
          const Color(0xFF3F51B5).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebulaPaint);

    final nebula2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, 0.5),
        colors: [
          const Color(0xFF00BCD4).withOpacity(0.12),
          const Color(0xFF1976D2).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula2);

    // Сызык жылдыздар
    final shootPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width * 0.20, size.height * 0.10),
        Offset(size.width * 0.35, size.height * 0.22),
        shootPaint);
    canvas.drawLine(
        Offset(size.width * 0.70, size.height * 0.05),
        Offset(size.width * 0.80, size.height * 0.15),
        shootPaint);
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) => false;
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