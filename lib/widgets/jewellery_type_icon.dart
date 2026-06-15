import 'package:flutter/material.dart';

/// Renders a jewellery-type image asset identified by [iconKey].
///
/// Valid [iconKey] values: 'ring' | 'pendant' | 'necklace' | 'bracelet' |
/// 'earrings' | 'goldbar' | 'other'
///
/// 'other' (and any unknown key) falls back to a Material icon so the widget
/// is always safe to call with any user-supplied string.
class JewelleryTypeIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color? tintColor;

  const JewelleryTypeIcon({
    super.key,
    required this.iconKey,
    this.size = 48,
    this.tintColor,
  });

  static const Map<String, String> _assetMap = {
    'ring':     'assets/images/jewellery_type/ring-removebg-preview.png',
    'pendant':  'assets/images/jewellery_type/pendant-removebg-preview.png',
    'necklace': 'assets/images/jewellery_type/necklace-removebg-preview.png',
    'bracelet': 'assets/images/jewellery_type/bracelet-removebg-preview.png',
    'earrings': 'assets/images/jewellery_type/earrings-removebg-preview.png',
    'goldbar':  'assets/images/jewellery_type/goldbar-removebg-preview.png',
  };

  /// Returns the asset path for [key], or null for 'other' / unknown keys.
  static String? assetPath(String key) => _assetMap[key];

  /// All valid icon key values, in display order.
  static const List<String> validKeys = [
    'ring', 'pendant', 'necklace', 'bracelet', 'earrings', 'goldbar', 'other',
  ];

  @override
  Widget build(BuildContext context) {
    final path = _assetMap[iconKey];

    Widget icon;
    if (path == null) {
      icon = Icon(Icons.category_outlined, size: size,
          color: tintColor ?? Colors.grey);
    } else {
      icon = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        // Apply optional tint via ColorFiltered (e.g. for dimmed states).
        color: tintColor,
        colorBlendMode: tintColor != null ? BlendMode.modulate : null,
        errorBuilder: (context, e, _) =>
            Icon(Icons.category_outlined, size: size, color: tintColor),
      );
    }

    return SizedBox(width: size, height: size, child: icon);
  }
}
