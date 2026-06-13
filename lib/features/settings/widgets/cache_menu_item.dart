import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Кэшти тазалоо" менюсунун пункту, оң жагында колдонмо версиясы.
class CacheMenuItem extends StatelessWidget {
  const CacheMenuItem({super.key});

  static const String _appVersion = 'v1.0.0'; // TODO: package_info_plus менен динамикалаштыруу

  void _onTap(BuildContext context) {
    // TODO: кэшти тазалоо логикасы (мис. cached_network_image .emptyCache())
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.cleaning_services_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Кэшти тазалоо', style: AppTextStyles.bodyMedium),
            ),
            Text(
              _appVersion,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}
