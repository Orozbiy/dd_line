import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../cart/screens/cart_screen.dart';
import '../../chat/screens/assistant_chat_screen.dart';
import '../../map/screens/map_screen.dart';
import '../models/category_model.dart';
import '../screens/favorites_screen.dart';

class CategoryList extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoryList({super.key, required this.onCategorySelected});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  String? selectedCategoryId;
  late List<CategoryModel> categories;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    categories = CategoryModel.getCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        categories: categories,
        selectedId: selectedCategoryId,
        onSelected: (id) {
          setState(() {
            if (selectedCategoryId == id) {
              selectedCategoryId = null;
              widget.onCategorySelected('');
            } else {
              selectedCategoryId = id;
              widget.onCategorySelected(id);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          // ── СОЛ: Категория баскычы ──
          GestureDetector(
            onTap: _openCategorySheet,
            child: Container(
              margin: const EdgeInsets.only(left: 12, right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selectedCategoryId != null
                    ? AppColors.primary
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selectedCategoryId != null
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18,
                      color: selectedCategoryId != null
                          ? Colors.white
                          : AppColors.grey600),
                  const SizedBox(width: 6),
                  Text('Категория',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: selectedCategoryId != null
                            ? Colors.white
                            : AppColors.grey600,
                        fontSize: 13,
                      )),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: selectedCategoryId != null
                          ? Colors.white
                          : AppColors.grey600),
                ],
              ),
            ),
          ),

          // ── ОҢ: ⋮ Меню ──
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.grey600),
            onSelected: (value) {
              switch (value) {
                case 'favorites':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FavoritesScreen()));
                  break;
                case 'cart':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen()));
                  break;
                case 'map':
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const MapScreen()));
                  break;
                case 'assistant':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AssistantChatScreen()));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'favorites',
                  child: ListTile(
                      leading: Icon(Icons.favorite_border),
                      title: Text('Избранный'))),
              PopupMenuItem(
                  value: 'cart',
                  child: ListTile(
                      leading: Icon(Icons.shopping_cart_outlined),
                      title: Text('Корзина'))),
              PopupMenuItem(
                  value: 'map',
                  child: ListTile(
                      leading: Icon(Icons.map_outlined), title: Text('Карта'))),
              PopupMenuItem(
                  value: 'assistant',
                  child: ListTile(
                      leading: Icon(Icons.smart_toy_outlined),
                      title: Text('Жардамчы'))),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// КАТЕГОРИЯЛАР BOTTOM SHEET
// ════════════════════════════════════════════════════════
class _CategoryBottomSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final Function(String) onSelected;

  const _CategoryBottomSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  final _searchController = TextEditingController();
  late List<CategoryModel> _filtered;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _filtered = widget.categories;
    _selectedId = widget.selectedId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = widget.categories
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.icon.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Категориялар', style: AppTextStyles.headingMedium),
                const Spacer(),
                if (_selectedId != null)
                  GestureDetector(
                    onTap: () {
                      widget.onSelected('');
                      Navigator.pop(context);
                    },
                    child: Text('Тазалоо',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Категория издөө...',
                hintStyle:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.grey400, size: 20),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('Категория табылган жок',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey400)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final cat = _filtered[index];
                      final color = Color(int.parse('0xFF${cat.color}'));
                      final isSelected = _selectedId == cat.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedId = cat.id);
                          widget.onSelected(cat.id);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isSelected ? color : AppColors.grey100,
                                width: isSelected ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                    child: Text(cat.icon,
                                        style: const TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(width: 14),
                              Text(cat.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? color
                                          : AppColors.grey600)),
                              const Spacer(),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded,
                                    color: color, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
