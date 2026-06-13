import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Профилди өзгөртүү" менюсунун пункту.
class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({super.key});

  void _onTap(BuildContext context) {
    // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Жакында кошулат'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
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
            Icon(Icons.person_outline, color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Профилди өзгөртүү',
                  style: AppTextStyles.bodyMedium),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}
