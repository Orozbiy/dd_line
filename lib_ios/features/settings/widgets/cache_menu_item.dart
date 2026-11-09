import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';

class CacheMenuItem extends StatefulWidget {
  const CacheMenuItem({super.key});

  @override
  State<CacheMenuItem> createState() => _CacheMenuItemState();
}

class _CacheMenuItemState extends State<CacheMenuItem> {
  bool _clearing = false;

  Future<void> _clearCache(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    setState(() => _clearing = true);
    try {
      await DefaultCacheManager().emptyCache();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.get('cache_cleared')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final version = '20.04';
    return InkWell(
      onTap: _clearing ? null : () => _clearCache(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/settings/ic_cache.png',
              width: 36, height: 36, fit: BoxFit.contain,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.get('clear_cache'), style: AppTextStyles.bodyMedium)),
            if (_clearing)
              const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            else
              Text('v$version',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey400)),
            const SizedBox(width: 8),
            Image.asset(
              'assets/icons/settings/ic_chevron_right.png',
              width: 20, height: 20,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
