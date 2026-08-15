import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class VoiceMessagePlayer extends StatelessWidget {
  final String audioUrl;
  final int durationSeconds;
  final bool isMe;
  // ── Жаңы параметрлер ──
  final bool isRead;
  final String formattedTime;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.durationSeconds,
    required this.isMe,
    this.isRead = false,
    this.formattedTime = '',
  });

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor     = isMe ? Colors.white : AppColors.primary;
    final trackColor    = isMe
        ? Colors.white.withValues(alpha: 0.3)
        : AppColors.grey200;
    final progressColor = isMe ? Colors.white : AppColors.primary;
    final subColor      = isMe
        ? Colors.white.withValues(alpha: 0.70)
        : AppColors.grey400;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded, color: iconColor, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.0,
                      minHeight: 4,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(durationSeconds),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          color: subColor,
                        ),
                      ),
                      if (formattedTime.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· $formattedTime',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                            color: subColor,
                          ),
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}