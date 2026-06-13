import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../models/seller_model.dart';
import '../services/seller_service.dart';
import '../services/subscription_service.dart';
import 'seller_product_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../chat/services/chat_service.dart';
import 'location_picker_screen.dart';
import '../../../core/supabase_client.dart';
import 'seller_login_screen.dart';
import '../../home/screens/home_screen.dart';
import 'seller_close_account_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String uid;

  const SellerDashboardScreen({super.key, required this.uid});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final _service = SellerService();
  final _subService = SubscriptionService();
  final _chatService = ChatService();
  SellerModel? _seller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    final seller = await _service.getSellerByUid(widget.uid);
    if (mounted) {
      setState(() {
        _seller = seller;
        _isLoading = false;
      });
    }
  }

  void _showSnack(String msg, [Color color = AppColors.grey600]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }


void _logout() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Чыгуу', style: AppTextStyles.headingSmall),
      content: const Text('Дүкөндөн чыгасызбы?', style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Жок', style: TextStyle(color: AppColors.grey500)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // диалог жабуу
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerCloseAccountScreen(sellerUid: _seller!.uid),
              ),
            );
          },
          child: const Text('Дүкөндөн баш тартуу',
              style: TextStyle(color: AppColors.error)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await supabase.auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
              (route) => false,
            );
          },
          child: const Text('Ооба', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

void _goBack() {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
}

  void _showSubscriptionSheet() {
    final cardCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    bool agreed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💳', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Айлык жазылуу', style: AppTextStyles.headingSmall),
                        Text(
                          'Ар айдын 1-күнүндө 2 000 сом алынат',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_seller?.hasCard == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEFFF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _seller!.cardMasked ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'байланган',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: _inputDec(
                  _seller?.hasCard == true
                      ? 'Жаңы карта номери (алмаштыруу)'
                      : 'Карта номери',
                  '0000 0000 0000 0000',
                ),
                onChanged: (v) {
                  final digits = v.replaceAll(' ', '');
                  final formatted = digits
                      .replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)} ')
                      .trim();
                  cardCtrl.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: _inputDec('Мөөнөтү', 'MM/YY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      decoration: _inputDec('CVV', '•••'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setS(() => agreed = !agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: agreed,
                      onChanged: (v) => setS(() => agreed = v ?? false),
                      activeColor: AppColors.primary,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Ар айдын 1-күнүндө картамдан 2 000 сом алынышына макулмун. Каалаган убакта токтотсо болот.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: agreed && cardCtrl.text.replaceAll(' ', '').length == 16
                      ? () => _saveCard(cardCtrl.text, ctx)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _seller?.hasCard == true
                        ? '🔄  Картаны алмаштыруу'
                        : '✅  Картаны байлоо',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_seller?.autoPayEnabled == true) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => _cancelSub(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '⛔  Авто төлөмдү токтотуу',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
              if (_seller?.hasCard == true) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => _removeCard(ctx),
                    child: const Text(
                      'Картаны өчүрүү',
                      style: TextStyle(color: AppColors.grey500, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Future<void> _saveCard(String cardNumber, BuildContext ctx) async {
    Navigator.pop(ctx);
    final digits = cardNumber.replaceAll(' ', '');
    final masked = '•••• ${digits.substring(12)}';
    await _subService.saveCard(
      uid: _seller!.uid,
      cardToken: 'token_${digits.substring(12)}',
      cardMasked: masked,
    );
    await _loadSeller();
    if (mounted) _showSnack('✅ Карта байланды! Авто төлөм иштейт.', AppColors.success);
  }

  Future<void> _cancelSub(BuildContext ctx) async {
    Navigator.pop(ctx);
    await _subService.cancelAutoPayment(_seller!.uid);
    await _loadSeller();
    if (mounted) _showSnack('⛔ Авто төлөм токтотулду', AppColors.error);
  }

  Future<void> _removeCard(BuildContext ctx) async {
    Navigator.pop(ctx);
    await _subService.removeCard(_seller!.uid);
    await _loadSeller();
    if (mounted) _showSnack('🗑️ Карта өчүрүлдү', AppColors.grey600);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goBack();
        },
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_seller == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goBack();
        },
        child: const Scaffold(
          body: Center(
            child: Text('Маалымат табылган жок', style: AppTextStyles.bodyMedium),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  leading: GestureDetector(
    onTap: _goBack,
    child: const Icon(Icons.arrow_back, color: AppColors.black),
  ),
  title: const Row(
    children: [
      Text('🏪', style: TextStyle(fontSize: 22)),
      SizedBox(width: 8),
      Text('Дүкөнүм', style: AppTextStyles.headingMedium),
    ],
  ),
),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _seller!.shopName.isNotEmpty
                                  ? _seller!.shopName[0].toUpperCase()
                                  : '🏪',
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _seller!.shopName,
                                style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _seller!.name,
                                style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _seller!.phone,
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Башкаруу', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: '📦',
                title: 'Менин товарларым',
                subtitle: 'Товарларды кошуу, өзгөртүү',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerProductScreen(
                      sellerUid: _seller!.uid,
                      shopName: _seller!.shopName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: '📊',
                title: 'Статистика',
                subtitle: 'Сатуу маалыматтары',
                onTap: () => _showSnack('Жакында кошулат!'),
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: '📍',
                title: 'Дүкөндүн жайгашкан жери',
                subtitle: 'Картада жериңизди белгилеңиз',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        shopName: _seller!.shopName,
                        sellerUid: _seller!.uid,
                        initialLat: _seller!.latitude,
                        initialLng: _seller!.longitude,
                      ),
                    ),
                  );
                  _loadSeller();
                },
              ),
              const SizedBox(height: 10),
              _buildChatMenuItem(),
              const SizedBox(height: 10),
              _buildMenuItem(
                icon: '📞',
                title: 'Номер өзгөртүү',
                subtitle: 'Admin га өтүнүч жиберүү',
                onTap: () => _showSnack('Жакында кошулат!'),
              ),
              const SizedBox(height: 10),
              _buildSubscriptionButton(),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💬', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Кайрылуу үчүн',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Активдүү сатуучулар проблемаларын WhatsApp аркылуу жиберсин:',
                            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '+996221000330',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  child: Text(
                    '🚪  Чыгуу',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionButton() {
    final hasCard = _seller?.hasCard ?? false;
    final autoOn = _seller?.autoPayEnabled ?? false;
    final paid = _seller?.currentMonthPaid ?? false;

    Color borderColor;
    Color bgColor;
    String statusText;
    String subtitleText;

    if (autoOn && paid) {
      borderColor = AppColors.success;
      bgColor = const Color(0xFFEEFFF5);
      statusText = '✅ Бул айдын төлөмү өткөрүлдү';
      subtitleText = '${_seller?.cardMasked ?? ''} · 2 000 сом/ай';
    } else if (autoOn && !paid) {
      borderColor = AppColors.primary;
      bgColor = const Color(0xFFFFF8F0);
      statusText = '💳 Авто төлөм иштеп жатат';
      subtitleText = '${_seller?.cardMasked ?? ''} · Айдын 1-күнүндө алынат';
    } else if (hasCard && !autoOn) {
      borderColor = AppColors.grey400;
      bgColor = Colors.white;
      statusText = '⏸️ Авто төлөм токтотулган';
      subtitleText = _seller?.cardMasked ?? '';
    } else {
      borderColor = AppColors.error.withValues(alpha: 0.5);
      bgColor = const Color(0xFFFFF1F0);
      statusText = '💳 Жазылуу — 2 000 сом/ай';
      subtitleText = 'Картаны байлап авто төлөм орнотуңуз';
    }

    return GestureDetector(
      onTap: _showSubscriptionSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('💳', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.grey400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMenuItem() {
    return StreamBuilder<List>(
      stream: _chatService.sellerChatsStream(_seller!.uid),
      builder: (context, snap) {
        final chats = snap.data ?? [];
        final totalUnread = chats.fold<int>(
          0,
          (sum, chat) => sum + ((chat as dynamic).sellerUnread as int),
        );

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatListScreen(
                isSeller: true,
                sellerId: _seller!.uid,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 28)),
                    if (totalUnread > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            totalUnread > 99 ? '99+' : '$totalUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Билдирүүлөр', style: AppTextStyles.labelLarge),
                          if (totalUnread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$totalUnread жаңы',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalUnread > 0
                            ? '$totalUnread окулбаган билдирүү бар'
                            : 'Кардарлар менен чат',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: totalUnread > 0 ? AppColors.error : AppColors.grey500,
                          fontWeight: totalUnread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.grey400, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.grey400, size: 16),
          ],
        ),
      ),
    );
  }
}