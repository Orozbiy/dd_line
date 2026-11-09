import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/dd_design.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/chat_background_provider.dart';
import '../../auth/screens/profile_screen.dart';
import '../widgets/settings_header.dart';
import '../widgets/language_section.dart';
import '../widgets/notifications_toggle.dart';
import '../widgets/dark_mode_toggle.dart';
import '../widgets/chat_bg_menu_item.dart';
import '../widgets/cache_menu_item.dart';
import '../widgets/support_menu_item.dart';
import '../widgets/terms_menu_item.dart';
import '../../home/widgets/suggestion_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p          = DDPalette.of(context);
    final isDark     = p.isDark;
    final loc        = AppLocalizations.of(context);
    final divColor   = p.divider;
    final textColor  = p.text;
    final subColor   = p.subText;
    final cardBg     = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.55);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.80);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.30)
                  : Colors.white.withOpacity(0.40),
            ),
          ),
        ),
        foregroundColor: textColor,
        title: Text(
          loc.get('settings'),
          style: AppTextStyles.headingMedium.copyWith(color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + kToolbarHeight + 12,
          20,
          120,
        ),
        child: Column(
          children: [
            const SettingsHeader(),
            const SizedBox(height: 24),

            // ── Profile Card ──
            _glassCard(
              cardBg: cardBg,
              cardBorder: cardBorder,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: DD.accentGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: DD.accent.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/icons/settings/ic_profile.png', width: 46, height: 46, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.get('profile'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.get('profile_view_edit'),
                              style: AppTextStyles.bodySmall.copyWith(color: subColor),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/icons/settings/ic_chevron_right.png',
                        width: 16, height: 16,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Негизги айнек блок ──
            _glassCard(
              cardBg: cardBg,
              cardBorder: cardBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const LanguageSection(),
                    Divider(height: 1, color: divColor),
                    const NotificationsToggle(),
                    Divider(height: 1, color: divColor),
                    const DarkModeToggle(),
                    Divider(height: 1, color: divColor),
                    ChatBgMenuItem(provider: ChatBackgroundProvider.instance),
                    Divider(height: 1, color: divColor),
                    const CacheMenuItem(),
                    Divider(height: 1, color: divColor),

                    // ── Өтүнүч жиберүү ──
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        builder: (_) => ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.55)
                                    : Colors.white.withOpacity(0.60),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.12)
                                        : Colors.black.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              child: const SuggestionButton(),
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/settings/ic_notifications.png',
                              width: 36, height: 36, fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.get('call_request_tooltip'),
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.get('rty'),
                                    
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'assets/icons/settings/ic_chevron_right.png',
                              width: 20, height: 20,
                              color: AppColors.grey300,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: divColor),
                    const SupportMenuItem(),
                    Divider(height: 1, color: divColor),
                    const TermsMenuItem(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({
    required Color cardBg,
    required Color cardBorder,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}