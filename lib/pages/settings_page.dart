import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';
import '../components/buttons.dart';
import '../services/backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
    final appTheme = _getAppTheme(context);

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
                    theme: AppTheme.gold,
                    isActive: appTheme == AppTheme.gold,
                    onTap: () {},
                  ),
                  _ThemeCircle(
                    theme: AppTheme.blush,
                    isActive: appTheme == AppTheme.blush,
                    onTap: () {},
                  ),
                  _ThemeCircle(
                    theme: AppTheme.sky,
                    isActive: appTheme == AppTheme.sky,
                    onTap: () {},
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
        backgroundColor: isError ? Colors.red : appTheme.accentPrimary,
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

AppTheme _getAppTheme(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
  if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
  if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
  return AppTheme.gold;
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
        Text(
          title,
          style: TextStyle(
            color: appTheme.textHeading,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.04,
          ),
        ),
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
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.backgroundPrimary,
          border: Border.all(
            color: isActive ? theme.accentPrimary : theme.borderColor,
            width: isActive ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme.label,
              style: TextStyle(
                color: theme.textHeading,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
