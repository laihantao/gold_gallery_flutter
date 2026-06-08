import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;
    setState(() {
      // Fix: HiveService methods return non-nullable lists, no need for ?? []
      brands = HiveService.getAllBrands();
      types = HiveService.getAllJewelleryTypes();
      filteredJewellery = HiveService.getAllJewellery();
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Fix: HiveService.getAllJewellery() returns non-nullable List<Jewellery>
    var result = HiveService.getAllJewellery();

    if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      result = result.where((j) => j.brand == selectedBrand).toList();
    }

    if (selectedPurity != null && selectedPurity!.isNotEmpty) {
      result = result.where((j) => j.goldPurity == selectedPurity).toList();
    }

    if (selectedTypeId != null) {
      result = result
          .where((j) => j.jewelleryTypeId == selectedTypeId)
          .toList();
    }

    if (mounted) {
      setState(() {
        filteredJewellery = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(title: 'Jewellery Listing', showBackButton: false),
      body: Column(
        children: [
          // Fix: Filter section restructured into 2 rows for stability
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Row 1: Brand and Purity filters with fixed width
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: _FilterChip(
                        label: 'Brand',
                        items: brands.map((b) => b.name).toList(),
                        selected: selectedBrand,
                        onChanged: (value) {
                          setState(() => selectedBrand = value);
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: _FilterChip(
                        label: 'Purity',
                        items: ['916', '999'],
                        selected: selectedPurity,
                        onChanged: (value) {
                          setState(() => selectedPurity = value);
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                    const Spacer(),
                    // Fix: Reset Filter button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedBrand = null;
                          selectedPurity = null;
                          selectedTypeId = null;
                        });
                        _applyFilters();
                      },
                      child: Text(
                        'Reset Filter',
                        style: TextStyle(color: appTheme.accentPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: Type filter with fixed width, left-aligned
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: _FilterChip(
                        label: 'Type',
                        items: types.map((t) => t.name).toList(),
                        selected: selectedTypeId != null
                            ? types
                                  .firstWhere(
                                    (t) => t.id == selectedTypeId,
                                    orElse: () => types.first,
                                  )
                                  .name
                            : null,
                        onChanged: (value) {
                          setState(() {
                            selectedTypeId = value != null
                                ? types
                                      .firstWhere(
                                        (t) => t.name == value,
                                        orElse: () => types.first,
                                      )
                                      .id
                                : null;
                          });
                          _applyFilters();
                        },
                        appTheme: appTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Jewellery List
          Expanded(
            child: filteredJewellery.isEmpty
                ? Center(
                    child: Text(
                      'No jewellery found',
                      style: TextStyle(color: appTheme.textBody, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredJewellery.length,
                    itemBuilder: (context, index) {
                      // Fix: ListView.builder provides itemCount indices starting from 0,
                      // so we're guaranteed safe access here. No need for bounds check.
                      final item = filteredJewellery[index];
                      
                      final currency = HiveService.getCurrency(1);
                      return _JewelleryCard(
                        jewellery: item,
                        currency: currency,
                        appTheme: appTheme,
                        onTap: () async {
                          await GoRouter.of(
                            context,
                          ).push('/details', extra: item.id);
                          // Fix: Added mounted check to prevent setState after deactivation
                          if (!mounted) return;
                          _loadData();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 1, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) async {
    if (index == 0) {
      GoRouter.of(context).go('/');
    } else if (index == 2) {
      await GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
      // Fix: Added mounted check to prevent setState after deactivation
      if (!mounted) return;
      _loadData();
    } else if (index == 3) {
      GoRouter.of(context).go('/users');
    } else if (index == 4) {
      GoRouter.of(context).go('/settings');
    }
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? selected;
  final Function(String?) onChanged;
  final AppTheme appTheme;

  const _FilterChip({
    required this.label,
    required this.items,
    this.selected,
    required this.onChanged,
    required this.appTheme,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  @override
  Widget build(BuildContext context) {
    // Fix: Changed display format to "Brand: All" / "Brand: Value"
    final displayValue = widget.selected ?? 'All';
    // Fix: Guard empty items list to prevent hit test failures
    final hasItems = widget.items.isNotEmpty;

    return PopupMenuButton<String?>(
      enabled: hasItems, // Disable if no items to prevent hit test errors
      onSelected: widget.onChanged,
      itemBuilder: (BuildContext context) {
        // Fix: Ensure menu always has at least "All" option
        return [
          // Fix: Changed first option to "All" instead of "Clear X"
          PopupMenuItem<String?>(value: null, child: const Text('All')),
          if (widget.items.isNotEmpty) const PopupMenuDivider(),
          if (widget.items.isNotEmpty)
            ...widget.items.map((item) {
              return PopupMenuItem<String?>(value: item, child: Text(item));
            }),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.appTheme.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fix: Display label format as "Brand: All" or "Brand: Value"
            Text(
              '${widget.label}: $displayValue',
              style: TextStyle(
                color: hasItems
                    ? widget.appTheme.textHeading
                    : widget.appTheme.textBody.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
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
  final VoidCallback onTap;

  const _JewelleryCard({
    required this.jewellery,
    this.currency,
    required this.appTheme,
    required this.onTap,
  });

  Widget _buildImageFromBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, color: appTheme.accentSecondary, size: 40);
        },
      );
    } catch (e) {
      return Icon(Icons.image, color: appTheme.accentSecondary, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fix: Guard against null values and provide safe defaults
    final jewelType = jewellery.jewelleryTypeId != null
        ? HiveService.getJewelleryType(jewellery.jewelleryTypeId!)?.name ??
              'N/A'
        : 'N/A';
    final dateOfPurchase = DateFormat('dd/MM/yyyy').format(jewellery.date);
    
    // Fix: Ensure totalPrice is never null in display
    final totalPrice = jewellery.totalPrice ?? 0.0;
    final priceText = totalPrice > 0
        ? '${currency?.symbol ?? 'RM'} ${totalPrice.toStringAsFixed(2)}'
        : '${currency?.symbol ?? 'RM'} 0.00';
    
    // Fix: brand and goldPurity are non-nullable strings with defaults
    // Just check if they're empty
    final brandName = jewellery.brand.isNotEmpty ? jewellery.brand : 'N/A';
    final purity = jewellery.goldPurity.isNotEmpty ? jewellery.goldPurity : '916';
    
    // Fix: Safely access jewelleryPhoto which is always initialized to non-null list by fromJson
    final photos = jewellery.jewelleryPhoto;
    final hasPhotos = photos.isNotEmpty;
    final firstPhoto = hasPhotos ? photos.first : '';

    // Fix: Use IntrinsicHeight to measure natural heights first, then stretch
    // This prevents infinite height constraint errors in ListView
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
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
          // Fix: Wrap in IntrinsicHeight to properly measure and stretch children
          // This solves the "infinite height" constraint error from ListView
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column 1: Image (fixed width SizedBox)
                SizedBox(
                  width: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: appTheme.backgroundSubtle,
                    ),
                    child: hasPhotos
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageFromBase64(firstPhoto),
                          )
                        : Icon(
                            Icons.image,
                            color: appTheme.accentSecondary,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Column 2: Name, Brand, Purity, Type, Date (stacked vertically)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        jewellery.name ?? 'Untitled',
                        style: TextStyle(
                          color: appTheme.textHeading,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      // Brand info
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Brand: ',
                              style: TextStyle(
                                color: appTheme.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: brandName,
                              style: TextStyle(
                                color: appTheme.textBody,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Purity info
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Purity: ',
                              style: TextStyle(
                                color: appTheme.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: purity,
                              style: TextStyle(
                                color: appTheme.textBody,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Type info
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Type: ',
                              style: TextStyle(
                                color: appTheme.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: jewelType,
                              style: TextStyle(
                                color: appTheme.textBody,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Date info
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Date: ',
                              style: TextStyle(
                                color: appTheme.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: dateOfPurchase,
                              style: TextStyle(
                                color: appTheme.textBody,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Column 3: Price pinned to bottom using MainAxisAlignment.end
                // Fix: Use a Column with MainAxisAlignment.end instead of Align.bottomRight
                // This works properly with IntrinsicHeight's stretched children
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        priceText,
                        style: TextStyle(
                          color: appTheme.accentPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
