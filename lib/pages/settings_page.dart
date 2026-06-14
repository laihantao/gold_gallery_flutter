import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';
import '../components/buttons.dart';
import '../services/backup_service.dart';
import '../services/gold_price_history_backfill_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/sketch_border.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isExportingPdf = false;
  bool _isSyncingHistory = false;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: AppHeader(title: 'Settings', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Theme ──────────────────────────────────────────
            _SettingSection(
              title: 'Theme',
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
              title: 'Users',
              appTheme: appTheme,
              child: PrimaryButton(
                label: 'Manage Users',
                onPressed: () => GoRouter.of(context).push('/users'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Brands ─────────────────────────────────────────
            _SettingSection(
              title: 'Brands',
              appTheme: appTheme,
              child: PrimaryButton(
                label: 'Manage Brands',
                onPressed: () => GoRouter.of(context).push('/brands'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Jewellery Types ─────────────────────────────────
            _SettingSection(
              title: 'Jewellery Types',
              appTheme: appTheme,
              child: PrimaryButton(
                label: 'Manage Types',
                onPressed: () =>
                    GoRouter.of(context).push('/jewellery-types'),
              ),
            ),
            const SizedBox(height: 24),

            // ── Price History ───────────────────────────────────
            _SettingSection(
              title: 'Price History',
              appTheme: appTheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pull missing gold price records from the cloud to fill any gaps in your history charts.',
                    style: TextStyle(
                      color: appTheme.textBody.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isSyncingHistory ? 'Syncing…' : 'Sync Price History',
                    onPressed: () => _syncHistory(context, appTheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Data ────────────────────────────────────────────
            _SettingSection(
              title: 'Data',
              appTheme: appTheme,
              child: Column(
                children: [
                  PrimaryButton(
                    label: _isExporting ? 'Exporting…' : 'Export Data',
                    onPressed: () => _exportData(context, appTheme),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isImporting ? 'Importing…' : 'Import Data',
                    onPressed: () => _importData(context, appTheme),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isExportingPdf
                        ? 'Generating PDF…'
                        : 'Export Inventory PDF',
                    onPressed: () => _exportPdf(context, appTheme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => GoRouter.of(context)
            .push('/add-product', extra: {'mode': 'add'}),
        backgroundColor: appTheme.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigation(currentIndex: 4, onTap: _onNavTap),
    );
  }

  Future<void> _syncHistory(BuildContext context, AppTheme appTheme) async {
    if (_isSyncingHistory) return;
    setState(() => _isSyncingHistory = true);
    try {
      final count = await GoldPriceHistoryBackfillService.manualSync();
      if (!mounted) return;
      _showSnackBar(
        count == 0
            ? 'Price history is already up to date'
            : 'Synced $count record${count == 1 ? '' : 's'} of price history',
        appTheme,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sync failed — check your connection', appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isSyncingHistory = false);
    }
  }

  Future<void> _exportData(BuildContext context, AppTheme appTheme) async {
    if (_isExporting || _isImporting) return;
    setState(() => _isExporting = true);
    try {
      final savePath = await BackupService.exportBackup();
      if (!mounted) return;
      _showSnackBar(
        savePath == null
            ? 'Export cancelled'
            : savePath == 'shared'
            ? 'JSON backup shared successfully'
            : 'JSON backup exported successfully',
        appTheme,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Export failed: $e', appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(BuildContext context, AppTheme appTheme) async {
    if (_isExporting || _isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await BackupService.importBackup();
      if (!mounted) return;
      if (result == null) {
        _showSnackBar('Import cancelled', appTheme);
      } else {
        _showSnackBar(
          'Imported ${result.totalImported} record${result.totalImported == 1 ? '' : 's'} successfully',
          appTheme,
          subtitle: result.breakdown.isNotEmpty ? result.breakdown : null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Import failed: $e', appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _exportPdf(BuildContext context, AppTheme appTheme) async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);
    try {
      await PdfExportService.exportInventory();
      if (!mounted) return;
      _showSnackBar('PDF generated successfully', appTheme);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('PDF export failed: $e', appTheme, isError: true);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
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
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              )
            : Text(message),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
      case 1:
        GoRouter.of(context).go('/dashboard');
      case 3:
        GoRouter.of(context).go('/listing');
    }
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title(appTheme.inkDark)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

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
                '✦ ${theme.label}',
                style: AppTextStyles.handNote(theme.inkDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
