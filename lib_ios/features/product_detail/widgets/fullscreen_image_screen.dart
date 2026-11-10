// ══════════════════════════════════════════════════════
// FULLSCREEN IMAGE
// product_detail_screen.dart файлынан бөлүнүп чыгарылды.
// ══════════════════════════════════════════════════════
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/dd_image_cache.dart';

class FullscreenImageScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTag;
  const FullscreenImageScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  @override
  State<FullscreenImageScreen> createState() => _FullscreenImageScreenState();
}

class _FullscreenImageScreenState extends State<FullscreenImageScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // Zoom деңгээлин байкоо үчүн — ар бир баракча өз контроллерине ээ.
  // Жөнөкөй чечим: бир глобал "zoomed" флаг, PageView physics башкарат.
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pageController,
          // Zoom болуп жатканда PageView скроллун өчүрүү
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final url = widget.images[index];

            return _ZoomableImage(
              url: url,
              screenSize: screenSize,
              isHero: index == widget.initialIndex,
              heroTag: widget.heroTag,
              onZoomChanged: (zoomed) {
                if (_isZoomed != zoomed) {
                  setState(() => _isZoomed = zoomed);
                }
              },
            );
          },
        ),

        // ── Жабуу баскычы ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),

        // ── Индикатор (бир нече сүрөт болгондо) ──
        if (widget.images.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ]),
    );
  }
}

// ── Жекелештирилген zoom виджети ──────────────────────
// Ар бир баракча өз TransformationController'ына ээ.
// Zoom > 1.0 болгондо _isZoomed = true → PageView блокталат.
// Zoom = 1.0 га кайткандан кийин PageView кайра иштейт.
class _ZoomableImage extends StatefulWidget {
  final String url;
  final Size screenSize;
  final bool isHero;
  final String heroTag;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImage({
    required this.url,
    required this.screenSize,
    required this.isHero,
    required this.heroTag,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    // Matrix4тин scale маанисин алуу
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    // 1.01 чектен ашса — зумда деп эсептейбиз (кичинекей буффер)
    widget.onZoomChanged(scale > 1.01);
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onTransformChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      cacheManager: DDImageCache.manager,
      imageUrl: widget.url,
      width: widget.screenSize.width,
      height: widget.screenSize.height,
      fit: BoxFit.contain,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (_, __, ___) => const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white54, size: 64)),
    );

    return InteractiveViewer(
      transformationController: _transformCtrl,
      minScale: 0.8,
      maxScale: 5.0,
      child: widget.isHero
          ? Hero(tag: widget.heroTag, child: image)
          : image,
    );
  }
}
