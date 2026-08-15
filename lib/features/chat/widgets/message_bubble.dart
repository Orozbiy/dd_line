import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/image_utils.dart';
import '../models/message_model.dart';
import '../widgets/voice_message_player_mobile.dart';
 // ← BackdropFilter, ImageFilter үчүн

// ══════════════════════════════════════════════════════
// GLASSMORPHISM HELPER
// ══════════════════════════════════════════════════════
class _GlassBubble extends StatelessWidget {
  final bool isMe;
  final BorderRadius borderRadius;
  final Widget child;

  const _GlassBubble({
    required this.isMe,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Өзүмдүн: көкчө прозрачный, башкасынын: ак прозрачный
    final Color bgColor = isMe
        ? (isDark
            ? const Color(0xFF1A6FD4).withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.55))
        : (isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.65));

    final Color borderColor = isMe
        ? Colors.white.withValues(alpha: 0.30)
        : (isDark
            ? Colors.white.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.80));

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// MESSAGE BUBBLE
// ══════════════════════════════════════════════════════
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;
  final VoidCallback? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.onCopy,
    this.onDelete,
    this.onReply,
    this.onReplyTap,
    this.onEdit,
  });

void _handleLongPress(BuildContext context) {
  if (isSelectionMode) {
    onLongPress?.call();
    return;
  }

  HapticFeedback.mediumImpact();

  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (sheetContext) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle ──
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Билдирүү preview ──
                if (message.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? Colors.white70 : AppColors.grey600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Divider ──
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),

                // ── Баскычтар ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Жооп берүү
                      _ActionButton(
                        icon: Icons.reply_rounded,
                        label: 'Жооп',
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onReply?.call();
                        },
                      ),

                      // Тандоо
                      _ActionButton(
                        icon: Icons.checklist_rounded,
                        label: 'Тандоо',
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onLongPress?.call();
                        },
                      ),

                      // Көчүрүү
                      if (message.text.isNotEmpty)
                        _ActionButton(
                          icon: Icons.copy_rounded,
                          label: 'Көчүрүү',
                          color: AppColors.primary,
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onCopy?.call();
                          },
                        ),

                      // Өзгөртүү (өзүнүн билдирүүсү гана)
                      if (isMe && message.text.isNotEmpty)
                        _ActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Өзгөртүү',
                          color: const Color(0xFF6C63FF),
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onEdit?.call();
                          },
                        ),

                      // Өчүрүү
                      _ActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Өчүрүү',
                        color: AppColors.error,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onDelete?.call();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.messageType == 'system') {
      return _SystemMessage(text: message.text);
    }

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      onTap: isSelectionMode ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        padding: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          bottom: 6,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // ── СҮРӨТ БИЛДИРҮҮ ──
              if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                _GlassBubble(
                  isMe: isMe,
                  borderRadius: bubbleRadius,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: toCloudinaryThumb(message.imageUrl!,
                            width: 300),
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 220,
                          height: 220,
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : AppColors.grey100,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 220,
                          height: 220,
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : AppColors.grey100,
                          child: const Icon(Icons.broken_image,
                              size: 48, color: AppColors.grey400),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── АУДИО БИЛДИРҮҮ ──
              if (message.audioUrl != null && message.audioUrl!.isNotEmpty)
                _GlassBubble(
                  isMe: isMe,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    child: VoiceMessagePlayer(
                      audioUrl: message.audioUrl!,
                      durationSeconds: message.audioDuration ?? 0,
                      isMe: isMe,
                      isRead: message.isRead,
                      formattedTime: message.formattedTime,
                    ),
                  ),
                ),

              // ── ТЕКСТ БИЛДИРҮҮ ──
              if (message.text.isNotEmpty ||
                  (message.imageUrl == null && message.audioUrl == null))
                _GlassBubble(
                  isMe: isMe,
                  borderRadius: bubbleRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Жооп preview ──
                        if (message.replyToId != null &&
                            message.replyToText != null)
                          GestureDetector(
                            onTap: onReplyTap,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : AppColors.grey100
                                        .withValues(alpha: 0.50),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                message.replyToText!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isMe
                                      ? Colors.white
                                          .withValues(alpha: 0.85)
                                      : AppColors.grey600,
                                ),
                              ),
                            ),
                          ),

                        // ── Текст ──
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isMe
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.black),
                            ),
                          ),

                        // ── Убакыт + окулду ──
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEdited)
                              Text(
                                'өзгөртүлдү • ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: isMe
                                      ? Colors.white
                                          .withValues(alpha: 0.7)
                                      : AppColors.grey400,
                                ),
                              ),
                            Text(
                              message.formattedTime,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.grey400,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 14,
                                color: message.isRead
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// SYSTEM MESSAGE
// ══════════════════════════════════════════════════════
class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ACTION BUTTON — горизонталдык меню баскычы
// ══════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}