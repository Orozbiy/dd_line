import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// Тил тандоо бөлүмү — Кыргызча / Орусча.
class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key});

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  String _selectedLanguage = 'ky'; // 'ky' = Кыргызча, 'ru' = Орусча

  void _selectLanguage(String code) {
    setState(() => _selectedLanguage = code);
    // TODO: тил которуу логикасы (мис. LocaleProvider)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Icon(Icons.language, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Тил', style: AppTextStyles.headingSmall),
              ],
            ),
          ),
          _languageOption(code: 'ky', title: 'Кыргызча', flag: '🇰🇬'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _languageOption(code: 'ru', title: 'Орусча', flag: '🇷🇺'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _languageOption({
    required String code,
    required String title,
    required String flag,
  }) {
    final isSelected = _selectedLanguage == code;
    return InkWell(
      onTap: () => _selectLanguage(code),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }
}
