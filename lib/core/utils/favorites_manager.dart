import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';

/// Избранный товарларды башкаруу
class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static const _kFavKey = 'favorites_items';

  final List<ProductModel> _favorites = [];

  List<ProductModel> get favorites => List.unmodifiable(_favorites);

  // --- SharedPreferences жүктөө ---
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavKey);
    if (raw == null) return;
    try {
      final List decoded = jsonDecode(raw);
      _favorites.clear();
      _favorites.addAll(decoded.map((e) => ProductModel.fromJson(e)));
    } catch (_) {}
  }

  // --- SharedPreferences сактоо ---
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_favorites.map((p) => p.toJson()).toList());
    await prefs.setString(_kFavKey, encoded);
  }

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  void toggle(ProductModel product) {
    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favorites.add(product);
    }
    _saveToPrefs();
  }

  int get count => _favorites.length;
}
