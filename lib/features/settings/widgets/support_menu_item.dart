import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Колдоо / Байланыш" менюсунун пункту.
/// Басылганда e-mail клиентин mailto: аркылуу ачат.
class SupportMenuItem extends StatelessWidget {
  const SupportMenuItem({super.key});

  static const String _supportEmail = 'orozbijhodzebekov@gmail.com';

  Future<void> _openSupport(BuildContext context) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('DD Online - Колдоо')}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Почта тиркемеси табылбады'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openSupport(context),
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.support_agent_outlined,
                color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Колдоо / Байланыш',
                  style: AppTextStyles.bodyMedium),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}