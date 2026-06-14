import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/supabase_client.dart';
import '../../../data/models/product_model.dart';

/// Товарларды Supabase'тен жүктөө:
/// пагинация + персонализация + поиск + "Мага жакын" geo-сорттоо.
class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  static const int pageSize = 10;

  /// Жаңылоо баскычы басылганда өзгөрөт → товарлар алмашат.
  double _randomSeed =
      DateTime.now().millisecondsSinceEpoch % 1000000 / 1000000;

  /// Жаңылоо учурунда чакырылат — жаңы seed орнотот.
  void refreshSeed() {
    _randomSeed = DateTime.now().millisecondsSinceEpoch % 1000000 / 1000000;
  }

  static const List<String> bannedWords = [
    'төш', 'сутюк', 'ички кийим', 'бюстгальтер', 'трус', 'стринг',
    'корсет', 'купальник', 'лифчик', 'танга', 'бикини',
    'трусы', 'стринги', 'нижнее бельё',
    'нижнее', 'белье', 'бельё',
  ];

  // ══════════════════════════════════════════════════════════════════
  // GPS
  // ══════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════
  // КӨРҮҮ ТАРЫХЫН ЖАЗУУ
  // ══════════════════════════════════════════════════════════════════

  Future<void> recordProductView(ProductModel product) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('product_views').upsert({
        'user_id': userId,
        'product_id': product.id,
        'category_id': product.category ?? '',
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      debugPrint('👁️ view жазылды: ${product.name}');
    } catch (e) {
      debugPrint('⚠️ recordProductView: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ПЕРСОНАЛИЗАЦИЯЛАНГАН ЛЕНТА
  // ══════════════════════════════════════════════════════════════════

  Future<List<ProductModel>> fetchProducts({
    int offset = 0,
    String? categoryId,
    String? region,
  }) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null && categoryId == null && region == null) {
      return await _fetchPersonalized(userId: userId, offset: offset);
    }

    return await _fetchRandom(
      offset: offset,
      categoryId: categoryId,
      region: region,
    );
  }

  Future<List<ProductModel>> _fetchPersonalized({
    required String userId,
    int offset = 0,
  }) async {
    try {
      final data = await supabase.rpc(
        'get_personalized_feed',
        params: {
          'p_user_id': userId,
          'p_offset': offset,
          'p_limit': pageSize,
        },
      );
      final results = _mapAndFilter(data as List);

      if (results.length < pageSize) {
        final extra = await _fetchRandom(
          offset: offset,
          extraLimit: pageSize - results.length,
        );
        final seen = results.map((p) => p.id).toSet();
        final merged = [...results, ...extra.where((p) => !seen.contains(p.id))];
        return merged.take(pageSize).toList();
      }

      return results;
    } catch (e) {
      debugPrint('⚠️ _fetchPersonalized ката: $e → random жүктөлөт');
      return await _fetchRandom(offset: offset);
    }
  }

  Future<List<ProductModel>> _fetchRandom({
    int offset = 0,
    String? categoryId,
    String? region,
    int? extraLimit,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_seed': _randomSeed,
        'p_offset': offset,
        'p_limit': extraLimit ?? pageSize,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        params['p_category_id'] = categoryId;
      }

      final data = await supabase.rpc('get_random_feed', params: params);
      return _mapAndFilter(data as List);
    } catch (e) {
      debugPrint('⚠️ _fetchRandom RPC ката: $e → fallback');
      return await _fetchFallback(
        offset: offset,
        categoryId: categoryId,
        region: region,
        limit: extraLimit ?? pageSize,
      );
    }
  }

  /// Fallback: RPC жок болсо жөнөкөй Supabase query.
  /// Жаңылоо басканда башка товарлар чыгышы үчүн — shuffle колдонулат.
  Future<List<ProductModel>> _fetchFallback({
    int offset = 0,
    String? categoryId,
    String? region,
    int limit = 10,
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

    // Жаңылоо баскычы басылганда башка товарлар чыгышы үчүн:
    // Суpabase'тен 50 товар алып, Random shuffle менен 10 тандайбыз.
    // Ошентип ар бир жаңылоодо башка 10 товар көрүнөт.
    final bigLimit = limit * 5; // 10 * 5 = 50 товар алат
    final rng = Random((_randomSeed * 1000000).toInt());

    final data = await query
        .order('created_at', ascending: false)
        .range(0, bigLimit - 1);

    final all = _mapAndFilter(data);

    // Shuffle колдонуп, алгачкы [limit] товарды кайтарат
    all.shuffle(rng);
    return all.take(limit).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  // НОРМАЛИЗАЦИЯ
  // ══════════════════════════════════════════════════════════════════

  static String _normalize(String input) {
    const Map<String, String> table = {
      'ү': 'у', 'Ү': 'у',
      'ө': 'о', 'Ө': 'о',
      'ң': 'н', 'Ң': 'н',
      'ғ': 'г', 'Ғ': 'г',
      'і': 'и', 'І': 'и',
      'ё': 'е', 'Ё': 'е',
    };

    var result = input.toLowerCase();
    for (final entry in table.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════════
  // ПОИСК
  // ══════════════════════════════════════════════════════════════════

  Future<List<ProductModel>> searchProducts({
    required String query,
    String? categoryId,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final normalized = _normalize(trimmed);

    try {
      final params = <String, dynamic>{
        'search_query': normalized,
        'result_limit': limit,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        params['p_category_id'] = categoryId;
      }

      final data = await supabase.rpc(
        'search_products_normalized',
        params: params,
      );

      final results = _mapAndFilter(data as List);
      if (results.isNotEmpty) return results;

      return await _searchFallback(
        normalized: normalized,
        original: trimmed,
        categoryId: categoryId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('⚠️ searchProducts RPC ката: $e → fallback');
      return await _searchFallback(
        normalized: normalized,
        original: trimmed,
        categoryId: categoryId,
        limit: limit,
      );
    }
  }

  Future<List<ProductModel>> _searchFallback({
    required String normalized,
    required String original,
    String? categoryId,
    int limit = 50,
  }) async {
    final queries = [
      _ilikeSearch(pattern: normalized, categoryId: categoryId, limit: limit),
      if (normalized != original)
        _ilikeSearch(pattern: original, categoryId: categoryId, limit: limit),
    ];

    final futures = await Future.wait(queries);

    final seen = <String>{};
    final merged = <ProductModel>[];
    for (final list in futures) {
      for (final p in list) {
        if (seen.add(p.id)) merged.add(p);
      }
    }

    merged.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return merged.take(limit).toList();
  }

  Future<List<ProductModel>> _ilikeSearch({
    required String pattern,
    String? categoryId,
    int limit = 50,
  }) async {
    try {
      var q = supabase
          .from('products')
          .select('*, stores(store_name, owner_id)')
          .eq('is_active', true)
          .ilike('title', '%$pattern%');

      if (categoryId != null && categoryId.isNotEmpty) {
        q = q.eq('category_id', categoryId);
      }

      final data = await q.order('rating', ascending: false).limit(limit);
      return _mapAndFilter(data);
    } catch (e) {
      debugPrint('❌ _ilikeSearch ката: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // МАГА ЖАКЫН
  // ══════════════════════════════════════════════════════════════════

  Future<List<ProductModel>> fetchProductsNearby({
    required double lat,
    required double lng,
    double radiusKm = 50,
    int limit = pageSize,
    String? categoryId,
  }) async {
    final params = <String, dynamic>{
      'user_lat': lat,
      'user_lng': lng,
      'radius_km': radiusKm,
      'result_limit': limit,
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      params['p_category_id'] = categoryId;
    }

    final data = await supabase.rpc('products_nearby', params: params);
    return _mapAndFilter(data as List);
  }

  // ══════════════════════════════════════════════════════════════════
  // ЖАРДАМЧЫ
  // ══════════════════════════════════════════════════════════════════

  List<ProductModel> _mapAndFilter(List<dynamic> rows) {
    return rows
        .cast<Map<String, dynamic>>()
        .map((row) => ProductModel.fromMap(row))
        .where((p) {
          final name = p.name.toLowerCase();
          return !bannedWords.any((w) => name.contains(w.toLowerCase()));
        })
        .toList();
  }
}
