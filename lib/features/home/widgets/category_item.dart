import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.40)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Сүрөт бөлүгү ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: category.imagePath != null
                  ? Stack(
                      children: [
                        Image.asset(
                          category.imagePath!,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackIcon(color, isSelected),
                        ),
                        // Активдүү болсо — түс маскасы
                        if (isSelected)
                          Positioned.fill(
                            child: Container(
                              color: color.withValues(alpha: 0.30),
                            ),
                          ),
                      ],
                    )
                  : _fallbackIcon(color, isSelected),
            ),

            // ── Аты ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Text(
                category.name,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.grey600),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(Color color, bool isSelected) {
    return Container(
      width: 80,
      height: 60,
      color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.10),
      child: Center(
        child: Text(category.icon, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}