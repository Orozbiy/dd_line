import 'package:flutter/material.dart';
import '../../promotions/screens/promotion_screen.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = [
      {'label': 'Жаңылык', 'emoji': '🔥', 'color': '0xFFD97706'},
      {'label': 'Жеңил', 'emoji': '👟', 'color': '0xFF8B5CF6'},
      {'label': 'Техника', 'emoji': '📱', 'color': '0xFF3B82F6'},
      {'label': 'Кийим', 'emoji': '👗', 'color': '0xFFEC4899'},
      {'label': 'Тамак', 'emoji': '🥗', 'color': '0xFF10B981'},
      {'label': 'Акция', 'emoji': '🎁', 'color': '0xFFF87171'},
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.90,
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('DD Online', style: AppTextStyles.headingLarge),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            // ── Stories ──
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 10),
              child: Text('Жаңылыктар', style: AppTextStyles.labelLarge),
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
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            s['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s['label']!,
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),

            // ── Promotions Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PromotionScreen(),
                    ),
                  );
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Акциялар',
                            style: AppTextStyles.headingSmall
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Арзан баадагы товарлар',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ── Footer ──
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Дордой Базары ',
                style: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}