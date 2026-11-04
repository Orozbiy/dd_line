import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Google Sign-In аркылуу Supabase Auth'ка кирүү/чыгуу логикасы.
///
/// Браузер (Custom Tab) аркылуу Google account picker ачылат,
/// андан кийин deep link менен колдонмого кайтарылып, Supabase
/// сессиясы автоматтык түзүлөт.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Колдонмонун deep link redirect URL'и.
  /// AndroidManifest.xml'деги intent-filter жана Supabase Dashboard'дагы
  /// Redirect URLs менен так дал келиши керек.
  static const String _redirectUrl = 'io.supabase.ddonline://login-callback/';

  /// Учурдагы Supabase колдонуучусу (же null).
  User? get currentUser => supabase.auth.currentUser;

  /// Колдонуучу кирген-кирбегенин текшерүү.
  bool get isSignedIn => currentUser != null;

  /// Колдонуучунун auth абалынын өзгөрүүлөрүн угуу
  /// (мис. OAuth callback аркылуу кирген учурда).
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Google аккаунту аркылуу Supabase'ге кирүү.
  ///
  /// Системалык браузерде Google account picker ачылат.
  /// Натыйжа [authStateChanges] аркылуу [AuthChangeEvent.signedIn]
  /// окуясы катары келет.
 Future<void> signInWithGoogle() async {
  try {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication, // ✅ inAppWebView эмес
      queryParams: const {
        'prompt': 'select_account',
        'access_type': 'offline',
      },
    );
  } catch (e) {
    throw AuthException('Кирүүдө ката кетти: $e');
  }
}

  /// Колдонуучу кирген соң профилди акыркы Google маалыматтары
  /// менен синхрондоо (аты, сүрөтү, email).
  ///
  /// [authStateChanges] боюнча signedIn окуясынан кийин чакыруу керек.
Future<void> syncProfile() async {
  final user = currentUser;
  if (user == null) return;

  final identity =
      user.identities?.where((i) => i.provider == 'google').firstOrNull;
  final data = identity?.identityData;

  // Авто ат генерациялоо — профиль жок болсо
  final autoName = data?['full_name'] as String?
      ?? data?['name'] as String?
      ?? user.email?.split('@').first
      ?? 'Колдонуучу';

  final autoAvatar = data?['avatar_url'] as String?
      ?? data?['picture'] as String?;

  try {
    await supabase.from('profiles').upsert({  // update → upsert
      'id':            user.id,
      'full_name':     autoName,
      'avatar_url':    autoAvatar,
      'email':         user.email,
      'role':          'customer',
      'last_active_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  } catch (e) {
    debugPrint('syncProfile ката: $e');
  }

  await NotificationService().saveMyToken();
}

  /// Apple аккаунту аркылуу Supabase'ге кирүү (iOS гана).
  Future<void> signInWithApple() async {
    // 1. nonce жаса — Apple жана Supabase экөөнө бирдей жиберилет
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // 2. Apple'дан credential ал
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw AuthException('Apple identity token жок');

    // 3. Supabase'ге кир
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Криптографиялык коопсуз nonce жасоо
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Колдонуучунун ролун (customer/seller/admin) алуу.
  Future<String> getUserRole() async {
    final user = currentUser;
    if (user == null) return 'customer';

    try {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return data['role'] as String? ?? 'customer';
    } catch (_) {
      return 'customer';
    }
  }

  /// Тиркемеден чыгуу.
  ///
  /// Чыгаар алдында FCM push токенди 'push_tokens' таблицасынан
  /// өчүрөт, антпесе эски колдонуучунун токенине жаны колдонуучунун
  /// push-билдирүүлөрү жетип кетет.
  Future<void> signOut() async {
    await NotificationService().clearMyToken();
    await supabase.auth.signOut();
  }
}