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
            Text('Товарлар табылган жок', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width > 1200) {
      crossAxisCount = 5;
    // ignore: curly_braces_in_flow_control_structures
    } else if (width > 900) crossAxisCount = 4;
    // ignore: curly_braces_in_flow_control_structures
    else if (width > 600) crossAxisCount = 3;
    // ignore: curly_braces_in_flow_control_structures
    else crossAxisCount = 2;

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _AnimatedProductCard(
          index: index,
          product: products[index],
          onTap: () => onProductTap(products[index]),
        );
      },
    );
  }
}

/// 0.3 секундада пайда болгон анимациялык карточка
class _AnimatedProductCard extends StatefulWidget {
  final int index;
  final ProductModel product;
  final VoidCallback onTap;

  const _AnimatedProductCard({
    required this.index,
    required this.product,
    required this.onTap,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Кийинки карточкалар бир аз кечигип пайда болот
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ProductCard(
          product: widget.product,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
