import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({super.key});

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  List<Jewellery> filteredJewellery = [];
  List<Brand> brands = [];
  List<JewelleryType> types = [];

  String? selectedBrand;
  String? selectedPurity;
  int? selectedTypeId;

  String? get _selectedTypeName {
    if (selectedTypeId == null) return null;
    for (final type in types) {
      if (type.id == selectedTypeId) return type.name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      brands = HiveService.getAllBrands();
      types = HiveService.getAllJewelleryTypes();
      filteredJewellery = HiveService.getAllJewellery();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var result = HiveService.getAllJewellery();

    if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      result = result.where((j) => j.brand == selectedBrand).toList();
    }
    if (selectedPurity != null && selectedPurity!.isNotEmpty) {
      result = result.where((j) => j.goldPurity == selectedPurity).toList();
    }
    if (selectedTypeId != null) {
      result =
          result.where((j) => j.jewelleryTypeId == selectedTypeId).toList();
    }

    if (mounted) setState(() => filteredJewellery = result);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(title: l10n.listingTitle, showBackButton: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FilterChip(
                        label: l10n.filterBrand,
                        items: brands.map((b) => b.name).toList(),
                        selected: selectedBrand,
                        allLabel: l10n.filterAll,
                        onChanged: (value) {
                          setState(() => selectedBrand = value);
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _FilterChip(
                        label: l10n.filterPurity,
                        items: const ['916', '999'],
                        selected: selectedPurity,
                        allLabel: l10n.filterAll,
                        onChanged: (value) {
                          setState(() => selectedPurity = value);
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FilterChip(
                        label: l10n.filterType,
                        items: types.map((t) => t.name).toList(),
                        selected: _selectedTypeName,
                        allLabel: l10n.filterAll,
                        onChanged: (value) {
                          setState(() {
                            selectedTypeId = null;
                            if (value != null) {
                              for (final type in types) {
                                if (type.name == value) {
                                  selectedTypeId = type.id;
                                  break;
                                }
                              }
                            }
                          });
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedBrand = null;
                          selectedPurity = null;
                          selectedTypeId = null;
                        });
                        _applyFilters();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.filterReset,
                        style: TextStyle(color: appTheme.accentPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredJewellery.isEmpty
                ? Center(
                    child: Text(
                      l10n.noJewelleryFound,
                      style:
                          TextStyle(color: appTheme.textBody, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredJewellery.length,
                    itemBuilder: (context, index) {
                      final item = filteredJewellery[index];
                      final currency = HiveService.getCurrency(1);
                      return _JewelleryCard(
                        jewellery: item,
                        currency: currency,
                        appTheme: appTheme,
                        l10n: l10n,
                        onTap: () async {
                          await GoRouter.of(context)
                              .push('/details', extra: item.id);
                          if (!mounted) return;
                          _loadData();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar:
          BottomNavigation(currentIndex: 1, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) async {
    if (index == 0) {
      GoRouter.of(context).go('/');
    } else if (index == 2) {
      await GoRouter.of(context)
          .push('/add-product', extra: {'mode': 'add'});
      if (!mounted) return;
      _loadData();
    } else if (index == 3) {
      GoRouter.of(context).go('/users');
    } else if (index == 4) {
      GoRouter.of(context).go('/settings');
    }
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? selected;
  final String allLabel;
  final Function(String?) onChanged;
  final AppTheme appTheme;

  const _FilterChip({
    required this.label,
    required this.items,
    this.selected,
    required this.allLabel,
    required this.onChanged,
    required this.appTheme,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  static const String _allValue = '__all__';

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.selected ?? widget.allLabel;
    final hasItems = widget.items.isNotEmpty;

    return PopupMenuButton<String>(
      onSelected: (value) {
        widget.onChanged(value == _allValue ? null : value);
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(value: _allValue, child: Text(widget.allLabel)),
          if (widget.items.isNotEmpty) const PopupMenuDivider(),
          if (widget.items.isNotEmpty)
            ...widget.items.map(
                (item) => PopupMenuItem<String>(value: item, child: Text(item))),
        ];
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.appTheme.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${widget.label}: $displayValue',
                style: TextStyle(
                  color: hasItems
                      ? widget.appTheme.textHeading
                      : widget.appTheme.textBody.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 16,
              color: hasItems
                  ? widget.appTheme.accentSecondary
                  : widget.appTheme.textBody.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _JewelleryCard extends StatelessWidget {
  final Jewellery jewellery;
  final Currency? currency;
  final AppTheme appTheme;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _JewelleryCard({
    required this.jewellery,
    this.currency,
    required this.appTheme,
    required this.l10n,
    required this.onTap,
  });

  Widget _buildImageFromBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.image, color: appTheme.accentSecondary, size: 28),
      );
    } catch (e) {
      return Icon(Icons.image, color: appTheme.accentSecondary, size: 28);
    }
  }

  String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: appTheme.accentPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: appTheme.textBody, fontSize: 11),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInfoStack(List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          _buildInfoRow(item.key, item.value),
          if (item != items.last) const SizedBox(height: 4),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final jewelType = jewellery.jewelleryTypeId != null
        ? _nonBlank(
            HiveService.getJewelleryType(jewellery.jewelleryTypeId!)?.name)
        : null;
    final ownerName = jewellery.ownerId != null
        ? _nonBlank(HiveService.getUser(jewellery.ownerId!)?.name)
        : null;
    final dateOfPurchase =
        DateFormat('dd/MM/yyyy').format(jewellery.date);

    final totalPrice = jewellery.totalPrice ?? 0.0;
    final priceText = totalPrice > 0
        ? '${currency?.symbol ?? 'RM'} ${totalPrice.toStringAsFixed(2)}'
        : '${currency?.symbol ?? 'RM'} 0.00';

    final productInfo = [
      if (_nonBlank(jewellery.brand) case final brand?)
        MapEntry(l10n.rowBrand, brand),
      if (jewelType case final type?) MapEntry(l10n.labelType, type),
      MapEntry(l10n.labelDate, dateOfPurchase),
    ];
    final ownerInfo = [
      if (_nonBlank(jewellery.goldPurity) case final purity?)
        MapEntry(l10n.rowPurity, purity),
      if (ownerName case final owner?) MapEntry(l10n.rowOwner, owner),
    ];

    final photos = jewellery.jewelleryPhoto;
    final hasPhotos = photos.isNotEmpty;
    final firstPhoto = hasPhotos ? photos.first : '';

    const imageSize = 100.0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: appTheme.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: imageSize,
                height: imageSize,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: appTheme.backgroundSubtle,
                  ),
                  child: hasPhotos
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageFromBase64(firstPhoto),
                        )
                      : Icon(
                          Icons.image,
                          color: appTheme.accentSecondary,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nonBlank(jewellery.name) ?? l10n.untitled,
                      style: TextStyle(
                        color: appTheme.textHeading,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.04,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInfoStack(productInfo)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInfoStack(ownerInfo)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        priceText,
                        style: TextStyle(
                          color: appTheme.accentPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
