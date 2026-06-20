import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../models/category_model.dart';

enum ProductFilterMode { all, newest, popular }

class CategoryList extends StatefulWidget {
  final Function(String) onCategorySelected;
  final Function(ProductFilterMode)? onFilterModeChanged;

  const CategoryList({
    super.key,
    required this.onCategorySelected,
    this.onFilterModeChanged,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  String? _selectedCategoryId;
  String? _selectedSubId;
  late List<CategoryModel> _categories;
  ProductFilterMode _filterMode = ProductFilterMode.all;

  @override
  void initState() {
    super.initState();
    _categories = CategoryModel.getCategories();
  }

  CategoryModel? get _selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  void _onCategoryTap(CategoryModel cat) {
  setState(() {
    if (_selectedCategoryId == cat.id) {
      _selectedCategoryId = null;
      _selectedSubId = null;
      // Filter mode reset — категория алынганда
      _filterMode = ProductFilterMode.all;
      widget.onFilterModeChanged?.call(ProductFilterMode.all);
      widget.onCategorySelected('');
    } else {
      _selectedCategoryId = cat.id;
      _selectedSubId = null;
      // Filter mode учурдагыдай калат, бирок HomeScreen кайра жүктөйт
      widget.onCategorySelected(cat.id);
    }
  });
}

  void _onSubCategoryTap(SubCategoryModel sub) {
    setState(() {
      if (_selectedSubId == sub.id) {
        _selectedSubId = null;
        widget.onCategorySelected(_selectedCategoryId ?? '');
      } else {
        _selectedSubId = sub.id;
        // id '..._1' — "Баары" кичи категориясы (тилден көз карандысыз id боюнча текшерилет)
        if (sub.id.endsWith('_1')) {
          widget.onCategorySelected(_selectedCategoryId ?? '');
        } else {
          widget.onCategorySelected(sub.id);
        }
      }
    });
  }

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        categories: _categories,
        selectedId: _selectedCategoryId,
        onSelected: (cat) {
          Navigator.pop(context);
          _onCategoryTap(cat);
        },
      ),
    );
  }

  void _setFilterMode(ProductFilterMode mode) {
    if (_filterMode == mode) {
      setState(() => _filterMode = ProductFilterMode.all);
      widget.onFilterModeChanged?.call(ProductFilterMode.all);
    } else {
      setState(() => _filterMode = mode);
      widget.onFilterModeChanged?.call(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cat = _selectedCategory;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Негизги фильтр катары ──
        SizedBox(
          height: 52,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Категория баскычы ──
                GestureDetector(
                  onTap: _openCategorySheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _selectedCategoryId != null
                          ? AppColors.primary
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _selectedCategoryId != null
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_view_rounded,
                            size: 17,
                            color: _selectedCategoryId != null
                                ? Colors.white
                                : AppColors.grey600),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCategoryId != null
                              ? (cat?.localizedName(loc.locale.languageCode) ?? loc.get('cat_label'))
                              : loc.get('cat_label'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _selectedCategoryId != null
                                ? Colors.white
                                : AppColors.grey600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _selectedCategoryId != null
                                ? Colors.white
                                : AppColors.grey500),
                      ],
                    ),
                  ),
                ),

                // ── Жаңы товарлар ──
                GestureDetector(
                  onTap: () => _setFilterMode(ProductFilterMode.newest),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _filterMode == ProductFilterMode.newest
                          ? const Color(0xFF16A34A)
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _filterMode == ProductFilterMode.newest
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new_rounded,
                            size: 16,
                            color: _filterMode == ProductFilterMode.newest
                                ? Colors.white
                                : AppColors.grey600),
                        const SizedBox(width: 5),
                        Text(
                          loc.get('cat_newest'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _filterMode == ProductFilterMode.newest
                                ? Colors.white
                                : AppColors.grey600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Таанымал ──
                GestureDetector(
                  onTap: () => _setFilterMode(ProductFilterMode.popular),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _filterMode == ProductFilterMode.popular
                          ? const Color(0xFFD97706)
                          : AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _filterMode == ProductFilterMode.popular
                          ? [
                              BoxShadow(
                                color: const Color(0xFFD97706)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded,
                            size: 16,
                            color: _filterMode == ProductFilterMode.popular
                                ? Colors.white
                                : AppColors.grey600),
                        const SizedBox(width: 5),
                        Text(
                          loc.get('cat_popular'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: _filterMode == ProductFilterMode.popular
                                ? Colors.white
                                : AppColors.grey600,
                            fontSize: 13,
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

        // ── Кичи категориялар ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: cat != null && cat.subcategories.isNotEmpty
              ? _SubCategoryBar(
                  category: cat,
                  selectedSubId: _selectedSubId,
                  onSubTap: _onSubCategoryTap,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// КИЧИ КАТЕГОРИЯЛАР КАТАРЫ
// ════════════════════════════════════════════════════
class _SubCategoryBar extends StatelessWidget {
  final CategoryModel category;
  final String? selectedSubId;
  final Function(SubCategoryModel) onSubTap;

  const _SubCategoryBar({
    required this.category,
    required this.selectedSubId,
    required this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xFF${category.color}'));

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: category.subcategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final sub = category.subcategories[i];
          final isSelected = selectedSubId == sub.id ||
              (selectedSubId == null && sub.id.endsWith('_1'));

          return GestureDetector(
            onTap: () => onSubTap(sub),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Builder(
                builder: (context) {
                  final loc = AppLocalizations.of(context);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sub.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        sub.localizedName(loc.locale.languageCode),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : color.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// CATEGORY BOTTOM SHEET
// ════════════════════════════════════════════════════
class _CategoryBottomSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final Function(CategoryModel) onSelected;

  const _CategoryBottomSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc  = AppLocalizations.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(loc.get('cat_select'),
                    style: AppTextStyles.headingSmall),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat       = categories[index];
                  final isSelected = selectedId == cat.id;
                  final color     = Color(int.parse('0xFF${cat.color}'));

                  return GestureDetector(
                    onTap: () => onSelected(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(cat.icon,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.localizedName(loc.locale.languageCode),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? color : AppColors.grey600,
                                height: 1.2,
                              ),
                            ),
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
    );
  }
}
