import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_channel.dart';

/// A pending OTA update, resolved from the channel's `version-*.json` manifest.
class UpdateInfo {
  final String version;
  final String apkUrl;
  final String notes;
  final bool forceUpdate;

  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
    required this.forceUpdate,
  });
}

/// Checks the GitHub-hosted release manifest for a newer build than the one
/// currently installed.
///
/// Never throws: any network failure or malformed manifest is treated as
/// "no update available" so it can safely run unattended after startup.
class UpdateChecker {
  static const Duration _timeout = Duration(seconds: 10);

  static const String _devManifestUrl =
      'https://raw.githubusercontent.com/laihantao/pocket-gold-releases/main/release_manifests/version-dev.json';
  static const String _prodManifestUrl =
      'https://raw.githubusercontent.com/laihantao/pocket-gold-releases/main/release_manifests/version-prod.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final manifestUrl = channelFromEnv == AppChannel.dev
          ? _devManifestUrl
          : _prodManifestUrl;

      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      final remoteVersion = json['version'];
      final apkUrl = json['apk_url'];
      if (remoteVersion is! String || apkUrl is! String) return null;

      final notes = json['notes'] is String ? json['notes'] as String : '';
      final forceUpdate = json['force_update'] == true;

      final localInfo = await PackageInfo.fromPlatform();
      final remoteBuildNumber = _asInt(json['build_number']);
      final localBuildNumber = int.tryParse(localInfo.buildNumber);

      final isNewer = remoteBuildNumber != null && localBuildNumber != null
          // CI sets --build-number to a monotonically increasing run number,
          // so this is authoritative when present and avoids the ambiguity
          // of comparing two "1.0.0-dev" builds that only differ by build.
          ? remoteBuildNumber > localBuildNumber
          : _isNewer(remoteVersion, localInfo.version);

      if (!isNewer) return null;

      return UpdateInfo(
        version: remoteVersion,
        apkUrl: apkUrl,
        notes: notes,
        forceUpdate: forceUpdate,
      );
    } catch (_) {
      // Silent failure by design: a broken manifest or offline device must
      // never block or crash app startup.
      return null;
    }
  }

  /// Compares two version strings numerically, ignoring any `-dev` (or other
  /// `-`/`+` prefixed) suffix — so `1.2.0-dev` and `1.2.0` compare equal.
  static bool _isNewer(String remote, String local) {
    final remoteParts = _numericParts(remote);
    final localParts = _numericParts(local);

    final length = remoteParts.length > localParts.length
        ? remoteParts.length
        : localParts.length;

    for (var i = 0; i < length; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (r != l) return r > l;
    }
    return false;
  }

  static List<int> _numericParts(String version) {
    final numericOnly = version.split(RegExp(r'[-+]')).first;
    return numericOnly
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
