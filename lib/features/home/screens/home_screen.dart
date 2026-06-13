import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../seller/screens/seller_entrance_screen.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../utils/product_repository.dart';
import '../widgets/category_list.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_bar_widget.dart';
import '../../home/widgets/app_end_drawer.dart';
import '../../map/screens/map_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> allProducts = [];
  List<ProductModel> displayedProducts = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategoryId = '';
  final fav = FavoritesManager();

  int _adminTapCount = 0;
  int _currentTab = 0;
  bool _mapLoaded = false;
  DateTime? _lastTapTime;

  // ── Пагинация ──
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = ProductRepository.pageSize;

  // ── "Мага жакын" режими ──
  bool _isNearbyMode = false;
  bool _isLocating = false;

FilterOptions _filter = FilterOptions(
  priceRange: const RangeValues(0, 1000000),
  selectedSizes: [],
  sortBy: 'rating',
);

  int get _filterCount {
  int c = 0;
  if (_filter.priceRange.start > 0 || _filter.priceRange.end < 1000000) c++;
  if (_filter.selectedSizes.isNotEmpty) c++;
  if (_filter.sortBy != 'rating') c++;
  return c;
}

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Биринчи баракты жүктөө (региондук фильтрсиз, жөнөкөй пагинация).
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _isNearbyMode = false;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final products = await ProductRepository.instance.fetchProducts(
        offset: 0,
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      );

      _hasMore = products.length == _pageSize;
      _offset = products.length;

      setState(() {
        allProducts = products;
        displayedProducts = List.from(products);
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('❌ loadProducts: $e');
      setState(() {
        allProducts = [];
        displayedProducts = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading || _isNearbyMode) return;
    _isLoadingMore = true;
    try {
      final newProducts = await ProductRepository.instance.fetchProducts(
        offset: _offset,
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      );

      _hasMore = newProducts.length == _pageSize;
      _offset += newProducts.length;

      if (newProducts.isNotEmpty && mounted) {
        allProducts.addAll(newProducts);
        _applyFilters();
      }
    } catch (e) {
      debugPrint('loadMore KATA: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// "Мага жакын" — GPS координатты алып, PostGIS аркылуу
  /// аралык боюнча сорттолгон товарларды жүктөйт.
  Future<void> _loadNearbyProducts() async {
    setState(() => _isLocating = true);

    final position = await ProductRepository.instance.getCurrentPosition();

    if (position == null) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Жайгашкан жериңизди аныктоо мүмкүн болбоду. '
              'Геолокацияга уруксат бериңиз.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isNearbyMode = true;
      _hasMore = false;
    });

    try {
      final products = await ProductRepository.instance.fetchProductsNearby(
        lat: position.latitude,
        lng: position.longitude,
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      );

      setState(() {
        allProducts = products;
        displayedProducts = List.from(products);
        _isLoading = false;
        _isLocating = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('❌ loadNearbyProducts: $e');
      setState(() {
        _isLoading = false;
        _isLocating = false;
      });
    }
  }

  void _onTitleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
    }
    _lastTapTime = now;
    if (_adminTapCount >= 15) {
      _adminTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  void _applyFilters() {
    List<ProductModel> result = List.from(allProducts);

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    result = result
        .where((p) =>
            p.price >= _filter.priceRange.start &&
            p.price <= _filter.priceRange.end)
        .toList();

    switch (_filter.sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      default:
        // "Мага жакын" режиминде аралык боюнча тартип сакталат,
        // башкача учурда сервердин тартиби (created_at desc) калат.
        if (_isNearbyMode) {
          result.sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
        }
    }
    setState(() => displayedProducts = result);
  }

 void _resetFilters() {
  setState(() {
    _filter = FilterOptions(
      priceRange: const RangeValues(0, 1000000),
      selectedSizes: [],
      sortBy: 'rating',
    );
  });
  _applyFilters();
}
  void _openFilter() {
    FilterBottomSheet.show(
      context,
      initialOptions: _filter,
      onApply: (opts) {
        _filter = opts;
        _applyFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      endDrawer: const AppEndDrawer(),
      floatingActionButton: _currentTab == 0
          ? Builder(
              builder: (context) => FloatingActionButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
  if (i == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    return;
  }
  setState(() {
    _currentTab = i;
    if (i == 1) _mapLoaded = true;
  });
},
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        backgroundColor: Colors.white,
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      items: const [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home_rounded),
    label: '',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.storefront_outlined),
    activeIcon: Icon(Icons.storefront_rounded),
    label: '',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_outlined),
    activeIcon: Icon(Icons.settings_rounded),
    label: '',
  ),
],
      ),
      body: Stack(
        children: [
          // ── TAB 0: Башкы ──
          Offstage(
            offstage: _currentTab != 0,
            child: SafeArea(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                    _loadMoreProducts();
                  }
                  return false;
                },
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      centerTitle: true,
                      leadingWidth: 90,
                      leading: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellerEntranceScreen(),
                          ),
                        ).then((_) => setState(() {})),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏪', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 2),
                              Text(
                                'Дүкөн',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      title: GestureDetector(
                        onTap: _onTitleTap,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'DD Online',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      actions: [
                     
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatListScreen(
                                isSeller: false,
                              ),
                            ),
                          ).then((_) => setState(() {})),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.chat_bubble_outline,
                                color: AppColors.grey600, size: 26),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          ).then((_) => setState(() {})),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12, left: 4),
                            child: Icon(Icons.person_outline,
                                color: AppColors.grey600, size: 26),
                          ),
                        ),
                      ],
                    ),

                    // ИЗДӨӨ + "МАГА ЖАКЫН" + ФИЛЬТР
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: SearchBarWidget(
                                onChanged: (q) {
                                  _searchQuery = q;
                                  _applyFilters();
                                },
                                onClear: () {
                                  _searchQuery = '';
                                  _applyFilters();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ── "МАГА ЖАКЫН" БАСКЫЧЫ ──
                            GestureDetector(
                              onTap: _isLocating
                                  ? null
                                  : (_isNearbyMode
                                      ? _loadProducts
                                      : _loadNearbyProducts),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _isNearbyMode
                                      ? AppColors.primary
                                      : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isLocating
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.near_me_rounded,
                                        color: _isNearbyMode
                                            ? Colors.white
                                            : AppColors.grey600,
                                        size: 22,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _openFilter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _filterCount > 0
                                      ? AppColors.primary
                                      : const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(Icons.tune_rounded,
                                        color: _filterCount > 0
                                            ? Colors.white
                                            : AppColors.grey600,
                                        size: 22),
                                    if (_filterCount > 0)
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle),
                                          child: Center(
                                            child: Text(
                                              '$_filterCount',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // КАТЕГОРИЯЛАР
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            CategoryList(
                              onCategorySelected: (id) {
                                _selectedCategoryId = id;
                                if (_isNearbyMode) {
                                  _loadNearbyProducts();
                                } else {
                                  _loadProducts();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // ТОВАРЛАР САНЫ + ЖАҢЫЛОО + ТАЗАЛОО
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: Row(
                          children: [
                            Text(
                              _isLoading
                                  ? 'Жүктөлүп жатат...'
                                  : _isNearbyMode
                                      ? '${displayedProducts.length} жакын товар'
                                      : '${displayedProducts.length} товар табылды',
                              style: AppTextStyles.headingSmall,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _isNearbyMode
                                  ? _loadNearbyProducts
                                  : _loadProducts,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.refresh,
                                        color: AppColors.primary, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Жаңылоо',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                                color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                            if (_filterCount > 0) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _resetFilters,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEEEE),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.close,
                                          color: AppColors.error, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Тазалоо',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                  color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ТОВАРЛАР
                    if (_isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Товарлар жүктөлүп жатат...',
                                style: TextStyle(
                                  color: AppColors.grey500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverFillRemaining(
                        child: Column(
                          children: [
                            Expanded(
                              child: ProductGrid(
                                products: displayedProducts,
                                onProductTap: (product) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                          product: product)),
                                ).then((_) => setState(() {})),
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

          // ── TAB 1: Дүкөндөр картасы — гана басканда жүктөлөт ──
          Offstage(
            offstage: _currentTab != 1,
            child: _mapLoaded ? const MapScreen() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}