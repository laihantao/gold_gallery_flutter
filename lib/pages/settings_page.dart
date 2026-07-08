import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../config/app_channel.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_notifier.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../components/form_section.dart';
import '../services/backup_service.dart';
import '../services/gold_price_history_backfill_service.dart';
import '../services/update_checker.dart';
import '../widgets/manage_collections_sheet.dart';
import '../widgets/update_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSharing = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncingHistory = false;
  bool _pinEnabled = false;
  bool _isCheckingUpdate = false;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadPinState();
    _loadVersionLabel();
  }

  Future<void> _loadVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    // versionName already carries the per-flavor suffix (e.g. "1.0.0-dev" vs
    // "1.0.0"), since it's set via `versionNameSuffix` in build.gradle.kts.
    if (mounted) {
      setState(() => _versionLabel = 'v${info.version} (${info.buildNumber})');
    }
  }

  Future<void> _loadPinState() async {
    final enabled = await AuthService.isPinEnabled();
    if (mounted) setState(() => _pinEnabled = enabled);
  }

  Future<void> _togglePin(bool value) async {
    final appTheme = context.read<ThemeNotifier>().currentTheme;
    if (value) {
      await GoRouter.of(context).push<bool>('/pin-setup');
      await _loadPinState();
      if (!mounted) return;
      if (_pinEnabled) {
        _showSnackBar('PIN lock enabled successfully.', appTheme);
      }
    } else {
      final confirmed = await _confirmDisable();
      if (!confirmed || !mounted) return;
      await AuthService.disablePin();
      if (!mounted) return;
      setState(() => _pinEnabled = false);
      _showSnackBar('PIN lock disabled.', appTheme);
    }
  }

  Future<bool> _confirmDisable() async {
    final appTheme = context.read<ThemeNotifier>().currentTheme;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: appTheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Disable App Lock',
                style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            content: Text(
              'Your PIN and security question will be removed. '
              'Jewellery data will not be affected.',
              style: TextStyle(
                  color: appTheme.inkMid, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(color: appTheme.inkLight)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Disable'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.settingsTitle,
        showBackButton: false,
        colored: true,
        actions: [
          IconButton(
            icon: Icon(Icons.language_outlined,
                color: appTheme.inkDark, size: 24),
            onPressed: () =>
                _showLanguageSheet(context, appTheme, l10n),
            tooltip: l10n.languageSection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Theme ──────────────────────────────────────────
            FormSection(
              title: l10n.themeSection,
              child: SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  children: [
                    for (final theme in AurumTheme.values) ...[
                      _ThemeCard(
                        theme: theme,
                        isActive: appTheme == theme,
                        onTap: () => context
                            .read<ThemeNotifier>()
                            .setTheme(theme),
                      ),
                      if (theme != AurumTheme.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── General (Users / Brands / Jewellery Types) ──────
            FormSection(
              title: l10n.generalSection,
              child: Column(
                children: [
                  PrimaryButton(
                    label: l10n.manageUsers,
                    onPressed: () => GoRouter.of(context).push('/users'),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: l10n.manageBrands,
                    onPressed: () => GoRouter.of(context).push('/brands'),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: l10n.manageTypes,
                    onPressed: () =>
                        GoRouter.of(context).push('/jewellery-types'),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: l10n.manageCollections,
                    onPressed: () => ManageCollectionsSheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Price Data (History sync + Alerts) ──────────────
            FormSection(
              title: l10n.priceDataSection,
              tooltip:
                  'Corrects the last 7 days of prices from the source of truth, '
                  'and fills any missing days in the past 30 days.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syncHistoryDesc,
                    style: TextStyle(
                      color: appTheme.textBody.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isSyncingHistory ? l10n.syncing : l10n.syncHistory,
                    onPressed: () => _syncHistory(context, appTheme, l10n),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.priceAlertsDesc,
                    style: TextStyle(
                      color: appTheme.textBody.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l10n.managePriceAlerts,
                    onPressed: () => GoRouter.of(context).push('/price-alerts'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Security ────────────────────────────────────────
            FormSection(
              title: l10n.securitySection,
              child: Column(
                children: [
                  // PIN toggle row
                  Row(
                    children: [
                      Icon(
                        _pinEnabled
                            ? Icons.lock_rounded
                            : Icons.lock_outline_rounded,
                        color: _pinEnabled
                            ? appTheme.primary
                            : appTheme.inkMid,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appPinLockTitle,
                              style: TextStyle(
                                color: appTheme.inkDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              l10n.appPinLockDesc,
                              style: TextStyle(
                                  color: appTheme.inkLight, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _pinEnabled,
                        onChanged: _togglePin,
                        activeThumbColor: appTheme.primary,
                        activeTrackColor: appTheme.primaryLight,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  // Change PIN (only visible when enabled)
                  if (_pinEnabled) ...[
                    const SizedBox(height: 14),
                    GhostButton(
                      label: l10n.changePin,
                      onPressed: () async {
                        final appTheme =
                            context.read<ThemeNotifier>().currentTheme;
                        await GoRouter.of(context)
                            .push<bool>('/pin-setup', extra: {'mode': 'change'});
                        if (!mounted) return;
                        _showSnackBar('PIN changed successfully.', appTheme);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Data ────────────────────────────────────────────
            FormSection(
              title: l10n.dataSection,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isSharing ? l10n.exporting : l10n.exportShare,
                          onPressed: () => _shareData(context, appTheme, l10n),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GhostButton(
                          label: _isExporting ? l10n.exporting : l10n.exportSaveDevice,
                          onPressed: () => _exportData(context, appTheme, l10n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isImporting ? l10n.importing : l10n.importData,
                    onPressed: () => _importData(context, appTheme, l10n),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: l10n.exportPdf,
                    onPressed: () =>
                        GoRouter.of(context).push('/export-pdf'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GhostButton(
              label: _isCheckingUpdate ? l10n.checkingForUpdate : l10n.checkForUpdate,
              isLoading: _isCheckingUpdate,
              onPressed: () => _checkForUpdate(appTheme, l10n),
            ),
            if (_versionLabel != null) ...[
              const SizedBox(height: 12),
              // Right-aligned so it clears the centre-docked FAB, which
              // floats above this scroll content at bottom-centre.
              Align(
                alignment: Alignment.centerRight,
                // Long-press reveals hidden update diagnostics (channel,
                // manifest URL, installed build, live check result).
                child: GestureDetector(
                  onLongPress: () => _showUpdateDiagnostics(appTheme),
                  child: Text(
                    _versionLabel!,
                    style: TextStyle(
                      color: appTheme.inkLight.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _syncHistory(
      BuildContext context, AppTheme appTheme, AppLocalizations l10n) async {
    if (_isSyncingHistory) return;
    setState(() => _isSyncingHistory = true);
    try {
      // Fill any gaps in the last 30 days, then reconcile recent days against
      // Sheets to overwrite stale data (e.g. a morning fetch with wrong price).
      final count = await GoldPriceHistoryBackfillService.manualSync();
      await GoldPriceHistoryBackfillService.reconcileRecentHistory(force: true);
      if (!mounted) return;
      _showSnackBar(
        count == 0 ? l10n.syncUpToDate : l10n.syncedCount(count),
        appTheme,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.syncFailed, appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isSyncingHistory = false);
    }
  }

  Future<void> _shareData(
      BuildContext context, AppTheme appTheme, AppLocalizations l10n) async {
    if (_isSharing || _isImporting) return;
    setState(() => _isSharing = true);
    try {
      await BackupService.shareBackup();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.exportFailed(e), appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _exportData(
      BuildContext context, AppTheme appTheme, AppLocalizations l10n) async {
    if (_isExporting || _isImporting) return;
    setState(() => _isExporting = true);
    try {
      final savePath = await BackupService.exportBackup();
      if (!mounted) return;
      if (savePath == null) return; // user cancelled the picker
      _showSnackBar(
        l10n.exportSaved(savePath.split(RegExp(r'[/\\]')).last),
        appTheme,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.exportFailed(e), appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(
      BuildContext context, AppTheme appTheme, AppLocalizations l10n) async {
    if (_isExporting || _isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.importBackup();
      if (!mounted) return;
      if (result == null) {
        _showSnackBar(l10n.importCancelled, appTheme);
      } else {
        _showSnackBar(
          l10n.importSuccess(result.totalImported),
          appTheme,
          subtitle: result.breakdown.isNotEmpty ? result.breakdown : null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(l10n.importFailed(e), appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _checkForUpdate(AppTheme appTheme, AppLocalizations l10n) async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    try {
      final result = await UpdateChecker.checkForUpdateDetailed();
      if (!mounted) return;
      switch (result) {
        case UpdateAvailable(:final info):
          await UpdateDialog.show(context, info);
        case UpToDate():
          _showSnackBar(l10n.updateUpToDate, appTheme);
        case UpdateCheckOffline():
          _showSnackBar(l10n.updateOffline, appTheme, isError: true);
        case UpdateCheckTimeout():
          _showSnackBar(l10n.updateTimeout, appTheme, isError: true);
        case UpdateCheckServerError():
          _showSnackBar(l10n.updateServerError, appTheme, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _showUpdateDiagnostics(AppTheme appTheme) async {
    final pkg = await PackageInfo.fromPlatform();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _UpdateDiagnosticsDialog(
        appTheme: appTheme,
        appVersion: pkg.version,
        buildNumber: pkg.buildNumber,
      ),
    );
  }

  void _showSnackBar(
    String message,
    AppTheme appTheme, {
    bool isError = false,
    String? subtitle,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? appTheme.error : appTheme.snackBarBg,
        duration: subtitle != null
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
        content: subtitle != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              )
            : Text(message),
      ),
    );
  }

}

// ── Language sheet ────────────────────────────────────────────────────────────

void _showLanguageSheet(
    BuildContext context, AppTheme appTheme, AppLocalizations l10n) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LanguageSheet(appTheme: appTheme, l10n: l10n),
  );
}

class _LanguageSheet extends StatelessWidget {
  final AppTheme appTheme;
  final AppLocalizations l10n;

  const _LanguageSheet({required this.appTheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, _) {
        // Material is required so ListTile ink splashes are visible.
        return Material(
          color: appTheme.backgroundSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.borderColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.languageSection,
                    style: AppTextStyles.headline(appTheme.inkDark,
                        locale: l10n.locale),
                  ),
                ),
              ),
              ...AppLocale.values.map(
                (loc) => ListTile(
                  leading:
                      Text(loc.flagEmoji, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    loc.displayName,
                    style: AppTextStyles.body(appTheme.textHeading,
                        locale: l10n.locale),
                  ),
                  trailing: localeNotifier.locale == loc
                      ? Icon(Icons.check_circle_outlined,
                          color: appTheme.primary, size: 22)
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  onTap: () {
                    context.read<LocaleNotifier>().setLocale(loc);
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}

// ── Theme card (horizontal-scroll, compact) ───────────────────────────────────
//
// Inspired by Genshin Impact / Wuthering Waves character-select cards:
// a portrait tile with a colour accent bar at top and theme name below.

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.locale;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        decoration: BoxDecoration(
          color: theme.primaryBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? theme.primary : theme.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Accent colour swatch with dark-ring border
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary,
                border: Border.all(color: theme.primaryDark, width: 1.5),
              ),
              child: isActive
                  ? Icon(Icons.check_rounded, size: 16, color: theme.primaryBg)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              theme.localizedLabel(locale),
              style: TextStyle(
                color: isActive ? theme.inkDark : theme.inkMid,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Update diagnostics (hidden: long-press the version label) ──────────────────
//
// Developer/support aid, intentionally not localized. Surfaces exactly what the
// update checker sees: which channel/manifest it queries, the installed build,
// and the live outcome — so "why didn't it update?" is answerable at a glance.

class _UpdateDiagnosticsDialog extends StatefulWidget {
  final AppTheme appTheme;
  final String appVersion;
  final String buildNumber;

  const _UpdateDiagnosticsDialog({
    required this.appTheme,
    required this.appVersion,
    required this.buildNumber,
  });

  @override
  State<_UpdateDiagnosticsDialog> createState() =>
      _UpdateDiagnosticsDialogState();
}

class _UpdateDiagnosticsDialogState extends State<_UpdateDiagnosticsDialog> {
  String _result = 'Checking…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final result = await UpdateChecker.checkForUpdateDetailed();
    if (!mounted) return;
    setState(() => _result = _describe(result));
  }

  String _describe(UpdateCheckResult result) => switch (result) {
    UpdateAvailable(:final info) => 'Update available → ${info.version}',
    UpToDate() => 'Up to date',
    UpdateCheckOffline() => 'Offline / no connection',
    UpdateCheckTimeout() => 'Timed out (slow network)',
    UpdateCheckServerError(:final statusCode) =>
      'Server error (${statusCode ?? 'unreadable manifest'})',
  };

  Widget _row(String label, String value) {
    final t = widget.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: t.inkLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: t.inkDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.appTheme;
    return AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Update diagnostics',
        style: TextStyle(
          color: t.inkDark,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Channel', activeChannel.name),
          _row('Installed', '${widget.appVersion} (${widget.buildNumber})'),
          _row('Result', _result),
          const SizedBox(height: 8),
          Text(
            'Manifest',
            style: TextStyle(
              color: t.inkLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            UpdateChecker.manifestUrl,
            style: TextStyle(color: t.inkMid, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(color: t.primary)),
        ),
      ],
    );
  }
}
