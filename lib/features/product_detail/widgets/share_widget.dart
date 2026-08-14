import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import 'package:share_plus/share_plus.dart';

class ShareWidget {
  static void show(BuildContext context, ProductModel product) {
    final text = '${product.name}\n'
        '${product.priceFormatted}\n\n'
        'https://dd-online-web.web.app/product/${product.id}';
    Share.share(text);
  }
}