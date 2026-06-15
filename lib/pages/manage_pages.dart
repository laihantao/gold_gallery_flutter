import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../widgets/jewellery_type_icon.dart';

// ── Brand management ──────────────────────────────────────────────────────────

class BrandManagePage extends StatefulWidget {
  const BrandManagePage({super.key});

  @override
  State<BrandManagePage> createState() => _BrandManagePageState();
}

class _BrandManagePageState extends State<BrandManagePage> {
  List<Brand> brands = [];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  void _loadBrands() {
    setState(() {
      brands = HiveService.getAllBrands();
    });
  }

  /// Seeded brands have isDefault=true; for installations that pre-date this
  /// field, IDs 1-8 match the init_brands.json set and are also protected.
  bool _isProtected(Brand b) => b.isDefault || b.id <= 8;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.brandsSection,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
            onPressed: () => _showBrandForm(context, appTheme, l10n),
          ),
        ],
      ),
      body: brands.isEmpty
          ? Center(
              child: Text(l10n.noBrandsFound,
                  style: TextStyle(color: appTheme.textBody)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final protected = _isProtected(brand);
                return Opacity(
                  opacity: brand.isActive ? 1.0 : 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appTheme.borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      brand.name,
                                      style: TextStyle(
                                        color: appTheme.textHeading,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (!brand.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: appTheme.borderColor
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.inactiveLabel,
                                        style: TextStyle(
                                            color: appTheme.textBody,
                                            fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              if (brand.description != null &&
                                  brand.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  brand.description!,
                                  style: TextStyle(
                                      color: appTheme.textBody, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.editButton),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(brand.isActive
                                  ? l10n.inactiveLabel
                                  : l10n.activeLabel),
                            ),
                            if (!protected)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.deleteButton,
                                    style:
                                        const TextStyle(color: Colors.red)),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showBrandForm(context, appTheme, l10n, brand);
                            } else if (value == 'toggle') {
                              HiveService.saveBrand(
                                  brand.copyWith(isActive: !brand.isActive));
                              _loadBrands();
                            } else if (value == 'delete') {
                              HiveService.deleteBrand(brand.id);
                              _loadBrands();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showBrandForm(BuildContext context, AppTheme appTheme,
      AppLocalizations l10n, [Brand? brand]) {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final descController =
        TextEditingController(text: brand?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          brand == null ? l10n.addBrand : l10n.editBrand,
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(
                  controller: nameController,
                  label: l10n.brandName,
                  appTheme: appTheme),
              const SizedBox(height: 12),
              _FormField(
                  controller: descController,
                  label: l10n.brandDesc,
                  appTheme: appTheme,
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              HiveService.saveBrand(Brand(
                id: brand?.id ?? HiveService.getNextBrandId(),
                name: nameController.text,
                description: descController.text,
                logo: brand?.logo,
                isDefault: brand?.isDefault ?? false,
                isActive: brand?.isActive ?? true,
                createdAt: brand?.createdAt ?? now,
                updatedAt: now,
              ));
              GoRouter.of(context).pop();
              _loadBrands();
            },
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}

// ── Jewellery Type management ─────────────────────────────────────────────────

class JewelleryTypeManagePage extends StatefulWidget {
  const JewelleryTypeManagePage({super.key});

  @override
  State<JewelleryTypeManagePage> createState() =>
      _JewelleryTypeManagePageState();
}

class _JewelleryTypeManagePageState extends State<JewelleryTypeManagePage> {
  List<JewelleryType> types = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  void _loadTypes() {
    setState(() {
      types = HiveService.getAllJewelleryTypes();
    });
  }

  /// Seeded types have isDefault=true; IDs 1-5 also protected for legacy installs.
  bool _isProtected(JewelleryType t) => t.isDefault || t.id <= 5;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.jewelleryTypesSection,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
            onPressed: () => _showTypeForm(context, appTheme, l10n),
          ),
        ],
      ),
      body: types.isEmpty
          ? Center(
              child: Text(l10n.noTypesFound,
                  style: TextStyle(color: appTheme.textBody)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                final protected = _isProtected(type);
                final display = type.localizedName(l10n.locale);

                // Subtitle shows the OTHER two locale names dynamically.
                final otherNames = [
                  if (l10n.locale != AppLocale.en && type.name.isNotEmpty)
                    type.name,
                  if (l10n.locale != AppLocale.zhCN &&
                      type.nameZh.isNotEmpty)
                    type.nameZh,
                  if (l10n.locale != AppLocale.ms && type.nameMs.isNotEmpty)
                    type.nameMs,
                ].join(' · ');

                return Opacity(
                  opacity: type.isActive ? 1.0 : 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.backgroundSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: appTheme.borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Type icon
                        JewelleryTypeIcon(
                          iconKey: type.iconKey,
                          size: 36,
                          tintColor: type.isActive
                              ? appTheme.accentPrimary
                              : appTheme.textBody.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      display,
                                      style: TextStyle(
                                        color: appTheme.textHeading,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (!type.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: appTheme.borderColor
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l10n.inactiveLabel,
                                        style: TextStyle(
                                            color: appTheme.textBody,
                                            fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                              if (otherNames.isNotEmpty)
                                Text(
                                  otherNames,
                                  style: TextStyle(
                                      color: appTheme.textBody, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.editButton),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(type.isActive
                                  ? l10n.inactiveLabel
                                  : l10n.activeLabel),
                            ),
                            if (!protected)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.deleteButton,
                                    style:
                                        const TextStyle(color: Colors.red)),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showTypeForm(context, appTheme, l10n, type);
                            } else if (value == 'toggle') {
                              HiveService.saveJewelleryType(
                                  type.copyWith(isActive: !type.isActive));
                              _loadTypes();
                            } else if (value == 'delete') {
                              HiveService.deleteJewelleryType(type.id);
                              _loadTypes();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showTypeForm(BuildContext context, AppTheme appTheme,
      AppLocalizations l10n, [JewelleryType? type]) {
    final enController = TextEditingController(text: type?.name ?? '');
    final zhController = TextEditingController(text: type?.nameZh ?? '');
    final msController = TextEditingController(text: type?.nameMs ?? '');
    String selectedIconKey = type?.iconKey ?? 'other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSave = enController.text.trim().isNotEmpty;

          return AlertDialog(
            title: Text(
              type == null ? l10n.addType : l10n.editType,
              style: TextStyle(color: appTheme.textHeading),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormField(
                    controller: enController,
                    label: '${l10n.typeNameEn} *',
                    appTheme: appTheme,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: zhController,
                    label: l10n.typeNameZh,
                    appTheme: appTheme,
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: msController,
                    label: l10n.typeNameMs,
                    appTheme: appTheme,
                  ),
                  const SizedBox(height: 16),
                  // ── Icon picker ───────────────────────────────
                  Text(
                    l10n.iconLabel,
                    style: TextStyle(
                        color: appTheme.textBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: JewelleryTypeIcon.validKeys.map((key) {
                      final selected = key == selectedIconKey;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedIconKey = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? appTheme.primaryLight
                                : appTheme.backgroundSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? appTheme.accentPrimary
                                  : appTheme.borderColor
                                      .withValues(alpha: 0.3),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: JewelleryTypeIcon(
                              iconKey: key,
                              size: 32,
                              tintColor: selected
                                  ? appTheme.accentPrimary
                                  : appTheme.textBody
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => GoRouter.of(context).pop(),
                child: Text(l10n.cancelButton),
              ),
              TextButton(
                onPressed: canSave
                    ? () {
                        final now = DateTime.now();
                        HiveService.saveJewelleryType(JewelleryType(
                          id: type?.id ?? HiveService.getNextJewelleryTypeId(),
                          name: enController.text.trim(),
                          nameZh: zhController.text.trim(),
                          nameMs: msController.text.trim(),
                          iconKey: selectedIconKey,
                          isDefault: type?.isDefault ?? false,
                          isActive: type?.isActive ?? true,
                          createdAt: type?.createdAt ?? now,
                          updatedAt: now,
                        ));
                        GoRouter.of(context).pop();
                        _loadTypes();
                      }
                    : null,
                child: Text(
                  l10n.saveButton,
                  style: TextStyle(
                      color: canSave ? null : appTheme.textBody),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared form field ─────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final AppTheme appTheme;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.controller,
    required this.label,
    required this.appTheme,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: appTheme.textBody),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
