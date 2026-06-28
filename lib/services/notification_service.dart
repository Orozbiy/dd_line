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
// GLOBAL NAVIGATOR KEY — main.dart'та MaterialApp'ка берилет
// ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Terminated state үчүн pending маалыматтар
  static String? pendingChatId;
  static String? pendingProductId; // ✅ ЖАҢЫ: deep link product

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
        // ── FOREGROUND: колдонуучу notification'го тапты ──
        final payload = response.payload ?? '';
        debugPrint('🔔 [Foreground tap] payload=$payload');

        // payload форматы: "chat:CHAT_ID" же "product:PRODUCT_ID"
        if (payload.startsWith('chat:')) {
          final chatId = payload.substring(5);
          _navigateToChat(chatId);
        } else if (payload.startsWith('product:')) {
          final productId = payload.substring(8);
          _navigateToProduct(productId);
        } else if (payload.isNotEmpty) {
          // Эски формат: жөн chatId
          _navigateToChat(payload);
        }
      },
    );

    // ── FOREGROUND: колдонмо ачык турганда билдирүүнү көрсөт ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 onMessage келди: ${message.data}');

      final notification = message.notification;
      final title =
          notification?.title ?? message.data['senderName'] ?? 'DD Online';
      final body =
          notification?.body ?? message.data['body'] ?? 'Жаңы билдирүү';

      // payload: chat же product
      final chatId    = message.data['chatId'] as String?;
      final productId = message.data['productId'] as String?;
      final payload   = chatId != null
          ? 'chat:$chatId'
          : productId != null
              ? 'product:$productId'
              : '';

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
    });

    // ── BACKGROUND → FOREGROUND ──
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('🔔 [Background→Foreground tap]');
      await _handleRemoteMessage(message);
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
  // ─────────────────────────────────────────────────────────────
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return;
    debugPrint('🔔 [Terminated→Open]');

    final chatId    = message.data['chatId'] as String?;
    final productId = message.data['productId'] as String?;

    if (chatId != null) {
      NotificationService.pendingChatId = chatId;
    } else if (productId != null) {
      NotificationService.pendingProductId = productId;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REMOTE MESSAGE HANDLER
  // ─────────────────────────────────────────────────────────────
  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final chatId    = message.data['chatId'] as String?;
    final productId = message.data['productId'] as String?;

    if (chatId != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _navigateToChat(chatId);
    } else if (productId != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _navigateToProduct(productId);
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
    // ✅ ТЕЗДЕТҮҮ: контекст даяр болгуча максимум 3 секунд күт (мурда 15 * 200ms = 3s болчу)
    BuildContext? context;
    for (int i = 0; i < 10; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (context == null) {
      debugPrint('⚠️ navigatorKey.currentContext null');
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final row = await supabase
          .from('chats')
          .select(
              'id, seller_id, buyer_id, product_id, seller_name, last_message, last_message_at')
          .eq('id', chatId)
          .maybeSingle();

      if (row == null) return;

      final isSeller = row['seller_id'] == user.id;

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

      context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _buildChatScreen(
            chatId:       chatId,
            sellerName:   row['seller_name']  as String? ?? 'Сатуучу',
            productName:  productName,
            productImage: productImage,
            isSeller:     isSeller,
            buyerId:      row['buyer_id']     as String? ?? '',
            sellerId:     row['seller_id']    as String? ?? '',
            otherAvatar:  otherAvatarUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ _navigateToChat ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ ЖАҢЫ: NAVIGATE TO PRODUCT (WhatsApp deep link үчүн)
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToProduct(String productId) async {
    BuildContext? context;
    for (int i = 0; i < 10; i++) {
      context = navigatorKey.currentContext;
      if (context != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (context == null) {
      debugPrint('⚠️ navigatorKey.currentContext null — product navigate болбой жатат');
      return;
    }

    try {
      final row = await supabase
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (row == null) {
        debugPrint('⚠️ Product табылбады: $productId');
        return;
      }

      final product = ProductModel.fromJson(row);

      context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } catch (e) {
      debugPrint('❌ _navigateToProduct ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CHAT SCREEN BUILDER
  // ─────────────────────────────────────────────────────────────
  Widget _buildChatScreen({
    required String chatId,
    required String sellerName,
    required String productName,
    required String productImage,
    required bool   isSeller,
    required String buyerId,
    required String sellerId,
    required String otherAvatar,
  }) {
    return ChatScreen(
      chatId:       chatId,
      sellerName:   sellerName,
      productName:  productName,
      productImage: productImage,
      isSeller:     isSeller,
      buyerId:      buyerId,
      sellerId:     sellerId,
      otherAvatarUrl: otherAvatar,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN САКТОО
  // ─────────────────────────────────────────────────────────────
  Future<void> saveMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await supabase.from('push_tokens').upsert({
        'user_id':    user.id,
        'token':      token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('✅ FCM токен сакталды');
    } catch (e) {
      debugPrint('❌ saveMyToken ката: $e');
    }
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
      final tokenRow = await supabase
          .from('push_tokens')
          .select('token')
          .eq('user_id', receiverUid)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final fcmToken = tokenRow?['token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM токен табылбады');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

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
                'channel_id':             'chat_messages',
                'sound':                  'default',
                'default_vibrate_timings': true,
                'notification_priority':  'PRIORITY_MAX',
                'visibility':             'PUBLIC',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound':             'default',
                  'badge':              1,
                  'content-available':  1,
                },
              },
              'headers': {'apns-priority': '10'},
            },
            'data': {
              'chatId':     chatId,
              'type':       'chat_message',
              'senderName': senderName,
              'title':      senderName,
              'body':       messageText,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification жиберилди');
      } else {
        debugPrint('❌ FCM ката: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ sendChatNotification ката: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ACCESS TOKEN
  // ─────────────────────────────────────────────────────────────
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/service_account.json');
      final json       = jsonDecode(jsonString);
      final creds      = ServiceAccountCredentials.fromJson(json);
      final scopes     = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client     = await clientViaServiceAccount(creds, scopes);
      final token      = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ Access Token ката: $e');
      return null;
    }
  }

  Future<void> showTestNotification() async {
    await _localNotif.show(
      999,
      'DD Online 🛍️',
      'Уведомления иштеп жатат!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Чат билдирүүлөрү',
          importance: Importance.max,
          priority:   Priority.max,
          icon:       '@mipmap/ic_launcher',
        ),
      ),
      payload: 'test',
    );
  }

  Future<void> clearMyToken() async {}
}