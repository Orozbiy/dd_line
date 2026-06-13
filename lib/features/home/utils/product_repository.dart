import 'package:geolocator/geolocator.dart';
import '../../../core/supabase_client.dart';
import '../../../data/models/product_model.dart';

/// Товарларды Supabase'тен жүктөө: пагинация + "Мага жакын" geo-сорттоо.
class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  static const int pageSize = 10;

  /// Сессия ичинде туруктуу random seed (app ачылган сайын жаны тартип).
  static final double _randomSeed =
      DateTime.now().millisecondsSinceEpoch % 1000000 / 1000000;

  static const List<String> bannedWords = [
    'төш', 'сутюк', 'ички кийим', 'бюстгальтер', 'трус', 'стринг',
    'корсет', 'купальник', 'лифчик', 'танга', 'бикини',
    'трусы', 'стринги', 'нижнее бельё',
    'нижнее', 'белье', 'бельё',
  ];

  /// Колдонуучунун учурдагы GPS координатын алуу.
  ///
  /// Уруксат берилбесе же геолокация өчүрүлсө `null` кайтарат.
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  /// Биринчи баракты жүктөө (жөнөкөй тизме, региондук фильтрсиз).
  ///
  /// `region` берилсе, ошол региондогу товарлар биринчи чыгат.
  Future<List<ProductModel>> fetchProducts({
    int offset = 0,
    String? categoryId,
    String? region,
  }) async {
    var query = supabase
        .from('products')
        .select('*, stores(store_name, owner_id)')
        .eq('is_active', true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (region != null && region.isNotEmpty) {
      query = query.eq('region', region);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return _mapAndFilter(data);
  }

  /// Башкы экран үчүн random тартиптеги товарлар (пагинация менен).
  ///
  /// Supabase'те `products_random` RPC функциясы талап кылынат:
  ///
  /// ```sql
  /// create or replace function products_random(
  ///   p_seed double precision,
  ///   p_offset int,
  ///   p_limit int,
  ///   p_category_id text default null
  /// )
  /// returns setof products
  /// language sql
  /// stable
  /// as $$
  ///   select * from products
  ///   tablesample bernoulli(5) repeatable(p_seed)
  ///   where is_active = true
  ///     and (p_category_id is null or category_id = p_category_id)
  ///   limit p_limit
  ///   offset p_offset;
  /// $$;
  /// ```
  Future<List<ProductModel>> fetchProductsRandom({
    int offset = 0,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{
      'p_seed': _randomSeed,
      'p_offset': offset,
      'p_limit': pageSize,
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      params['p_category_id'] = categoryId;
    }

    final data = await supabase.rpc('products_random', params: params);

    return _mapAndFilter(data as List);
  }

  /// "Мага жакын" — PostGIS аркылуу аралык боюнча сорттолгон товарлар.
  ///
  /// `lat`/`lng` — колдонуучунун учурдагы координаты.
  /// Натыйжада ар бир товарда `distanceKm` толтурулат.
  Future<List<ProductModel>> fetchProductsNearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int limit = pageSize,
    String? categoryId,
  }) async {
    // PostGIS: ST_DWithin + ST_Distance аркылуу аралык боюнча сорттоо.
    // Бул RPC функциясын Supabase'те бир жолу түзүү керек (төмөндө SQL берилди).
    final params = <String, dynamic>{
      'user_lat': lat,
      'user_lng': lng,
      'radius_km': radiusKm,
      'result_limit': limit,
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      params['p_category_id'] = categoryId;
    }

    final data = await supabase.rpc(
      'products_nearby',
      params: params,
    );

    return _mapAndFilter(data as List);
  }

  /// Firestore'догу `_mapAndFilter` аналогу: тыюу салынган сөздөрдү
  /// камтыган товарларды чыгарып салат жана `ProductModel` тизмесине айлантат.
  List<ProductModel> _mapAndFilter(List<dynamic> rows) {
    final list = rows
        .cast<Map<String, dynamic>>()
        .map((row) => ProductModel.fromMap(row))
        .where((p) {
      final name = p.name.toLowerCase();
      return !bannedWords.any((w) => name.contains(w.toLowerCase()));
    }).toList();
    return list;
  }
}