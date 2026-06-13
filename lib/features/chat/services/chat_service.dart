import 'package:flutter/foundation.dart';
import '../../../core/supabase_client.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Supabase'тин `chats` жана `messages` таблицалары аркылуу
/// иштеген чат сервиси (Realtime колдонот).
class ChatService {
  /// Кардар-сатуучу-товар комбинациясы үчүн чатты табуу/түзүү.
  /// Сатуучунун аты жана товар маалыматы _enrichChats() аркылуу
  /// автоматтык түрдө стримде толтурулат, ошондуктан бул жерде
  /// зарыл эмес.
  Future<String> getOrCreateChat({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) async {
    // Бар болсо табуу
    final existing = await supabase
        .from('chats')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Жок болсо түзүү
    final inserted = await supabase
        .from('chats')
        .insert({
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'product_id': productId,
          'last_message': '',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  /// Билдирүү жөнөтүү. Натыйжада `chats.last_message` жана unread эсептегичтер
  /// триггер аркылуу авто жаңырат.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    String? imageUrl,
    String? audioUrl,
    int? audioDuration,
    String? replyToId,
    String? replyToText,
  }) async {
    await supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'is_read': false,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToText != null) 'reply_to_text': replyToText,
    });
  }

  /// Чатты "окулду" деп белгилөө: unread эсептегичти нөлдөйт жана
  /// башка колдонуучудан келген билдирүүлөрдү `is_read = true` кылат.
  Future<void> markAsRead({
    required String chatId,
    required String myUserId,
    required bool readerIsBuyer,
  }) async {
    debugPrint(
        '👁️ markAsRead чакырылды → chatId=$chatId, myUserId=$myUserId, readerIsBuyer=$readerIsBuyer');

    try {
      // 1) chats таблицасындагы unread эсептегичти нөлдөө
      final chatUpdateResult = await supabase
          .from('chats')
          .update({
            if (readerIsBuyer) 'buyer_unread': 0,
            if (!readerIsBuyer) 'seller_unread': 0,
          })
          .eq('id', chatId)
          .select();
      debugPrint('👁️ chats update натыйжасы: $chatUpdateResult');

      // 2) Башка колдонуучудан келген окулбаган билдирүүлөрдү окулду кылуу
      final msgUpdateResult = await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .eq('is_read', false)
          .neq('sender_id', myUserId)
          .select();
      debugPrint(
          '👁️ messages update натыйжасы (жаныртылган катарлар): ${msgUpdateResult.length} — $msgUpdateResult');
    } catch (e) {
      debugPrint('❌ markAsRead катасы: $e');
    }
  }

  /// Чатты толугу менен өчүрүү (билдирүүлөр + чат жазуусу).
  Future<void> deleteChat(String chatId) async {
    await supabase.from('messages').delete().eq('chat_id', chatId);
    await supabase.from('chats').delete().eq('id', chatId);
  }

  /// Тандалган билдирүүлөрдү гана өчүрүү (chats жазуусуна тийбейт).
  Future<void> deleteMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await supabase.from('messages').delete().inFilter('id', messageIds);
  }

  /// Чаттагы билдирүүлөрдүн реалдуу убакыттагы стриму.
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map((row) => MessageModel.fromMap(row)).toList());
  }

  /// Кардардын чаттарынын стриму (сатуучунун аты product JOIN аркылуу).
  Stream<List<ChatModel>> buyerChatsStream(String buyerId) {
    return supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('buyer_id', buyerId)
        .order('last_message_at', ascending: false)
        .asyncMap((rows) => _enrichChats(rows, isSeller: false));
  }

  /// Сатуучунун чаттарынын стриму.
  Stream<List<ChatModel>> sellerChatsStream(String sellerId) {
    return supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .order('last_message_at', ascending: false)
        .asyncMap((rows) => _enrichChats(rows, isSeller: true));
  }

  /// Ар бир чатка тиешелүү товардын аталышы/сүрөтүн, сатуучунун
  /// атын жана эки тараптын аватарларын кошуп, `ChatModel`
  /// тизмесине айлантат.
  ///
  /// Realtime `stream()` JOIN колдобогондуктан, бул жерде
  /// product/profile маалыматтары өзүнчө сурам менен толтурулат.
  Future<List<ChatModel>> _enrichChats(
    List<Map<String, dynamic>> rows, {
    required bool isSeller,
  }) async {
    final result = <ChatModel>[];

    for (final row in rows) {
      final enriched = Map<String, dynamic>.from(row);

      // Товар маалыматы
      final productId = row['product_id'] as String?;
      if (productId != null) {
        try {
          final product = await supabase
              .from('products')
              .select('title, images')
              .eq('id', productId)
              .maybeSingle();
          if (product != null) enriched['products'] = product;
        } catch (_) {}
      }

      // Сатуучунун аты (эгер сакталбаган болсо)
      if ((row['seller_name'] as String? ?? '').isEmpty) {
        try {
          final store = await supabase
              .from('stores')
              .select('store_name')
              .eq('owner_id', row['seller_id'])
              .maybeSingle();
          if (store != null) {
            enriched['seller_name'] = store['store_name'];
          }
        } catch (_) {}
      }

      // Эки тараптын аватарлары (profiles таблицасынан)
      try {
        final buyerProfile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', row['buyer_id'])
            .maybeSingle();
        if (buyerProfile != null) {
          enriched['buyer_avatar'] = buyerProfile['avatar_url'];
        }
      } catch (_) {}

      try {
        final sellerProfile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', row['seller_id'])
            .maybeSingle();
        if (sellerProfile != null) {
          enriched['seller_avatar'] = sellerProfile['avatar_url'];
        }
      } catch (_) {}

      result.add(ChatModel.fromMap(enriched, isSeller: isSeller));
    }

    return result;
  }
}