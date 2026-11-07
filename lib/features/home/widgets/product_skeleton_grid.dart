import 'package:flutter/material.dart';

/// Товарлар жүктөлүп жатканда спиннердин ордуна көрүнүүчү товар орундары
/// (2 мамычалуу). Жумшак пульсация менен — айлануу жок.
class ProductSkeletonGrid extends StatefulWidget {
  final int rows;
  const ProductSkeletonGrid({super.key, this.rows = 4});

  @override
  State<ProductSkeletonGrid> createState() => _ProductSkeletonGridState();
}

class _ProductSkeletonGridState extends State<ProductSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF14162A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2560) : const Color(0xFFEAEAEA);
    final blockColor = isDark ? const Color(0xFF1E2040) : const Color(0xFFE8E8E8);

    Widget card() => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(color: blockColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(blockColor, widthFactor: 0.85, height: 14),
                      const SizedBox(height: 10),
                      _bar(blockColor, widthFactor: 0.5, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final opacity = 0.45 + 0.45 * _pulse.value;
        return Opacity(
          opacity: opacity,
          child: Column(
            children: List.generate(widget.rows, (_) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card()),
                    const SizedBox(width: 9),
                    Expanded(child: card()),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _bar(Color color, {required double widthFactor, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
