import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/supabase_client.dart';
import '../../auth/screens/welcome_screen.dart';

/// Аккаунтту коопсуз өчүрүү экраны.
///
/// 3 кадам коопсуздук:
/// 1. Face ID / Биометрия текшерүү
/// 2. "Түшүндүм" баскычын 5 секунд кармоо
/// 3. Галочка + 5 секунд таймер → "Өчүрүү" баскычы активдешет
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen>
    with TickerProviderStateMixin {
  // ── Абал ──
  int _step = 0; // 0=биометрия, 1=түшүндүм, 2=галочка+таймер
  bool _biometricPassed = false;
  bool _isDeleting = false;

  // Кадам 1: Түшүндүм баскычы — 5 сек кармоо
  bool _holdingButton = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  // Кадам 2: Галочка + таймер
  bool _checkboxChecked = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _deleteReady = false;

  final _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    // Биометрияны автоматтык текшерүү
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  // КАДАМ 0: БИОМЕТРИЯ (Face ID / Touch ID)
  // ═══════════════════════════════════════════
  Future<void> _authenticate() async {
    final loc = AppLocalizations.of(context);
    try {
      final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) {
        // Биометрия жок — PIN/пароль менен текшерүү
        final didAuth = await _auth.authenticate(
          localizedReason: loc.get('delete_biometric_reason'),
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (didAuth && mounted) {
          setState(() {
            _biometricPassed = true;
            _step = 1;
          });
        }
        return;
      }

      final didAuth = await _auth.authenticate(
        localizedReason: loc.get('delete_biometric_reason'),
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuth && mounted) {
        setState(() {
          _biometricPassed = true;
          _step = 1;
        });
        HapticFeedback.mediumImpact();
      } else if (mounted) {
        Navigator.pop(context);
      }
    } on PlatformException catch (e) {
      debugPrint('Биометрия ката: $e');
      if (mounted) {
        _showSnack('${loc.get('error')}: $e');
        Navigator.pop(context);
      }
    }
  }

  // ═══════════════════════════════════════════
  // КАДАМ 1: "ТҮШҮНДҮМ" БАСКЫЧЫН 5 СЕК КАРМОО
  // ═══════════════════════════════════════════
  void _onHoldStart() {
    setState(() => _holdingButton = true);
    HapticFeedback.lightImpact();

    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 0.05 / 5; // 5 секундда толот (50мс * 100 = 5000мс)
      });
      if (_holdProgress >= 1.0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _step = 2;
          _holdingButton = false;
        });
      }
    });
  }

  void _onHoldEnd() {
    _holdTimer?.cancel();
    if (_step < 2) {
      setState(() {
        _holdingButton = false;
        _holdProgress = 0.0;
      });
    }
  }

  // ═══════════════════════════════════════════
  // КАДАМ 2: ГАЛОЧКА + 5 СЕК ТАЙМЕР
  // ═══════════════════════════════════════════
  void _onCheckboxChanged(bool? value) {
    setState(() {
      _checkboxChecked = value ?? false;
      _deleteReady = false;
      _countdown = 5;
    });
    _countdownTimer?.cancel();

    if (_checkboxChecked) {
      HapticFeedback.selectionClick();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _countdown--);
        if (_countdown <= 0) {
          timer.cancel();
          setState(() => _deleteReady = true);
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  // ═══════════════════════════════════════════
  // АККАУНТТУ ӨЧҮрҮҮ
  // ═══════════════════════════════════════════
  Future<void> _deleteAccount() async {
    if (_isDeleting) return;
    final loc = AppLocalizations.of(context);

    setState(() => _isDeleting = true);

    try {
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('Сессия табылган жок');

      // Edge Function чакыруу — серверде жок кылуу
      final response = await supabase.functions.invoke(
        'delete-account',
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Белгисиз ката';
        throw Exception(error);
      }

      // Локалдык сессияны тазалоо
      await supabase.auth.signOut();

      if (mounted) {
        HapticFeedback.heavyImpact();
        // Welcome экранга кайтуу — бардык стекти тазалоо
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showSnack('${loc.get('error')}: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ═══════════════════════════════════════════
  // GLASS HELPER
  // ═══════════════════════════════════════════
  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.80),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : AppColors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ),
        foregroundColor: textColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.get('delete_account_title'),
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.error),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + kToolbarHeight + 24,
          20,
          60,
        ),
        child: Column(
          children: [
            // ── Эскертүү иконкасы ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              loc.get('delete_account_warning'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // ── КАДАМДАР ──
            if (!_biometricPassed) _buildBiometricStep(isDark, loc),
            if (_step == 1) _buildHoldStep(isDark, loc),
            if (_step == 2) _buildFinalStep(isDark, loc),
          ],
        ),
      ),
    );
  }

  // ── Кадам 0: Биометрия күтүү ──
  Widget _buildBiometricStep(bool isDark, AppLocalizations loc) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        children: [
          const Icon(Icons.face, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            loc.get('delete_biometric_title'),
            style: AppTextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.get('delete_biometric_subtitle'),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _authenticate,
            child: Text(loc.get('delete_biometric_retry'),
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Кадам 1: 5 сек кармоо ──
  Widget _buildHoldStep(bool isDark, AppLocalizations loc) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        children: [
          // Кадам индикатору
          _stepIndicator(1, isDark),
          const SizedBox(height: 20),

          Text(
            loc.get('delete_step1_title'),
            style: AppTextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.get('delete_step1_subtitle'),
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Эскертүү тизмеси
          _warningItem(loc.get('delete_warn_products'), isDark),
          _warningItem(loc.get('delete_warn_chats'), isDark),
          _warningItem(loc.get('delete_warn_favorites'), isDark),
          _warningItem(loc.get('delete_warn_profile'), isDark),
          _warningItem(loc.get('delete_warn_irreversible'), isDark),

          const SizedBox(height: 24),

          // 5 сек кармоо баскычы
          GestureDetector(
            onLongPressStart: (_) => _onHoldStart(),
            onLongPressEnd: (_) => _onHoldEnd(),
            onLongPressCancel: _onHoldEnd,
            child: Stack(
              children: [
                // Фон
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.08),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Прогресс
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: LinearProgressIndicator(
                      value: _holdProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                // Текст
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _holdingButton
                              ? Icons.touch_app
                              : Icons.touch_app_outlined,
                          color: AppColors.error,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _holdingButton
                              ? loc.get('delete_holding')
                              : loc.get('delete_hold_button'),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Кадам 2: Галочка + таймер ──
  Widget _buildFinalStep(bool isDark, AppLocalizations loc) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        children: [
          _stepIndicator(2, isDark),
          const SizedBox(height: 20),

          Text(
            loc.get('delete_step2_title'),
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Галочка
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _checkboxChecked
                        ? AppColors.error.withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
                child: CheckboxListTile(
                  value: _checkboxChecked,
                  onChanged: _isDeleting ? null : _onCheckboxChanged,
                  activeColor: AppColors.error,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    loc.get('delete_checkbox_text'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Таймер же Өчүрүү баскычы
          if (_checkboxChecked && !_deleteReady)
            // Таймер
            Column(
              children: [
                Text(
                  '$_countdown',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  loc.get('delete_countdown'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.grey500,
                  ),
                ),
              ],
            ),

          if (_deleteReady)
            // ӨЧҮРҮҮ БАСКЫЧЫ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.delete_forever, color: Colors.white),
                label: Text(
                  _isDeleting
                      ? loc.get('delete_deleting')
                      : loc.get('delete_final_button'),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          if (!_checkboxChecked)
            Text(
              loc.get('delete_checkbox_hint'),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white38 : AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ── Кадам индикатору ──
  Widget _stepIndicator(int step, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, step, isDark),
        Container(
          width: 40,
          height: 2,
          color: step >= 2
              ? AppColors.error.withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : AppColors.grey300),
        ),
        _stepDot(2, step, isDark),
      ],
    );
  }

  Widget _stepDot(int dotStep, int currentStep, bool isDark) {
    final isActive = dotStep <= currentStep;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.error
            : (isDark ? Colors.white12 : AppColors.grey300),
      ),
      child: Center(
        child: isActive
            ? (dotStep < currentStep
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('$dotStep',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)))
            : Text('$dotStep',
                style: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.grey500,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Эскертүү пункту ──
  Widget _warningItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline,
              color: AppColors.error.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
