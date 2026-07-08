import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_notifier.dart';
import '../services/install_permission_service.dart';
import '../services/update_checker.dart';

/// Prompts the user about a pending OTA update and, once accepted, drives the
/// download/install via `ota_update`.
///
/// When [UpdateInfo.forceUpdate] is true, the "later" action is hidden and the
/// dialog cannot be dismissed by tapping outside or pressing back.
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (_) => UpdateDialog(info: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  StreamSubscription<OtaEvent>? _subscription;
  bool _downloading = false;
  double? _progress;
  String? _error;

  // Total APK size, read from the download's Content-Length header so we can
  // show "X / Y MB" and a speed. Null when the host doesn't report it, in
  // which case the UI falls back to a plain percentage.
  int? _totalBytes;
  double? _speedBytesPerSec;
  DateTime? _lastSampleTime;
  double? _lastSampleBytes;

  @override
  void initState() {
    super.initState();
    _fetchTotalSize();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Probes the APK URL for its size via a HEAD request. Best-effort: any
  /// failure (redirect without Content-Length, offline, etc.) just leaves the
  /// UI on the percentage-only display.
  Future<void> _fetchTotalSize() async {
    try {
      final resp = await http
          .head(Uri.parse(widget.info.apkUrl))
          .timeout(const Duration(seconds: 10));
      final len = resp.headers['content-length'];
      final bytes = len == null ? null : int.tryParse(len);
      if (bytes != null && bytes > 0 && mounted) {
        setState(() => _totalBytes = bytes);
      }
    } catch (_) {
      // Size stays unknown; percentage fallback remains in effect.
    }
  }

  /// Updates progress and, when the total size is known, a smoothed download
  /// speed (EMA over progress ticks).
  void _onDownloadProgress(double progress) {
    final total = _totalBytes;
    if (total != null) {
      final now = DateTime.now();
      final curBytes = progress * total;
      final lastTime = _lastSampleTime;
      final lastBytes = _lastSampleBytes;
      if (lastTime != null && lastBytes != null) {
        final dt = now.difference(lastTime).inMilliseconds / 1000.0;
        // Ignore sub-250ms gaps so a tiny dt can't spike the estimate.
        if (dt >= 0.25) {
          final inst = (curBytes - lastBytes) / dt;
          if (inst.isFinite && inst >= 0) {
            _speedBytesPerSec = _speedBytesPerSec == null
                ? inst
                : _speedBytesPerSec! * 0.6 + inst * 0.4;
          }
          _lastSampleTime = now;
          _lastSampleBytes = curBytes;
        }
      } else {
        _lastSampleTime = now;
        _lastSampleBytes = curBytes;
      }
    }
    _progress = progress;
  }

  void _startDownload() {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
      _speedBytesPerSec = null;
      _lastSampleTime = null;
      _lastSampleBytes = null;
    });

    _subscription = OtaUpdate().execute(widget.info.apkUrl).listen(
      _handleEvent,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _downloading = false;
          _error = context.read<LocaleNotifier>().localizations.updateDownloadFailed;
        });
      },
    );
  }

  Future<void> _handleEvent(OtaEvent event) async {
    if (!mounted) return;
    final l10n = context.read<LocaleNotifier>().localizations;

    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        setState(() {
          _onDownloadProgress((double.tryParse(event.value ?? '') ?? 0) / 100);
        });
        break;

      case OtaStatus.INSTALLING:
        setState(() => _progress = null);
        break;

      case OtaStatus.INSTALLATION_DONE:
        if (!widget.info.forceUpdate && mounted) {
          Navigator.of(context).pop();
        }
        break;

      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        setState(() {
          _downloading = false;
          _error = l10n.updatePermissionRequired;
        });
        final canInstall =
            await InstallPermissionService.canRequestPackageInstalls();
        if (!canInstall) {
          await InstallPermissionService.openInstallPermissionSettings();
        }
        break;

      case OtaStatus.ALREADY_RUNNING_ERROR:
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.DOWNLOAD_ERROR:
      case OtaStatus.CHECKSUM_ERROR:
        setState(() {
          _downloading = false;
          _error = l10n.updateFailed;
        });
        break;

      case OtaStatus.CANCELED:
        setState(() => _downloading = false);
        break;
    }
  }

  /// "4.2 / 79.0 MB · 1.3 MB/s" when the size is known, else "45%", and
  /// "Installing…" once the download hands off to the installer.
  String _progressLabel(AppLocalizations l10n) {
    final progress = _progress;
    if (progress == null) return l10n.updateInstalling;

    final total = _totalBytes;
    if (total != null) {
      final done = progress * total;
      var label = '${_formatMb(done)} / ${_formatMb(total)} MB';
      final speed = _speedBytesPerSec;
      if (speed != null && speed > 0) label = '$label · ${_formatSpeed(speed)}';
      return label;
    }
    return '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';
  }

  String _formatMb(num bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  String _formatSpeed(double bytesPerSec) => bytesPerSec >= 1024 * 1024
      ? '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s'
      : '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';

  @override
  Widget build(BuildContext context) {
    final canDismiss = !widget.info.forceUpdate;
    final l10n = context.l10n;

    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        title: Text(l10n.updateFoundTitle(widget.info.version)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.info.notes.isNotEmpty) Text(widget.info.notes),
              if (_downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 6),
                Text(
                  _progressLabel(l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (canDismiss && !_downloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.updateLater),
            ),
          TextButton(
            onPressed: _downloading ? null : _startDownload,
            child: Text(_downloading ? l10n.updateDownloading : l10n.updateNow),
          ),
        ],
      ),
    );
  }
}
