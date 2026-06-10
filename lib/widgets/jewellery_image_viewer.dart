import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

  if (payload.startsWith('/') && !payload.startsWith('/9j/')) {
    return null;
  }

  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openImageAt(int index) {
    widget.onImageTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return Column(
        children: [
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: widget.appTheme.backgroundSubtle,
                child: Image.asset(
                  'assets/images/defaults/default_jewellery.png',
                  key: const ValueKey('default_jewellery_placeholder'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image,
                        color: widget.appTheme.accentSecondary,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: GestureDetector(
            onTap: () => _openImageAt(_currentIndex),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.imagePaths.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: widget.appTheme.backgroundSubtle,
                    child: _JewelleryImageTile(
                      imagePath: widget.imagePaths[index],
                      appTheme: widget.appTheme,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.imagePaths.length > 1) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.imagePaths.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _JewelleryThumbnailTile(
                    imagePath: widget.imagePaths[index],
                    appTheme: widget.appTheme,
                    isSelected: index == _currentIndex,
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _JewelleryImageTile extends StatelessWidget {
  final String imagePath;
  final AppTheme appTheme;
  final BoxFit fit;

  const _JewelleryImageTile({
    required this.imagePath,
    required this.appTheme,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        key: ValueKey('asset_$imagePath'),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
        },
      );
    }

    final bytes = _decodeBase64(imagePath);
    if (bytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          bytes,
          key: ValueKey('img_$imagePath'),
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
          },
        ),
      );
    }

    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return SizedBox.expand(
          child: Image.file(
            file,
            key: ValueKey('file_$imagePath'),
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
            },
          ),
        );
      }
    } catch (_) {}

    return Icon(Icons.image, color: appTheme.accentSecondary, size: 48);
  }
}

class _JewelleryThumbnailTile extends StatelessWidget {
  final String imagePath;
  final AppTheme appTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _JewelleryThumbnailTile({
    required this.imagePath,
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
          borderRadius: BorderRadius.circular(8),
          child: _JewelleryImageTile(
            imagePath: imagePath,
            appTheme: appTheme,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
