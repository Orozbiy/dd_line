import 'package:flutter/material.dart';
import '../../promotions/screens/promotion_screen.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : AppColors.white;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    final stories = [
      {
        'label': loc.get('drawer_story_new'),
        'emoji': '🔥',
        'color': '0xFFD97706'
      },
      {
        'label': loc.get('drawer_story_light'),
        'emoji': '👟',
        'color': '0xFF8B5CF6'
      },
      {
        'label': loc.get('drawer_story_tech'),
        'emoji': '📱',
        'color': '0xFF3B82F6'
      },
      {
        'label': loc.get('drawer_story_cloth'),
        'emoji': '👗',
        'color': '0xFFEC4899'
      },
      {
        'label': loc.get('drawer_story_food'),
        'emoji': '🥗',
        'color': '0xFF10B981'
      },
      {
        'label': loc.get('drawer_story_sale'),
        'emoji': '🎁',
        'color': '0xFFF87171'
      },
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.90,
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('DD Online', style: AppTextStyles.headingLarge),
            ),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 16),

            // ── Stories ──
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: Text(loc.get('drawer_stories_title'),
                  style: AppTextStyles.labelLarge),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final s = stories[i];
                  final color = Color(int.parse(s['color']!));
                  return Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border:
                              Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        child: Center(
                            child: Text(s['emoji']!,
                                style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(height: 6),
                      Text(s['label']!, style: AppTextStyles.labelSmall),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 20),

            // ── Promotions Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop(); // drawer жабылат
                  await Future.delayed(
                      const Duration(milliseconds: 150)); // анимация бүтсүн
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PromotionScreen()),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
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
                              style: AppTextStyles.headingSmall
                                  .copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(loc.get('drawer_promo_subtitle'),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
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

            const Spacer(),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Дордой Базары',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.grey500 : null,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
