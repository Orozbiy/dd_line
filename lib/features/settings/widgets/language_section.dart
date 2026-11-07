import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../main.dart';

class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  @override
  Widget build(BuildContext context) {
    final provider = LocaleScope.of(context);
    final selected = provider.locale.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // Тышкы артыкча паддингдер алынды
      decoration: const BoxDecoration(
        color: Colors.transparent, // Кара фон толугу менен тунук кылынды
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8DEF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF5B8DEF), size: 18),
                ),
                SizedBox(width: 10),
                Text('Тил / Язык', style: AppTextStyles.headingSmall),
              ],
            ),
          ),
          _option(provider, selected, 'ky', 'Кыргызча', '🇰🇬', dividerColor),
          Divider(height: 1, color: dividerColor),
          _option(provider, selected, 'ru', 'Орусча', '🇷🇺', dividerColor),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _option(
    dynamic provider,
    String selected,
    String code,
    String title,
    String flag,
    Color dividerColor,
  ) {
    final isSelected = selected == code;
    return InkWell(
      onTap: () async {
        await provider.setLocale(code);
        if (mounted) setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }
}