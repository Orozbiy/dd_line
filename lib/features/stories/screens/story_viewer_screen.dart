import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../widgets/story_progress_bar.dart';
import '../widgets/story_like_button.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late List<StoryModel> _stories;
  late int _currentIndex;

  // ── Прогресс ──
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  static const int _imageDuration = 5;

  bool _isPaused = false;

  // ── Video player ──
  CachedVideoPlayerPlusController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _stories      = List<StoryModel>.from(widget.stories);
    _currentIndex = widget.initialIndex.clamp(0, _stories.length - 1);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _progressCtrl = AnimationController(vsync: this);
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve:  Curves.linear,
    );

    _startStory(_currentIndex);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progressCtrl.dispose();
    _disposeVideo();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Video dispose
  // ─────────────────────────────────────────────
  void _disposeVideo() {
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
  }

  // ─────────────────────────────────────────────
  // Story баштоо
  // ─────────────────────────────────────────────
  Future<void> _startStory(int index) async {
    if (index >= _stories.length) {
      _close();
      return;
    }

    // Эски видеону өчүрүү
    _disposeVideo();

    _progressCtrl.removeStatusListener(_onProgressStatus);
    _progressCtrl.stop();
    _progressCtrl.reset();

    final story = _stories[index];

    if (story.isVideo) {
      // ── Видео жүктөө ──
      await _initVideo(story.mediaUrl);
    } else {
      // ── Сүрөт: 5 сек ──
      _progressCtrl.duration = const Duration(seconds: _imageDuration);
      _progressCtrl.forward();
      _progressCtrl.addStatusListener(_onProgressStatus);
    }
  }

  Future<void> _initVideo(String url) async {
    try {
      final ctrl = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(url),
        invalidateCacheIfOlderThan: const Duration(days: 7),
      );
      _videoCtrl = ctrl;

      await ctrl.initialize();
      if (!mounted) return;

      // Видео узундугун прогрессте колдонобуз
      final duration = ctrl.value.duration;
      _progressCtrl.duration =
          duration.inSeconds > 0 ? duration : const Duration(seconds: 15);

      setState(() => _videoReady = true);

      ctrl.play();
      _progressCtrl.forward();
      _progressCtrl.addStatusListener(_onProgressStatus);

      // Видео бүтүп калса автоматтык кийинкиге өтүү
      // progressCtrl listener жетиштүү — видео listener алып салынды
      // (эки жолу чакырылып кызыл экран болбосун)
    } catch (e) {
      debugPrint('❌ Video init error: $e');
      // Ката болсо сүрөт режимине кайтуу
      if (mounted) {
        _progressCtrl.duration = const Duration(seconds: _imageDuration);
        _progressCtrl.forward();
        _progressCtrl.addStatusListener(_onProgressStatus);
      }
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _progressCtrl.removeStatusListener(_onProgressStatus);
      _goNext();
    }
  }

  // ─────────────────────────────────────────────
  // Навигация
  // ─────────────────────────────────────────────
  bool _isNavigating = false; // эки жолу чакырылып кетпесин

  void _goNext() {
    if (_isNavigating) return;
    _isNavigating = true;

    _progressCtrl.removeStatusListener(_onProgressStatus);

    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
        _isNavigating = false;
      });
      _startStory(_currentIndex);
    } else {
      // Акыркы story бүтсө — биринчиге кайт (жабылбасын)
      setState(() {
        _currentIndex = 0;
        _isNavigating = false;
      });
      _startStory(0);
    }
  }

  void _goPrev() {
    _progressCtrl.removeStatusListener(_onProgressStatus);
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else {
      _progressCtrl.reset();
    }
    _startStory(_currentIndex);
  }

  void _close() {
    Navigator.of(context).pop(_stories);
  }

  // ─────────────────────────────────────────────
  // Пауза / Resume
  // ─────────────────────────────────────────────
  void _pause() {
    if (_isPaused) return;
    _progressCtrl.stop();
    _videoCtrl?.pause();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (!_isPaused) return;
    _progressCtrl.forward();
    _videoCtrl?.play();
    setState(() => _isPaused = false);
  }

  // ─────────────────────────────────────────────
  // Лайк
  // ─────────────────────────────────────────────
  Future<void> _toggleLike() async {
    final story  = _stories[_currentIndex];
    final result = await StoryService.instance.toggleLike(story);
    if (mounted) {
      setState(() {
        _stories[_currentIndex] = story.copyWith(
          isLikedByMe: result.liked,
          likesCount:  result.newCount,
        );
      });
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final story = _stories[_currentIndex];
    final size  = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final x = details.globalPosition.dx;
          if (x < size.width / 3) {
            _goPrev();
          } else if (x > size.width * 2 / 3) {
            _goNext();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd:   (_) => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Медиа ──
            _buildMedia(story),

            // ── Градиент жогору ──
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),

            // ── Градиент төмөн ──
            const Positioned(
              bottom: 0, left: 0, right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.bottomCenter,
                    end:    Alignment.center,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SizedBox(height: 120),
              ),
            ),

            // ── Прогресс + жабуу ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StoryProgressBar(
                      count:        _stories.length,
                      currentIndex: _currentIndex,
                      progress:     _progressAnim,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Spacer(),
                        if (_isPaused)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.pause_circle_outline,
                                color: Colors.white70, size: 22),
                          ),
                        GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Лайк баскычы ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StoryLikeButton(
                        isLiked:    story.isLikedByMe,
                        likesCount: story.likesCount,
                        onTap:      _toggleLike,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Медиа виджет
  // ─────────────────────────────────────────────
  Widget _buildMedia(StoryModel story) {
    // ── СҮРӨТ ──
    if (story.isImage) {
      return CachedNetworkImage(
        key:      ValueKey(story.id),
        imageUrl: story.mediaUrl,
        fit:      BoxFit.cover,
        width:    double.infinity,
        height:   double.infinity,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white54, size: 64),
        ),
      );
    }

    // ── ВИДЕО — кат жок, кэштен жүктөлөт ──
    if (_videoReady && _videoCtrl != null && _videoCtrl!.value.isInitialized) {
     return SizedBox.expand(
  child: FittedBox(
    fit: BoxFit.cover,  // толук экранга масштабтайт, кара жолок жок
    child: SizedBox(
      width: _videoCtrl!.value.size.width,
      height: _videoCtrl!.value.size.height,
      child: CachedVideoPlayerPlus(_videoCtrl!),
    ),
  ),
);
    }

    // Видео жүктөлүп жатканда — spinner
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 12),
          Text('Видео жүктөлүп жатат...',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
