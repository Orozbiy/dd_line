import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/supabase_client.dart';
import '../../../data/models/product_model.dart';
import '../../product_detail/screens/product_detail_screen.dart';

// Cloudinary URL — сапаты 80%, кичине размер
String _thumbUrl(String url, {int width = 280}) {
  if (url.isEmpty) return url;
  if (!url.contains('cloudinary')) return url;
  return url.replaceFirst(
    '/upload/',
    '/upload/w_$width,q_80,f_auto/',
  );
}

class SimilarProductsSection extends StatefulWidget {
  final List<ProductModel> initialProducts;
  final String currentProductId;
  final String? categoryId;

  const SimilarProductsSection({
    super.key,
    required this.initialProducts,
    required this.currentProductId,
    this.categoryId,
  });

  @override
  State<SimilarProductsSection> createState() => _SimilarProductsSectionState();
}

class _SimilarProductsSectionState extends State<SimilarProductsSection> {
  final List<ProductModel> _products = [];
  bool _loading = false;
  bool _noMore = false;
  int _page = 0;
  static const int _pageSize = 6;

  @override
  void initState() {
    super.initState();
    _products.addAll(widget.initialProducts);
    if (_products.length < 4) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _noMore) return;
    setState(() => _loading = true);

    try {
      final existingIds = [
        widget.currentProductId,
        ..._products.map((p) => p.id),
      ];

      List<dynamic> data = [];

      // 1. Адегенде окшош категориядагы товарлар
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        data = await supabase
            .from('products')
            .select('*, stores(store_name)')
            .eq('category_id', widget.categoryId!)
            .eq('is_active', true)
            .not('id', 'in', '(${existingIds.join(',')})')
            .range(_page * _pageSize, (_page + 1) * _pageSize - 1);
      }

      // 2. Окшош товар жок болсо — башка каалаган товарлар
      if (data.isEmpty) {
        data = await supabase
            .from('products')
            .select('*, stores(store_name)')
            .eq('is_active', true)
            .not('id', 'in', '(${existingIds.join(',')})')
            .order('views_count', ascending: false)
            .range(0, _pageSize - 1);
      }

      final newItems = (data)
          .cast<Map<String, dynamic>>()
          .map((row) => ProductModel.fromMap(row))
          .toList();

      if (mounted) {
        setState(() {
          _products.addAll(newItems);
          _page++;
          if (newItems.length < _pageSize) _noMore = true;
        });
      }
    } catch (e) {
      debugPrint('SimilarProductsSection _loadMore: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && !_loading) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Аталыш ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            loc.locale.languageCode == 'ru' ? 'Похожие товары' : 'Окшош товарлар',
            style: AppTextStyles.headingMedium,
          ),
        ),

        // ── 2 колонкалуу GRID ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              // Акыркы карточкага жеткенде кошумча жүктө
              if (i == _products.length - 2 && !_loading && !_noMore) {
                _loadMore();
              }
              return _SimilarProductCard(
                product: _products[i],
                isDark: isDark,
                cur: loc.get('currency'),
              );
            },
          ),
        ),

        // ── Жүктөлүп жатат индикатор ──
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Жеке карточка ──
class _SimilarProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final String cur;

  const _SimilarProductCard({
    required this.product,
    required this.isDark,
    required this.cur,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasPromotion &&
        product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    final cardColor = isDark ? const Color(0xFF1A1C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2C3E) : const Color(0xFFE5E7EB);
    final placeholderColor =
        isDark ? const Color(0xFF23253A) : const Color(0xFFF3F4F6);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Сүрөт ──
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _thumbUrl(product.imageUrl),
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 120),
                    placeholder: (_, __) =>
                        Container(color: placeholderColor),
                    errorWidget: (_, __, ___) => Container(
                      color: placeholderColor,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.grey300),
                    ),
                  ),
                  // Скидка badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${((1 - product.discountedPrice! / product.price) * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Маалымат ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium
                        .copyWith(height: 1.3, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  if (hasDiscount) ...[
                    Text(
                      '${product.discountedPrice!.toStringAsFixed(0)} $cur',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${product.price.toStringAsFixed(0)} $cur',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey400,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.grey400,
                      ),
                    ),
                  ] else
                    Text(
                      '${product.price.toStringAsFixed(0)} $cur',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary, fontSize: 14),
                    ),
                  if ((product.rating ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        product.rating!.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.grey500, fontSize: 13),
                      ),
                      if ((product.ratingCount ?? 0) > 0)
                        Text(
                          ' (${product.ratingCount})',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.grey400, fontSize: 13),
                        ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}