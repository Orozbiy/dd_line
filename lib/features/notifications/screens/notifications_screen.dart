import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/app_localizations.dart';
import '../../../core/supabase_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  Set<String> _readIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('read_notification_ids') ?? [];
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
        _readIds = saved.toSet();
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id) async {
    if (_readIds.contains(id)) return;
    setState(() => _readIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notification_ids', _readIds.toList());
  }

  String _timeAgo(String? createdAt, bool isKy) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isKy ? 'Азыр' : 'Сейчас';
    if (diff.inHours < 1)
      return isKy ? '${diff.inMinutes} мүн. мурун' : '${diff.inMinutes} мин. назад';
    if (diff.inDays < 1)
      return isKy ? '${diff.inHours} саат мурун' : '${diff.inHours} ч. назад';
    if (diff.inDays < 30)
      return isKy ? '${diff.inDays} күн мурун' : '${diff.inDays} д. назад';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final loc   = AppLocalizations.of(context);
    final isKy  = loc.locale.languageCode == 'ky';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subColor  = isDark ? const Color(0xFFAAAAAA) : AppColors.grey500;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ),
        foregroundColor: textColor,
        centerTitle: true,
        title: Text(
          isKy ? 'Билдирүүлөр' : 'Уведомления',
          style: AppTextStyles.headingSmall.copyWith(color: textColor),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: textColor),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 72,
                          color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        isKy ? 'Билдирүүлөр жок' : 'Нет уведомлений',
                        style: AppTextStyles.bodyMedium.copyWith(color: subColor),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                      16,
                      32,
                    ),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n        = _notifications[i];
                      final id       = n['id'] as String;
                      final title    = n['title'] as String? ?? '';
                      final body     = n['body'] as String? ?? '';
                      final imageUrl = n['image_url'] as String?;
                      final isRead   = _readIds.contains(id);

                      return GestureDetector(
                        onTap: () => _markRead(id),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.white.withValues(alpha: 0.55))
                                    : (isDark
                                        ? AppColors.primary.withValues(alpha: 0.10)
                                        : AppColors.primary.withValues(alpha: 0.06)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.white.withValues(alpha: 0.80))
                                      : AppColors.primary.withValues(alpha: 0.40),
                                  width: isRead ? 1.0 : 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Иконка + Башлык ──
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.campaign_rounded,
                                            color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: AppTextStyles.labelLarge.copyWith(
                                                      color: textColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin: const EdgeInsets.only(left: 6, top: 4),
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: AppTextStyles.bodyMedium.copyWith(color: subColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ── Сүрөт ──
                                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          height: 200,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.06)
                                              : Colors.black.withValues(alpha: 0.04),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                color: AppColors.primary, strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          height: 60,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.black.withValues(alpha: 0.03),
                                          child: const Icon(Icons.broken_image_outlined,
                                              color: AppColors.grey400),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // ── Убакыт ──
                                  const SizedBox(height: 10),
                                  Text(
                                    _timeAgo(n['created_at'] as String?, isKy),
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}