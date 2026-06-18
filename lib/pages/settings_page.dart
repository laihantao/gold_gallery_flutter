import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_notifier.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../services/backup_service.dart';
import '../services/gold_price_history_backfill_service.dart';
import '../widgets/sketch_border.dart';

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

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.settingsTitle,
        showBackButton: false,
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
            _SettingSection(
              title: l10n.themeSection,
              appTheme: appTheme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThemeCircle(
                    theme: AurumTheme.parchment,
                    isActive: appTheme == AurumTheme.parchment,
                    onTap: () => context
                        .read<ThemeNotifier>()
                        .setTheme(AurumTheme.parchment),
                  ),
                  _ThemeCircle(
                    theme: AurumTheme.sky,
                    isActive: appTheme == AurumTheme.sky,
                    onTap: () =>
                        context.read<ThemeNotifier>().setTheme(AurumTheme.sky),
                  ),
                  _ThemeCircle(
                    theme: AurumTheme.blush,
                    isActive: appTheme == AurumTheme.blush,
                    onTap: () => context
                        .read<ThemeNotifier>()
                        .setTheme(AurumTheme.blush),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Users ───────────────────────────────────────────
            _SettingSection(
              title: l10n.usersSection,
              appTheme: appTheme,
              child: PrimaryButton(
                label: l10n.manageUsers,
                onPressed: () => GoRouter.of(context).push('/users'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Brands ─────────────────────────────────────────
            _SettingSection(
              title: l10n.brandsSection,
              appTheme: appTheme,
              child: PrimaryButton(
                label: l10n.manageBrands,
                onPressed: () => GoRouter.of(context).push('/brands'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Jewellery Types ─────────────────────────────────
            _SettingSection(
              title: l10n.jewelleryTypesSection,
              appTheme: appTheme,
              child: PrimaryButton(
                label: l10n.manageTypes,
                onPressed: () =>
                    GoRouter.of(context).push('/jewellery-types'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Price History ───────────────────────────────────
            _SettingSection(
              title: l10n.priceHistorySection,
              appTheme: appTheme,
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Data ────────────────────────────────────────────
            _SettingSection(
              title: l10n.dataSection,
              appTheme: appTheme,
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
      final count = await GoldPriceHistoryBackfillService.manualSync();
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

  void _showSnackBar(
    String message,
    AppTheme appTheme, {
    bool isError = false,
    String? subtitle,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? appTheme.error : appTheme.inkDark,
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

// ── Section scaffold ──────────────────────────────────────────────────────────

class _SettingSection extends StatelessWidget {
  final String title;
  final Widget child;
  final AppTheme appTheme;

  const _SettingSection({
    required this.title,
    required this.child,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Watch locale directly so the font style updates on language change.
    final locale = context.l10n.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.title(appTheme.inkDark, locale: locale)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ── Theme circle ──────────────────────────────────────────────────────────────

class _ThemeCircle extends StatelessWidget {
  final AppTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeCircle({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.locale;
    return GestureDetector(
      onTap: onTap,
      child: SketchBorder(
        radius: 18,
        strokeWidth: isActive ? 2 : 1.5,
        color: isActive ? theme.primary : theme.border,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.primaryBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primary,
                  border: Border.all(color: theme.primaryDark, width: 1.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '✦ ${theme.localizedLabel(locale)}',
                style: AppTextStyles.handNote(theme.inkDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
