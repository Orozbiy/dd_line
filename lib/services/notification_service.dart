import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../core/supabase_client.dart';
import '../features/chat/screens/chat_screen.dart';

// ─────────────────────────────────────────────────────────────
// GLOBAL NAVIGATOR KEY — main.dart'та MaterialApp'ка берилет
// ─────────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        final chatId = response.payload;
        debugPrint('🔔 [Foreground tap] chatId=$chatId');
        if (chatId != null) {
          _navigateToChat(chatId);
        }
      },
    );

    // ── FOREGROUND: колдонмо ачык турганда билдирүүнү көрсөт ──
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  debugPrint('🔔 onMessage келди: ${message.data}');  // ← кош

      final notification = message.notification;
      final title =
          notification?.title ?? message.data['senderName'] ?? 'DD Online';
      final body =
          notification?.body ?? message.data['body'] ?? 'Жаңы билдирүү';

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
        // chatId payload'у — таптаганда onDidReceiveNotificationResponse'ка берилет
        payload: message.data['chatId'],
      );
    });

    // ── BACKGROUND → FOREGROUND: колдонмо фондо турганда notification таптаганда ──
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatId = message.data['chatId'] as String?;
      debugPrint('🔔 [Background→Foreground tap] chatId=$chatId');
      if (chatId != null) {
        _navigateToChat(chatId);
      }
    });

    // ── TERMINATED → OPEN: колдонмо толук өчүк турганда notification таптаганда ──
    // (handleInitialMessage main.dart'та init'тен кийин чакырылат)

    // ── iOS foreground notification ──
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('✅ NotificationService даяр');
  }

  // ─────────────────────────────────────────────────────────────
  // TERMINATED STATE: колдонмо өчүк турганда notification таптаса
  // main.dart'та _initFirebase() ичинен чакырылат
  // ─────────────────────────────────────────────────────────────
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return;
    final chatId = message.data['chatId'] as String?;
    debugPrint('🔔 [Terminated→Open] chatId=$chatId');
    if (chatId != null) {
      // SplashRouter жүктөлүп бүтүшүн күтөбүз
      await Future.delayed(const Duration(milliseconds: 800));
      _navigateToChat(chatId);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NAVIGATE TO CHAT — chatId аркылуу ChatScreen'ге өтүү
  // Supabase'тан chat маалыматтарын алып, ChatScreen.fromChat() менен ачат
  // ─────────────────────────────────────────────────────────────
  Future<void> _navigateToChat(String chatId) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ navigatorKey.currentContext null — navigate болбой жатат');
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Колдонуучу кирген эмес — navigate токтотулду');
        return;
      }

      // Supabase'тан chat маалыматтарын алуу
      final row = await supabase
          .from('chats')
          .select(
              'id, seller_id, buyer_id, product_id, seller_name, last_message, last_message_at')
          .eq('id', chatId)
          .maybeSingle();

      if (row == null) {
        debugPrint('⚠️ Chat табылбады: chatId=$chatId');
        return;
      }

      // Учурдагы колдонуучу сатуучубу же кардарбы
      final isSeller = row['seller_id'] == user.id;

      // Товар маалыматы
      String productName = '';
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
            productName = product['title'] as String? ?? '';
            final images = product['images'] as List?;
            productImage = (images != null && images.isNotEmpty)
                ? images.first as String
                : '';
          }
        } catch (_) {}
      }

      // Башка колдонуучунун аватары
      String otherAvatarUrl = '';
      final otherUserId = isSeller
          ? row['buyer_id'] as String? ?? ''
          : row['seller_id'] as String? ?? '';
      try {
        final profile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();
        otherAvatarUrl = profile?['avatar_url'] as String? ?? '';
      } catch (_) {}

      // Эскертүү: navigator context'и mounted болушу керек
      if (!context.mounted) return;

      // ChatScreen импорту
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _buildChatScreen(
            chatId: chatId,
            sellerName: row['seller_name'] as String? ?? 'Сатуучу',
            productName: productName,
            productImage: productImage,
            isSeller: isSeller,
            buyerId: row['buyer_id'] as String? ?? '',
            sellerId: row['seller_id'] as String? ?? '',
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
  // ChatScreen widget'ын lazy import менен кура
  // (circular import болбосун деп функция катары бөлүндү)
  // ─────────────────────────────────────────────────────────────
  Widget _buildChatScreen({
    required String chatId,
    required String sellerName,
    required String productName,
    required String productImage,
    required bool isSeller,
    required String buyerId,
    required String sellerId,
    required String otherAvatarUrl,
  }) {
    // Import'ту бул файлдын башына кош:
    // import '../features/chat/screens/chat_screen.dart';
    return _ChatScreenProxy(
      chatId: chatId,
      sellerName: sellerName,
      productName: productName,
      productImage: productImage,
      isSeller: isSeller,
      buyerId: buyerId,
      sellerId: sellerId,
      otherAvatarUrl: otherAvatarUrl,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN — Supabase'ка сактоо
  // ─────────────────────────────────────────────────────────────
  Future<void> saveMyToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      debugPrint('✅ FCM Token: $token');

      await supabase.from('push_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      _messaging.onTokenRefresh.listen((newToken) async {
        await supabase.from('push_tokens').upsert({
          'user_id': user.id,
          'token': newToken,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      });
    } catch (e) {
      debugPrint('❌ Token сактоо катасы: $e');
    }
  }

  /// Logout'та токенди өчүрүү
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
  // ACCESS TOKEN — service_account.json аркылуу
  // ─────────────────────────────────────────────────────────────
  Future<String?> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('service_account.json');
      final json = jsonDecode(jsonString);
      final accountCredentials = ServiceAccountCredentials.fromJson(json);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ Access Token ката: $e');
      return null;
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
      const url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'chat_messages',
                'sound': 'default',
                'default_vibrate_timings': true,
                'notification_priority': 'PRIORITY_MAX',
                'visibility': 'PUBLIC',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                  'content-available': 1,
                },
              },
              'headers': {
                'apns-priority': '10',
              },
            },
            'data': {
              'chatId': chatId,
              'type': 'chat_message',
              'senderName': senderName,
              'title': senderName, // ← notification title data'да
              'body': messageText, // ← notification body data'да
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
          priority: Priority.max,
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
}

// ─────────────────────────────────────────────────────────────
// Proxy widget — circular import'тан качуу үчүн
// notification_service.dart ChatScreen'ди түз import кылбайт,
// анын ордуна _ChatScreenProxy колдонот.
//
// ❗ Бул классты ЖОК КЫЛ жана notification_service.dart'ка
//    төмөнкү import'ту кош:
//    import '../features/chat/screens/chat_screen.dart';
//    Анан _buildChatScreen() ичинде ChatScreen(...) түз кайтар.
//
// Же болбосо ушул proxy'ни chat_screen.dart'та сактап кой —
// ал жерде ChatScreen жеткиликтүү.
// ─────────────────────────────────────────────────────────────
class _ChatScreenProxy extends StatelessWidget {
  final String chatId;
  final String sellerName;
  final String productName;
  final String productImage;
  final bool isSeller;
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
      chatId: chatId,
      sellerName: sellerName,
      productName: productName,
      productImage: productImage,
      isSeller: isSeller,
      buyerId: buyerId,
      sellerId: sellerId,
      otherAvatarUrl: otherAvatarUrl,
    );
  }
}
