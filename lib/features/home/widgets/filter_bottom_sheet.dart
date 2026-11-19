import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';

class FilterOptions {
  final RangeValues priceRange;
  final List<String> selectedSizes;
  final List<String> selectedColors;
  final String sortBy;
  final String pricingType; // 'all' | 'retail' | 'wholesale'
  final bool onlyPromotion;

  FilterOptions({
    required this.priceRange,
    required this.selectedSizes,
    this.selectedColors = const [],
    required this.sortBy,
    this.pricingType = 'all',
    this.onlyPromotion = false,
  });

  FilterOptions copyWith({
    RangeValues? priceRange,
    List<String>? selectedSizes,
    List<String>? selectedColors,
    String? sortBy,
    String? pricingType,
    bool? onlyPromotion,
  }) {
    return FilterOptions(
      priceRange: priceRange ?? this.priceRange,
      selectedSizes: selectedSizes ?? this.selectedSizes,
      selectedColors: selectedColors ?? this.selectedColors,
      sortBy: sortBy ?? this.sortBy,
      pricingType: pricingType ?? this.pricingType,
      onlyPromotion: onlyPromotion ?? this.onlyPromotion,
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions initialOptions;
  final Function(FilterOptions) onApply;
  final List<String> availableSizes;
  final List<String> availableColors;

  const FilterBottomSheet({
    super.key,
    required this.initialOptions,
    required this.onApply,
    this.availableSizes = const [],
    this.availableColors = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required FilterOptions initialOptions,
    required Function(FilterOptions) onApply,
    List<String> availableSizes = const [],
    List<String> availableColors = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialOptions: initialOptions,
        onApply: onApply,
        availableSizes: availableSizes,
        availableColors: availableColors,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late List<String> _selectedSizes;
  late List<String> _selectedColors;
  late String _sortBy;
  late String _pricingType;
  late bool _onlyPromotion;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  static const double _maxPrice = 100000;

  final List<Map<String, String>> _sortValues = [
    {'value': 'popular', 'icon': '🔥', 'key': 'sort_popular'},
    {'value': 'price_asc', 'icon': '⬆️', 'key': 'sort_price_asc'},
    {'value': 'price_desc', 'icon': '⬇️', 'key': 'sort_price_desc'},
    {'value': 'rating', 'icon': '⭐', 'key': 'sort_rating'},
    {'value': 'newest', 'icon': '🆕', 'key': 'sort_newest'},
  ];

  static Color _colorFromName(String name) {
    final n = name.trim().toLowerCase();
    const map = <String, Color>{
      'кызыл': Color(0xFFE53935),
      'кок': Color(0xFF1E88E5),
      'көк': Color(0xFF1E88E5),
      'жашыл': Color(0xFF43A047),
      'сары': Color(0xFFFDD835),
      'кара': Color(0xFF212121),
      'ак': Color(0xFFF5F5F5),
      'боз': Color(0xFF9E9E9E),
      'күрөң': Color(0xFF795548),
      'кызгылт': Color(0xFFE91E63),
      'нарынжы': Color(0xFFFF9800),
      'күлгүн': Color(0xFF9C27B0),
      'алтын': Color(0xFFFFD700),
      'күмүш': Color(0xFFC0C0C0),
      'красный': Color(0xFFE53935),
      'синий': Color(0xFF1E88E5),
      'зеленый': Color(0xFF43A047),
      'зелёный': Color(0xFF43A047),
      'желтый': Color(0xFFFDD835),
      'чёрный': Color(0xFF212121),
      'черный': Color(0xFF212121),
      'белый': Color(0xFFF5F5F5),
      'серый': Color(0xFF9E9E9E),
      'коричневый': Color(0xFF795548),
      'розовый': Color(0xFFE91E63),
      'оранжевый': Color(0xFFFF9800),
      'фиолетовый': Color(0xFF9C27B0),
      'голубой': Color(0xFF03A9F4),
      'золотой': Color(0xFFFFD700),
      'серебряный': Color(0xFFC0C0C0),
      'бежевый': Color(0xFFF5DEB3),
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'green': Color(0xFF43A047),
      'yellow': Color(0xFFFDD835),
      'black': Color(0xFF212121),
      'white': Color(0xFFF5F5F5),
      'gray': Color(0xFF9E9E9E),
      'grey': Color(0xFF9E9E9E),
      'brown': Color(0xFF795548),
      'pink': Color(0xFFE91E63),
      'orange': Color(0xFFFF9800),
      'purple': Color(0xFF9C27B0),
      'navy': Color(0xFF1A237E),
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'beige': Color(0xFFF5DEB3),
      'cream': Color(0xFFFFFDD0),
      'maroon': Color(0xFF800000),
      'teal': Color(0xFF009688),
      'olive': Color(0xFF808000),
      'coral': Color(0xFFFF6347),
      'turquoise': Color(0xFF40E0D0),
    };
    return map[n] ?? const Color(0xFF9E9E9E);
  }

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialOptions.priceRange;
    _minCtrl = TextEditingController(text: _priceRange.start.toInt().toString());
    _maxCtrl = TextEditingController(text: _priceRange.end.toInt().toString());
    _selectedSizes = List.from(widget.initialOptions.selectedSizes);
    _selectedColors = List.from(widget.initialOptions.selectedColors);
    _sortBy = widget.initialOptions.sortBy;
    _pricingType = widget.initialOptions.pricingType;
    _onlyPromotion = widget.initialOptions.onlyPromotion;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, _maxPrice);
      _selectedSizes = [];
      _selectedColors = [];
      _sortBy = 'default';
      _pricingType = 'all';
      _onlyPromotion = false;
      _minCtrl.text = '0';
      _maxCtrl.text = _maxPrice.toInt().toString();
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_priceRange.start > 0 || _priceRange.end < _maxPrice) count++;
    if (_selectedSizes.isNotEmpty) count++;
    if (_selectedColors.isNotEmpty) count++;
    if (_sortBy != 'default') count++;
    if (_pricingType != 'all') count++;
    if (_onlyPromotion) count++;
    return count;
  }

  String _formatPrice(double price) {
    if (price >= _maxPrice) return '100000 + с';
    final str = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return '${buf.toString()} с';
  }

  Widget _priceField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? Colors.white : AppColors.black,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          suffixText: 'с',
          suffixStyle: TextStyle(
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap, {
    bool isDark = false,
    Color? selectedColor,
  }) {
    final selColor = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? selColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? selColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08)),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected
                ? selColor
                : (isDark ? Colors.white : AppColors.black),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.65);
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : AppColors.black;
    final subtitleColor = isDark ? AppColors.grey400 : AppColors.grey500;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          loc.get('filter'),
                          style: AppTextStyles.headingMedium.copyWith(color: textColor),
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: Text(
                        loc.get('filter_reset'),
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey500),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ══════════════ 1. БААСЫ ══════════════
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.get('price'),
                              style: AppTextStyles.headingSmall.copyWith(color: textColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_formatPrice(_priceRange.start)} — ${_formatPrice(_priceRange.end)}',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.12),
                          trackHeight: 4,
                        ),
                        child: RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: _maxPrice,
                          divisions: 100,
                          onChanged: (v) {
                            setState(() {
                              _priceRange = v;
                              _minCtrl.text = v.start.toInt().toString();
                              _maxCtrl.text = v.end.toInt().toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _priceField(
                              controller: _minCtrl,
                              hint: '0',
                              isDark: isDark,
                              onChanged: (val) {
                                final v = double.tryParse(val) ?? 0;
                                setState(() {
                                  final c = v.clamp(0, _priceRange.end);
                                  _priceRange = RangeValues(c.toDouble(), _priceRange.end);
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('—',
                                style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
                          ),
                          Expanded(
                            child: _priceField(
                              controller: _maxCtrl,
                              hint: '100000',
                              isDark: isDark,
                              onChanged: (val) {
                                final v = double.tryParse(val) ?? _maxPrice;
                                setState(() {
                                  final c = v.clamp(_priceRange.start, _maxPrice);
                                  _priceRange = RangeValues(_priceRange.start, c.toDouble());
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      const SizedBox(height: 20),

                      // ══════════════ 2. ДҮҢ / ЧЕКЕНЕ ══════════════
                      Text(
                        'Сатуу түрү',
                        style: AppTextStyles.headingSmall.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _chip('Баары', _pricingType == 'all',
                              () => setState(() => _pricingType = 'all'), isDark: isDark),
                          _chip('Чекене', _pricingType == 'retail',
                              () => setState(() => _pricingType = 'retail'), isDark: isDark),
                          _chip('Дүң (оптом)', _pricingType == 'wholesale',
                              () => setState(() => _pricingType = 'wholesale'), isDark: isDark),
                        ],
                      ),

                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => _onlyPromotion = !_onlyPromotion),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _onlyPromotion
                                ? const Color(0xFFFF5722).withValues(alpha: 0.12)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _onlyPromotion
                                  ? const Color(0xFFFF5722)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🏷️', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Жеңилдик бар товарлар',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _onlyPromotion
                                        ? const Color(0xFFFF5722)
                                        : textColor,
                                    fontWeight: _onlyPromotion
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_onlyPromotion)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFFFF5722), size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      const SizedBox(height: 20),

                      // ══════════════ 3. СОРТТОО ══════════════
                      Text(
                        loc.get('filter_sort'),
                        style: AppTextStyles.headingSmall.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 12),
                      ..._sortValues.map((option) {
                        final isSelected = _sortBy == option['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _sortBy = option['value']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(option['icon']!, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    loc.get(option['key']!),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isSelected ? AppColors.primary : textColor,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      const SizedBox(height: 20),

                      // ══════════════ 4. РАЗМЕР — динамикалуу ══════════════
                      if (widget.availableSizes.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              loc.get('size_label'),
                              style: AppTextStyles.headingSmall.copyWith(color: textColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${widget.availableSizes.length} вариант)',
                              style: AppTextStyles.labelSmall.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.availableSizes.map((size) {
                            final isSelected = _selectedSizes.contains(size);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSizes.remove(size);
                                  } else {
                                    _selectedSizes.add(size);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                constraints: const BoxConstraints(minWidth: 56),
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.03)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.12)
                                            : Colors.black.withValues(alpha: 0.08)),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    size,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: isSelected ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: dividerColor),
                        const SizedBox(height: 20),
                      ],

                      // ══════════════ 5. ТҮС — динамикалуу ══════════════
                      if (widget.availableColors.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'Түс / Цвет',
                              style: AppTextStyles.headingSmall.copyWith(color: textColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${widget.availableColors.length} вариант)',
                              style: AppTextStyles.labelSmall.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.availableColors.map((colorName) {
                            final isSelected = _selectedColors.contains(colorName);
                            final colorValue = _colorFromName(colorName);
                            final isLight = colorValue.computeLuminance() > 0.6;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedColors.remove(colorName);
                                  } else {
                                    _selectedColors.add(colorName);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorValue
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.03)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorValue
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.1)),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: colorValue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.2)
                                              : Colors.black.withValues(alpha: 0.15),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      colorName,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: isSelected
                                            ? (isLight ? Colors.black87 : Colors.white)
                                            : textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (widget.availableSizes.isEmpty && widget.availableColors.isEmpty)
                        const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Колдонуу баскычы ──
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.30)
                          : Colors.white.withOpacity(0.40),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(FilterOptions(
                          priceRange: _priceRange,
                          selectedSizes: _selectedSizes,
                          selectedColors: _selectedColors,
                          sortBy: _sortBy,
                          pricingType: _pricingType,
                          onlyPromotion: _onlyPromotion,
                        ));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _activeFilterCount > 0
                            ? '${loc.get('filter_apply')} ($_activeFilterCount ${loc.get('filter_count_suffix')})'
                            : loc.get('filter_apply'),
                        style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
