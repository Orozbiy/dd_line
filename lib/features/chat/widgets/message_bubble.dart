import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../models/message_model.dart';
import 'voice_message_player.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  // ── Select режими (1-этап) ──
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  // ── Long-press menu / reply (2-этап) ──
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;

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
  });

  // ── Long-press: select режиминде эмес болсо action sheet чыгат ──
  void _handleLongPress(BuildContext context) {
    if (isSelectionMode) {
      onLongPress?.call();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_outlined,
                    color: AppColors.primary),
                title:
                    const Text('Көчүрүү', style: AppTextStyles.labelLarge),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onCopy?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply_outlined,
                  color: AppColors.primary),
              title: const Text('Жооп берүү', style: AppTextStyles.labelLarge),
              onTap: () {
                Navigator.pop(sheetContext);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Өчүрүү', style: AppTextStyles.labelLarge),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      onTap: isSelectionMode ? onTap : null,
      child: Container(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            left: isMe ? 60 : 12,
            right: isMe ? 12 : 60,
            bottom: 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // ── Select режиминде checkbox ──
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.grey300,
                    size: 22,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // ── Сүрөт билдирүү (эгер бар болсо) ──
                    if (message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            message.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 150,
                              color: AppColors.grey100,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.grey300,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Үн билдирүү (эгер бар болсо) ──
                    if (message.audioUrl != null &&
                        message.audioUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: VoiceMessagePlayer(
                          audioUrl: message.audioUrl!,
                          durationSeconds: message.audioDuration ?? 0,
                          isMe: isMe,
                        ),
                      ),

                    // ── Текст билдирүү + reply preview + убакыт + галочка ──
                    if (message.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // ── Жооп берилген билдирүүгө шилтеме ──
                            if (message.replyToText != null &&
                                message.replyToText!.isNotEmpty)
                              GestureDetector(
                                onTap: onReplyTap,
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : AppColors.grey100,
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
                                          ? Colors.white.withValues(alpha: 0.85)
                                          : AppColors.grey600,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Text(
                                message.text,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isMe ? Colors.white : AppColors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  message.formattedTime,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : AppColors.grey400,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  _ReadReceiptIcon(
                                      isRead: message.isRead, isMe: isMe),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ── Аудио билдирүү учурунда (текст жок) убакыт+галочка ──
                    if (message.text.isEmpty &&
                        message.audioUrl != null &&
                        message.audioUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.formattedTime,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 11,
                                color: AppColors.grey400,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _ReadReceiptIcon(
                                  isRead: message.isRead, isMe: isMe),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Галочка виджети ──
// isRead = false → Icons.done         (1 галочка, боз)
// isRead = true  → Icons.done_all     (2 галочка, көк)
class _ReadReceiptIcon extends StatelessWidget {
  final bool isRead;
  final bool isMe;

  const _ReadReceiptIcon({required this.isRead, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        key: ValueKey(isRead),
        isRead ? Icons.done_all_rounded : Icons.done_rounded,
        size: 15,
        color: isRead
            ? const Color(0xFF4FC3F7)
            : (isMe
                ? Colors.white.withValues(alpha: 0.65)
                : AppColors.grey400),
      ),
    );
  }
}