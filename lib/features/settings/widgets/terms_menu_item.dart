import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../screens/terms_screen.dart';

class TermsMenuItem extends StatelessWidget {
  const TermsMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.grey600;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/settings/ic_terms.png',
              width: 36, height: 36, fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.get('terms'),
                style: AppTextStyles.bodyMedium.copyWith(color: textColor))),
            Image.asset('assets/icons/settings/ic_chevron_right.png',
                width: 20, height: 20, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }
}