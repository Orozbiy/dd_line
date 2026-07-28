import 'package:flutter/material.dart';
import '../../promotions/screens/promotion_screen.dart';
import '../../stories/models/story_model.dart';
import '../../stories/services/story_service.dart';
import '../../stories/widgets/story_circle_button.dart';
import '../../stories/screens/story_viewer_screen.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../screens/flash_sale_screen.dart';
import '../../featured/screens/featured_screen.dart';
// import '../../featured/roulette/screens/roulette_screen.dart'; // коментарийде
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
// Бул функцияны home_screen.dart'тан чакыр:
// openSidePanel(context);
// ══════════════════════════════════════════════════════
void openSidePanel(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => const _SidePanelScreen(),
      transitionsBuilder: (_, anim, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // оңдон
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return SlideTransition(position: slide, child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    ),
  );
}

// ── Эски Drawer — home_screen.dart'та endDrawer үчүн калтырылган (бош) ──
class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ══════════════════════════════════════════════════════
// ЖАҢЫ СЛАЙД ПАНЕЛ ЭКРАН
// ══════════════════════════════════════════════════════
class _SidePanelScreen extends StatefulWidget {
  const _SidePanelScreen();

  @override
  State<_SidePanelScreen> createState() => _SidePanelScreenState();
}

class _SidePanelScreenState extends State<_SidePanelScreen> {
  List<StoryModel> _stories = [];
  bool _loading = true;
  Set<String> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('viewed_story_ids') ?? [];
    final list = await StoryService.instance.fetchActiveStories();
    if (mounted) {
      setState(() {
        _viewedIds = ids.toSet();
        _stories = list
            .map((s) => s.copyWith(isViewed: _viewedIds.contains(s.id)))
            .toList();
        _loading = false;
      });
    }
  }

  Future<void> _openStory(int index) async {
    Navigator.of(context).pop(); // панелди жап
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await Navigator.push<List<StoryModel>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => StoryViewerScreen(
          stories: _stories,
          initialIndex: index,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('viewed_story_ids') ?? [];
    setState(() {
      _viewedIds = ids.toSet();
      _stories = _stories
          .map((s) => s.copyWith(isViewed: _viewedIds.contains(s.id)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : AppColors.white;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        // Сол жагына (тышкары) бассаңыз жабылат
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // панел ичин басуу — жабылбасын
            child: Container(
              width: screenWidth * 0.90, // 90%
              height: double.infinity,
              color: bgColor,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [


                      const Text(
  'DD Online',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  ),
),

                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: dividerColor),
                    const SizedBox(height: 16),

                    // ── Прокрутулуучу мазмун ──
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Жаңылыктар (Stories) ──
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, bottom: 10),
                              child:Text(
  loc.get('drawer_stories_title'),
  style: AppTextStyles.labelLarge.copyWith(
    decoration: TextDecoration.none,
  ),
),
                            ),
                            SizedBox(
                              height: 100,
                              child: _loading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : _stories.isEmpty
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Text(
                                            loc.get('story_empty'),
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: AppColors.grey500),
                                          ),
                                        )
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          itemCount: _stories.length,
                                          itemBuilder: (_, i) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 12),
                                            child: StoryCircleButton(
                                              story: _stories[i],
                                              onTap: () => _openStory(i),
                                            ),
                                          ),
                                        ),
                            ),

                            Divider(height: 24, color: dividerColor),

                            // ── 🎁 Акциялар Card ──
                            // ── 🎁 Акциялар Card ──
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: GestureDetector(
    onTap: () {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PromotionScreen()),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.get('drawer_promo_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  )),
              const SizedBox(height: 2),
              Text(loc.get('drawer_promo_subtitle'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  )),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 20),
        ],
      ),
    ),
  ),
),

                           // ── ⚡ Flash Sale Card ──
const SizedBox(height: 12),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: GestureDetector(
    onTap: () {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FlashSaleScreen()),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.get('drawer_flash_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  )),
              const SizedBox(height: 2),
              Text(loc.get('drawer_flash_subtitle'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  )),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 20),
        ],
      ),
    ),
  ),
),

                         // ── ⭐ Өзгөчө товарлар Card ──
const SizedBox(height: 12),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: GestureDetector(
    onTap: () {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FeaturedScreen()),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.get('drawer_featured_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  )),
              const SizedBox(height: 2),
              Text(loc.get('drawer_featured_subtitle'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  )),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 20),
        ],
      ),
    ),
  ),
),

                            // ── 🎰 Рулетка (коментарийде) ──
                            /*
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await Future.delayed(const Duration(milliseconds: 150));
                                  if (context.mounted) {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const RouletteScreen()));
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(children: [
                                    const Text('🎰', style: TextStyle(fontSize: 32)),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.get('drawer_roulette_title'), ...),
                                        Text(loc.get('drawer_roulette_subtitle'), ...),
                                      ],
                                    )),
                                  ]),
                                ),
                              ),
                            ),
                            */

                            const SizedBox(height: 24),

                            // ── Footer ──
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                loc.get('drawer_footer'),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.grey500
                                      : AppColors.grey400,
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
          ),
        ),
      ),
    );
  }
}
