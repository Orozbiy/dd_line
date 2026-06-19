import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/utils/favorites_manager.dart';
import '../../../data/models/product_model.dart';
import '../../product_detail/screens/product_detail_screen.dart';
import '../widgets/product_grid.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _fav = FavoritesManager();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final products = _fav.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(loc.get('favorites'), style: AppTextStyles.headingMedium),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_outline, size: 80, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text(
                    loc.get('favorites_empty'),
                    style: AppTextStyles.headingSmall.copyWith(color: AppColors.grey400),
                  ),
                  const SizedBox(height: 8),
                  Text(loc.get('favorites_empty_desc'), style: AppTextStyles.bodyMedium),
                ],
              ),
            )
          : ProductGrid(
              products: List<ProductModel>.from(products),
              onProductTap: (product) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                ).then((_) => setState(() {}));
              },
            ),
    );
  }
}
