import 'package:dd_online/data/models/product_model.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart' show AppColors;
import '../../../config/theme/app_text_styles.dart' show AppTextStyles;

class PromoProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const PromoProductCard({super.key, required this.product, this.onTap});

  // _discountPct getter да:
int get _discountPct {
  final disc = (product.discountedPrice as num?)?.toDouble();
  if (disc == null || product.price == 0) return 0;
  return ((1 - disc / product.price) * 100).round();
}

 double? get _discountedPrice => (product.discountedPrice as num?)?.toDouble();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: AppColors.grey100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.grey400),
                      ),
                    ),
                  ),
                ),
                if (_discountPct > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-$_discountPct%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} сом',
                    style: AppTextStyles.bodySmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.grey400,
                      color: AppColors.grey400,
                      decorationThickness: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_discountedPrice ?? product.price).toStringAsFixed(0)} сом',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}