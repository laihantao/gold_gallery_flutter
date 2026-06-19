import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../l10n/app_localizations.dart';
import '../models/export_settings.dart';
import '../models/user.dart';
import '../services/hive_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

class ExportPdfPage extends StatefulWidget {
  const ExportPdfPage({super.key});

  @override
  State<ExportPdfPage> createState() => _ExportPdfPageState();
}

class _ExportPdfPageState extends State<ExportPdfPage> {
  ExportFormat _format = ExportFormat.table;
  Set<ExportColumn> _columns = ExportColumn.values.toSet();
  List<User> _users = [];
  Set<int> _selectedUserIds = {};
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _groupByUser = false;
  bool _includePhotos = true;
  bool _isGeneratingPreview = false;
  bool _isGeneratingExport = false;

  bool get _isBusy => _isGeneratingPreview || _isGeneratingExport;

  @override
  void initState() {
    super.initState();
    _users = HiveService.getAllUsers()..sort((a, b) => a.id.compareTo(b.id));
    _selectedUserIds = _users.map((u) => u.id).toSet();
  }

  ExportSettings get _settings => ExportSettings(
        format: _format,
        columns: _columns,
        selectedUserIds: Set.from(_selectedUserIds),
        fromDate: _fromDate,
        toDate: _toDate,
        groupByUser: _groupByUser,
        includePhotos: _includePhotos,
      );

  String get _filename {
    final now = DateTime.now();
    return 'aurum_inventory_'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year}.pdf';
  }

  Future<Uint8List?> _generate({required bool forPreview}) async {
    if (forPreview) {
      setState(() => _isGeneratingPreview = true);
    } else {
      setState(() => _isGeneratingExport = true);
    }
    try {
      return await PdfExportService.generatePdf(_settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          if (forPreview) {
            _isGeneratingPreview = false;
          } else {
            _isGeneratingExport = false;
          }
        });
      }
    }
  }

  Future<void> _onPreview() async {
    final bytes = await _generate(forPreview: true);
    if (bytes == null || !mounted) return;
    context.push('/pdf-preview',
        extra: {'bytes': bytes, 'filename': _filename});
  }

  Future<void> _onExport() async {
    final bytes = await _generate(forPreview: false);
    if (bytes == null || !mounted) return;
    final savedPath = await PdfExportService.savePdf(bytes, _filename);
    if (!mounted) return;
    if (savedPath != null) {
      final appTheme = context.read<ThemeNotifier>().currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: appTheme.snackBarBg,
          content: Text(context.l10n.pdfSaved),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final locale = context.l10n.locale;

    return Scaffold(
      appBar: AppHeader(title: 'Export PDF'),
      backgroundColor: appTheme.primaryBg,
      body: Column(
        children: [
          // ── Format toggle ─────────────────────────────────────────────────
          Container(
            color: appTheme.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(
                  value: ExportFormat.table,
                  icon: Icon(Icons.table_rows_outlined, size: 18),
                  label: Text('Table'),
                ),
                ButtonSegment(
                  value: ExportFormat.productCard,
                  icon: Icon(Icons.view_agenda_outlined, size: 18),
                  label: Text('Product Card'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (s) =>
                  setState(() => _format = s.first),
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(
                    AppTextStyles.bodyBold(appTheme.primary,
                        locale: locale)),
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Scrollable settings ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Columns',
                    appTheme: appTheme,
                    locale: locale,
                    child: _buildColumns(appTheme),
                  ),
                  const SizedBox(height: 12),

                  if (_format == ExportFormat.productCard) ...[
                    _SectionCard(
                      title: 'Image',
                      appTheme: appTheme,
                      locale: locale,
                      child: _buildImageOption(appTheme),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _SectionCard(
                    title: 'Users',
                    appTheme: appTheme,
                    locale: locale,
                    child: _buildUsers(appTheme),
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Date Range',
                    appTheme: appTheme,
                    locale: locale,
                    child: _buildDateRange(appTheme, locale),
                  ),
                  const SizedBox(height: 12),

                  _SectionCard(
                    title: 'Grouping',
                    appTheme: appTheme,
                    locale: locale,
                    child: _buildGrouping(appTheme),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          _buildBottomBar(appTheme, locale),
        ],
      ),
    );
  }

  // ── Section: Columns ────────────────────────────────────────────────────────

  Widget _buildColumns(AurumTheme appTheme) {
    final allSelected = _columns.length == ExportColumn.values.length;
    return Column(
      children: [
        _MasterToggle(
          label: 'Select All',
          value: allSelected,
          onChanged: (v) => setState(() => _columns = v
              ? ExportColumn.values.toSet()
              : {}),
          appTheme: appTheme,
        ),
        const Divider(height: 8),
        for (final col in ExportColumn.values)
          _CheckRow(
            label: col.label,
            value: _columns.contains(col),
            onChanged: (v) => setState(() {
              v ? _columns.add(col) : _columns.remove(col);
            }),
            appTheme: appTheme,
          ),
      ],
    );
  }

  // ── Section: Image ──────────────────────────────────────────────────────────

  Widget _buildImageOption(AurumTheme appTheme) {
    return _CheckRow(
      label: 'Include product thumbnail',
      value: _includePhotos,
      onChanged: (v) => setState(() => _includePhotos = v),
      appTheme: appTheme,
    );
  }

  // ── Section: Users ──────────────────────────────────────────────────────────

  Widget _buildUsers(AurumTheme appTheme) {
    if (_users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No users found.',
            style: TextStyle(color: appTheme.inkLight, fontSize: 13)),
      );
    }
    final allSelected = _selectedUserIds.length == _users.length;
    return Column(
      children: [
        _MasterToggle(
          label: 'Select All',
          value: allSelected,
          onChanged: (v) => setState(() => _selectedUserIds = v
              ? _users.map((u) => u.id).toSet()
              : {}),
          appTheme: appTheme,
        ),
        const Divider(height: 8),
        for (final u in _users)
          _CheckRow(
            label: u.name.isNotEmpty ? u.name : 'User ${u.id}',
            value: _selectedUserIds.contains(u.id),
            onChanged: (v) => setState(() {
              v
                  ? _selectedUserIds.add(u.id)
                  : _selectedUserIds.remove(u.id);
            }),
            appTheme: appTheme,
          ),
      ],
    );
  }

  // ── Section: Date Range ─────────────────────────────────────────────────────

  Widget _buildDateRange(AurumTheme appTheme, AppLocale locale) {
    return Column(
      children: [
        _DateRow(
          label: 'From',
          date: _fromDate,
          fmtDate: _fmtDate,
          onPick: () => _pickDate(isFrom: true),
          onClear: () => setState(() => _fromDate = null),
          appTheme: appTheme,
          locale: locale,
        ),
        const SizedBox(height: 8),
        _DateRow(
          label: 'To',
          date: _toDate,
          fmtDate: _fmtDate,
          onPick: () => _pickDate(isFrom: false),
          onClear: () => setState(() => _toDate = null),
          appTheme: appTheme,
          locale: locale,
        ),
      ],
    );
  }

  // ── Section: Grouping ────────────────────────────────────────────────────────

  Widget _buildGrouping(AurumTheme appTheme) {
    return _CheckRow(
      label: 'Group by User (separate table per owner)',
      value: _groupByUser,
      onChanged: (v) => setState(() => _groupByUser = v),
      appTheme: appTheme,
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar(AurumTheme appTheme, AppLocale locale) {
    return Container(
      color: appTheme.surface,
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: _isGeneratingPreview
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: appTheme.primary),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text('Preview',
                  style: AppTextStyles.bodyBold(appTheme.primary,
                      locale: locale)),
              onPressed: _isBusy ? null : _onPreview,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: appTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: _isGeneratingExport
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_outlined, size: 18),
              label: Text('Export PDF',
                  style: AppTextStyles.bodyBold(Colors.white,
                      locale: locale)),
              onPressed: _isBusy ? null : _onExport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final AurumTheme appTheme;
  final AppLocale locale;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.appTheme,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: appTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: appTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(title,
                  style: AppTextStyles.title(appTheme.inkDark,
                      locale: locale)),
            ),
            Divider(height: 1, color: appTheme.divider),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AurumTheme appTheme;

  const _MasterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appTheme.inkDark)),
      value: value,
      tristate: false,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: appTheme.primary,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AurumTheme appTheme;

  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label,
          style: TextStyle(fontSize: 13, color: appTheme.inkMid)),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: appTheme.primary,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String Function(DateTime) fmtDate;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final AurumTheme appTheme;
  final AppLocale locale;

  const _DateRow({
    required this.label,
    required this.date,
    required this.fmtDate,
    required this.onPick,
    required this.onClear,
    required this.appTheme,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: appTheme.inkDark)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            date != null ? fmtDate(date!) : 'No filter',
            style: TextStyle(
                fontSize: 13,
                color: date != null
                    ? appTheme.inkMid
                    : appTheme.inkLight),
          ),
        ),
        if (date != null)
          IconButton(
            icon: Icon(Icons.clear, size: 18, color: appTheme.inkLight),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.calendar_today_outlined,
              size: 18, color: appTheme.primary),
          onPressed: onPick,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
