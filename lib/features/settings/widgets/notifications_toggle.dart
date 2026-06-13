import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Билдирмелер" toggle пункту.
class NotificationsToggle extends StatefulWidget {
  const NotificationsToggle({super.key});

  @override
  State<NotificationsToggle> createState() => _NotificationsToggleState();
}

class _NotificationsToggleState extends State<NotificationsToggle> {
  bool _enabled = true; // TODO: FCM логикасына туташтыруу

  void _onChanged(bool value) {
    setState(() => _enabled = value);
    // TODO: бул жерден FCM subscribe/unsubscribe чакырылат
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Билдирмелер', style: AppTextStyles.bodyMedium),
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
