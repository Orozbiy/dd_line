import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 45° диагоналдык пайда болуу анимациясы.
///
/// Элемент төмөнкү-оң бурчтан өз ордуна 45° бурч менен жылып келет жана
/// ошол эле учурда тунуктан көрүнүккө өтөт.
///
/// [revealId] берилсе — ошол id үчүн анимация бир жолу гана ойнойт
/// (тизме скролл болуп виджет кайра курулганда кайталанбайт).
/// Жаңы тизме жүктөлгөндө [DiagonalReveal.resetPlayed] чакырылат.
class DiagonalReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Жылуу аралыгы (логикалык пиксель).
  final double distance;

  /// Жылуу бурчу (градус). 45 = төмөнкү-оң бурчтан.
  final double angleDeg;
  final String? revealId;

  const DiagonalReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.distance = 56,
    this.angleDeg = 45,
    this.revealId,
  });

  static final Set<String> _played = <String>{};

  /// Жаңы маалымат жүктөлгөндө бардык элементтер кайра анимацияланышы үчүн.
  static void resetPlayed() => _played.clear();

  @override
  State<DiagonalReveal> createState() => _DiagonalRevealState();
}

class _DiagonalRevealState extends State<DiagonalReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

    final id = widget.revealId;
    if (id != null && DiagonalReveal._played.contains(id)) {
      _c.value = 1; // мурда ойногон — түз көрсөтөбүз
      return;
    }
    if (id != null) DiagonalReveal._played.add(id);

    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rad = widget.angleDeg * math.pi / 180.0;
    final dx = math.cos(rad) * widget.distance;
    final dy = math.sin(rad) * widget.distance;

    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        final inv = 1.0 - v;
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(dx * inv, dy * inv),
            child: child,
          ),
        );
      },
    );
  }
}
