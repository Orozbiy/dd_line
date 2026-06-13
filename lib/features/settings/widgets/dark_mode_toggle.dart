import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Караңгы режим" toggle пункту.
class DarkModeToggle extends StatefulWidget {
  const DarkModeToggle({super.key});

  @override
  State<DarkModeToggle> createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends State<DarkModeToggle> {
  bool _enabled = false; // TODO: ThemeMode провайдерине туташтыруу

  void _onChanged(bool value) {
    setState(() => _enabled = value);
    // TODO: бул жерден ThemeMode.dark / ThemeMode.light которулат
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.dark_mode_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Караңгы режим', style: AppTextStyles.bodyMedium),
          ),
          Switch(
            value: _enabled,
            onChanged: _onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
