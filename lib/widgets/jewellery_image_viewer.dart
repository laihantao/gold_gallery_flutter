import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Base64 decoding helper (module-level, side-effect free)
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

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class JewelleryImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final AppTheme appTheme;
  final void Function(int index)? onImageTap;

  const JewelleryImageViewer({
    super.key,
    required this.imagePaths,
    required this.appTheme,
    this.onImageTap,
  });

  @override
  State<JewelleryImageViewer> createState() => _JewelleryImageViewerState();
}

class _JewelleryImageViewerState extends State<JewelleryImageViewer> {
  late final PageController _pageController;

  // ValueNotifier so only the thumbnail row rebuilds on page change,
  // leaving the PageView and its heavy image tiles untouched.
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);

  // Bytes decoded once in initState; never re-decoded on rebuild.
  late final List<Uint8List?> _cachedBytes;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cachedBytes = widget.imagePaths.map(_decodeBase64).toList();
  }

  @override
  void didUpdateWidget(JewelleryImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePaths != widget.imagePaths) {
      // Re-decode only if the list reference changed.
      _cachedBytes
        ..clear()
        ..addAll(widget.imagePaths.map(_decodeBase64));
      _currentIndex.value = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return _Placeholder(appTheme: widget.appTheme);
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => _currentIndex.value = i,
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: GestureDetector(
                  onTap: () => widget.onImageTap?.call(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: widget.appTheme.backgroundSubtle,
                      child: _ImageTile(
                        // Stable key by position — avoids key comparison on
                        // long base64 strings and prevents spurious rebuilds.
                        key: ValueKey(index),
                        imagePath: widget.imagePaths[index],
                        cachedBytes: _cachedBytes[index],
                        appTheme: widget.appTheme,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imagePaths.length > 1) ...[
          const SizedBox(height: 12),
          // ValueListenableBuilder scopes rebuilds to the thumbnail row only.
          ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, currentIdx, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    widget.imagePaths.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ThumbnailTile(
                        key: ValueKey(index),
                        imagePath: widget.imagePaths[index],
                        cachedBytes: _cachedBytes[index],
                        appTheme: widget.appTheme,
                        isSelected: index == currentIdx,
                        onTap: () => _navigateTo(index),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty-state placeholder
// ---------------------------------------------------------------------------

class _Placeholder extends StatelessWidget {
  final AppTheme appTheme;
  const _Placeholder({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: appTheme.backgroundSubtle,
          child: Image.asset(
            'assets/images/defaults/default_jewellery.png',
            key: const ValueKey('default_jewellery_placeholder'),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Icon(Icons.image, color: appTheme.accentSecondary, size: 80),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-size image tile (used inside PageView)
// ---------------------------------------------------------------------------

class _ImageTile extends StatelessWidget {
  final String imagePath;
  final Uint8List? cachedBytes;
  final AppTheme appTheme;
  final BoxFit fit;

  const _ImageTile({
    super.key,
    required this.imagePath,
    required this.cachedBytes,
    required this.appTheme,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: _errorIcon,
      );
    }

    if (cachedBytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          cachedBytes!,
          fit: fit,
          errorBuilder: _errorIcon,
        ),
      );
    }

    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return SizedBox.expand(
          child: Image.file(file, fit: fit, errorBuilder: _errorIcon),
        );
      }
    } catch (_) {}

    return Center(
      child: Icon(Icons.image, color: appTheme.accentSecondary, size: 48),
    );
  }

  Widget _errorIcon(BuildContext ctx, Object err, StackTrace? st) =>
      Center(child: Icon(Icons.image, color: appTheme.accentSecondary, size: 48));
}

// ---------------------------------------------------------------------------
// Thumbnail tile
// ---------------------------------------------------------------------------

class _ThumbnailTile extends StatelessWidget {
  final String imagePath;
  final Uint8List? cachedBytes;
  final AppTheme appTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailTile({
    super.key,
    required this.imagePath,
    required this.cachedBytes,
    required this.appTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? appTheme.accentPrimary
                : appTheme.borderColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: _ImageTile(
            imagePath: imagePath,
            cachedBytes: cachedBytes,
            appTheme: appTheme,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
