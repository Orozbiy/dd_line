import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

// ══════════════════════════════════════════════════════
// Глобалдык активдүү плеер — бир эле убакта бир гана
// ══════════════════════════════════════════════════════
AudioPlayer? _activePlayer;

class VoiceMessagePlayer extends StatefulWidget {
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

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  int _currentSeconds = 0;
  int _totalSeconds = 0;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationSeconds;

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      final total = _totalSeconds > 0 ? _totalSeconds : 1;
      setState(() {
        _currentSeconds = pos.inSeconds;
        _progress = (pos.inSeconds / total).clamp(0.0, 1.0);
      });
    });

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _totalSeconds = d.inSeconds);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _progress = 0.0;
        _currentSeconds = 0;
      });
      if (_activePlayer == _player) _activePlayer = null;
    });
  }

  @override
  void dispose() {
    if (_activePlayer == _player) _activePlayer = null;
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_activePlayer != null && _activePlayer != _player) {
      await _activePlayer!.stop();
      _activePlayer = null;
    }

    setState(() => _isLoading = true);
    try {
      if (_currentSeconds > 0 && _progress < 1.0) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.audioUrl));
      }
      _activePlayer = _player;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Үн ойнотулбай жатат: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor     = widget.isMe ? Colors.white : AppColors.primary;
    final trackColor    = widget.isMe
        ? Colors.white.withValues(alpha: 0.3)
        : AppColors.grey200;
    final progressColor = widget.isMe ? Colors.white : AppColors.primary;
    final subColor      = widget.isMe
        ? Colors.white.withValues(alpha: 0.70)
        : AppColors.grey400;

    final displaySeconds = _currentSeconds > 0
        ? _currentSeconds
        : widget.durationSeconds;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Play / Pause баскычы ──
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: iconColor,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Progress bar + убакыт + птичка ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  GestureDetector(
                    onTapDown: (details) async {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final localX = details.localPosition.dx;
                      final width  = box.size.width - 44;
                      final ratio  = (localX / width).clamp(0.0, 1.0);
                      final seekMs = (ratio * _totalSeconds * 1000).toInt();
                      await _player.seek(Duration(milliseconds: seekMs));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 4,
                        backgroundColor: trackColor,
                        valueColor: AlwaysStoppedAnimation(progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Убакыт + птичка (окулду белгиси) ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(displaySeconds),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          color: subColor,
                        ),
                      ),
                      if (widget.formattedTime.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${widget.formattedTime}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11,
                            color: subColor,
                          ),
                        ),
                      ],
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: widget.isRead
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