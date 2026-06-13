import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'core/supabase_client.dart';
import 'core/utils/favorites_manager.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/cart/utils/cart_manager.dart';
import 'features/home/screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'core/active_status_tracker.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase (Auth + Database + Storage)
  await SupabaseInit.init();

  // Firebase бул жерде болгону FCM (push notifications) үчүн калат
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await NotificationService().init();
    await NotificationService().saveMyToken();
  } catch (e) {
    debugPrint('❌ NotificationService ката: $e');
  }

  await CartManager.instance.loadFromPrefs();
  await FavoritesManager().loadFromPrefs();

  runApp(const ActiveStatusTracker(child: DDOnlineApp()));
}

class DDOnlineApp extends StatelessWidget {
  const DDOnlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DD Online',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashRouter(),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  bool _checking = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _determineScreen();
  }

  Future<void> _determineScreen() async {
    // Минимум 2.5 секунд splash көрсөтүү
    final results = await Future.wait([
      _getTargetScreen(),
      Future.delayed(const Duration(milliseconds: 4000)),
    ]);
    _targetScreen = results[0] as Widget;

    if (mounted) {
      setState(() => _checking = false);
    }
  }

  Future<Widget> _getTargetScreen() async {
    // Supabase Auth: учурдагы сессияны текшерүү
    final user = supabase.auth.currentSession?.user;
    if (user != null) return const HomeScreen();

    return const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _SplashScreen();
    }
    return _targetScreen!;
  }
}

// ══════════════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════════════
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Логотип + навигация badge ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFD97706),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Color(0xFFD97706),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  'DD Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Дордой базары',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 13,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 40),

                const _DotsIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Анимацияланган чекиттер ──
class _DotsIndicator extends StatefulWidget {
  const _DotsIndicator();

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final value = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity =
                (value < 0.5 ? value * 2 : (1.0 - value) * 2).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}