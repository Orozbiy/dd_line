import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/services/in_app_notification_banner.dart';
import '../core/supabase_client.dart';
import '../data/models/product_model.dart';
// Screen imports removed — builders registered via registerScreenBuilders()

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static String? pendingChatId;
  static String? pendingProductId;
  static bool pendingNotifications = false;

  // ── Screen builders (registered at app startup to avoid circular imports) ──
  static Widget Function(String chatId, String sellerName, String? productId,
      String productName, String productImage, bool isSeller,
      String buyerId, String sellerId, String otherAvatarUrl)? _buildChatScreen;
  static Widget Function(dynamic product)? _buildProductDetail;
  static Widget Function()? _buildNotifications;

  static void registerScreenBuilders({
    required Widget Function(String, String, String?, String, String, bool, String, String, String) chatScreen,
    required Widget Function(dynamic) productDetail,
    required Widget Function() notifications,
  }) {
    _buildChatScreen = chatScreen;
    _buildProductDetail = productDetail;
    _buildNotifications = notifications;
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_messages',
    'Чат билдирүүлөрү',
    description: 'DD Online чат билдирүүлөрү',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    debugPrint('🚀 NotificationService.init() башталды');

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload ?? '';
        debugPrint('🔔 [Foreground tap] payload=$payload');
        if (payload.isEmpty) return;

        if (payload.startsWith('chat:')) {
          final chatId = payload.substring(5);
          if (chatId.isNotEmpty) _navigateToChat(chatId);
        } else if (payload.startsWith('product:')) {
          final productId = payload.substring(8);
          if (productId.isNotEmpty) _navigateToProduct(productId);
        } else if (payload == 'notifications') {
          _navigateToNotifications();
        } else {
          _navigateToChat(payload);
        }
      },
    );

    // ── FOREGROUND ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 onMessage: ${message.data}');

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type']      as String? ?? 'chat_message';

      final notification = message.notification;
      final title = notification?.title ?? message.data['senderName'] ?? 'DD Online';
      final body  = notification?.body  ?? message.data['body']       ?? 'Жаңы билдирүү';

      String payload = '';
      if (type == 'admin_broadcast') {
        payload = 'notifications';
      } else if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        payload = 'chat:$chatId';
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        payload = 'product:$productId';
      } else if (chatId != null && chatId.isNotEmpty) {
        payload = 'chat:$chatId';
      }

      // ── Foreground: айнек banner ──
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        InAppNotificationBanner.show(
          context: ctx,
          title: title,
          body: body,
          avatarText: title,
          onTap: () {
            if (payload.startsWith('chat:')) {
              _navigateToChat(payload.substring(5));
            } else if (payload.startsWith('product:')) {
              _navigateToProduct(payload.substring(8));
            } else if (payload == 'notifications') {
              _navigateToNotifications();
            } else if (payload.isNotEmpty) {
              _navigateToChat(payload);
            }
          },
        );
      } else {
        // App фондо болсо — кадимки system notification
        _localNotif.show(
          message.messageId.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.max,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
              channelShowBadge: true,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: payload,
        );
      }
    });

    // ── BACKGROUND → FOREGROUND ──
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('🔔 [Background→Foreground tap] data=${message.data}');

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type']      as String? ?? 'chat_message';

      await Future.delayed(const Duration(milliseconds: 300));

      if (type == 'admin_broadcast') {
        await _navigateToNotifications();
      } else if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        await _navigateToChat(chatId);
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        await _navigateToProduct(productId);
      } else if (chatId != null && chatId.isNotEmpty) {
        await _navigateToChat(chatId);
      }
    });

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('✅ NotificationService даяр');
  }

  // ─────────────────────────────────────────────────────────────
  // TERMINATED STATE
  // ─────────────────────────────────────────────────────────────
  Future<void> handleInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) {
        debugPrint('🔔 [Terminated] getInitialMessage: null');
        return;
      }

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type']      as String? ?? 'chat_message';

      debugPrint('🔔 [Terminated→Open] type=$type chatId=$chatId productId=$productId');

      if (type == 'admin_broadcast') {
        NotificationService.pendingNotifications = true;
      } else if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        NotificationService.pendingChatId = chatId;
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        NotificationService.pendingProductId = productId;
      } else if (chatId != null && chatId.isNotEmpty) {
        NotificationService.pendingChatId = chatId;
      }
    } catch (e) {
      debugPrint('❌ handleInitialMessage ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC WRAPPERS
  // ─────────────────────────────────────────────────────────────
  Future<void> navigateToChatPublic(String chatId) => _navigateToChat(chatId);
  Future<void> navigateToProductPublic(String productId) => _navigateToProduct(productId);

  // ─────────────────────────────────────────────────────────────
  // NAVIGATE TO CHAT
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToChat(String chatId) async {
    debugPrint('🧭 _navigateToChat chatId=$chatId');

    BuildContext? context;
    for (int i = 0; i < 20; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (context == null) {
      debugPrint('⚠️ navigatorKey null — pendingChatId катары сактайбыз');
      NotificationService.pendingChatId = chatId;
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ User null — pendingChatId катары сактайбыз');
        NotificationService.pendingChatId = chatId;
        return;
      }

      // Баарын параллел жүктөйбүз — 3 запрос бирдикте иштейт
      final row = await supabase
          .from('chats')
          .select('id, seller_id, buyer_id, product_id, seller_name')
          .eq('id', chatId)
          .maybeSingle();

      if (row == null) {
        debugPrint('⚠️ Chat табылбады: chatId=$chatId');
        return;
      }

      final isSeller = row['seller_id'] == user.id;
      debugPrint('🔍 isSeller=$isSeller (userId=${user.id}, sellerId=${row['seller_id']}, buyerId=${row['buyer_id']})');

      final productId = row['product_id'] as String?;
      final otherUserId = isSeller
          ? row['buyer_id']  as String? ?? ''
          : row['seller_id'] as String? ?? '';

      // product жана profile запростарын параллел иштетебиз
      final results = await Future.wait([
        productId != null
            ? supabase.from('products').select('title, images').eq('id', productId).maybeSingle().catchError((_) => null)
            : Future.value(null),
        otherUserId.isNotEmpty
            ? supabase.from('profiles').select('avatar_url').eq('id', otherUserId).maybeSingle().catchError((_) => null)
            : Future.value(null),
      ]);

      String productName  = '';
      String productImage = '';
      final productData = results[0];
      if (productData != null) {
        productName = productData['title'] as String? ?? '';
        final images = productData['images'] as List?;
        productImage = (images != null && images.isNotEmpty) ? images.first as String : '';
      }

      String otherAvatarUrl = '';
      final profileData = results[1];
      final rawAvatar = profileData?['avatar_url'] as String? ?? '';
      otherAvatarUrl = rawAvatar.startsWith('http') ? rawAvatar : '';

      context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => _buildChatScreen!(
            chatId,
            row['seller_name'] as String? ?? 'Сатуучу',
            productId,
            productName,
            productImage,
            isSeller,
            row['buyer_id']  as String? ?? '',
            row['seller_id'] as String? ?? '',
            otherAvatarUrl,
          ),
        ),
      );

      debugPrint('✅ ChatScreen navigate болду → isSeller=$isSeller');
    } catch (e) {
      debugPrint('❌ _navigateToChat катасы: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATE TO PRODUCT
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToProduct(String productId) async {
    debugPrint('🧭 _navigateToProduct productId=$productId');

    BuildContext? context;
    for (int i = 0; i < 15; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (context == null) {
      debugPrint('⚠️ navigatorKey null — pendingProductId катары сактайбыз');
      NotificationService.pendingProductId = productId;
      return;
    }

    try {
      final data = await supabase
          .from('products')
          .select('*, stores(*)')
          .eq('id', productId)
          .maybeSingle();

      if (data == null) {
        debugPrint('⚠️ Product табылбады: productId=$productId');
        return;
      }

      final product = ProductModel.fromMap(data);

      context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _buildProductDetail!(product)),
      );

      debugPrint('✅ ProductDetailScreen navigate болду');
    } catch (e) {
      debugPrint('❌ _navigateToProduct катасы: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATE TO NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToNotifications() async {
    debugPrint('🧭 _navigateToNotifications');

    BuildContext? context;
    for (int i = 0; i < 20; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (context == null || !context.mounted) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => _buildNotifications!()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEND CHAT NOTIFICATION
  // ─────────────────────────────────────────────────────────────
  Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    debugPrint('📤 sendChatNotification → receiverUid=$receiverUid');
    try {
      final res = await supabase.functions.invoke(
        'send-push',
        body: {
          'receiver_uid': receiverUid,
          'title':        senderName,
          'body':         messageText,
          'chat_id':      chatId,
        },
      );
      debugPrint('✅ send-push: ${res.status} ${res.data}');
    } catch (e) {
      debugPrint('❌ sendChatNotification ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BROADCAST — Supabase Edge Function аркылуу
  // ─────────────────────────────────────────────────────────────
  Future<int> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('📢 sendBroadcastNotification башталды');
    try {
      final rows = await supabase
          .from('push_tokens')
          .select('user_id')
          .order('updated_at', ascending: false);

      final userIds = (rows as List)
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isEmpty) {
        debugPrint('⚠️ Колдонуучулар жок');
        return 0;
      }

      debugPrint('📢 Жалпы колдонуучу саны: ${userIds.length}');

      int successCount = 0;
      for (final uid in userIds) {
        try {
          final res = await supabase.functions.invoke(
            'send-push',
            body: {
              'receiver_uid': uid,
              'title':        title,
              'body':         body,
              'chat_id':      '',
            },
          );
          if (res.status == 200) successCount++;
        } catch (e) {
          debugPrint('❌ Broadcast uid=$uid ката: $e');
        }
      }

      debugPrint('✅ Broadcast: $successCount/${userIds.length}');
      return successCount;
    } catch (e) {
      debugPrint('❌ sendBroadcastNotification ката: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TEST NOTIFICATION
  // ─────────────────────────────────────────────────────────────
  Future<void> showTestNotification() async {
    await _localNotif.show(
      999,
      'DD Online 🛍️',
      'Уведомления иштеп жатат!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority:   Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> testSendPush() async {
    debugPrint('🧪 testSendPush башталды...');

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ Колдонуучу кирген жок!');
      return;
    }

    try {
      final res = await supabase.functions.invoke(
        'send-push',
        body: {
          'receiver_uid': user.id,
          'title':        'Тест пуш 🔔',
          'body':         'Пуш иштеп жатат!',
          'chat_id':      'test',
        },
      );
      if (res.status == 200) {
        debugPrint('✅ Тест пуш жиберилди!');
      } else {
        debugPrint('❌ Тест пуш ката: ${res.status} ${res.data}');
      }
    } catch (e) {
      debugPrint('❌ testSendPush ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN — САКТОО
  // ─────────────────────────────────────────────────────────────
  Future<void> saveMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? token;
      String  platform;

      if (kIsWeb) {
        platform = 'web';
        token = await _messaging.getToken(
          vapidKey: 'BDpKYBHjHAilY1jGXlduqw1eJ6lSsmxwkJ8dIgag-2svdBpjn_QsiN2BrSbBboBNmVh2ZI-AQqZe3zaOjFsdXL0',
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
        // iOS: FCM токенден мурун APNs токен даяр болушу керек
        String? apns = await _messaging.getAPNSToken();
        for (int i = 0; apns == null && i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          apns = await _messaging.getAPNSToken();
        }
        if (apns == null) {
          debugPrint('⚠️ APNs token алынган жок (Push capability/APNs key текшериңиз)');
        }
        token = await _messaging.getToken();
      } else {
        platform = 'android';
        token = await _messaging.getToken();
      }

      if (token == null) {
        debugPrint('⚠️ Token null — $platform');
        return;
      }

      debugPrint('💾 FCM Token сакталууда... ($platform): ${token.substring(0, 20)}...');

      await supabase.from('push_tokens').upsert(
        {
          'user_id':    user.id,
          'token':      token,
          'platform':   platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,platform',
      );

      debugPrint('✅ FCM Token сакталды ($platform)');

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await supabase.from('push_tokens').upsert(
            {
              'user_id':    user.id,
              'token':      newToken,
              'platform':   platform,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,platform',
          );
          debugPrint('✅ FCM Token жаңырды ($platform)');
        } catch (e) {
          debugPrint('❌ Token жаңыртуу катасы: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ saveMyToken ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN — ӨЧҮРҮҮ
  // ─────────────────────────────────────────────────────────────
  Future<void> clearMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      await supabase.from('push_tokens').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('❌ clearMyToken ката: $e');
    }
  }

}
