import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/supabase_client.dart';

class SellerProductScreen extends StatefulWidget {
  final String sellerUid;
  final String shopName;

  const SellerProductScreen({
    super.key,
    required this.sellerUid,
    required this.shopName,
  });

  @override
  State<SellerProductScreen> createState() => _SellerProductScreenState();
}

class _SellerProductScreenState extends State<SellerProductScreen> {
  static const _cloudName = 'dedwm4krp';
  static const _uploadPreset = 'dd-online';

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _selectedCategoryId;
  String? _storeId;

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products
        .where((p) => p['category_id'] == _selectedCategoryId)
        .toList();
  }

  final List<Map<String, String>> _categories = [
    {'id': '1', 'name': 'Кийим-кече', 'icon': '👕'},
    {'id': '2', 'name': 'Эркектер кийими', 'icon': '👔'},
    {'id': '3', 'name': 'Аялдар кийими', 'icon': '👗'},
    {'id': '4', 'name': 'Балдар кийими', 'icon': '🧒'},
    {'id': '5', 'name': 'Мектеп формасы', 'icon': '🏫'},
    {'id': '6', 'name': 'Кышкы кийим', 'icon': '🧥'},
    {'id': '7', 'name': 'Жайкы кийим', 'icon': '☀️'},
    {'id': '8', 'name': 'Күзгү / Жазгы кийим', 'icon': '🍂'},
    {'id': '9', 'name': 'Спорт кийими', 'icon': '🏋️'},
    {'id': '10', 'name': 'Бут кийим', 'icon': '👟'},
    {'id': '11', 'name': 'Аксессуарлар', 'icon': '👜'},
    {'id': '12', 'name': 'Сумкалар', 'icon': '🎒'},
    {'id': '13', 'name': 'Кол / Баш кийим', 'icon': '🧤'},
    {'id': '14', 'name': 'Зергерчилик', 'icon': '💍'},
    {'id': '15', 'name': 'Кездеме / Мата', 'icon': '🧵'},
    {'id': '16', 'name': 'Электроника', 'icon': '📱'},
    {'id': '17', 'name': 'Муздаткыч / Техника', 'icon': '❄️'},
    {'id': '18', 'name': 'Кир жуучу машина', 'icon': '🫧'},
    {'id': '19', 'name': 'Куралдар / Инструмент', 'icon': '🔧'},
    {'id': '20', 'name': 'Үй буюмдар', 'icon': '🏠'},
    {'id': '21', 'name': 'Үй өсүмдүктөрү', 'icon': '🪴'},
    {'id': '22', 'name': 'Дүкөн буюмдары', 'icon': '🏪'},
    {'id': '23', 'name': 'Спорт', 'icon': '⚽'},
    {'id': '24', 'name': 'Балдар оюнчуктары', 'icon': '🧸'},
    {'id': '25', 'name': 'Сулуулук / Косметика', 'icon': '💄'},
    {'id': '26', 'name': 'Жеке гигиена', 'icon': '🧴'},
    {'id': '27', 'name': 'Азык-түлүк', 'icon': '🛒'},
    {'id': '28', 'name': 'Автотовар', 'icon': '🚗'},
    {'id': '29', 'name': 'Китептер / Канцтовар', 'icon': '📚'},
    {'id': '30', 'name': 'Оюнчуктар', 'icon': '🎮'},
  ];

  final List<Map<String, dynamic>> _allColors = [
    {'name': 'Кара', 'hex': 0xFF000000},
    {'name': 'Ак', 'hex': 0xFFFFFFFF},
    {'name': 'Кызыл', 'hex': 0xFFEF4444},
    {'name': 'Көк', 'hex': 0xFF3B82F6},
    {'name': 'Жашыл', 'hex': 0xFF22C55E},
    {'name': 'Сары', 'hex': 0xFFEAB308},
    {'name': 'Кызгылт', 'hex': 0xFFEC4899},
    {'name': 'Күрөң', 'hex': 0xFF92400E},
    {'name': 'Боз', 'hex': 0xFF6B7280},
    {'name': 'Күлгүн', 'hex': 0xFF8B5CF6},
    {'name': 'Кызгылт сары', 'hex': 0xFFF97316},
    {'name': 'Ачык көк', 'hex': 0xFF06B6D4},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ══════════════════════════════════════════════
  // ДҮКӨН ID АЛУУ (же түзүү)
  // ══════════════════════════════════════════════
  Future<String> _getOrCreateStoreId() async {
    if (_storeId != null) return _storeId!;

    final uid = widget.sellerUid;

    final existing = await supabase
        .from('stores')
        .select('id')
        .eq('owner_id', uid)
        .maybeSingle();

    if (existing != null) {
      _storeId = existing['id'] as String;
      return _storeId!;
    }

    final inserted = await supabase
        .from('stores')
        .insert({
          'owner_id': uid,
          'store_name': widget.shopName,
        })
        .select('id')
        .single();

    _storeId = inserted['id'] as String;
    return _storeId!;
  }

  // ══════════════════════════════════════════════
  // МААЛЫМАТ ЖҮКТӨӨ
  // ══════════════════════════════════════════════
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final storeId = await _getOrCreateStoreId();
      final rows = await supabase
          .from('products')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      setState(() {
        _products = (rows as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ _loadProducts error: $e');
      setState(() => _isLoading = false);
      if (mounted) _showSnack('Товарларды жүктөөдө ката: $e', isError: true);
    }
  }

  // ══════════════════════════════════════════════
  // CLOUDINARY ЖҮКТӨӨ
  // ══════════════════════════════════════════════
  Future<String?> _uploadToCloudinary(Uint8List bytes) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMsg = errorData?['error']?['message'] ?? 'Белгисиз ката';
        if (mounted) _showSnack('Сүрөт жүктөлбөдү: $errorMsg', isError: true);
        return null;
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Интернет байланышын текшериңиз: $e', isError: true);
      }
      return null;
    }
  }

  // ══════════════════════════════════════════════
  // SNACKBAR
  // ══════════════════════════════════════════════
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 4),
    ));
  }

  // ══════════════════════════════════════════════
  // ТОВАР ӨЧҮРҮҮ
  // ══════════════════════════════════════════════
  Future<void> _deleteProduct(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Товарды өчүрүү', style: AppTextStyles.headingSmall),
        content: Text('"$name" товарын өчүрөсүзбү?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жок'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Ооба, өчүр', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase.from('products').delete().eq('id', id);
      _showSnack('Товар өчүрүлдү');
      _loadProducts();
    } catch (e) {
      _showSnack('Өчүрүүдө ката: $e', isError: true);
    }
  }

  // ══════════════════════════════════════════════
  // АРЗАНДАТУУ SHEET
  // ══════════════════════════════════════════════
  void _showDiscountSheet(Map<String, dynamic> product) {
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final ctrl = TextEditingController(
      text: (product['discount_percent'] as num?)?.toString() ?? '',
    );
    double? discountedPrice;
    int percent = int.tryParse(ctrl.text) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          void recalc(String v) {
            final p = int.tryParse(v) ?? 0;
            setS(() {
              percent = p.clamp(0, 100);
              discountedPrice = price - (price * percent / 100);
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('🏷️ Арзандатуу белгилөө',
                    style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Text(
                  'Баштапкы баа: ${price.toStringAsFixed(0)} сом',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey500),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  onChanged: recalc,
                  decoration: InputDecoration(
                    labelText: 'Арзандатуу пайызы (0–100)',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                if (percent > 0 && discountedPrice != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$percent% арзандатуу',
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: AppColors.primary)),
                            Text(
                              '${discountedPrice!.toStringAsFixed(0)} сом',
                              style: AppTextStyles.headingSmall
                                  .copyWith(color: AppColors.error),
                            ),
                            Text(
                              '${(price - discountedPrice!).toStringAsFixed(0)} сомго арзандады',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.grey500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: percent < 1
                        ? null
                        : () async {
                            await _saveDiscount(
                              productId: product['id'] as String,
                              product: product,
                              percent: percent,
                              discountedPrice: discountedPrice!,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Аксияга кошуу',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                if ((product['discount_percent'] as num? ?? 0) > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        await supabase.from('products').update({
                          'discount_percent': null,
                          'discounted_price': null,
                          'has_promotion': false,
                        }).eq('id', product['id'] as String);
                        _showSnack('Аксия алынып салынды');
                        _loadProducts();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Аксияны алып салуу',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  // АКЦИЯ САКТОО
  // ══════════════════════════════════════════════
  Future<void> _saveDiscount({
    required String productId,
    required Map<String, dynamic> product,
    required int percent,
    required double discountedPrice,
  }) async {
    await supabase.from('products').update({
      'discount_percent': percent,
      'discounted_price': discountedPrice,
      'has_promotion': true,
    }).eq('id', productId);
    _showSnack('✅ Аксия сакталды! Товар акциялар бөлүмүнө кошулду.');
    _loadProducts();
  }

  String _getCategoryName(String id) {
    final cat = _categories.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'name': 'Башка', 'icon': '📦'},
    );
    return '${cat['icon']} ${cat['name']}';
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Менин товарларым', style: AppTextStyles.headingSmall),
            Text(widget.shopName,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey500)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh, color: AppColors.grey600),
            tooltip: 'Жаңылоо',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Категория фильтр ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _categoryChip(
                      id: null,
                      icon: '📦',
                      name: 'Баары',
                      count: _products.length),
                  const SizedBox(width: 8),
                  ..._categories.where((cat) {
                    return _products.any((p) => p['category_id'] == cat['id']);
                  }).map((cat) {
                    final count = _products
                        .where((p) => p['category_id'] == cat['id'])
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _categoryChip(
                        id: cat['id'],
                        icon: cat['icon']!,
                        name: cat['name']!,
                        count: count,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Товарлар тизмеси ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategoryId == null
                                  ? 'Товарыңыз жок'
                                  : 'Бул категорияда товар жок',
                              style: AppTextStyles.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedCategoryId == null
                                  ? 'Товар кошуу үчүн төмөнкү + баскычты басыңыз'
                                  : 'Башка категорияны тандаңыз',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final colors =
                                List<String>.from(p['colors'] as List? ?? []);
                            final sizes =
                                List<String>.from(p['sizes'] as List? ?? []);
                            final images =
                                List<String>.from(p['images'] as List? ?? []);
                            final imageUrl =
                                images.isNotEmpty ? images.first : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Сүрөт (басканда арзандатуу sheet) ──
                                  GestureDetector(
                                    onTap: () => _showDiscountSheet(p),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _noImage(),
                                            ),
                                          ),
                                        ),
                                        if ((p['discount_percent'] as num? ??
                                                0) >
                                            0)
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.error,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '-${p['discount_percent']}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // ── Маалымат ──
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['title'] as String? ?? '',
                                          style: AppTextStyles.labelLarge,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(p['price'] as num?)?.toStringAsFixed(0) ?? 0} сом',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                  color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getCategoryName(
                                              p['category_id'] as String? ??
                                                  '1'),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors.grey500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Складда: ${p['in_stock'] ?? 0} дана',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color:
                                                (p['in_stock'] as int? ?? 0) > 0
                                                    ? AppColors.success
                                                    : AppColors.error,
                                          ),
                                        ),
                                        if (colors.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children:
                                                colors.take(5).map((name) {
                                              final c = _allColors.firstWhere(
                                                (x) => x['name'] == name,
                                                orElse: () =>
                                                    {'hex': 0xFF888888},
                                              );
                                              return Container(
                                                width: 14,
                                                height: 14,
                                                margin: const EdgeInsets.only(
                                                    right: 4),
                                                decoration: BoxDecoration(
                                                  color: Color(c['hex'] as int),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                        if (sizes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Размер: ${sizes.join(', ')}',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                    color: AppColors.grey500),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // ── Өзгөртүү / Өчүрүү ──
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _showProductDialog(existing: p),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.edit,
                                              size: 18,
                                              color: Color(0xFF0369A1)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _deleteProduct(
                                          p['id'] as String? ?? '',
                                          p['title'] as String? ?? '',
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEEEE),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.delete,
                                              size: 18, color: AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Товар кошуу',
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // КАТЕГОРИЯ ЧИП
  // ══════════════════════════════════════════════
  Widget _categoryChip({
    required String? id,
    required String icon,
    required String name,
    required int count,
  }) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              name,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.grey300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ТОВАР ДИАЛОГУ
  // ══════════════════════════════════════════════
  Future<void> _showProductDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['title'] ?? '');
    final priceCtrl =
        TextEditingController(text: existing?['price']?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: existing?['description'] ?? '');
    final stockCtrl =
        TextEditingController(text: existing?['in_stock']?.toString() ?? '');
    final extra1Ctrl = TextEditingController(text: existing?['extra1'] ?? '');
    final extra2Ctrl = TextEditingController(text: existing?['extra2'] ?? '');
    final extra3Ctrl = TextEditingController(text: existing?['extra3'] ?? '');

    String selectedCategory = existing?['category_id'] ?? '1';
    List<String> selectedColors = List<String>.from(existing?['colors'] ?? []);
    List<String> selectedSizes = List<String>.from(existing?['sizes'] ?? []);

    Uint8List? imageBytes;
    final existingImages =
        List<String>.from(existing?['images'] as List? ?? []);
    String existingImageUrl =
        existingImages.isNotEmpty ? existingImages.first : '';
    bool isUploading = false;
    bool isLoading = false;
    String uploadStatus = '';

    const clothSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
    const shoeSizes = [
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45',
      '46'
    ];

    Future<void> pickImage(StateSetter setD) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setD(() => imageBytes = bytes);
        }
      } catch (e) {
        _showSnack('Сүрөт тандоодо ката: $e', isError: true);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 520,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Башлык
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        existing == null ? 'Товар кошуу' : 'Товар өзгөртүү',
                        style: AppTextStyles.headingSmall
                            .copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (!isLoading) Navigator.pop(ctx);
                        },
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Форма
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. СҮРӨТ
                        _label('🖼️ Товардын сүрөтү *'),
                        GestureDetector(
                          onTap: () => pickImage(setD),
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: imageBytes != null ||
                                        existingImageUrl.isNotEmpty
                                    ? AppColors.primary
                                    : AppColors.grey300,
                                width: 1.5,
                              ),
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.memory(imageBytes!,
                                        fit: BoxFit.cover),
                                  )
                                : existingImageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.network(
                                          existingImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _uploadPlaceholder(),
                                        ),
                                      )
                                    : _uploadPlaceholder(),
                          ),
                        ),
                        if (isUploading) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(
                              color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(uploadStatus,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.grey500)),
                        ],
                        const SizedBox(height: 14),

                        // 2. АТЫ
                        _label('📝 Товардын аты *'),
                        _field(nameCtrl, 'Мисалы: Кара футболка'),
                        const SizedBox(height: 14),

                        // 3. БААСЫ
                        _label('💰 Баасы (сом) *'),
                        _field(priceCtrl, 'Мисалы: 500',
                            type: TextInputType.number),
                        const SizedBox(height: 14),

                        // 4. КАТЕГОРИЯ
                        _label('🗂️ Категория *'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c['id'],
                                        child: Text(
                                          '${c['icon']}  ${c['name']}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setD(() {
                                    selectedCategory = val;
                                    selectedColors = [];
                                    selectedSizes = [];
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (selectedCategory == '1') ...[
                          _label('🎨 Түстөр (каалоо боюнча)'),
                          _colorPicker(selectedColors, setD),
                          const SizedBox(height: 14),
                          _label('📏 Размерлер (каалоо боюнча)'),
                          _sizePicker(clothSizes, selectedSizes, setD),
                        ],
                        if (selectedCategory == '2') ...[
                          _label('🎨 Түстөр (каалоо боюнча)'),
                          _colorPicker(selectedColors, setD),
                          const SizedBox(height: 14),
                          _label('📏 Размерлер (каалоо боюнча)'),
                          _sizePicker(shoeSizes, selectedSizes, setD),
                        ],
                        if (selectedCategory == '4') ...[
                          _label('🏷️ Бренд (каалоо боюнча)'),
                          _field(extra1Ctrl, 'Мисалы: Samsung, Apple'),
                          const SizedBox(height: 14),
                          _label('📋 Модель (каалоо боюнча)'),
                          _field(extra2Ctrl, 'Мисалы: Galaxy S24'),
                        ],

                        const SizedBox(height: 14),
                        _label('📦 Складдагы саны'),
                        _field(stockCtrl, 'Мисалы: 10',
                            type: TextInputType.number),
                        const SizedBox(height: 14),

                        _label('📄 Сүрөттөмө'),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          style: AppTextStyles.bodyMedium,
                          decoration:
                              _deco('Товар жөнүндө кыскача маалымат...'),
                        ),

                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text('ℹ️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '* белгиленген талаалар милдеттүү.',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.grey500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // САКТОО БАСКЫЧЫ
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final name = nameCtrl.text.trim();
                                    final price =
                                        double.tryParse(priceCtrl.text.trim());
                                    if (name.isEmpty) {
                                      _showSnack('Товардын атын жазыңыз!',
                                          isError: true);
                                      return;
                                    }
                                    if (price == null || price <= 0) {
                                      _showSnack('Туура баа жазыңыз!',
                                          isError: true);
                                      return;
                                    }
                                    if (imageBytes == null &&
                                        existingImageUrl.isEmpty) {
                                      _showSnack('Сүрөт тандаңыз!',
                                          isError: true);
                                      return;
                                    }

                                    setD(() {
                                      isLoading = true;
                                      uploadStatus = '';
                                    });

                                    try {
                                      String imageUrl = existingImageUrl;

                                      if (imageBytes != null) {
                                        setD(() {
                                          isUploading = true;
                                          uploadStatus =
                                              'Сүрөт жүктөлүп жатат...';
                                        });

                                        final compressed =
                                            await compressImage(imageBytes!);
                                        final uploaded =
                                            await _uploadToCloudinary(
                                                compressed);

                                        if (uploaded == null) {
                                          setD(() {
                                            isLoading = false;
                                            isUploading = false;
                                            uploadStatus = '';
                                          });
                                          return;
                                        }
                                        imageUrl = uploaded;
                                        setD(() {
                                          isUploading = false;
                                          uploadStatus = '✅ Сүрөт жүктөлдү';
                                        });
                                      }

                                      setD(() => uploadStatus =
                                          'Товар сакталып жатат...');

                                      final storeId =
                                          await _getOrCreateStoreId();

                                      final data = {
                                        'title': name,
                                        'price': price,
                                        'category_id': selectedCategory,
                                        'store_id': storeId,
                                        'images': [imageUrl],
                                        'in_stock': int.tryParse(
                                                stockCtrl.text.trim()) ??
                                            0,
                                        'description': descCtrl.text.trim(),
                                        'colors': selectedColors,
                                        'sizes': selectedSizes,
                                        'extra1': extra1Ctrl.text.trim(),
                                        'extra2': extra2Ctrl.text.trim(),
                                        'extra3': extra3Ctrl.text.trim(),
                                        'rating': existing?['rating'] ?? 0.0,
                                      };

                                      if (existing != null) {
                                        await supabase
                                            .from('products')
                                            .update(data)
                                            .eq('id', existing['id'] as String);
                                      } else {
                                        await supabase
                                            .from('products')
                                            .insert(data);
                                      }

                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _showSnack(existing == null
                                          ? '✅ Товар ийгиликтүү кошулду!'
                                          : '✅ Товар жаңыртылды!');
                                      _loadProducts();
                                    } catch (e) {
                                      setD(() {
                                        isLoading = false;
                                        isUploading = false;
                                        uploadStatus = '';
                                      });
                                      _showSnack('Ката чыкты: $e',
                                          isError: true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    existing == null
                                        ? 'Товарды сактоо'
                                        : 'Өзгөртүүлөрдү сактоо',
                                    style: AppTextStyles.labelLarge
                                        .copyWith(color: Colors.white),
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
    );
  }

  // ══════════════════════════════════════════════
  // ЖАРДАМЧЫ ВИДЖЕТТЕР
  // ══════════════════════════════════════════════
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                AppTextStyles.labelMedium.copyWith(color: AppColors.grey600)),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: AppTextStyles.bodyMedium,
        decoration: _deco(hint),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _noImage() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('📦', style: TextStyle(fontSize: 28))),
      );

  Widget _uploadPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              size: 40, color: AppColors.grey400),
          const SizedBox(height: 8),
          Text('Сүрөт тандоо үчүн басыңыз',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
          const SizedBox(height: 4),
          Text('Галереядан тандалат',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.grey300)),
        ],
      );

  Widget _colorPicker(List<String> selected, StateSetter setD) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allColors.map((c) {
        final isSelected = selected.contains(c['name']);
        return GestureDetector(
          onTap: () {
            setD(() {
              if (isSelected) {
                selected.remove(c['name']);
              } else {
                selected.add(c['name'] as String);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(c['hex'] as int),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  c['name'] as String,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.grey600,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 12, color: AppColors.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sizePicker(
      List<String> sizes, List<String> selected, StateSetter setD) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((s) {
        final isSelected = selected.contains(s);
        return GestureDetector(
          onTap: () {
            setD(() {
              if (isSelected) {
                selected.remove(s);
              } else {
                selected.add(s);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}