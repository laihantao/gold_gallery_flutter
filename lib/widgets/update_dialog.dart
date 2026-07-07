import 'dart:async';

import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
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
          _progress = (double.tryParse(event.value ?? '') ?? 0) / 100;
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
                  _progress == null
                      ? l10n.updateInstalling
                      : '${(_progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
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
