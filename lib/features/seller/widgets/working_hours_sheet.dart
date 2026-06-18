import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/supabase_client.dart';

/// Сатуучунун дашбордунан чакырылат.
/// stores таблицасына work_start, work_end, work_days жазат.
class WorkingHoursSheet extends StatefulWidget {
  final String sellerUid;
  final String? initialStart; // '09:00'
  final String? initialEnd;   // '18:00'
  final String? initialDays;  // 'Дш-Жм'

  const WorkingHoursSheet({
    super.key,
    required this.sellerUid,
    this.initialStart,
    this.initialEnd,
    this.initialDays,
  });

  @override
  State<WorkingHoursSheet> createState() => _WorkingHoursSheetState();
}

class _WorkingHoursSheetState extends State<WorkingHoursSheet> {
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _days;
  bool _saving = false;

  // Жумуш күндөрүнүн опциялары
  static const _dayOptions = [
    'Дш-Жм',
    'Дш-Шб',
    'Дш-Жк',
    'Жк күн эмес',
    'Күн сайын',
  ];

  @override
  void initState() {
    super.initState();
    _start = _parseTime(widget.initialStart ?? '09:00');
    _end   = _parseTime(widget.initialEnd   ?? '18:00');
    _days  = widget.initialDays ?? 'Дш-Жм';
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) _start = picked;
      else _end = picked;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await supabase.from('stores').update({
        'work_start': _fmt(_start),
        'work_end':   _fmt(_end),
        'work_days':  _days,
      }).eq('owner_id', widget.sellerUid);

      if (mounted) {
        Navigator.pop(context, true); // true = сакталды
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Иштөө убактысы сакталды'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ката: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ручка ──
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('🕐 Иштөө убактысы', style: AppTextStyles.headingSmall),
          const SizedBox(height: 20),

          // ── Башталуу — Аяктоо ──
          Row(
            children: [
              Expanded(
                child: _TimeCard(
                  label: 'Башталат',
                  time: _fmt(_start),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('—', style: TextStyle(fontSize: 22, color: AppColors.grey400)),
              ),
              Expanded(
                child: _TimeCard(
                  label: 'Аяктайт',
                  time: _fmt(_end),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Жумуш күндөрү ──
          const Text('Жумуш күндөрү', style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dayOptions.map((d) {
              final selected = _days == d;
              return GestureDetector(
                onTap: () => setState(() => _days = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    d,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected ? Colors.white : AppColors.grey600,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Алдын ала көрүнүш ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$_days  ${_fmt(_start)} — ${_fmt(_end)}',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Сактоо баскычы ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Сактоо', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Убакыт карточкасы ──
class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 6),
            Text(
              time,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.edit_outlined, size: 14, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
