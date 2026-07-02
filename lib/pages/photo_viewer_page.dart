import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_notifier.dart';

// ---------------------------------------------------------------------------
// Base64 decoding — same logic as jewellery_image_viewer.dart
// ---------------------------------------------------------------------------

Uint8List? _decodeBase64(String path) {
  final source = path.trim();
  final commaIndex = source.indexOf(',');
  final payload = source.startsWith('data:image') && commaIndex >= 0
      ? source.substring(commaIndex + 1)
      : source;

  if (payload.length < 100 ||
      payload.startsWith('file:') ||
      payload.contains(r'\') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(payload)) {
    return null;
  }
  if (payload.startsWith('/') && !payload.startsWith('/9j/')) return null;

  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

ImageProvider _resolveProvider(String path) {
  if (path.startsWith('assets/')) return AssetImage(path);
  final bytes = _decodeBase64(path);
  if (bytes != null) return MemoryImage(bytes);
  try {
    return FileImage(File(path));
  } catch (_) {
    return const AssetImage('assets/images/defaults/default_jewellery.png');
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PhotoViewerPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _pageController;
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  // True whenever any page is zoomed in — hides all chrome (close, arrows, etc.)
  final ValueNotifier<bool> _anyZoomed = ValueNotifier(false);
  late final List<ImageProvider> _providers;

  @override
  void initState() {
    super.initState();
    _currentIndex.value = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _providers = widget.imagePaths.map(_resolveProvider).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    _anyZoomed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final count = widget.imagePaths.length;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Swipeable pages ──────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              _currentIndex.value = i;
              // Reset UI visibility when page changes (zoom resets per-page)
              _anyZoomed.value = false;
            },
            itemCount: count,
            itemBuilder: (context, index) => _ZoomableImagePage(
              key: ValueKey(index),
              imageProvider: _providers[index],
              onZoomChanged: (zoomed) => _anyZoomed.value = zoomed,
              onSwipeLeft: index < count - 1
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                  : null,
              onSwipeRight: index > 0
                  ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                  : null,
            ),
          ),

          // ── All chrome — fades out when zoomed ───────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: _anyZoomed,
            builder: (_, zoomed, _) => AnimatedOpacity(
              opacity: zoomed ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: zoomed,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Close button (replaces AppBar so it can be hidden)
                    Positioned(
                      top: topPad + 4,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                    // Navigation arrows + counter pill (multi-image only)
                    if (count > 1)
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (_, idx, _) => Stack(
                          fit: StackFit.expand,
                          children: [
                            if (idx > 0)
                              _ArrowButton(
                                side: _ArrowSide.left,
                                onTap: () => _pageController.previousPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            if (idx < count - 1)
                              _ArrowButton(
                                side: _ArrowSide.right,
                                onTap: () => _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            Positioned(
                              bottom: 80,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${idx + 1} / $count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Thumbnail strip (multi-image only)
                    if (count > 1)
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (_, idx, _) => Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  count,
                                  (i) => Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _pageController.animateToPage(
                                        i,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: idx == i
                                                ? appTheme.accentPrimary
                                                : Colors.white
                                                    .withValues(alpha: 0.2),
                                            width: idx == i ? 2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: ColoredBox(
                                            color: Colors.grey.shade800,
                                            child: Image(
                                              image: _providers[i],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                Icons.image,
                                                color: Colors.white38,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zoomable image page — owns TransformationController + double-tap animation
// ---------------------------------------------------------------------------

class _ZoomableImagePage extends StatefulWidget {
  final ImageProvider imageProvider;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  // Notifies parent when zoom state changes so it can show/hide chrome.
  final void Function(bool isZoomed)? onZoomChanged;

  const _ZoomableImagePage({
    super.key,
    required this.imageProvider,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onZoomChanged,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animController;

  final ValueNotifier<bool> _isZoomed = ValueNotifier(false);

  TapDownDetails? _doubleTapDetails;
  Matrix4? _animBegin;
  Matrix4? _animEnd;

  static const double _doubleTapScale = 2.5;
  static const double _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onAnimTick);
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _animController.dispose();
    _transform.dispose();
    _isZoomed.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.05;
    if (_isZoomed.value != zoomed) {
      _isZoomed.value = zoomed;
      widget.onZoomChanged?.call(zoomed);
    }
  }

  void _onAnimTick() {
    if (_animBegin == null || _animEnd == null) return;
    final t = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    ).value;
    final b = _animBegin!.storage;
    final e = _animEnd!.storage;
    final result = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      result.storage[i] = b[i] + (e[i] - b[i]) * t;
    }
    _transform.value = result;
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    final currentScale = _transform.value.getMaxScaleOnAxis();
    final isZoomedIn = currentScale > 1.5;

    final Matrix4 target;
    if (isZoomedIn) {
      target = Matrix4.identity();
    } else {
      final pos = _doubleTapDetails!.localPosition;
      const s = _doubleTapScale;
      target = Matrix4.diagonal3Values(s, s, 1.0)
        ..setTranslationRaw(pos.dx * (1.0 - s), pos.dy * (1.0 - s), 0.0);
    }

    _animBegin = Matrix4.copy(_transform.value);
    _animEnd = target;
    _animController.forward(from: 0);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) widget.onSwipeLeft?.call();
    if (velocity > 300) widget.onSwipeRight?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isZoomed,
        builder: (_, isZoomed, _) => Stack(
          fit: StackFit.expand,
          children: [
            // panEnabled=false when not zoomed so InteractiveViewer doesn't
            // compete with the swipe overlay for single-finger horizontal drags.
            InteractiveViewer(
              transformationController: _transform,
              minScale: 1.0,
              maxScale: _maxScale,
              panEnabled: isZoomed,
              boundaryMargin: const EdgeInsets.all(20),
              child: Center(
                child: Image(
                  image: widget.imageProvider,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
            // Swipe-to-change-page overlay — only active when not zoomed.
            // translucent so 2-finger pinch still reaches InteractiveViewer.
            if (!isZoomed)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arrow navigation button
// ---------------------------------------------------------------------------

enum _ArrowSide { left, right }

class _ArrowButton extends StatelessWidget {
  final _ArrowSide side;
  final VoidCallback onTap;

  const _ArrowButton({required this.side, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLeft = side == _ArrowSide.left;
    return Positioned(
      left: isLeft ? 16 : null,
      right: isLeft ? null : 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
