import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';

class ShareWidget {
  static void show(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareBottomSheet(product: product),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final ProductModel product;

  const _ShareBottomSheet({required this.product});

  void _shareToApp(BuildContext context, String appName) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$appName га жөнөтүлдү! ✅'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = [
      {'name': 'WhatsApp', 'icon': '💬', 'color': '0xFF25D366'},
      {'name': 'Telegram', 'icon': '✈️', 'color': '0xFF0088CC'},
      {'name': 'Instagram', 'icon': '📸', 'color': '0xFFE1306C'},
      {'name': 'Facebook', 'icon': '👤', 'color': '0xFF1877F2'},
      {'name': 'SMS', 'icon': '📱', 'color': '0xFF34C759'},
      {'name': 'Башкалар', 'icon': '⋯', 'color': '0xFF8E8E93'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Бөлүшүү', style: AppTextStyles.headingMedium),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56, color: AppColors.grey100,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.grey300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(product.priceFormatted, style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: apps.map((app) {
              final color = Color(int.parse(app['color']!));
              return GestureDetector(
                onTap: () => _shareToApp(context, app['name']!),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(app['icon']!, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(app['name']!, style: AppTextStyles.labelMedium),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔗 Шилтеме көчүрүлдү!'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Шилтемени көчүрүү', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
