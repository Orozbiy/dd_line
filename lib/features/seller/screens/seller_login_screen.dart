import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/seller_auth_service.dart';
import '../../../core/supabase_client.dart';
import '../models/seller_model.dart';
import '../services/seller_service.dart';
import 'seller_dashboard_screen.dart';
import 'seller_pending_screen.dart';
import 'seller_register_screen.dart';
import '../../home/screens/home_screen.dart';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _phoneCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _sellerService  = SellerService();

  bool _obscure          = true;
  bool _isLoading        = false;
  bool _checkingSession  = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _checkingSession = false);
      return;
    }

    final seller = await _sellerService.getSellerByUid(user.id);
    if (!mounted) return;

    if (seller == null) {
      await supabase.auth.signOut();
      setState(() => _checkingSession = false);
      return;
    }

    if (seller.status == SellerStatus.pending) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SellerPendingScreen()), (route) => false);
    } else if (seller.status == SellerStatus.rejected) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SellerRejectedScreen()), (route) => false);
    } else if (seller.status == SellerStatus.blocked) {
      await supabase.auth.signOut();
      setState(() => _checkingSession = false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => SellerDashboardScreen(uid: seller.uid)), (route) => false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Future<void> _login() async {
    final loc        = AppLocalizations.of(context);
    final localPhone = _phoneCtrl.text.trim();
    final password   = _passwordCtrl.text;

    if (localPhone.length < 9) {
      _showSnack(loc.get('reg_err_phone'));
      return;
    }
    if (password.isEmpty) {
      _showSnack(loc.get('login_err_pass'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone  = SellerAuthService.formatPhone(localPhone);
      final seller = await SellerAuthService.instance.login(phone: phone, password: password);

      if (!mounted) return;

      if (seller.status == SellerStatus.pending) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SellerPendingScreen()), (route) => false);
      } else if (seller.status == SellerStatus.rejected) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SellerRejectedScreen()), (route) => false);
      } else if (seller.status == SellerStatus.blocked) {
        await supabase.auth.signOut();
        _showSnack(loc.get('login_blocked'));
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => SellerDashboardScreen(uid: seller.uid)), (route) => false);
      }
    } catch (e) {
      if (mounted) _showSnack('${AppLocalizations.of(context).get('error')}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (_checkingSession) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
            }
          },
          child: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: Text(loc.get('login_title'), style: AppTextStyles.headingMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(loc.get('login_heading'), style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                loc.get('login_subheading'),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 32),

              // ── ТЕЛЕФОН ──
              Text(loc.get('reg_label_phone'), style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  prefixText: '+996  ',
                  prefixStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  hintText: '700123456',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // ── ПАРОЛЬ ──
              Text(loc.get('reg_label_pass'), style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: AppTextStyles.bodyMedium,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.grey400),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(loc.get('login_btn'), style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SellerRegisterScreen())),
                  child: Text(
                    loc.get('login_no_account'),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
