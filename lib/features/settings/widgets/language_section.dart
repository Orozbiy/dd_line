import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
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
    final _lp = DDPalette.of(context);
    final dividerColor = _lp.divider;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // Тышкы артыкча паддингдер алынды
      decoration: const BoxDecoration(
        color: Colors.transparent, // Кара фон толугу менен тунук кылынды
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/settings/ic_language.png',
                  width: 36, height: 36, fit: BoxFit.contain,
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
            Image.asset(
              isSelected
                  ? 'assets/icons/settings/ic_radio_on.png'
                  : 'assets/icons/settings/ic_radio_off.png',
              width: 24, height: 24,
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }
}