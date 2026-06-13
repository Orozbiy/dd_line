import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../core/supabase_client.dart';

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
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> init() async {
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
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['chatId'],
      );
    });

    debugPrint('✅ NotificationService даяр');
  }

  /// FCM токенди Supabase 'push_tokens' таблицасына сактоо
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

  /// Колдонуучу чыгаар алдында (logout) FCM токенди
  /// 'push_tokens' таблицасынан өчүрөт. Бул эски колдонуучунун
  /// токенине жаны колдонуучунун push'тары жетип кетишин болтурбайт.
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

  /// Чат билдирүүсү боюнча push-уведомление жиберүү.
  /// Кабыл алуучунун FCM токенин Supabase 'push_tokens'тан алат.
  Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    debugPrint('📤 sendChatNotification чакырылды → receiverUid=$receiverUid');
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
            'notification': {
              'title': senderName,
              'body': messageText,
            },
            'android': {
              'priority': 'high',
            },
            'data': {
              'chatId': chatId,
              'type': 'chat_message',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Уведомление жиберилди → $senderName: $messageText');
      } else {
        debugPrint('❌ FCM ката: ${response.statusCode} — ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Уведомление жибере алган жок: $e');
    }
  }

  Future<void> showTestNotification() async {
    await _localNotif.show(
      999,
      'DD Online 🛍️',
      'Уведомления иштеп жатат! ✅',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
