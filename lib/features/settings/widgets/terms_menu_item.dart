import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../screens/terms_screen.dart';

/// "Эрежелер жана купуялык саясаты" менюсунун пункту.
class TermsMenuItem extends StatelessWidget {
  const TermsMenuItem({super.key});

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Эрежелер жана купуялык саясаты',
                  style: AppTextStyles.bodyMedium),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}
