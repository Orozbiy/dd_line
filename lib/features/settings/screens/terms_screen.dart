import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';

/// "Эрежелер жана купуялык саясаты" — толук маалымат экраны.
/// Эки тилди колдойт: кыргызча (ky) жана орусча (ru).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(loc.get('terms_title'), style: AppTextStyles.headingSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(loc.get('terms_s1_title'), loc.get('terms_s1_body')),
            _section(loc.get('terms_s2_title'), loc.get('terms_s2_body')),
            _section(loc.get('terms_s3_title'), loc.get('terms_s3_body')),
            _section(loc.get('terms_s4_title'), loc.get('terms_s4_body')),
            _section(loc.get('terms_s5_title'), loc.get('terms_s5_body')),
            _section(loc.get('terms_s6_title'), loc.get('terms_s6_body')),
            _section(loc.get('terms_s7_title'), loc.get('terms_s7_body')),
            _section(loc.get('terms_s8_title'), loc.get('terms_s8_body')),
            _section(loc.get('terms_s9_title'), loc.get('terms_s9_body')),
            const SizedBox(height: 4),
            _contactRow(Icons.business_outlined, 'DD Online'),
            const SizedBox(height: 8),
            _contactRow(Icons.email_outlined, 'support@ddonline.kg'),
            const SizedBox(height: 8),
            _contactRow(Icons.phone_outlined, '+996 (XXX) XX-XX-XX'),
            const SizedBox(height: 8),
            _contactRow(Icons.location_on_outlined, loc.get('terms_contact_addr')),
            const SizedBox(height: 24),
            Text(
              loc.get('terms_disclaimer'),
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}
