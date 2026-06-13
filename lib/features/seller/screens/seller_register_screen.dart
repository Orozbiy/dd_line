import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/seller_auth_service.dart';
import '../services/seller_service.dart';
import 'seller_login_screen.dart';
import 'seller_pending_screen.dart';



class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _containerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _shopNameCtrl.dispose();
    _containerCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
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

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    final shopName = _shopNameCtrl.text.trim();
    final containerNumber = _containerCtrl.text.trim();
    final localPhone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final passwordConfirm = _passwordConfirmCtrl.text;

    if (name.isEmpty) {
      _showSnack('Аты-жөнүңүздү жазыңыз');
      return;
    }
    final age = int.tryParse(ageText);
    if (age == null || age < 14 || age > 100) {
      _showSnack('Жашыңызды туура жазыңыз');
      return;
    }
    if (shopName.isEmpty && containerNumber.isEmpty) {
      _showSnack('Контейнер номерин же дүкөндүн атын жазыңыз');
      return;
    }
    if (localPhone.length < 9) {
      _showSnack('Телефон номерин толук жазыңыз');
      return;
    }

    final passError = SellerService.validatePassword(password);
    if (passError != null) {
      _showSnack(passError);
      return;
    }
    if (password != passwordConfirm) {
      _showSnack('Пароль дал келген жок');
      return;
    }

    setState(() => _isLoading = true);
    try {
     
     final formattedPhone = SellerAuthService.formatPhone(localPhone);
      await SellerAuthService.instance.register(
        phone: formattedPhone,
        password: password,
        fullName: name,
        age: age,
        containerNumber: containerNumber,
        shopName: shopName,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const SellerPendingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
  debugPrint('SellerRegister error: $e');
  if (e is SellerPhoneTakenException) {
    if (mounted) _showSnack(e.toString());
  } else {
    if (mounted) _showSnack('Ката: $e');  // <- убактынча, чыныгы катаны көрсөтөт
  }
}finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration({String? hint, String? prefixText, TextStyle? prefixStyle, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: prefixStyle,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.grey600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: const Text('Катталуу', style: AppTextStyles.headingMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('Дүкөнүңүздү ачыңыз!', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Маалыматтарыңызды толтуруңуз',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 28),

              // ── АТЫ-ЖӨНҮ ───────────────────────────
              _label('Аты-жөнү'),
              TextField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(hint: 'Мисалы: Айгерим Осмонова'),
              ),
              const SizedBox(height: 20),

              // ── ЖАШЫ ───────────────────────────────
              _label('Жашы'),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(hint: 'Мисалы: 28'),
              ),
              const SizedBox(height: 20),

              // ── КОНТЕЙНЕР / ДҮКӨН АТЫ ──────────────
              _label('Контейнер номери же дүкөндүн аты'),
              TextField(
                controller: _containerCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(hint: 'Мисалы: 4-катар, А-12'),
              ),
              const SizedBox(height: 20),

              _label('Дүкөндүн аты (милдеттүү эмес)'),
              TextField(
                controller: _shopNameCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(hint: 'Мисалы: Айгерим Shop'),
              ),
              const SizedBox(height: 20),

              // ── ТЕЛЕФОН ────────────────────────────
              _label('Телефон номери'),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(
                  hint: '700123456',
                  prefixText: '+996  ',
                  prefixStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),

              // ── ПАРОЛЬ ─────────────────────────────
              _label('Пароль'),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure1,
                style: AppTextStyles.bodyMedium,
                decoration: _decoration(
                  hint: 'Кеминде 8 символ, баш/кичи тамга, сан, белги',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure1 = !_obscure1),
                    child: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: AppColors.grey400),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── ПАРОЛЬ КАЙТАЛОО ────────────────────
              _label('Паролду кайталаңыз'),
              TextField(
                controller: _passwordConfirmCtrl,
                obscureText: _obscure2,
                style: AppTextStyles.bodyMedium,
                onSubmitted: (_) => _register(),
                decoration: _decoration(
                  hint: '••••••••',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure2 = !_obscure2),
                    child: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: AppColors.grey400),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('🏪  Дүкөн ачуу', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
                  ),
                  child: Text(
                    'Аккаунтуңуз барбы? Кирүү',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
