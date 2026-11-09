import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Жүктөлүп жатканда көрүнгөн placeholder: 45° бурчка оодарылган жарык сызыгы
/// солдон оңго жылып өтүп турат.
/// Сүрөттөр жана карточкалар жүктөлүп жатканда колдонулат.
class ShimmerLoading extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E2040) : const Color(0xFFE8E8E8);
    final sheen = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.white.withOpacity(0.75);

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: baseColor),
            if (widget.child != null) widget.child!,
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _SheenPainter(_controller.value, sheen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  final double t;
  final Color color;
  _SheenPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final c = rect.center;
    // Сызык толугу менен сол жактан чыгып, оң жакка өтүп кетет
    final travel = (size.width + size.height) / 2 + size.width * 0.35;
    final dx = (t * 2 - 1) * travel;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.transparent, color, Colors.transparent],
      stops: const [0.42, 0.5, 0.58],
      // 45° бурчка бурабыз, андан соң горизонталдуу жылдырабыз
      transform: _SheenTransform(c, dx),
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t || old.color != color;
}

class _SheenTransform extends GradientTransform {
  final Offset center;
  final double dx;
  const _SheenTransform(this.center, this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0)
      ..translate(center.dx, center.dy)
      ..rotateZ(math.pi / 4)
      ..translate(-center.dx, -center.dy);
  }
}
