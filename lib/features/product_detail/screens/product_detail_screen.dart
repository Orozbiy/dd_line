import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/supabase_client.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../widgets/review_section.dart';
import '../widgets/share_widget.dart';
import '../../cart/screens/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _fav = FavoritesManager();
  final _chatService = ChatService();

  bool _chatLoading = false;
  bool _dataLoading = true;
  String selectedSize = '';

  late ProductModel _product;
  String? _sellerUid; // stores.owner_id
  String? _storeId; // stores.id
  String _sellerName = '';
  String _shopName = '';
  String _containerNumber = '';
  List<ProductModel> _similarProducts = [];

  // Категориялар статикалык бойдон калат (CategoryModel'ден алынса да болот)
  static const _categoryNames = {
    '1': 'Кийим-кече',
    '2': 'Бут кийим',
    '3': 'Аксессуарлар',
    '4': 'Электроника',
    '5': 'Үй буюмдар',
    '6': 'Спорт',
    '7': 'Балдар',
    '8': 'Сулуулук',
    '9': 'Азык-түлүк',
    '10': 'Автотовар',
    '11': 'Китептер',
    '12': 'Оюнчуктар',
  };

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadFullProductData();
  }

  /// Товар + дүкөн (stores) маалыматын Supabase'тен жаңыртуу.
  Future<void> _loadFullProductData() async {
    try {
      final data = await supabase
          .from('products')
          .select('*, stores(*)')
          .eq('id', widget.product.id)
          .single();

      if (mounted) {
        setState(() => _product = ProductModel.fromMap(data));

        final storeData = data['stores'] as Map<String, dynamic>?;
        if (storeData != null) {
          setState(() {
            _storeId = storeData['id'] as String?;
            _sellerUid = storeData['owner_id'] as String?;
            _shopName = storeData['store_name'] as String? ?? '';
            // "Контейнер номери" катары дүкөндүн районун көрсөтөбүз
            _containerNumber = [
              storeData['market'] as String? ?? '',
              storeData['district'] as String? ?? '',
            ].where((s) => s.isNotEmpty).join(', ');
          });

          // Сатуучунун (profiles) атын алуу
          if (_sellerUid != null) {
            try {
              final profile = await supabase
                  .from('profiles')
                  .select('full_name')
                  .eq('id', _sellerUid!)
                  .single();
              if (mounted) {
                setState(
                    () => _sellerName = profile['full_name'] as String? ?? '');
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('❌ _loadFullProductData: $e');
    } finally {
      await _loadSimilarProducts();
      if (mounted) setState(() => _dataLoading = false);
    }
  }

  /// Окшош товарларды category_id боюнча жүктөө.
  Future<void> _loadSimilarProducts() async {
    if (_product.category == null || _product.category!.isEmpty) return;
    try {
      final data = await supabase
          .from('products')
          .select('*, stores(store_name, owner_id)')
          .eq('category_id', _product.category!)
          .eq('is_active', true)
          .limit(10);

      final list = (data as List)
          .cast<Map<String, dynamic>>()
          .where((row) => row['id'] != _product.id)
          .map((row) => ProductModel.fromMap(row))
          .toList();

      if (mounted) setState(() => _similarProducts = list);
    } catch (e) {
      debugPrint('_loadSimilarProducts: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // КАРТА НАВИГАЦИЯ — 2ГИС bottom sheet
  // ══════════════════════════════════════════════════════
  Future<void> _openMapNavigation() async {
    // Уруксат + GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnack('📍 Уруксат бериңиз');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) await Geolocator.openAppSettings();
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Алгач _product'тогу координатты колдонобуз (эгер бар болсо)

    double? sellerLat = _product.latitude;
    double? sellerLng = _product.longitude;
    debugPrint('1) product lat=$sellerLat lng=$sellerLng');

    if (sellerLat == null || sellerLng == null) {
      String? storeId = _storeId;
      debugPrint('2) _storeId=$storeId');

      if (storeId == null) {
        try {
          final row = await supabase
              .from('products')
              .select('store_id')
              .eq('id', _product.id)
              .single();
          storeId = row['store_id'] as String?;
          debugPrint('3) products.store_id=$storeId');
        } catch (e) {
          debugPrint('❌ store_id алуу: $e');
        }
      }

      if (storeId != null) {
        setState(() => _dataLoading = true);
        try {
          final store = await supabase
              .from('stores')
              .select('latitude, longitude')
              .eq('id', storeId)
              .single();
          debugPrint('4) stores row=$store');
          sellerLat = (store['latitude'] as num?)?.toDouble();
          sellerLng = (store['longitude'] as num?)?.toDouble();
        } catch (e) {
          debugPrint('❌ stores lat/lng алуу: $e');
        }
        if (!mounted) return;
        setState(() => _dataLoading = false);
      }
    }
    debugPrint('5) final lat=$sellerLat lng=$sellerLng');
    if (sellerLat == null || sellerLng == null) {
      if (mounted) _showSnack('Сатуучунун картадагы жери белгисиз');
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NavigationGuideSheet(
        shopName: _shopName,
        containerNumber: _containerNumber,
        sellerLat: sellerLat!,
        sellerLng: sellerLng!,
      ),
    );
  }

  Future<void> _openChat() async {
    if (_sellerUid == null || _sellerUid!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Сатуучу маалыматы жок!'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Чат үчүн кирүү керек!'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    if (user.id == _sellerUid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Бул сиздин өз товарыңыз!'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() => _chatLoading = true);
    try {
      final chatId = await _chatService.getOrCreateChat(
        buyerId: user.id,
        sellerId: _sellerUid!,
        productId: _product.id,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            sellerName: _shopName.isNotEmpty ? _shopName : _sellerName,
            productName: _product.name,
            productImage: _product.imageUrl,
            isSeller: false,
            buyerId: user.id,
            sellerId: _sellerUid!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ката: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPriceSection() {
    final hasDiscount = _product.discountedPrice != null &&
        _product.discountedPrice! < _product.price;

    if (hasDiscount) {
      final discounted = _product.discountedPrice!;
      final pct = ((1 - discounted / _product.price) * 100).round();
      final saved = (_product.price - discounted).toStringAsFixed(0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${discounted.toStringAsFixed(0)} сом',
                style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${_product.price.toStringAsFixed(0)} сом',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey400,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.grey400,
                  decorationThickness: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$saved сомго арзан',
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ],
      );
    }

    return Text(
      '${_product.price.toStringAsFixed(0)} сом',
      style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav = _fav.isFavorite(_product.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.black),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  _fav.toggle(_product);
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : AppColors.grey600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ShareWidget.show(context, _product),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.share_outlined, color: AppColors.grey600),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _product.imageUrl.isNotEmpty
                  ? GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          barrierColor: Colors.black,
                          transitionDuration:
                              const Duration(milliseconds: 250),
                          pageBuilder: (_, __, ___) =>
                              _FullscreenImageScreen(
                            imageUrl: _product.imageUrl,
                            heroTag: 'product_image_${_product.id}',
                          ),
                        ),
                      ),
                      child: Hero(
                        tag: 'product_image_${_product.id}',
                        child: Image.network(
                          _product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.grey100,
                            child: const Icon(Icons.image_not_supported,
                                size: 80, color: AppColors.grey300),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.grey100,
                      child: const Icon(Icons.image,
                          size: 80, color: AppColors.grey300),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _dataLoading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPriceSection(),
                            const SizedBox(height: 8),
                            Text(_product.name,
                                style: AppTextStyles.headingMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _categoryNames[_product.category] ??
                                        'Башка',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if ((_product.rating ?? 0) > 0) ...[
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    _product.rating!.toStringAsFixed(1),
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  if ((_product.ratingCount ?? 0) > 0)
                                    Text(
                                      ' (${_product.ratingCount})',
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: AppColors.grey400),
                                    ),
                                ],
                                const Spacer(),
                                if (_product.distanceFormatted.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          _product.distanceFormatted,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCharacteristics(),
                      const SizedBox(height: 8),
                      if (_product.description != null &&
                          _product.description!.isNotEmpty) ...[
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Сүрөттөмө',
                                  style: AppTextStyles.headingSmall),
                              const SizedBox(height: 8),
                              Text(_product.description!,
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_product.sizes.isNotEmpty) ...[
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Размер тандаңыз',
                                  style: AppTextStyles.headingSmall),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _product.sizes.map((size) {
                                  final isSel = selectedSize == size;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => selectedSize = size),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? AppColors.primary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel
                                              ? AppColors.primary
                                              : AppColors.grey200,
                                        ),
                                      ),
                                      child: Text(
                                        size,
                                        style:
                                            AppTextStyles.labelLarge.copyWith(
                                          color: isSel
                                              ? Colors.white
                                              : AppColors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Сатуучу',
                                style: AppTextStyles.headingSmall),
                            const SizedBox(height: 12),
                            if (_shopName.isNotEmpty) ...[
                              _infoRow(
                                  Icons.store_outlined, 'Дүкөн', _shopName),
                              const SizedBox(height: 8),
                            ],
                            if (_sellerName.isNotEmpty) ...[
                              _infoRow(
                                  Icons.person_outline, 'Сатуучу', _sellerName),
                              const SizedBox(height: 8),
                            ],
                            if (_containerNumber.isNotEmpty)
                              _infoRow(
                                Icons.location_on_outlined,
                                'Жайгашкан жери',
                                _containerNumber,
                                valueColor: AppColors.primary,
                              ),
                            if (_shopName.isEmpty && _sellerName.isEmpty)
                              Text('Маалымат жок',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.grey500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_sellerUid != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _chatLoading ? null : _openChat,
                              icon: _chatLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary))
                                  : const Icon(Icons.chat_bubble_outline,
                                      color: AppColors.primary),
                              label: Text('Сатуучуга жазуу',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_similarProducts.isNotEmpty)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Окшош товарлар',
                                  style: AppTextStyles.headingSmall),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _similarProducts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, i) {
                                    final p = _similarProducts[i];
                                    final pHasDiscount = p.hasPromotion &&
                                        p.discountedPrice != null &&
                                        p.discountedPrice! < p.price;
                                    return GestureDetector(
                                      onTap: () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailScreen(product: p),
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                p.imageUrl,
                                                height: 140,
                                                width: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  height: 140,
                                                  color: AppColors.grey100,
                                                  child: const Icon(Icons
                                                      .image_not_supported),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            if (pHasDiscount) ...[
                                              Text(
                                                '${p.discountedPrice!.toStringAsFixed(0)} сом',
                                                style: AppTextStyles.labelLarge
                                                    .copyWith(
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${p.price.toStringAsFixed(0)} сом',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color: AppColors.grey400,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ] else
                                              Text(
                                                '${p.price.toStringAsFixed(0)} сом',
                                                style: AppTextStyles.labelLarge
                                                    .copyWith(
                                                        color:
                                                            AppColors.primary),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ReviewSection(productId: _product.id),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Себет экранына өтүү (кичине квадрат) ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.primary),
                tooltip: 'Себет',
              ),
            ),
            const SizedBox(width: 12),
            // ── Навигация (чоң, мурунку себетке кошуу ордунда) ──
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openMapNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon:
                      const Icon(Icons.navigation_rounded, color: Colors.white),
                  label: Text(
                    'Маршрут түзүү',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristics() {
    final hasColors = _product.colors.isNotEmpty;
    if (!hasColors) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Характеристикалар', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          Text('🎨 Жеткиликтүү түстөр',
              style:
                  AppTextStyles.labelMedium.copyWith(color: AppColors.grey500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _product.colors.map((colorName) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Text(colorName, style: AppTextStyles.labelSmall),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.labelMedium),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.black,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// 2ГИС НАВИГАЦИЯ BOTTOM SHEET
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
    final appUri = Uri.parse(
      'dgis://2gis.ru/routeSearch/rsType/pedestrian/to/${widget.sellerLng},${widget.sellerLat}',
    );
    final webUri = Uri.parse(
      'https://2gis.kg/bishkek/geo/${widget.sellerLng},${widget.sellerLat}',
    );
    final playStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=ru.dublgis.dgismobile',
    );
    final appStoreUri = Uri.parse(
      'https://apps.apple.com/app/id481627348',
    );

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('2ГИС орнотулган жок'),
          content: const Text(
            'Маршрут үчүн 2ГИС тиркемесин жүктөп алыңыз.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Жок'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
                final storeUri = isIOS ? appStoreUri : playStoreUri;
                if (await canLaunchUrl(storeUri)) {
                  await launchUrl(storeUri,
                      mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                'Жүктөп алуу',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            widget.shopName.isNotEmpty ? widget.shopName : 'Дүкөн',
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          if (widget.containerNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${widget.containerNumber}',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _step('1', 'Төмөндөгү баскычты басыңыз'),
                const SizedBox(height: 10),
                _step('2', '2ГИС тиркемеси ачылат'),
                const SizedBox(height: 10),
                _step('3', '"Маршрут түзүү" баскычын басып жолго чыгыңыз'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _open2GIS,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.map_rounded, color: Colors.white),
              label: Text(
                '2ГИС менен маршрут түзүү',
                style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// СҮРӨТТҮ ТОЛУК ЭКРАНДА КӨРСӨТҮҮ (zoom/pan + Hero animation)
// ══════════════════════════════════════════════════════
class _FullscreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullscreenImageScreen({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
