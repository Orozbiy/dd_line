import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/supabase_client.dart';
import '../../../data/models/product_model.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class _StoreLocation {
  final String id;
  final String shopName;
  final String ownerName;
  final String containerNumber;
  final double? latitude;
  final double? longitude;
  final String ownerId;

  _StoreLocation({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.containerNumber,
    this.latitude,
    this.longitude,
    this.ownerId = '',
  });

  factory _StoreLocation.fromMap(Map<String, dynamic> data) {
    final profile   = data['profiles'] as Map<String, dynamic>?;
    final container = [
      data['market']   as String? ?? '',
      data['district'] as String? ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    return _StoreLocation(
      id:              data['id']         as String? ?? '',
      shopName:        data['store_name'] as String? ?? '',
      ownerName:       profile?['full_name'] as String? ?? '',
      containerNumber: container,
      latitude:        (data['latitude']  as num?)?.toDouble(),
      longitude:       (data['longitude'] as num?)?.toDouble(),
      ownerId:         data['owner_id']   as String? ?? '',
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<_StoreLocation> _sellers  = [];
  List<_StoreLocation> _filtered = [];
  _StoreLocation? _selectedSeller;
  bool _isLoading       = true;
  int  _noLocationCount = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    try {
      final data = await supabase
          .from('stores')
          .select('*, profiles!inner(full_name, seller_status)')
          .eq('is_active', true)
          .eq('profiles.seller_status', 'approved');

      final all = (data as List)
          .cast<Map<String, dynamic>>()
          .map((row) => _StoreLocation.fromMap(row))
          .toList();

      final withLocation =
          all.where((s) => s.latitude != null && s.longitude != null).toList();
      final noLocation =
          all.where((s) => s.latitude == null || s.longitude == null).length;

      setState(() {
        _sellers         = withLocation;
        _filtered        = withLocation;
        _noLocationCount = noLocation;
        _isLoading       = false;
      });
    } catch (e) {
      debugPrint('❌ _loadSellers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = _sellers
          .where((s) =>
              s.shopName.toLowerCase().contains(query.toLowerCase()) ||
              s.containerNumber.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _open2GIS(_StoreLocation seller) async {
    final loc = AppLocalizations.of(context);
    final lat = seller.latitude!;
    final lng = seller.longitude!;

    final appUri       = Uri.parse('dgis://2gis.ru/routeSearch/rsType/pedestrian/to/$lng,$lat');
    final playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=ru.dublgis.dgismobile');
    final appStoreUri  = Uri.parse('https://apps.apple.com/app/id481627348');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      if (!mounted) return;
      final isIOS    = Theme.of(context).platform == TargetPlatform.iOS;
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
              child: Text(loc.get('no')),
            ),
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

  void _openStoreProducts(_StoreLocation seller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StoreProductsScreen(
          storeId: seller.id,
          shopName: seller.shopName,
          containerNumber: seller.containerNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputBg   = isDark ? const Color(0xFF2C2C2C) : AppColors.grey100;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Container(
              color: cardColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(' ${loc.get('map_title')}', style: AppTextStyles.headingMedium),
                      const Spacer(),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_sellers.length} ${loc.get('map_store_count')}',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: _search,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: loc.get('map_search_hint'),
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
                      prefixIcon: const Icon(Icons.search, color: AppColors.grey400, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () { _searchController.clear(); _search(''); },
                              child: const Icon(Icons.close, color: AppColors.grey400, size: 18),
                            )
                          : null,
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Тизме ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? _buildEmpty(loc)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildSellerCard(_filtered[i], loc, isDark, cardColor),
                        ),
            ),

            // ── Статистика ──
            if (!_isLoading && _noLocationCount > 0)
              Container(
                color: cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 6),
                    Text(
                      '$_noLocationCount ${loc.get('map_no_location')}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(loc.get('map_not_found'), style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(loc.get('map_try_search'),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
        ],
      ),
    );
  }

  Widget _buildSellerCard(_StoreLocation seller, AppLocalizations loc, bool isDark, Color cardColor) {
    final isSelected   = _selectedSeller?.id == seller.id;
    final dividerColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return GestureDetector(
      onTap: () => setState(() => _selectedSeller = isSelected ? null : seller),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      seller.shopName.isNotEmpty ? seller.shopName[0].toUpperCase() : '🏪',
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seller.shopName,
                          style: AppTextStyles.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              seller.containerNumber.isNotEmpty
                                  ? seller.containerNumber
                                  : loc.get('location_unknown'),
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('📍'),
                ),
              ],
            ),

            if (isSelected) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 12),
              if (seller.ownerName.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(seller.ownerName,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // ── Эки кнопка ──
              Row(
                children: [
                  // Дүкөндү көрүү
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _openStoreProducts(seller),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                        label: Text(
                          loc.locale.languageCode == 'ru' ? 'Товары' : 'Товарлар',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Маршрут
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _open2GIS(seller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                        label: Text(
                          loc.get('open_2gis'),
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ДҮКӨНДҮН ТОВАРЛАРЫ ЭКРАНЫ
// ══════════════════════════════════════════════════════
class _StoreProductsScreen extends StatefulWidget {
  final String storeId;
  final String shopName;
  final String containerNumber;

  const _StoreProductsScreen({
    required this.storeId,
    required this.shopName,
    required this.containerNumber,
  });

  @override
  State<_StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<_StoreProductsScreen> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: textColor),
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
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏪', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        loc.locale.languageCode == 'ru'
                            ? 'Товаров пока нет'
                            : 'Азырынча товар жок',
                        style: AppTextStyles.headingSmall,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: _products[i],
                    isDark: isDark,
                    cardColor: cardColor,
                    loc: loc,
                  ),
                ),
    );
  }
}

// ── Товар карточкасы ──
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final Color cardColor;
  final AppLocalizations loc;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.cardColor,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final cur = loc.get('currency');
    final hasDiscount = product.discountedPrice != null &&
        product.discountedPrice! < product.price;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Сүрөт ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: isDark ? const Color(0xFF2C2C2C) : AppColors.grey100,
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 140,
                  color: isDark ? const Color(0xFF2C2C2C) : AppColors.grey100,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.grey400),
                ),
              ),
            ),
            // ── Маалымат ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
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
            ),
          ],
        ),
      ),
    );
  }
}
