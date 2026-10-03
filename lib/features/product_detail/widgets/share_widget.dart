import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/product_model.dart';

class ShareWidget {
  static const _playStore =
      'https://play.google.com/store/apps/details?id=com.ddonline.app';

  static Future<void> show(BuildContext context, ProductModel product) async {
    final text = '🛍 ${product.name}\n'
        '💰 ${product.priceFormatted}\n\n'
        '📲 Колдонмодо кара:\n'
        'ddonline://product/${product.id}\n\n'
        '🌐 же браузерде:\n'
        'https://dd-online-web.web.app/product/${product.id}\n\n'
        '⬇️ Жүктөп алуу:\n'
        '$_playStore';

    // Бөлүшүү аймагы (iPad үчүн керек)
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(const SnackBar(
      content: Text('Сүрөт даярдалып жатат...'),
      duration: Duration(seconds: 2),
    ));

    final file = await _prepareImage(product);
    messenger?.hideCurrentSnackBar();

    if (file != null) {
      try {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg', name: 'product.jpg')],
          text: text,
          subject: product.name,
          sharePositionOrigin: origin,
        );
        return;
      } catch (e) {
        debugPrint('SHARE image error: $e');
      }
    }

    await Share.share(text, sharePositionOrigin: origin);
  }

  /// Товардын 1-сүрөтүн JPG файл катары даярдайт.
  static Future<File?> _prepareImage(ProductModel product) async {
    final raw = product.imageUrl.isNotEmpty
        ? product.imageUrl
        : (product.images.isNotEmpty ? product.images.first : '');
    if (raw.isEmpty) {
      debugPrint('SHARE: сүрөт URL бош');
      return null;
    }

    // Cloudinary болсо — так JPG, 1080px (webp/avif болуп калбасын)
    final url = (raw.contains('res.cloudinary.com') && raw.contains('/upload/'))
        ? raw.replaceFirst('/upload/', '/upload/w_1080,q_auto,f_jpg/')
        : raw;

    final dir = await getTemporaryDirectory();
    final out = File('${dir.path}/share_${product.id}.jpg');

    // 1) Түз жүктөө
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await out.writeAsBytes(res.bodyBytes, flush: true);
        return out;
      }
      debugPrint('SHARE: http ${res.statusCode} → $url');
    } catch (e) {
      debugPrint('SHARE http error: $e');
    }

    // 2) Кэштен (тиркемеде көрсөтүлгөн сүрөт бар болсо)
    try {
      final cached = await DefaultCacheManager().getSingleFile(raw);
      await cached.copy(out.path);
      return out;
    } catch (e) {
      debugPrint('SHARE cache error: $e');
    }
    return null;
  }
}