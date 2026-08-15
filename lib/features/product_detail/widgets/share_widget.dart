import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import 'package:share_plus/share_plus.dart';

class ShareWidget {
  static const _playStore =
      'https://play.google.com/store/apps/details?id=com.ddonline.app';

  static void show(BuildContext context, ProductModel product) {
    final text = '🛍 ${product.name}\n'
        '💰 ${product.priceFormatted}\n\n'
        '📲 Колдонмодо кара:\n'
        'ddonline://product/${product.id}\n\n'
        '🌐 же браузерде:\n'
        'https://dd-online-web.web.app/product/${product.id}\n\n'
        '⬇️ Жүктөп алуу:\n'
        '$_playStore';

    Share.share(text);
  }
}