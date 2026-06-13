import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  final _favorites = FavoritesManager();
  late AnimationController _heartController;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    _favorites.toggle(widget.product);
    _heartController.forward().then((_) => _heartController.reverse());
    setState(() {});
  }

  String _thumbUrl(String url) {
    if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/w_400,q_auto,f_auto/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isFav = _favorites.isFavorite(widget.product.id);
    final rating = widget.product.rating ?? 0.0;
    final hasDiscount = widget.product.hasPromotion &&
        widget.product.discountedPrice != null &&
        widget.product.discountedPrice! < widget.product.price;
    final discountPct = hasDiscount
        ? ((1 - widget.product.discountedPrice! / widget.product.price) * 100)
            .round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Сүрөт ──
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: _thumbUrl(widget.product.imageUrl),
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, __) => Container(
                        color: AppColors.grey100,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.grey300),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.grey100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.grey300,
                          size: 36,
                        ),
                      ),
                    ),

                    // ── Скидка badge (сол жогору) ──
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-$discountPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                    // ── Жүрөк баскычы (оң жогору) ──
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: ScaleTransition(
                          scale: _heartAnim,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? AppColors.error.withValues(alpha: 0.12)
                                  : AppColors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color:
                                  isFav ? AppColors.error : AppColors.grey400,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Маалымат ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аты
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),

                  // Рейтинг
                  if (rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),

                  // Баа
                  if (hasDiscount) ...[
                    Row(
                      children: [
                        Text(
                          '${widget.product.discountedPrice!.toStringAsFixed(0)} с',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '-$discountPct%',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.priceFormatted,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey400,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.grey400,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ] else
                    Text(
                      widget.product.priceFormatted,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
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