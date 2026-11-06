import 'package:flutter/material.dart';

/// Lalafo/iOS стилиндеги shimmer эффект — 45° бурчта жылуучу жарык сызык.
/// Сүрөттөр жана карточкалар жүктөлүп жатканда placeholder катары колдонулат.
class ShimmerLoading extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF1E2040)
        : const Color(0xFFE8E8E8);
    final highlightColor = isDark
        ? const Color(0xFF2A2D55)
        : const Color(0xFFF5F5F5);

    final v = _controller.value;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          // 45° бурч — солдон оңго, жогорудан ылдыйга
          begin: const Alignment(-1.0, -0.5),
          end: const Alignment(1.0, 0.5),
          colors: [
            baseColor,
            baseColor,
            highlightColor,
            baseColor,
            baseColor,
          ],
          stops: [
            0.0,
            (v - 0.3).clamp(0.0, 1.0),
            v,
            (v + 0.3).clamp(0.0, 1.0),
            1.0,
          ],
        ),
      ),
    );
  }
}
