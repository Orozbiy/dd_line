import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';

class PriceWatchService {
  static final PriceWatchService _i = PriceWatchService._();
  factory PriceWatchService() => _i;
  PriceWatchService._();

  Future<void> notifyWatchers({
    required String productId,
    required String productName,
    required double oldPrice,
    required double newPrice,
  }) async {
    try {
      final rows = await supabase
          .from('price_watch')
          .select('user_id')
          .eq('product_id', productId);

      if ((rows as List).isEmpty) return;

      final userIds = rows
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (userIds.isEmpty) return;

      final saved = (oldPrice - newPrice).toStringAsFixed(0);
      final title = '🏷️ Баа түштү! — $productName';
      final body  =
          '${newPrice.toStringAsFixed(0)} сом '
          '(${oldPrice.toStringAsFixed(0)} сомдон), '
          '$saved сомго арзандады!';

      int successCount = 0;
      for (final uid in userIds) {
        try {
          final res = await supabase.functions.invoke(
            'send-push',
            body: {
              'receiver_uid': uid,
              'title':        title,
              'body':         body,
              'chat_id':      productId,
            },
          );
          if (res.status == 200) successCount++;
        } catch (e) {
          debugPrint('❌ PriceWatch uid=$uid ката: $e');
        }
      }

      debugPrint('✅ PriceWatchService: $successCount/${userIds.length} кабарлама жиберилди');
    } catch (e) {
      debugPrint('❌ PriceWatchService.notifyWatchers ката: $e');
    }
  }
}
