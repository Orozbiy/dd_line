// lib/features/admin/screens/admin_complaints_screen.dart
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/supabase_client.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
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
          .from('complaints')
          .select('*, products(title)')
          .order('created_at', ascending: false);
      setState(() {
        _complaints = (data as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ AdminComplaintsScreen: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await supabase.from('complaints').update({'is_read': true}).eq('id', id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : AppColors.grey500;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Арыз жок',
              style: AppTextStyles.headingSmall.copyWith(color: subColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = _complaints[i];
          final isRead = c['is_read'] as bool? ?? false;
          final createdAt = DateTime.tryParse(c['created_at'] as String? ?? '');
          final dateStr = createdAt != null
              ? '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}'
              : '';

          final senderName = (c['sender_name'] as String?)?.isNotEmpty == true
              ? c['sender_name'] as String
              : 'Белгисиз';
          final senderEmail = c['sender_email'] as String? ?? '';
          final topic = c['topic'] as String? ?? '';
          final purpose = c['purpose'] as String? ?? '';
          final details = c['details'] as String? ?? '';
          final productName = (c['products'] as Map?)?['title'] as String? ?? '';

          return Container(
            decoration: BoxDecoration(
              color: isRead
                  ? bgColor
                  : (isDark
                      ? const Color(0xFFEF4444).withOpacity(0.08)
                      : const Color(0xFFFFF1F0)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRead
                    ? (isDark ? Colors.white12 : AppColors.grey200)
                    : const Color(0xFFEF4444).withOpacity(0.35),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead
                      ? AppColors.grey200
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: isRead ? AppColors.grey400 : const Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      senderName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Жаңы',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (senderEmail.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 13, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            senderEmail,
                            style: AppTextStyles.labelSmall.copyWith(color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (topic.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        topic,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                  if (purpose.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      purpose,
                      style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (productName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📦 $productName',
                      style: AppTextStyles.labelSmall.copyWith(color: subColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTextStyles.labelSmall.copyWith(color: subColor),
                  ),
                ],
              ),
              onTap: () {
                if (!isRead) _markRead(c['id'] as String);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _ComplaintDetailSheet(
                    complaint: c,
                    senderName: senderName,
                    senderEmail: senderEmail,
                    topic: topic,
                    purpose: purpose,
                    details: details,
                    productName: productName,
                    dateStr: dateStr,
                    isDark: isDark,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Арыздын толук маалыматы ──
class _ComplaintDetailSheet extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final String senderName;
  final String senderEmail;
  final String topic;
  final String purpose;
  final String details;
  final String productName;
  final String dateStr;
  final bool isDark;

  const _ComplaintDetailSheet({
    required this.complaint,
    required this.senderName,
    required this.senderEmail,
    required this.topic,
    required this.purpose,
    required this.details,
    required this.productName,
    required this.dateStr,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : AppColors.grey500;
    final handleColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey[300]!;

    return Container(
      color: bg,
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(senderName,
                        style: AppTextStyles.headingSmall.copyWith(color: textColor)),
                    if (senderEmail.isNotEmpty)
                      Text(senderEmail,
                          style: AppTextStyles.labelSmall.copyWith(color: subColor)),
                  ],
                ),
              ),
              Text(dateStr, style: AppTextStyles.labelSmall.copyWith(color: subColor)),
            ],
          ),
          const SizedBox(height: 16),
          if (topic.isNotEmpty) ...[
            _row('Тема', topic, textColor, subColor),
            const SizedBox(height: 10),
          ],
          if (purpose.isNotEmpty) ...[
            _row('Максат', purpose, textColor, subColor),
            const SizedBox(height: 10),
          ],
          if (details.isNotEmpty) ...[
            _row('Кошумча маалымат', details, textColor, subColor),
            const SizedBox(height: 10),
          ],
          if (productName.isNotEmpty) ...[
            _row('Товар', '📦 $productName', textColor, subColor),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color text, Color sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: sub)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(color: text)),
      ],
    );
  }
}