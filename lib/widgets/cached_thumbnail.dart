import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Decodes base64 thumbnails once and caches the bytes app-wide, so repeated
/// rebuilds and tab switches don't re-decode the same image (which shows as a
/// blank-then-flash). Bounded so it can't grow without limit.
class ThumbnailBytesCache {
  ThumbnailBytesCache._();

  static final Map<String, Uint8List> _cache = {};
  static const int _maxEntries = 80;

  static Uint8List? decode(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final existing = _cache[base64];
    if (existing != null) return existing;
    try {
      final bytes = base64Decode(base64);
      // Simple bounded eviction: drop the oldest inserted entry.
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[base64] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

/// A base64 image that decodes via [ThumbnailBytesCache] and uses
/// `gaplessPlayback`, so it never flashes to blank on rebuild. Falls back to
/// [placeholder] when the string is empty or fails to decode.
class CachedThumbnail extends StatelessWidget {
  final String? base64;
  final BoxFit fit;
  final Widget placeholder;

  const CachedThumbnail({
    super.key,
    required this.base64,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = ThumbnailBytesCache.decode(base64);
    if (bytes == null) return placeholder;
    return Image.memory(
      bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
