import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';

class DarkModeToggle extends StatefulWidget {
  const DarkModeToggle({super.key});

  @override
  State<DarkModeToggle> createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends State<DarkModeToggle> {
  bool _enabled = false;

  void _onChanged(bool value) => setState(() => _enabled = value);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.dark_mode_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(loc.get('dark_mode'), style: AppTextStyles.bodyMedium)),
          Switch(value: _enabled, onChanged: _onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}