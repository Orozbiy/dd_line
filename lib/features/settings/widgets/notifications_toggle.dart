import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

/// "Билдирмелер" toggle пункту.
/// FCM topic subscribe/unsubscribe аркылуу push'терди өчүрүп-күйгүзөт.
/// Абал SharedPreferences'та сакталат — колдонмо кайра ачылганда эсте калат.
class NotificationsToggle extends StatefulWidget {
  const NotificationsToggle({super.key});

  @override
  State<NotificationsToggle> createState() => _NotificationsToggleState();
}

class _NotificationsToggleState extends State<NotificationsToggle> {
  static const _prefKey = 'notifications_enabled';
  static const _topic = 'all_users'; // FCM topic — глобал эскертмелер үчүн

  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  /// SharedPreferences'тан сакталган абалды жүктөө
  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey) ?? true;
    if (mounted) {
      setState(() {
        _enabled = saved;
        _loading = false;
      });
    }
  }

  /// Toggle өзгөргөндө:
  /// 1) UI жаңыртат
  /// 2) SharedPreferences'ка сактайт
  /// 3) FCM topic'ке subscribe же unsubscribe кылат
  Future<void> _onChanged(bool value) async {
    setState(() => _enabled = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);

    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic(_topic);
      debugPrint('🔔 Notifications ON — subscribed to "$_topic"');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(_topic);
      debugPrint('🔕 Notifications OFF — unsubscribed from "$_topic"');
    }
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
          if (_loading)
            const SizedBox(
              width: 36,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
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