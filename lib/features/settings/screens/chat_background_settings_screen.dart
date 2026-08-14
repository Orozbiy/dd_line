import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/chat_background_provider.dart';

class ChatBackgroundSettingsScreen extends StatefulWidget {
  final ChatBackgroundProvider provider;
  const ChatBackgroundSettingsScreen({super.key, required this.provider});

  @override
  State<ChatBackgroundSettingsScreen> createState() =>
      _ChatBackgroundSettingsScreenState();
}

class _ChatBackgroundSettingsScreenState
    extends State<ChatBackgroundSettingsScreen> {
  late ChatBgTheme _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.provider.theme;
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        foregroundColor: textColor,
        title: Text('Чат фону',
            style: AppTextStyles.headingSmall.copyWith(color: textColor)),
      ),
      body: Column(
        children: [
          // ── Чоң превью ──
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _selected.buildBackground(isDark),
                ),
                // Үлгү билдирүүлөр
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selected == ChatBgTheme.galaxy
                                ? const Color(0xFF2A2A4A)
                                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Text('Саламатсызбы? 👋',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _selected == ChatBgTheme.galaxy
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black87))),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: const Text('Жакшы, рахмат! 😊',
                              style: TextStyle(fontSize: 13, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Тема тизмеси ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ChatBgTheme.values.map((t) {
                final isActive = t == _selected;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selected = t);
                    await widget.provider.setTheme(t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Мини превью
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: t.buildBackground(isDark),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            t.label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: textColor,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(right: 14),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(right: 14),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF3A3A3A) : AppColors.grey300,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}