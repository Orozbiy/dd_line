import 'package:flutter/material.dart';

import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
import '../models/category_model.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xFF${category.color}'));
    final p = DDPalette.of(context);
    final isDark = p.isDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color : p.card,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.40)
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // ── Сүрөт (карточканын жогору бөлүгү) ──
              Positioned(
                top: 0, left: 0, right: 0,
                child: _buildImage(color),
              ),

              // ── Бүт карточка (колонна: сүрөт + текст) ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Сүрөт placeholder (бийиктик ылайыктоо үчүн)
                  const SizedBox(height: 68),

                  // ── Аты ──
                  Container(
                    width: double.infinity,
                    color: isSelected ? color : p.card,
                    padding: const EdgeInsets.fromLTRB(4, 5, 4, 7),
                    child: Text(
                      category.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : p.subText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Активдүү болсо — жеңил түс маскасы ──
              if (isSelected)
                Positioned(
                  top: 0, left: 0, right: 0,
                  height: 68,
                  child: Container(
                    color: color.withOpacity(0.25),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Color color) {
    if (category.imagePath == null) {
      return _fallbackIcon(color);
    }
    return Image.asset(
      category.imagePath!,
      width: 80,
      height: 68,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackIcon(color),
    );
  }

  Widget _fallbackIcon(Color color) {
    return Container(
      width: 80,
      height: 68,
      color: color.withOpacity(0.10),
      child: Center(
        child: Text(category.icon, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}