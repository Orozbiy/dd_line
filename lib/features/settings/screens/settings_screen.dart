import 'package:flutter/material.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../widgets/settings_header.dart';
import '../widgets/language_section.dart';
import '../widgets/notifications_toggle.dart';
import '../widgets/dark_mode_toggle.dart';

import '../widgets/cache_menu_item.dart';
import '../widgets/support_menu_item.dart';
import '../widgets/terms_menu_item.dart';

const _dividerColor = Color(0xFFEEEEEE);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(loc.get('settings'), style: AppTextStyles.headingSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SettingsHeader(),
            const SizedBox(height: 32),
            const LanguageSection(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  NotificationsToggle(),
                  Divider(height: 1, color: _dividerColor),
                  DarkModeToggle(),
                
                  Divider(height: 1, color: _dividerColor),
                  CacheMenuItem(),
                  Divider(height: 1, color: _dividerColor),
                  SupportMenuItem(),
                  Divider(height: 1, color: _dividerColor),
                  TermsMenuItem(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}