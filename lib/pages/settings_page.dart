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
import '../widgets/sketch_border.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
  }

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
            // Theme Selector
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
            // Brands
            _SettingSection(
              title: 'Brands',
              appTheme: appTheme,
              child: PrimaryButton(
                label: 'Manage Brands',
                onPressed: () {
                  GoRouter.of(context).push('/brands');
                },
              ),
            ),
            const SizedBox(height: 24),
            // Jewellery Types
            _SettingSection(
              title: 'Jewellery Types',
              appTheme: appTheme,
              child: PrimaryButton(
                label: 'Manage Types',
                onPressed: () {
                  GoRouter.of(context).push('/jewellery-types');
                },
              ),
            ),
            const SizedBox(height: 24),
            // Export/Import
            _SettingSection(
              title: 'Data',
              appTheme: appTheme,
              child: Column(
                children: [
                  PrimaryButton(
                    label: _isExporting ? 'Exporting...' : 'Export Data',
                    onPressed: () {
                      _exportData(context, appTheme);
                    },
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: _isImporting ? 'Importing...' : 'Import Data',
                    onPressed: () {
                      _importData(context, appTheme);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 4, onTap: _onNavTap),
    );
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
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData(BuildContext context, AppTheme appTheme) async {
    if (_isExporting || _isImporting) return;

    setState(() => _isImporting = true);
    try {
      final result = await BackupService.importBackup();
      if (!mounted) return;

      _showSnackBar(
        result == null
            ? 'Import cancelled'
            : 'Imported ${result.totalImported} records successfully',
        appTheme,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Import failed: $e', appTheme, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showSnackBar(
    String message,
    AppTheme appTheme, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? appTheme.error : appTheme.inkDark,
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      GoRouter.of(context).go('/');
    } else if (index == 1) {
      GoRouter.of(context).go('/listing');
    } else if (index == 2) {
      GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
    } else if (index == 3) {
      GoRouter.of(context).go('/users');
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
              // Colored circle swatch (44dp)
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
