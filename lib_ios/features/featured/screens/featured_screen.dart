import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
import '../../../core/paged_loader.dart';
import '../../../core/supabase_client.dart';
import '../../../data/models/product_model.dart';
import '../../home/widgets/product_grid.dart';
import '../../product_detail/screens/product_detail_screen.dart';

class FeaturedScreen extends StatefulWidget {
  const FeaturedScreen({super.key});

  @override
  State<FeaturedScreen> createState() => _FeaturedScreenState();
}

class _FeaturedScreenState extends State<FeaturedScreen> {
  String _searchQuery = '';
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  // Алгач 25 товар, астыга scroll кылганда дагы 25 (серверден).
  late final PagedLoader<ProductModel> _pager = PagedLoader<ProductModel>(
    fetchPage: _fetchPage,
    idOf: (p) => p.id,
  );

  void _notify() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _pager.refresh(_notify);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _fetchPage(int from, int to) async {
    var query = supabase
        .from('products')
        .select('*, stores(store_name, owner_id)')
        .eq('is_featured', true)
        .eq('is_active', true);
    final q = _searchQuery.trim();
    if (q.isNotEmpty) query = query.ilike('title', ilikePattern(q));
    final data = await query
        .order('created_at', ascending: false)
        .order('id', ascending: true)
        .range(from, to);
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map((row) => ProductModel.fromMap(row))
        .toList();
  }

  Future<void> _loadFeaturedProducts() => _pager.refresh(_notify);

  // Издөө серверде жүрөт — бардык өзгөчө товарлардан издейт.
  void _onSearchChanged(String v) {
    setState(() => _searchQuery = v);
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 350), _loadFeaturedProducts);
  }

  @override
  Widget build(BuildContext context) {
    final p          = DDPalette.of(context);
    final isDark     = p.isDark;
    final bgColor    = p.bg;
    final divColor   = p.divider;
    final inputFill  = p.field;
    final titleColor = p.text;

    final filtered = _pager.items;
    final isFirstLoad =
        !_pager.loadedOnce || (_pager.isLoading && filtered.isEmpty);

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
              decoration: BoxDecoration(
                color: (isDark ? DD.bgDark : Colors.white).withOpacity(isDark ? 0.75 : 0.85),
                border: Border(
                  bottom: BorderSide(color: divColor),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFEDEDF0)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.arrow_back_rounded, color: p.text, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(isDark ? 0.25 : 0.18), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Өзгөчө товарлар',
              style: AppTextStyles.headingMedium.copyWith(color: titleColor, fontSize: 17),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _loadFeaturedProducts,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFEDEDF0)),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : AppColors.grey600, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Фон жарыктары ──
          Positioned.fill(child: _FeaturedBackground(isDark: isDark)),

          Column(
        children: [
          // ── Издөө ──
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.black),
              decoration: InputDecoration(
                hintText: 'Товар издөө...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.grey400),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.grey400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.grey400),
                      )
                    : null,
                filled: true,
                fillColor: inputFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
              ),
            ),
          ),

          // ── Табылган саны ──
          if (!isFirstLoad && _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length}${_pager.hasMore ? '+' : ''} товар табылды',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // ── Товарлар ──
          Expanded(
            child: isFirstLoad
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? _buildEmpty(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadFeaturedProducts,
                        color: const Color(0xFF10B981),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (PagedLoader.nearEnd(n)) {
                              _pager.loadMore(_notify);
                            }
                            return false;
                          },
                          child: ProductGrid(
                            products: filtered,
                            footer: PagedFooter(
                              visible: _pager.isLoadingMore,
                              color: const Color(0xFF10B981),
                            ),
                            onProductTap: (product) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final searching = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(searching ? '🔍' : '⭐', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            searching ? 'Эч нерсе табылган жок' : 'Өзгөчө товар жок',
            style: AppTextStyles.headingSmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.black),
          ),
          if (!searching) ...[
            const SizedBox(height: 8),
            Text(
              'Сатуучулар азырынча өзгөчө\nтовар белгилеген жок',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ФОН ЖАРЫКТАРЫ
// ══════════════════════════════════════════════════════
class _FeaturedBackground extends StatelessWidget {
  final bool isDark;
  const _FeaturedBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _FeaturedBgPainter(isDark)),
    );
  }
}

class _FeaturedBgPainter extends CustomPainter {
  final bool isDark;
  _FeaturedBgPainter(this.isDark);

  void _blob(Canvas c, Offset o, double r, Color color) {
    c.drawCircle(o, r,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withOpacity(0)])
              .createShader(Rect.fromCircle(center: o, radius: r)));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF000D08) : const Color(0xFFF4FCF8);
    canvas.drawRect(Offset.zero & s, bgPaint);
    if (isDark) {
      _blob(canvas, Offset(s.width * 0.1, s.height * 0.07), s.width * 0.85,
          const Color(0xFF10B981).withOpacity(0.18));
      _blob(canvas, Offset(s.width * 0.9, s.height * 0.92), s.width * 0.80,
          const Color(0xFF059669).withOpacity(0.14));
      _blob(canvas, Offset(s.width * 0.5, s.height * 0.45), s.width * 0.55,
          DD.accent2.withOpacity(0.06));
    } else {
      _blob(canvas, Offset(s.width * 0.15, s.height * 0.06), s.width * 0.70,
          const Color(0xFF10B981).withOpacity(0.10));
      _blob(canvas, Offset(s.width * 0.92, s.height * 0.88), s.width * 0.60,
          const Color(0xFF059669).withOpacity(0.07));
      _blob(canvas, Offset(s.width * 0.55, s.height * 0.40), s.width * 0.45,
          DD.accent2.withOpacity(0.04));
    }
  }

  @override
  bool shouldRepaint(_FeaturedBgPainter o) => o.isDark != isDark;
}