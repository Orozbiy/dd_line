import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../seller/screens/seller_entrance_screen.dart';
import '../utils/product_repository.dart';
import '../widgets/category_list.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/search_bar_widget.dart';
import '../../home/widgets/app_end_drawer.dart';
import '../../map/screens/map_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/chat_model.dart';
import '../../../core/supabase_client.dart';
import '../widgets/product_grid.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../widgets/fav_badge.dart';
import '../screens/favorites_screen.dart';

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

  int _favCount = 0;

  // ── Пагинация ──
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = ProductRepository.pageSize;

  // ── "Мага жакын" режими ──
  bool _isNearbyMode = false;
  bool _isLocating = false;

  // ── Поиск режими ──
  bool _isSearchMode = false;
  Timer? _debounce;

  ProductFilterMode _filterMode = ProductFilterMode.all;

  FilterOptions _filter = FilterOptions(
    priceRange: const RangeValues(0, 1000000),
    selectedSizes: [],
    sortBy: 'default',
  );

  int get _filterCount {
    int c = 0;
    if (_filter.priceRange.start > 0 || _filter.priceRange.end < 1000000) c++;
    if (_filter.selectedSizes.isNotEmpty) c++;
    if (_filter.sortBy != 'default') c++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _favCount = fav.count;
    fav.addListener(_onFavChanged);
  }

  void _onFavChanged() {
    if (mounted) setState(() => _favCount = fav.count);
  }

  @override
  void dispose() {
    fav.removeListener(_onFavChanged);
    _debounce?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // ЖҮКТӨӨ
  // ══════════════════════════════════════════════════════════════════

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      ProductRepository.instance.refreshSeed();
    }

    setState(() {
      _isLoading = true;
      _isNearbyMode = false;
      _isSearchMode = false;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final products = await ProductRepository.instance.fetchProducts(
        offset: 0,
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      );

      products.shuffle();

      _hasMore = products.length == _pageSize;
      _offset = products.length;

      if (mounted) {
        setState(() {
          allProducts = List.from(products);
          displayedProducts = List.from(products);
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('❌ loadProducts: $e');
      if (mounted) {
        setState(() {
          allProducts = [];
          displayedProducts = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNewest() async {
    setState(() {
      _isLoading = true;
      _isNearbyMode = false;
      _isSearchMode = false;
      _offset = 0;
      _hasMore = false;
    });

    try {
      final products = await ProductRepository.instance.fetchNewest(
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        limit: 40,
      );

      if (mounted) {
        setState(() {
          allProducts = products;
          displayedProducts = List.from(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ loadNewest: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPopular() async {
    setState(() {
      _isLoading = true;
      _isNearbyMode = false;
      _isSearchMode = false;
      _offset = 0;
      _hasMore = false;
    });

    try {
      final products = await ProductRepository.instance.fetchPopular(
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        limit: 40,
      );

      if (mounted) {
        setState(() {
          allProducts = products;
          displayedProducts = List.from(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ loadPopular: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterModeChanged(ProductFilterMode mode) {
    setState(() => _filterMode = mode);
    switch (mode) {
      case ProductFilterMode.newest:
        _loadNewest();
        break;
      case ProductFilterMode.popular:
        _loadPopular();
        break;
      case ProductFilterMode.all:
        _loadProducts(refresh: true);
        break;
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _isLoading ||
        _isNearbyMode ||
        _isSearchMode ||
        _filterMode != ProductFilterMode.all) return;
    _isLoadingMore = true;
    try {
      final newProducts = await ProductRepository.instance.fetchProducts(
        offset: _offset,
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      );

      newProducts.shuffle();

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
      _isSearchMode = false;
      _hasMore = false;
      _filterMode = ProductFilterMode.all;
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

  // ══════════════════════════════════════════════════════════════════
  // ПОИСК
  // ══════════════════════════════════════════════════════════════════

  void _onSearchChanged(String q) {
    _searchQuery = q;
    _debounce?.cancel();

    if (q.trim().isEmpty) {
      setState(() => _isSearchMode = false);
      _loadProducts();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _isSearchMode = true;
        _isNearbyMode = false;
        _hasMore = false;
        _filterMode = ProductFilterMode.all;
      });

      try {
        final results = await ProductRepository.instance.searchProducts(
          query: q,
          categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        );

        if (!mounted) return;
        setState(() {
          displayedProducts = results;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('❌ searchProducts: $e');
        if (!mounted) return;
        setState(() {
          displayedProducts = [];
          _isLoading = false;
        });
      }
    });
  }

  void _onSearchClear() {
    _searchQuery = '';
    _debounce?.cancel();
    setState(() => _isSearchMode = false);
    _loadProducts();
  }

  // ══════════════════════════════════════════════════════════════════
  // ФИЛЬТР
  // ══════════════════════════════════════════════════════════════════

  void _applyFilters() {
    if (_isSearchMode) return;

    List<ProductModel> result = List.from(allProducts);

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
      case 'default':
      default:
        if (_isNearbyMode) {
          result.sort((a, b) =>
              (a.distanceKm ?? double.infinity)
                  .compareTo(b.distanceKm ?? double.infinity));
        }
        break;
    }

    setState(() => displayedProducts = result);
  }

  void _resetFilters() {
    setState(() {
      _filter = FilterOptions(
        priceRange: const RangeValues(0, 1000000),
        selectedSizes: [],
        sortBy: 'default',
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

  // ══════════════════════════════════════════════════════════════════
  // ADMIN
  // ══════════════════════════════════════════════════════════════════

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

  String get _filterModeLabel {
    switch (_filterMode) {
      case ProductFilterMode.newest:
        return '🆕 Жаңы товарлар';
      case ProductFilterMode.popular:
        return '🔥 Таанымал';
      case ProductFilterMode.all:
        return '';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // BOTTOM NAV — build()тен ТЫШКАРЫ
  // ══════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            if (i == 2) return; // камера орну — баспайт
            if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ).then((_) => setState(() => _favCount = fav.count));
              return;
            }
            if (i == 4) {
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: '',
            ),
            // ── Камера үчүн бош орун ──
            const BottomNavigationBarItem(
              icon: SizedBox(width: 56),
              label: '',
            ),
            BottomNavigationBarItem(
              label: '',
              icon: FavBadge(count: _favCount, active: false),
              activeIcon: FavBadge(count: _favCount, active: true),
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: '',
            ),
          ],
        ),

        // ── Чоң камера кнопкасы ──
        Positioned(
          top: -24,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Издөө камерасы',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Жакында кошулат! 🚀\nТовардын сүрөтүн тартып издей аласыз.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                  actions: [
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Жарайт',
                            style: TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════

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
      bottomNavigationBar: _buildBottomNav(),
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
                    // ── APP BAR ──
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
                        // ── Чат иконасы ──
                        StreamBuilder<List<ChatModel>>(
                          stream: supabase.auth.currentUser != null
                              ? ChatService().buyerChatsStream(
                                  supabase.auth.currentUser!.id)
                              : const Stream.empty(),
                          builder: (context, snapshot) {
                            final chats = snapshot.data ?? [];
                            final totalUnread = chats.fold<int>(
                              0, (sum, chat) => sum + chat.buyerUnread,
                            );
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ChatListScreen(isSeller: false),
                                ),
                              ).then((_) => setState(() {})),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline,
                                        color: AppColors.grey600, size: 26),
                                    if (totalUnread > 0)
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 1.5),
                                          ),
                                          child: Text(
                                            totalUnread > 100
                                                ? '100+'
                                                : '$totalUnread',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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

                    // ── ИЗДӨӨ + "МАГА ЖАКЫН" + ФИЛЬТР ──
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: SearchBarWidget(
                                onChanged: _onSearchChanged,
                                onClear: _onSearchClear,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _isLocating
                                  ? null
                                  : (_isNearbyMode
                                      ? () => _loadProducts(refresh: true)
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
                                                  fontWeight:
                                                      FontWeight.bold),
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

                    // ── КАТЕГОРИЯЛАР ──
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
                                if (_isSearchMode &&
                                    _searchQuery.isNotEmpty) {
                                  _onSearchChanged(_searchQuery);
                                } else if (_isNearbyMode) {
                                  _loadNearbyProducts();
                                } else {
                                  _onFilterModeChanged(_filterMode);
                                }
                              },
                              onFilterModeChanged: _onFilterModeChanged,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // ── ЖАҢЫЛОО БАСКЫЧЫ ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: Row(
                          children: [
                            if (_isSearchMode && !_isLoading)
                              Text(
                                '${displayedProducts.length} натыйжа',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500),
                              ),
                            if (_isNearbyMode && !_isLoading)
                              Text(
                                '📍 ${displayedProducts.length} жакын товар',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500),
                              ),
                            if (_filterMode != ProductFilterMode.all &&
                                !_isSearchMode &&
                                !_isNearbyMode &&
                                !_isLoading)
                              Text(
                                '$_filterModeLabel · ${displayedProducts.length}',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500),
                              ),
                            const Spacer(),
                            if (!_isSearchMode)
                              GestureDetector(
                                onTap: _isNearbyMode
                                    ? _loadNearbyProducts
                                    : () {
                                        switch (_filterMode) {
                                          case ProductFilterMode.newest:
                                            _loadNewest();
                                            break;
                                          case ProductFilterMode.popular:
                                            _loadPopular();
                                            break;
                                          case ProductFilterMode.all:
                                            _loadProducts(refresh: true);
                                            break;
                                        }
                                      },
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

                    // ── ТОВАРЛАР ──
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
                    else if (displayedProducts.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔍',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                _isSearchMode
                                    ? '"$_searchQuery" — табылган жок'
                                    : 'Товар табылган жок',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.grey500),
                                textAlign: TextAlign.center,
                              ),
                              if (_isSearchMode) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Башка сөз менен издеп көрүңүз',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.grey400),
                                ),
                              ],
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

          // ── TAB 1: Дүкөндөр картасы ──
          Offstage(
            offstage: _currentTab != 1,
            child: _mapLoaded ? const MapScreen() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
