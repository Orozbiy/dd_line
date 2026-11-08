import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
import '../../../core/app_localizations.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../seller/screens/seller_entrance_screen.dart';
import '../../seller/screens/seller_dashboard_screen.dart';
import '../../../core/seller_session_service.dart';
import '../../../core/supabase_client.dart' as supa;
import 'package:cached_network_image/cached_network_image.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../utils/product_repository.dart';
import '../widgets/category_list.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/search_bar_widget.dart';
import '../../home/widgets/app_end_drawer.dart';
import '../../map/screens/map_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/chat_model.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../screens/favorites_screen.dart';

import '../widgets/product_card.dart';
import '../widgets/product_skeleton_grid.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'dart:ui';
import '../constants/home_colors.dart';
import '../widgets/home_bottom_nav.dart';
// ignore: duplicate_import
import '../widgets/equal_height_row.dart';
import '../widgets/home_background.dart';
import '../../../core/update_checker.dart';

// ══════════════════════════════════════════════════════
// TAB индекстери
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
// COSMIC DARK — түс константалары
// ══════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<ProductModel> allProducts = [];
  List<ProductModel> displayedProducts = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategoryId = '';
  final fav = FavoritesManager();

  int _adminTapCount = 0;
  int _currentTab = tabHome;
  DateTime? _lastTapTime;

  int _favCount = 0;
  int _totalUnreadChat = 0;
  StreamSubscription<List<ChatModel>>? _chatSub;

  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = ProductRepository.pageSize;

  String? _sellerAvatarUrl;

  // ── Header bounce анимациясы ──
  late AnimationController _headerBounceCtrl;
  late Animation<Offset> _headerSlide;
  bool _isNearbyMode = false;
  bool _hasUnread = false;
  bool _isSearchMode = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _searchResults = []; // издөө натыйжаларынын оригиналы

  ProductFilterMode _filterMode = ProductFilterMode.all;

  FilterOptions _filter = FilterOptions(
    priceRange: const RangeValues(0, 100000),
    selectedSizes: [],
    sortBy: 'default',
  );

  // ── Lalafo-стиль скролл ──
  // Логотип (DD Online) жашынат/чыгат
  // Search+CategoryList дайыма туруктуу
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;
  bool _titleVisible = true;
  bool _navVisible = true;
  double _navBottomPadding = 12;

  // DD Online блогу көрүнөбү

  // DD Online блогунун бийиктиги: toolbar(52px)
  // (status bar бийиктиги + 50px) — эки катардын ортосу жакын болсун
  // iPhone (notch/Dynamic Island): катар status bar'га жакын жайгашат
  double get _headerTopInset {
    final top = MediaQuery.of(context).padding.top;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return (isIOS && top >= 44) ? top - 22 : top;
  }

  double get _titleBarHeight => _headerTopInset + 50.0;
  // Sticky header'дин чыныгы бийиктиги (категория ачылганда өзгөрөт)
  final GlobalKey _headerKey = GlobalKey();
  double? _headerH;

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if (_headerH == null || (_headerH! - h).abs() > 0.5) {
      setState(() => _headerH = h);
    }
  }

  int get _filterCount {
    int c = 0;
    if (_filter.priceRange.start > 0 || _filter.priceRange.end < 100000) c++;
    if (_filter.selectedSizes.isNotEmpty) c++;
    if (_filter.sortBy != 'default') c++;
    return c;
  }

  @override
  void initState() {
    super.initState();

    // ── Header bounce анимациясы — жогорудан ылдыга ──
    _headerBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerBounceCtrl,
      curve: Curves.elasticOut,
    ));
    _headerBounceCtrl.forward();

    _loadProducts(); // ← бул бар
    _loadSellerAvatar();
    _favCount = fav.count;
    _checkUnread();
    fav.addListener(_onFavChanged);
    _subscribeChatUnread();

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottom = MediaQuery.of(context).padding.bottom;
      setState(() => _navBottomPadding = bottom > 0 ? bottom : 12);
      _checkAppUpdate();
    });
  }

// ── Жаңы метод ──

  Future<void> _loadSellerAvatar() async {
    final uid = await SellerSessionService.instance.getSavedUid();
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _sellerAvatarUrl = null);
      return;
    }
    try {
      final row = await supa.supabase.from('stores').select('logo_url').eq('owner_id', uid).maybeSingle();
      final logo = row?['logo_url'] as String?;
      if (mounted) setState(() => _sellerAvatarUrl = (logo != null && logo.isNotEmpty) ? logo : null);
    } catch (_) {
      if (mounted) setState(() => _sellerAvatarUrl = null);
    }
  }

  Future<void> _checkAppUpdate() async {
    final langCode = AppLocalizations.of(context).locale.languageCode;
    await UpdateChecker.check(context, langCode);
  }

  // ══════════════════════════════════════════════════════
  // LALAFO SCROLL ЛОГИКАСЫ
  // Ылдый скролл → DD Online жашынат
  // Жогору скролл → DD Online кайтат
  // ══════════════════════════════════════════════════════
  void _onScroll() {
    final current = _scrollController.offset;
    final delta = current - _lastScrollOffset;
    _lastScrollOffset = current;

    // Эгер эң жогоруда болсо — логотип дайыма көрүнсүн
    if (current <= 0) {
      if (!_titleVisible) setState(() => _titleVisible = true);
      if (!_navVisible) setState(() => _navVisible = true);
      return;
    }

    if (delta > 2) {
      if (_titleVisible) setState(() => _titleVisible = false);
      if (_navVisible) setState(() => _navVisible = false);
    } else if (delta < -2) {
      if (!_titleVisible) setState(() => _titleVisible = true);
      if (!_navVisible) setState(() => _navVisible = true);
    }
  }

  void _subscribeChatUnread() {
    final user = supa.supabase.auth.currentUser;
    if (user == null) return;
    _chatSub = ChatService().buyerChatsStream(user.id).listen((chats) {
      if (!mounted) return;
      final total = chats.fold<int>(0, (sum, c) => sum + c.buyerUnread);
      setState(() => _totalUnreadChat = total);
    });
  }

  void _onFavChanged() {
    if (mounted) setState(() => _favCount = fav.count);
  }

  Future<void> _checkUnread() async {
    try {
      final userId = supa.supabase.auth.currentUser?.id;
      if (userId == null) return;
      final all = await supa.supabase.from('admin_notifications').select('id')
       .isFilter('seller_id', null);
      if ((all as List).isEmpty) return;
      final allIds = all.map((r) => r['id'] as String).toSet();
            final reads = await supa.supabase
          .from('notification_reads')
          .select('notification_id')
          .eq('user_id', userId);
      final readIds =
          (reads as List).map((r) => r['notification_id'] as String).toSet();
      final hasUnread = allIds.any((id) => !readIds.contains(id));
      if (mounted) setState(() => _hasUnread = hasUnread);
    } catch (_) {}
  }

  @override
  void dispose() {
    fav.removeListener(_onFavChanged);
    _debounce?.cancel();
    _chatSub?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerBounceCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
      _navVisible = true;
      _titleVisible = true;
    });
  }

  // ── Катуу тартып жаңыртуу: жеңил тийүү/тартууда сүрөттөр жаңырбайт ──
  static const double _pullThreshold = 130;
  bool _pullArmed = false;

  void _handlePull(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return;
    final px = n.metrics.pixels;
    if (n is ScrollUpdateNotification || n is OverscrollNotification) {
      if (px <= -_pullThreshold && !_pullArmed) {
        _pullArmed = true;
        HapticFeedback.mediumImpact();
      } else if (_pullArmed && px > -_pullThreshold * 0.6) {
        _pullArmed = false; // кайра жогору жыйды — жокко чыгат
      }
    } else if (n is ScrollEndNotification) {
      if (_pullArmed) {
        _pullArmed = false;
        _pullRefresh();
      }
    }
  }

  Future<void> _pullRefresh() async {
    if (_isLoading) return;
    if (_isSearchMode && _searchQuery.isNotEmpty) {
      _onSearchChanged(_searchQuery);
    } else if (_isNearbyMode) {
      await _loadNearbyProducts();
    } else {
      switch (_filterMode) {
        case ProductFilterMode.newest:
          await _loadNewest();
          break;
        case ProductFilterMode.popular:
          await _loadPopular();
          break;
        case ProductFilterMode.all:
          await _loadProducts(refresh: true);
          break;
      }
    }
  }

  /// Жүктөлүп жатканда спиннердин ордуна товар орундары.
  Widget _buildSkeletonSliver() {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(10, 15, 10, 12),
      sliver: SliverToBoxAdapter(child: ProductSkeletonGrid()),
    );
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) ProductRepository.instance.refreshSeed();
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
      _hasMore = true;
    });
    try {
      final products = await ProductRepository.instance.fetchNewest(
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        limit: _pageSize,
        offset: 0,
      );
      _hasMore = products.length == _pageSize;
      _offset = products.length;
      if (mounted) {
        setState(() {
          allProducts = products;
          displayedProducts = List.from(products);
          _isLoading = false;
        });
        _applyFilters(); // баа/сорттоо фильтрин колдонуу
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPopular() async {
    setState(() {
      _isLoading = true;
      _isNearbyMode = false;
      _isSearchMode = false;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final products = await ProductRepository.instance.fetchPopular(
        categoryId: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        limit: _pageSize,
        offset: 0,
      );
      _hasMore = products.length == _pageSize;
      _offset = products.length;
      if (mounted) {
        setState(() {
          allProducts = products;
          displayedProducts = List.from(products);
          _isLoading = false;
        });
        _applyFilters(); // баа/сорттоо фильтрин колдонуу
      }
    } catch (e) {
      debugPrint('❌ loadPopular: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterModeChanged(ProductFilterMode mode) {
    // ── Издөө режиминде турса — издөөнү тазалоо ──
    if (_isSearchMode || _searchQuery.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
      _debounce?.cancel();
    }
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
        _isSearchMode) {
      return;
    }
    _isLoadingMore = true;
    try {
      List<ProductModel> newProducts;
      if (_filterMode == ProductFilterMode.newest) {
        newProducts = await ProductRepository.instance.fetchNewest(
          categoryId:
              _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
          limit: _pageSize,
          offset: _offset,
        );
      } else if (_filterMode == ProductFilterMode.popular) {
        newProducts = await ProductRepository.instance.fetchPopular(
          categoryId:
              _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
          limit: _pageSize,
          offset: _offset,
        );
      } else {
        newProducts = await ProductRepository.instance.fetchProducts(
          offset: _offset,
          categoryId:
              _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        );
      }
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
    // ── Издөөнү тазалоо ──
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
      _debounce?.cancel();
    }
    final position = await ProductRepository.instance.getCurrentPosition();
    if (position == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.get('nearby_error')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
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
      });
      _applyFilters();
    } catch (e) {
      debugPrint('❌ loadNearbyProducts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        // _filterMode өзгөртпөйбүз — издөө тазалангандан кийин
        // мурунку режимге (popular/newest/all) кайтуу үчүн
      });
      try {
        final results = await ProductRepository.instance.searchProducts(
          query: q,
          categoryId:
              _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
        );
        if (!mounted) return;
        _searchResults = results;
        setState(() {
          displayedProducts = List.from(results);
          _isLoading = false;
        });
        _applyFilters(); // баа фильтрин издөө натыйжаларына колдонуу
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
    // ── Мурунку фильтр режимин калыбына келтирүү ──
    switch (_filterMode) {
      case ProductFilterMode.newest:
        _loadNewest();
        break;
      case ProductFilterMode.popular:
        _loadPopular();
        break;
      case ProductFilterMode.all:
        _loadProducts();
        break;
    }
  }

  void _applyFilters() {
    // ── Издөө режиминде да, кадимки режимде да фильтр колдонулат ──
    List<ProductModel> source;
    if (_isSearchMode) {
      source = List.from(_searchResults);
    } else {
      source = List.from(allProducts);
    }

    List<ProductModel> result = source
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
        if (_isNearbyMode) {
          result.sort((a, b) => (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
        }
        break;
    }
    setState(() => displayedProducts = result);
  }

  void _resetFilters() {
    setState(() {
      _filter = FilterOptions(
          priceRange: const RangeValues(0, 100000),
          selectedSizes: [],
          sortBy: 'default');
    });
    _applyFilters();
  }

  void _openFilter() {
    FilterBottomSheet.show(context, initialOptions: _filter, onApply: (opts) {
      _filter = opts;
      _applyFilters();
    });
  }

  // Жашыруун админ: "Жөндөөлөр" кнопкасын 13 жолу ээрчий басуу,
  // ар бир басуунун ортосу 1 секундадан ашпашы керек.
  void _onNavTapped(int tab) {
    if (tab != tabSettings) {
      _adminTapCount = 0;
      _lastTapTime = null;
      return;
    }
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
    }
    _lastTapTime = now;
    if (_adminTapCount >= 13) {
      _adminTapCount = 0;
      _lastTapTime = null;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    }
  }

  String _filterModeLabel(AppLocalizations loc) {
    switch (_filterMode) {
      case ProductFilterMode.newest:
        return loc.get('newest');
      case ProductFilterMode.popular:
        return loc.get('popular');
      case ProductFilterMode.all:
        return '';
    }
  }

  Widget _glassButton({
    required Widget child,
    required VoidCallback onTap,
    bool active = false,
    Color? activeColor,
    double padding = 13,
    double radius = 18,
  }) {
    final _hp = DDPalette.of(context);
    final color = activeColor ?? DD.accent;
    return _IosBtn(
      onTap: onTap,
      active: active,
      activeColor: color,
      padding: EdgeInsets.all(padding),
      radius: radius,
      isDark: _hp.isDark,
      child: child,
    );
  }

  // ══════════════════════════════════════════════════════
  // NAVBAR
  // ══════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════
  // HOME TAB мазмуну
  // ══════════════════════════════════════════════════════
  Widget _buildHomeTab(AppLocalizations loc, bool isDark) {
    final p2           = DDPalette.of(context);
    final dividerColor = p2.divider;
    final appBarColor = p2.card;

    // ── Search + CategoryList бийиктиги (туруктуу sticky блок) ──
    // search(44+8padding) + divider(1) + pills(44) = ~97
    const double _searchCatH = 97.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });

    return _HomeBodySlider(
      onOpenPanel: () => openSidePanel(context),
      child: Stack(
        children: [
          // ════════════════════════════════════════════
          // СКРОЛЛ МАЗМУН — CustomScrollView
          // ════════════════════════════════════════════
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                _loadMoreProducts();
              }
              _handlePull(n);
              return false;
            },
            child: RefreshIndicator(
              color: Colors.transparent,
              backgroundColor: Colors.transparent,
              elevation: 0,
              // Адаттагы жеңил тартуу жаңыртпайт — төмөндө катуу тартуу логикасы
              notificationPredicate: (_) => false,
              onRefresh: () async {
                if (_isSearchMode && _searchQuery.isNotEmpty) {
                  // ── Издөө режиминде — издөөнү кайра жүргүзүү ──
                  _onSearchChanged(_searchQuery);
                } else if (_isNearbyMode) {
                  await _loadNearbyProducts();
                } else {
                  switch (_filterMode) {
                    case ProductFilterMode.newest:
                      await _loadNewest();
                      break;
                    case ProductFilterMode.popular:
                      await _loadPopular();
                      break;
                    case ProductFilterMode.all:
                      await _loadProducts(refresh: true);
                      break;
                  }
                }
              },
              displacement: 80,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // ── Жогоруда бош орун (sticky header бийиктиги) ──
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _headerH ??
                          (_titleVisible
                              ? _titleBarHeight + _searchCatH
                              : _searchCatH),
                    ),
                  ),

                  // ── Баскычтар сабы ──
                  // ── Баскычтар сабы — маалымат болгондо гана ──
if (_isSearchMode || _isNearbyMode || 
    (_filterMode != ProductFilterMode.all && !_isLoading) || 
    _filterCount > 0)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 10),
      child: Row(
        children: [
          if (_isSearchMode && !_isLoading)
            Flexible(
              child: Text(
                '${displayedProducts.length} ${loc.get('results')}',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: p2.subText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_isNearbyMode && !_isLoading)
            Flexible(
              child: Text(
                '📍 ${displayedProducts.length} ${loc.get('nearby_count')}',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: p2.subText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (_filterMode != ProductFilterMode.all &&
              !_isSearchMode &&
              !_isNearbyMode &&
              !_isLoading)
            Flexible(
              child: Text(
                '${_filterModeLabel(loc)} · ${displayedProducts.length} шт',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: p2.subText),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          const Spacer(),
          if (_filterCount > 0) ...[
            const SizedBox(width: 8),
            _IosLabelBtn(
              onTap: _resetFilters,
              icon: Icons.close,
              label: loc.get('filter_reset'),
              color: AppColors.error,
              isDark: isDark,
            ),
          ],
        ],
      ),
    ),
  ),

                  // ── Товарлар ──
                  if (_isLoading)
                    _buildSkeletonSliver()
                  else if (displayedProducts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              _isSearchMode
                                  ? '"$_searchQuery" — ${loc.get('no_products')}'
                                  : loc.get('no_products'),
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey500),
                              textAlign: TextAlign.center,
                            ),
                            if (_isSearchMode) ...[
                              const SizedBox(height: 8),
                              Text(loc.get('search_empty'),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.grey400)),
                            ],
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 15, 10, 12),
                      // SliverGrid childAspectRatio колдонбойбуз — ал бардык
                      // картага бирдей бекитилген бийиктик берип, астында
                      // боштук калтырат. EqualHeightRow ар бир катардын
                      // бийиктигин ошол катардагы эң узун картага ылайыктайт.
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, rowIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: EqualHeightRow(
                                spacing: 9,
                                children: [
                                  for (var col = 0; col < 2; col++)
                                    rowIndex * 2 + col < displayedProducts.length
                                        ? RepaintBoundary(
                                            key: ValueKey(
                                                displayedProducts[rowIndex * 2 + col].id),
                                            child: ProductCard(
                                              product: displayedProducts[
                                                  rowIndex * 2 + col],
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProductDetailScreen(
                                                      product: displayedProducts[
                                                          rowIndex * 2 + col]),
                                                ),
                                              ).then((_) => setState(() {})),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                ],
                              ),
                            );
                          },
                          childCount: (displayedProducts.length / 2).ceil(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ════════════════════════════════════════════
          // STICKY HEADER — экрандын жогору жагында туруктуу
          // ════════════════════════════════════════════
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _headerSlide,
              child: NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => mounted ? _measureHeader() : null);
                return true;
              },
              child: SizeChangedLayoutNotifier(
                key: _headerKey,
                child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  color: appBarColor.withOpacity(0.75),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── DD Online блогу — анимация менен жашынат/чыгат ──
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: _titleVisible ? _titleBarHeight : 0,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: SizedBox(
                          height: _titleBarHeight,
                          child: Padding(
                            padding: EdgeInsets.only(top: _headerTopInset),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Дүкөн баскычы
                                GestureDetector(
                                  onTap: () async {
                                    final uid = await SellerSessionService.instance.getSavedUid();
                                    if (!context.mounted) return;
                                    if (uid != null && uid.isNotEmpty) {
                                      await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => SellerDashboardScreen(uid: uid),
                                      ));
                                    } else {
                                      await Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => const SellerEntranceScreen(),
                                      ));
                                    }
                                    if (mounted) setState(() {});
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFCCCCCC),
                                          Color(0xFFEAEAEA),
                                          Color(0xFFB8B8B8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(DD.rPill),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.18),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                          spreadRadius: -2,
                                        ),
                                      ],
                                    ),
                                    child: _sellerAvatarUrl != null
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: _sellerAvatarUrl!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(
                                                  Icons.store_rounded, color: Color(0xFF444444), size: 20),
                                            ),
                                          )
                                        : Text(loc.get('shop'),
                                            style: const TextStyle(
                                                color: Color(0xFF333333),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15)),
                                  ),
                                ),
                                // DD Online жазуусу (функциясы жок, 22px)
                                Expanded(
                                  child: Center(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [DD.accent2, DD.accent],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ).createShader(bounds),
                                      child: const Text('DD Online',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.6)),
                                    ),
                                  ),
                                ),
                                // Коңгуроо
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const NotificationsScreen()))
                                      .then((_) => _checkUnread()),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Image.asset('assets/icons/nav/ic_bell.png', width: 28, height: 28),
                                        if (_hasUnread)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle),
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
                      ),

                      // ── Search + баскычтар (дайыма туруктуу) ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: Row(
                          children: [
                            Expanded(
                                child: SearchBarWidget(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    onClear: _onSearchClear)),
                            const SizedBox(width: 8),
                            _glassButton(
                              active: _filterCount > 0,
                              onTap: _openFilter,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Image.asset('assets/icons/nav/ic_filter.png', width: 26, height: 26),
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
                                            child: Text('$_filterCount',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: dividerColor),
                      const SizedBox(height: 6),

                      // ── CategoryList (дайыма туруктуу) ──
                      CategoryList(
                        currentFilterMode: _isSearchMode || _isNearbyMode
                            ? ProductFilterMode.all
                            : _filterMode,
                        onCategorySelected: (id) {
                          setState(() => _selectedCategoryId = id);
                          if (_isSearchMode && _searchQuery.isNotEmpty) {
                            _onSearchChanged(_searchQuery);
                          } else if (_isNearbyMode) {
                            _loadNearbyProducts();
                          } else {
                            _onFilterModeChanged(_filterMode);
                          }
                        },
                        onFilterModeChanged: _onFilterModeChanged,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ), // ← Container
              ), // ← BackdropFilter
            ),
              ), // ← SizeChangedLayoutNotifier
            ), // ← NotificationListener
            ), // ← SlideTransition
          ), // ← ClipRect
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final _bp = DDPalette.of(context);
    final isDark = _bp.isDark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_currentTab != tabHome) {
          setState(() => _currentTab = tabHome);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            HomeBackground(isDark: isDark),

            // ── Мазмун ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  // Башкы беттен башка 4 табда да: ылдый → навбар жашынат,
                  // жогору → кайра чыгат
                  if (_currentTab == tabHome || n.metrics.axis != Axis.vertical) {
                    return false;
                  }
                  if (n.direction == ScrollDirection.reverse &&
                      n.metrics.pixels > 0 &&
                      _navVisible) {
                    setState(() => _navVisible = false);
                  } else if ((n.direction == ScrollDirection.forward ||
                          n.metrics.pixels <= 0) &&
                      !_navVisible) {
                    setState(() => _navVisible = true);
                  }
                  return false;
                },
                child: Stack(
                children: [
                  Offstage(
                    offstage: _currentTab != tabHome,
                    child: _buildHomeTab(loc, isDark),
                  ),
                  Offstage(
                    offstage: _currentTab != tabChat,
                    child: const ChatListScreen(isSeller: false),
                  ),
                  Offstage(
                    offstage: _currentTab != tabMap,
                    child: const MapScreen(),
                  ),
                  Offstage(
                    offstage: _currentTab != tabFavorites,
                    child: const FavoritesScreen(),
                  ),
                  Offstage(
                    offstage: _currentTab != tabSettings,
                    child: const SettingsScreen(),
                  ),
                ],
              ),
              ),
            ),

            // ── Калкып турган меню баскычы ──
            if (_currentTab == tabHome)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                right: 16,
                bottom: _navVisible
                    ? HomeBottomNav.footprint(_navBottomPadding) + 16
                    : 32,
                child: _MenuFab(onTap: () => openSidePanel(context)),
              ),

            // ── Navbar ──

            HomeBottomNav(
              currentTab: _currentTab,
              isVisible: _navVisible,
              totalUnreadChat: _totalUnreadChat,
              favCount: _favCount,
              bottomPadding: _navBottomPadding,
              onTabSelected: _switchTab,
              onTabTapped: _onNavTapped,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// _HomeBodySlider
// ══════════════════════════════════════════════════════
class _HomeBodySlider extends StatefulWidget {
  final Widget child;
  final VoidCallback onOpenPanel;
  const _HomeBodySlider({required this.child, required this.onOpenPanel});

  @override
  State<_HomeBodySlider> createState() => _HomeBodySliderState();
}

class _HomeBodySliderState extends State<_HomeBodySlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _progress = 0.0;
  bool _isDragging = false;
  static const double _openThreshold = 0.3;
  static const double _velocityThreshold = 500.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _isDragging = true;
    _ctrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final sw = MediaQuery.of(context).size.width;
    if (details.delta.dx < 0) {
      setState(() {
        _progress = (_progress - details.delta.dx / sw).clamp(0.0, 1.0);
        _ctrl.value = _progress;
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;
    if (_progress > _openThreshold || velocity < -_velocityThreshold) {
      _ctrl
          .animateTo(1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic)
          .then((_) {
        if (!mounted) return;
        setState(() => _progress = 0.0);
        _ctrl.value = 0.0;
        widget.onOpenPanel();
      });
    } else {
      _ctrl
          .animateTo(0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic)
          .then((_) {
        if (!mounted) return;
        setState(() => _progress = 0.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class RouteAwareSlide extends StatelessWidget {
  final Widget child;
  const RouteAwareSlide({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

// ══════════════════════════════════════════════════════
// КАЛКЫП ТУРГАН МАБ БАСКЫЧ
// ══════════════════════════════════════════════════════
class _MenuFab extends StatefulWidget {
  final VoidCallback onTap;
  const _MenuFab({required this.onTap});

  @override
  State<_MenuFab> createState() => _MenuFabState();
}

class _MenuFabState extends State<_MenuFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DD.accent2.withOpacity(0.90),
                DD.accent.withOpacity(0.90),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DD.rPill),
            boxShadow: [
              BoxShadow(
                color: DD.accent.withOpacity(0.45),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// iOS стил баскычтары
// ══════════════════════════════════════════════════════
class _IosBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool active;
  final Color activeColor;
  final EdgeInsets padding;
  final double radius;
  final bool isDark;

  const _IosBtn({
    required this.child,
    required this.onTap,
    required this.active,
    required this.activeColor,
    required this.padding,
    required this.radius,
    required this.isDark,
  });

  @override
  State<_IosBtn> createState() => _IosBtnState();
}

class _IosBtnState extends State<_IosBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? widget.activeColor
        : (widget.isDark
            ? HomeColors.btnBg.withOpacity(0.55)
            : Colors.white.withOpacity(0.55));

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                        color: widget.activeColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2)
                  ]
                : widget.isDark
                    ? []
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.09),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2),
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 3,
                            offset: const Offset(0, 1)),
                      ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _IosLabelBtn extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _IosLabelBtn({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  State<_IosLabelBtn> createState() => _IosLabelBtnState();
}

class _IosLabelBtnState extends State<_IosLabelBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? HomeColors.btnBg : Colors.white;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(45),
            boxShadow: widget.isDark
                ? [
                    BoxShadow(
                        color: HomeColors.glow1.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1)),
                  ],
            border: widget.isDark
                ? Border.all(color: HomeColors.btnBorder, width: 0.8)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 14),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}