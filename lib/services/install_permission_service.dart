import 'package:flutter/services.dart';

/// Bridges to the native "install unknown apps" permission (Android 8+),
/// which has no Flutter-side API. Backed by a MethodChannel implemented in
/// `MainActivity.kt`.
class InstallPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'com.laihantao.pocketgold/install_permission',
  );

  /// True on Android < 8 (no such restriction) or once the user has granted
  /// the permission for this app. Defaults to true if the platform call
  /// fails, so a transient channel error never blocks the update flow.
  static Future<bool> canRequestPackageInstalls() async {
    try {
      return await _channel.invokeMethod<bool>(
            'canRequestPackageInstalls',
          ) ??
          true;
    } on PlatformException {
      return true;
    }
  }

  /// Opens the system "install unknown apps" settings screen scoped to this
  /// app, so the user can grant the permission before retrying the install.
  static Future<void> openInstallPermissionSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallPermissionSettings');
    } on PlatformException {
      // Nothing sensible to do if the settings screen can't be opened.
    }
  }
}
