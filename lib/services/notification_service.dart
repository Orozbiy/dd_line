import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../core/supabase_client.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/product_detail/screens/product_detail_screen.dart';
import '../data/models/product_model.dart';

// ─────────────────────────────────────────────────────────────
// GLOBAL NAVIGATOR KEY — MaterialApp'ка берилет
// ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Terminated state үчүн убактылуу сакталат
  static String? pendingChatId;
  static String? pendingProductId;

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
        // ── FOREGROUND: колдонуучу local notification'го тапты ──
        final payload = response.payload ?? '';
        debugPrint('🔔 [Foreground tap] payload=$payload');
        if (payload.isEmpty) return;

        // payload форматы: "chat:CHAT_ID" же "product:PRODUCT_ID"
        if (payload.startsWith('chat:')) {
          final chatId = payload.substring(5);
          if (chatId.isNotEmpty) _navigateToChat(chatId);
        } else if (payload.startsWith('product:')) {
          final productId = payload.substring(8);
          if (productId.isNotEmpty) navigateToProductPublic(productId);
        } else {
          // Эски формат: түздөн-түз chatId
          _navigateToChat(payload);
        }
      },
    );

    // ── FOREGROUND: колдонмо ачык турганда FCM билдирүүнү local notification катары көрсөт ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 onMessage келди: ${message.data}');

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type'] as String? ?? 'chat_message';

      final notification = message.notification;
      final title = notification?.title ?? message.data['senderName'] ?? 'DD Online';
      final body  = notification?.body  ?? message.data['body']       ?? 'Жаңы билдирүү';

      // payload: navigate үчүн
      String payload = '';
      if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        payload = 'chat:$chatId';
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        payload = 'product:$productId';
      } else if (chatId != null && chatId.isNotEmpty) {
        payload = 'chat:$chatId';
      }

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
            priority:   Priority.max,
            icon:       '@mipmap/ic_launcher',
            playSound:        true,
            enableVibration:  true,
            channelShowBadge: true,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload, // ✅ tap болгондо onDidReceiveNotificationResponse чакырылат
      );
    });

    // ── BACKGROUND → FOREGROUND: фондо турганда FCM notification таптаганда ──
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('🔔 [Background→Foreground tap] data=${message.data}');

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type'] as String? ?? 'chat_message';

      // Колдонмо жүктөлүп бүтө электе болушу мүмкүн
      await Future.delayed(const Duration(milliseconds: 800));

      if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        await _navigateToChat(chatId);
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        await navigateToProductPublic(productId);
      } else if (chatId != null && chatId.isNotEmpty) {
        await _navigateToChat(chatId);
      }
    });

    // ── iOS foreground ──
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('✅ NotificationService даяр');
  }

  // ─────────────────────────────────────────────────────────────
  // TERMINATED STATE
  // Колдонмо ТОЛУК жабык турганда notification басылганда
  // main() ичинде runApp() ЧЕЙИН чакырылат
  // ─────────────────────────────────────────────────────────────
  Future<void> handleInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) {
        debugPrint('🔔 [Terminated] getInitialMessage: null (колдонмо notification менен эмес ачылды)');
        return;
      }

      final chatId    = message.data['chatId']    as String?;
      final productId = message.data['productId'] as String?;
      final type      = message.data['type'] as String? ?? 'chat_message';

      debugPrint('🔔 [Terminated→Open] type=$type chatId=$chatId productId=$productId');

      if (type == 'chat_message' && chatId != null && chatId.isNotEmpty) {
        NotificationService.pendingChatId = chatId;
      } else if (type == 'price_drop' && productId != null && productId.isNotEmpty) {
        NotificationService.pendingProductId = productId;
      } else if (chatId != null && chatId.isNotEmpty) {
        // type жок болсо да chatId бар болсо чатка өт
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

    // navigatorKey даяр болгонча күт (макс 3 секунд)
    BuildContext? context;
    for (int i = 0; i < 15; i++) {
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
        debugPrint('⚠️ Колдонуучу кирген эмес');
        NotificationService.pendingChatId = chatId;
        return;
      }

      // Chat маалыматтарын алабыз
      final row = await supabase
          .from('chats')
          .select('id, seller_id, buyer_id, product_id, seller_name, last_message, last_message_at')
          .eq('id', chatId)
          .maybeSingle();

      if (row == null) {
        debugPrint('⚠️ Chat табылбады: chatId=$chatId');
        return;
      }

      final isSeller = row['seller_id'] == user.id;

      // Товар маалыматтарын алабыз
      String productName  = '';
      String productImage = '';
      final productId = row['product_id'] as String?;
      if (productId != null) {
        try {
          final product = await supabase
              .from('products')
              .select('title, images')
              .eq('id', productId)
              .maybeSingle();
          if (product != null) {
            productName  = product['title'] as String? ?? '';
            final images = product['images'] as List?;
            productImage = (images != null && images.isNotEmpty)
                ? images.first as String
                : '';
          }
        } catch (_) {}
      }

      // Башка колдонуучунун аватарын алабыз
      String otherAvatarUrl = '';
      final otherUserId = isSeller
          ? row['buyer_id']  as String? ?? ''
          : row['seller_id'] as String? ?? '';
      try {
        final profile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();
        otherAvatarUrl = profile?['avatar_url'] as String? ?? '';
      } catch (_) {}

      // Context дагы эле жашап жатабы?
      context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ChatScreenProxy(
            chatId:        chatId,
            sellerName:    row['seller_name'] as String? ?? 'Сатуучу',
            productName:   productName,
            productImage:  productImage,
            isSeller:      isSeller,
            buyerId:       row['buyer_id']    as String? ?? '',
            sellerId:      row['seller_id']   as String? ?? '',
            otherAvatarUrl: otherAvatarUrl,
          ),
        ),
      );

      debugPrint('✅ ChatScreen\'ге navigate болду → chatId=$chatId');
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
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );

      debugPrint('✅ ProductDetailScreen\'ге navigate болду → productId=$productId');
    } catch (e) {
      debugPrint('❌ _navigateToProduct катасы: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEND CHAT NOTIFICATION — FCM v1 API
  // ─────────────────────────────────────────────────────────────
  Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    debugPrint('📤 sendChatNotification → receiverUid=$receiverUid');
    try {
      final tokenRow = await supabase
          .from('push_tokens')
          .select('token')
          .eq('user_id', receiverUid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final fcmToken = tokenRow?['token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM токен табылбады, receiverUid=$receiverUid');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('⚠️ Access Token алынбады');
        return;
      }

      const projectId = 'dd-online-web';
      const url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {
              'title': senderName,
              'body':  messageText,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id':              'chat_messages',
                'sound':                   'default',
                'default_vibrate_timings': true,
                'notification_priority':   'PRIORITY_MAX',
                'visibility':              'PUBLIC',
                // ✅ Android'до tap болгондо колдонмо ачылышы үчүн
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound':             'default',
                  'badge':             1,
                  'content-available': 1,
                },
              },
              'headers': {
                'apns-priority': '10',
              },
            },
            'data': {
              'chatId':     chatId,         // ✅ navigate үчүн негизгиси
              'type':       'chat_message',
              'senderName': senderName,
              'title':      senderName,
              'body':       messageText,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification жиберилди → $senderName: $messageText');
      } else {
        debugPrint('❌ FCM ката: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Notification жибере алган жок: $e');
    }
  }

  /// Тест notification'у (debug үчүн)
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
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN — Supabase'ка сактоо / өчүрүү
  // ─────────────────────────────────────────────────────────────
  Future<void> saveMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      debugPrint('✅ FCM Token сакталды');

      await supabase.from('push_tokens').upsert({
        'user_id':    user.id,
        'token':      token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // Token жаңырса автоматтык жаңыртат
      _messaging.onTokenRefresh.listen((newToken) async {
        await supabase.from('push_tokens').upsert({
          'user_id':    user.id,
          'token':      newToken,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      });
    } catch (e) {
      debugPrint('❌ Token сактоо катасы: $e');
    }
  }

  Future<void> clearMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      await supabase.from('push_tokens').delete().eq('user_id', user.id);
      debugPrint('🗑️ FCM Token өчүрүлдү (user_id=${user.id})');
    } catch (e) {
      debugPrint('❌ Token өчүрүү катасы: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ACCESS TOKEN (Google Service Account)
  // ─────────────────────────────────────────────────────────────
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final json = jsonDecode(jsonString);
      final accountCredentials = ServiceAccountCredentials.fromJson(json);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final token  = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ Access Token ката: $e');
      return null;
    }
  }
} // ← NotificationService классы бул жерде ЖАБЫЛАТ

// ─────────────────────────────────────────────────────────────
// _ChatScreenProxy — circular import'тан качуу үчүн
// ChatScreen'ди түздөн-түз notification_service.dart'тан
// импорт кылуу circular import берет, ошондуктан
// proxy widget аркылуу өтөбүз.
// ─────────────────────────────────────────────────────────────
class _ChatScreenProxy extends StatelessWidget {
  final String chatId;
  final String sellerName;
  final String productName;
  final String productImage;
  final bool   isSeller;
  final String buyerId;
  final String sellerId;
  final String otherAvatarUrl;

  const _ChatScreenProxy({
    required this.chatId,
    required this.sellerName,
    required this.productName,
    required this.productImage,
    required this.isSeller,
    required this.buyerId,
    required this.sellerId,
    required this.otherAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChatScreen(
      chatId:        chatId,
      sellerName:    sellerName,
      productName:   productName,
      productImage:  productImage,
      isSeller:      isSeller,
      buyerId:       buyerId,
      sellerId:      sellerId,
      otherAvatarUrl: otherAvatarUrl,
    );
  }
}