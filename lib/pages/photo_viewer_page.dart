import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
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
  // ValueNotifier to scope UI rebuilds to navigation elements only.
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  late final List<ImageProvider> _providers;

  @override
  void initState() {
    super.initState();
    _currentIndex.value = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Resolve providers once; MemoryImage caches the Uint8List.
    _providers = widget.imagePaths.map(_resolveProvider).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final count = widget.imagePaths.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Swipeable pages ──────────────────────────────────────────────
          // NeverScrollableScrollPhysics removes PageView from the gesture
          // arena so InteractiveViewer can win horizontal drags when zoomed.
          // Each _ZoomableImagePage handles swipe-navigation when not zoomed.
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => _currentIndex.value = i,
            itemCount: count,
            itemBuilder: (context, index) => _ZoomableImagePage(
              key: ValueKey(index),
              imageProvider: _providers[index],
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

          // ── Navigation arrows + counter pill ────────────────────────────
          if (count > 1)
            ValueListenableBuilder<int>(
              valueListenable: _currentIndex,
              builder: (_, idx, _) => Stack(
                fit: StackFit.expand,
                children: [
                  // Left arrow
                  if (idx > 0)
                    _ArrowButton(
                      side: _ArrowSide.left,
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  // Right arrow
                  if (idx < count - 1)
                    _ArrowButton(
                      side: _ArrowSide.right,
                      onTap: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  // Counter pill
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${idx + 1} / $count',
                          style: TextStyle(
                            color: appTheme.textBody,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Thumbnail strip ──────────────────────────────────────────────
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
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: idx == i
                                      ? appTheme.accentPrimary
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: idx == i ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: ColoredBox(
                                  color: Colors.grey.shade800,
                                  child: Image(
                                    image: _providers[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Zoomable image page — owns TransformationController + double-tap animation
// ---------------------------------------------------------------------------

class _ZoomableImagePage extends StatefulWidget {
  final ImageProvider imageProvider;

  // Called when user swipes past the edge while not zoomed in.
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const _ZoomableImagePage({
    super.key,
    required this.imageProvider,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animController;

  // Tracks zoom so the swipe recognizer is toggled without touching InteractiveViewer.
  final ValueNotifier<bool> _isZoomed = ValueNotifier(false);

  // Capture position between onDoubleTapDown → onDoubleTap.
  TapDownDetails? _doubleTapDetails;

  // Animation endpoints updated on each double-tap.
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
    if (_isZoomed.value != zoomed) _isZoomed.value = zoomed;
  }

  // Linear interpolation between two Matrix4 values.
  // Correct for pure scale+translate matrices (no rotation shear).
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
      // Zoom to the tapped position.
      // At scale 1 the matrix is identity, so local tap coords == child coords.
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
      // Capture tap position BEFORE the double-tap fires.
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isZoomed,
        // `child` is built once; InteractiveViewer's element is kept alive
        // by Flutter's reconciler across recognizer-map updates.
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1.0,
          maxScale: _maxScale,
          // boundaryMargin lets the user pan to image edges when zoomed.
          boundaryMargin: const EdgeInsets.all(20),
          child: Center(
            child: Image(
              image: widget.imageProvider,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child:
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
        builder: (_, isZoomed, child) => RawGestureDetector(
          // When zoomed: empty map → InteractiveViewer wins horizontal drags.
          // When not zoomed: swipe recognizer fires page navigation.
          gestures: isZoomed
              ? const <Type, GestureRecognizerFactory>{}
              : <Type, GestureRecognizerFactory>{
                  HorizontalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          HorizontalDragGestureRecognizer>(
                    HorizontalDragGestureRecognizer.new,
                    (r) => r.onEnd = _onHorizontalDragEnd,
                  ),
                },
          behavior: HitTestBehavior.translucent,
          child: child!,
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
