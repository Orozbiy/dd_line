import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/supabase_client.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/product_model.dart';
class StoreProductsScreen extends StatefulWidget {
  final String storeId;
  final String shopName;
  final String containerNumber;
  final double? latitude;
  final double? longitude;
  final String ownerName;
  final String? avatarUrl;
  final Widget Function(ProductModel product)? productBuilder;

  const StoreProductsScreen({
    super.key,
    required this.storeId,
    required this.shopName,
    this.containerNumber = '',
    this.ownerName = '',
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.productBuilder,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select('*, stores(*)')
          .eq('store_id', widget.storeId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final list = (data as List)
          .cast<Map<String, dynamic>>()
          .map((row) => ProductModel.fromMap(row))
          .toList();

      if (mounted) setState(() { _products = list; _isLoading = false; });
    } catch (e) {
      debugPrint('❌ _loadProducts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isRu   = loc.locale.languageCode == 'ru';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.30)
                  : Colors.white.withOpacity(0.50),
            ),
          ),
        ),
        foregroundColor: textColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.shopName,
                style: AppTextStyles.headingSmall.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (widget.containerNumber.isNotEmpty)
              Text('📍 ${widget.containerNumber}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // ── Сатуучу карточкасы ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                      12,
                      8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Row(
                            children: [
                              // Аватар
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                                      ? const LinearGradient(
                                          colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD97706).withOpacity(0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(widget.avatarUrl!)
                                      : null,
                                  child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                                      ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Маалымат
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isRu ? 'Магазин' : 'Дүкөн',
                                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
                                    ),
                                    Text(
                                      widget.shopName,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.ownerName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        isRu ? 'Продавец' : 'Сатуучу',
                                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
                                      ),
                                      Text(
                                        widget.ownerName,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (widget.containerNumber.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                            const SizedBox(width: 3),
                                            Text(
                                              widget.containerNumber,
                                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Товар саны + Маршрут
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_products.length}',
                                          style: AppTextStyles.headingSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          isRu ? 'товар' : 'товар',
                                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.latitude != null && widget.longitude != null) {
                                        showModalBottomSheet(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          builder: (_) => _NavigationGuideSheet(
                                            shopName: widget.shopName,
                                            containerNumber: widget.containerNumber,
                                            sellerLat: widget.latitude!,
                                            sellerLng: widget.longitude!,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isRu ? 'Координаты не указаны' : 'Координаттар жок')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD97706).withOpacity(0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                                          const SizedBox(height: 2),
                                          Text(
                                            isRu ? 'Маршрут' : 'Маршрут',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Товарлар ──
                if (_products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏪', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            isRu ? 'Товаров пока нет' : 'Азырынча товар жок',
                            style: AppTextStyles.headingSmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, rowIndex) {
                          final left  = rowIndex * 2;
                          final right = left + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ProductCard(
                                    product: _products[left],
                                    isDark: isDark,
                                    loc: loc,
                                    productBuilder: widget.productBuilder,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: right < _products.length
                                      ? _ProductCard(
                                          product: _products[right],
                                          isDark: isDark,
                                          loc: loc,
                                          productBuilder: widget.productBuilder,
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: (_products.length / 2).ceil(),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final AppLocalizations loc;
  final Widget Function(ProductModel)? productBuilder;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.loc,
    this.productBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cur = loc.get('currency');
    final hasDiscount = product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    return GestureDetector(
      onTap: () {
        final screen = productBuilder?.call(product);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.85),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: toCloudinaryThumb(product.imageUrl, width: 400),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    fadeInDuration: const Duration(milliseconds: 120),
                    placeholder: (_, __) => Container(
                      height: 140,
                      color: isDark ? const Color(0xFF2C2C2C) : AppColors.grey100,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: isDark ? const Color(0xFF2C2C2C) : AppColors.grey100,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.grey400),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasDiscount) ...[
                        Text(
                          '${product.discountedPrice!.toStringAsFixed(0)} $cur',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${product.price.toStringAsFixed(0)} $cur',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.grey400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${product.price.toStringAsFixed(0)} $cur',
                          style: AppTextStyles.labelLarge.copyWith(
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
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// NAVIGATION GUIDE SHEET (2GIS)
// ══════════════════════════════════════════════════════
class _NavigationGuideSheet extends StatefulWidget {
  final String shopName;
  final String containerNumber;
  final double sellerLat;
  final double sellerLng;

  const _NavigationGuideSheet({
    required this.shopName,
    required this.containerNumber,
    required this.sellerLat,
    required this.sellerLng,
  });

  @override
  State<_NavigationGuideSheet> createState() => _NavigationGuideSheetState();
}

class _NavigationGuideSheetState extends State<_NavigationGuideSheet> {
  Future<void> _open2GIS() async {
    final loc = AppLocalizations.of(context);
    final appUri = Uri.parse(
        'dgis://2gis.ru/routeSearch/rsType/pedestrian/to/${widget.sellerLng},${widget.sellerLat}');
    final playStoreUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=ru.dublgis.dgismobile');
    final appStoreUri = Uri.parse('https://apps.apple.com/app/id481627348');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      if (!mounted) return;
      final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
      final storeUri = isIOS ? appStoreUri : playStoreUri;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(loc.get('2gis_not_installed')),
          content: Text(loc.get('2gis_download_hint')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.get('no'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (await canLaunchUrl(storeUri)) {
                  await launchUrl(storeUri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(loc.get('download'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final stepBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
    final stepBorder = isDark ? const Color(0xFF3A3A3A) : Colors.grey[200]!;
    final handleColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey[300]!;

    return Container(
      color: sheetBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: handleColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
                widget.shopName.isNotEmpty ? widget.shopName : '',
                style: AppTextStyles.headingSmall,
                textAlign: TextAlign.center),
            if (widget.containerNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('📍 ${widget.containerNumber}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: stepBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: stepBorder)),
              child: Column(children: [
                _step('1', loc.get('nav_step1')),
                const SizedBox(height: 10),
                _step('2', loc.get('nav_step2')),
                const SizedBox(height: 10),
                _step('3', loc.get('nav_step3')),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _open2GIS,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: Text(loc.get('open_2gis'),
                    style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Row(children: [
      Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(num,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
    ]);
  }
}