import 'dart:async';
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

/// Outcome of a manual update check, so the UI can give a meaningful message
/// per scenario instead of collapsing every failure into "up to date".
sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

/// A newer build is available.
final class UpdateAvailable extends UpdateCheckResult {
  final UpdateInfo info;
  const UpdateAvailable(this.info);
}

/// Reached the manifest and the installed build is current.
final class UpToDate extends UpdateCheckResult {
  const UpToDate();
}

/// No connectivity — the request failed before reaching the server
/// (offline, DNS failure, connection refused).
final class UpdateCheckOffline extends UpdateCheckResult {
  const UpdateCheckOffline();
}

/// Had connectivity but the request exceeded [UpdateChecker._timeout].
final class UpdateCheckTimeout extends UpdateCheckResult {
  const UpdateCheckTimeout();
}

/// Reached the network but couldn't read a valid manifest — a non-200
/// response (e.g. 404/5xx) or malformed/incomplete JSON.
final class UpdateCheckServerError extends UpdateCheckResult {
  final int? statusCode;
  const UpdateCheckServerError(this.statusCode);
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

  /// Silent variant for the unattended startup check: returns the pending
  /// update if any, and `null` for every other outcome (up to date, offline,
  /// timeout, error) so it can never surface as a startup crash.
  static Future<UpdateInfo?> checkForUpdate() async {
    final result = await checkForUpdateDetailed();
    return result is UpdateAvailable ? result.info : null;
  }

  /// Full variant for the manual "Check for Updates" action, classifying the
  /// outcome so the UI can distinguish offline / timeout / server error /
  /// up to date / update available.
  static Future<UpdateCheckResult> checkForUpdateDetailed() async {
    try {
      // Use the runtime channel the app booted with, not the compile-time
      // dart-define — the two can drift (e.g. a dev-target build that omits
      // --dart-define=CHANNEL=dev), which silently checks the wrong manifest.
      final manifestUrl = activeChannel == AppChannel.dev
          ? _devManifestUrl
          : _prodManifestUrl;

      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(_timeout);
      // Reached the server but it didn't serve the manifest.
      if (response.statusCode != 200) {
        return UpdateCheckServerError(response.statusCode);
      }

      final json = jsonDecode(response.body);
      // Reached the manifest but couldn't read the fields we need.
      if (json is! Map<String, dynamic>) {
        return const UpdateCheckServerError(null);
      }

      final remoteVersion = json['version'];
      final apkUrl = json['apk_url'];
      if (remoteVersion is! String || apkUrl is! String) {
        return const UpdateCheckServerError(null);
      }

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

      if (!isNewer) return const UpToDate();

      return UpdateAvailable(
        UpdateInfo(
          version: remoteVersion,
          apkUrl: apkUrl,
          notes: notes,
          forceUpdate: forceUpdate,
        ),
      );
    } on TimeoutException {
      // Had a connection but the server was too slow to respond in time.
      return const UpdateCheckTimeout();
    } catch (_) {
      // Connection-level failures (offline, DNS failure, connection refused)
      // surface as SocketException / http.ClientException depending on the
      // platform. Classified as offline without importing dart:io so the
      // web build stays compilable.
      return const UpdateCheckOffline();
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
