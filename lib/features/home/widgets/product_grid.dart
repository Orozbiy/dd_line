import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;

  const ProductGrid({super.key, required this.products, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Товарлар табылган жок',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width > 1200) {
      crossAxisCount = 5;
    } else if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      cacheExtent: MediaQuery.of(context).size.height * 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          key: ValueKey(products[index].id),
          child: ProductCard(
            product: products[index],
            onTap: () => onProductTap(products[index]),
          ),
        );
      },
    );
  }
}