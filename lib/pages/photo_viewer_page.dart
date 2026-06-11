import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/theme_notifier.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const PhotoViewerPage({
    Key? key,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

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

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    } else {
      // Try base64 decode first
      try {
        final bytes = base64Decode(imagePath);
        return MemoryImage(bytes);
      } catch (_) {
        // Fall back to file path
        try {
          return FileImage(File(imagePath));
        } catch (_) {
          // Final fallback to asset
          return AssetImage('assets/images/default_image.png');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

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
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: _getImageProvider(widget.imagePaths[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                enableRotation: false,
              );
            },
          ),
          // Left arrow button (visible on desktop/web)
          if (widget.imagePaths.length > 1 && _currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          // Right arrow button (visible on desktop/web)
          if (widget.imagePaths.length > 1 && _currentIndex < widget.imagePaths.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      if (_currentIndex < widget.imagePaths.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          // Counter pill at the bottom center
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imagePaths.length}',
                    style: TextStyle(
                      color: appTheme.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          // Thumbnail row at the bottom
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      widget.imagePaths.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _currentIndex == index
                                    ? appTheme.accentPrimary
                                    : Colors.white.withValues(alpha: 0.2),
                                width: _currentIndex == index ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color: Colors.grey[800],
                                child: Image(
                                  image: _getImageProvider(widget.imagePaths[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image,
                                      color: appTheme.accentSecondary,
                                      size: 24,
                                    );
                                  },
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
