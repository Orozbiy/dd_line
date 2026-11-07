import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer_loading.dart';

/// Товарлар жүктөлүп жатканда спиннердин ордуна көрүнүүчү товар орундары
/// (2 мамычалуу). Ар бир карточканын ичинде 45° жарык сызыгы жылып турат.
class ProductSkeletonGrid extends StatelessWidget {
  final int rows;
  const ProductSkeletonGrid({super.key, this.rows = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockColor = isDark ? const Color(0xFF2A2D55) : const Color(0xFFDADADA);

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    Widget card() => AspectRatio(
          aspectRatio: 0.68,
          child: ShimmerLoading(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                const Expanded(
                  flex: 7,
                  child: SizedBox.expand(),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        bar(0.85, 13),
                        const SizedBox(height: 9),
                        bar(0.5, 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      children: List.generate(rows, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Expanded(child: card()),
              const SizedBox(width: 9),
              Expanded(child: card()),
            ],
          ),
        );
      }),
    );
  }
}
