import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';
import '../components/badges.dart';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _loadData() {
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
      result = result.where((j) => j.jewelleryTypeId == selectedTypeId).toList();
    }

    setState(() {
      filteredJewellery = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(
        title: 'Jewellery Listing',
        showBackButton: false,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedBrand = null;
                selectedPurity = null;
                selectedTypeId = null;
              });
              _applyFilters();
            },
            child: Text('All', style: TextStyle(color: appTheme.accentPrimary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Brand',
                  items: brands.map((b) => b.name).toList(),
                  selected: selectedBrand,
                  onChanged: (value) {
                    setState(() => selectedBrand = value);
                    _applyFilters();
                  },
                  appTheme: appTheme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Purity',
                  items: ['916', '999'],
                  selected: selectedPurity,
                  onChanged: (value) {
                    setState(() => selectedPurity = value);
                    _applyFilters();
                  },
                  appTheme: appTheme,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Type',
                  items: types.map((t) => t.name).toList(),
                  selected: selectedTypeId != null ? types.firstWhere((t) => t.id == selectedTypeId).name : null,
                  onChanged: (value) {
                    setState(() {
                      selectedTypeId = value != null ? types.firstWhere((t) => t.name == value).id : null;
                    });
                    _applyFilters();
                  },
                  appTheme: appTheme,
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
                      style: TextStyle(
                        color: appTheme.textBody,
                        fontSize: 16,
                      ),
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
                        onTap: () async {
                          await GoRouter.of(context).push(
                            '/details',
                            extra: item.id,
                          );
                          _loadData();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) async {
    if (index == 0) {
      GoRouter.of(context).go('/');
    } else if (index == 2) {
      await GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
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
    return PopupMenuButton<String>(
      onSelected: widget.onChanged,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: null,
            child: Text('Clear ${widget.label}'),
          ),
          const PopupMenuDivider(),
          ...widget.items.map((item) {
            return PopupMenuItem(
              value: item,
              child: Text(item),
            );
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
          children: [
            Text(
              widget.selected != null ? widget.selected! : widget.label,
              style: TextStyle(
                color: widget.appTheme.textHeading,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 16,
              color: widget.appTheme.accentSecondary,
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
    final jewelType = jewellery.jewelleryTypeId != null 
        ? HiveService.getJewelleryType(jewellery.jewelleryTypeId!)?.name ?? 'N/A' 
        : 'N/A';
    final ownerName = jewellery.ownerId != null 
        ? HiveService.getUser(jewellery.ownerId!)?.name ?? 'N/A' 
        : 'N/A';
    final dateOfPurchase = DateFormat('dd/MM/yyyy').format(jewellery.date);
    final priceText = jewellery.totalPrice != null 
        ? '${currency?.symbol ?? 'RM'} ${jewellery.totalPrice!.toStringAsFixed(2)}' 
        : '${currency?.symbol ?? 'RM'} 0.00';

    return GestureDetector(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (15-20%)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: appTheme.backgroundSubtle,
              ),
              child: jewellery.jewelleryPhoto != null && jewellery.jewelleryPhoto!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageFromBase64(jewellery.jewelleryPhoto!.first),
                    )
                  : Icon(
                      Icons.image,
                      color: appTheme.accentSecondary,
                      size: 40,
                    ),
            ),
            const SizedBox(width: 12),
            // Middle Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Product Name
                  Text(
                    jewellery.name,
                    style: TextStyle(
                      color: appTheme.textHeading,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.04,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Row 2: Brand and Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
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
                                text: jewellery.brand,
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RichText(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Row 3: Purity and Owner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
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
                                text: jewellery.goldPurity,
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Owner: ',
                                style: TextStyle(
                                  color: appTheme.accentPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ownerName,
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Row 4: Date
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Section: Total Price (10-15%)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          ],
        ),
      ),
    );
  }
}
