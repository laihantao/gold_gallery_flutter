import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';

class BrandManagePage extends StatefulWidget {
  const BrandManagePage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(
        title: 'Brands',
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
            onPressed: () {
              _showBrandForm(context, appTheme);
            },
          ),
        ],
      ),
      body: brands.isEmpty
          ? Center(
              child: Text(
                'No brands found',
                style: TextStyle(color: appTheme.textBody),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return Container(
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
                            Text(
                              brand.name,
                              style: TextStyle(
                                color: appTheme.textHeading,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (brand.description != null && brand.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                brand.description!,
                                style: TextStyle(
                                  color: appTheme.textBody,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Edit'),
                            onTap: () {
                              _showBrandForm(context, appTheme, brand);
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () {
                              HiveService.deleteBrand(brand.id);
                              _loadBrands();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showBrandForm(BuildContext context, AppTheme appTheme, [Brand? brand]) {
    final nameController = TextEditingController(text: brand?.name ?? '');
    final descController = TextEditingController(text: brand?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          brand == null ? 'Add Brand' : 'Edit Brand',
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Brand Name',
                  labelStyle: TextStyle(color: appTheme.textBody),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: appTheme.textBody),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              final newBrand = Brand(
                id: brand?.id ?? HiveService.getNextBrandId(),
                name: nameController.text,
                description: descController.text,
                logo: brand?.logo,
                createdAt: brand?.createdAt ?? now,
                updatedAt: now,
              );
              HiveService.saveBrand(newBrand);
              GoRouter.of(context).pop();
              _loadBrands();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}

// Jewellery Type Manage Page
class JewelleryTypeManagePage extends StatefulWidget {
  const JewelleryTypeManagePage({Key? key}) : super(key: key);

  @override
  State<JewelleryTypeManagePage> createState() => _JewelleryTypeManagePageState();
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

  @override
  Widget build(BuildContext context) {
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(
        title: 'Jewellery Types',
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appTheme.textHeading),
            onPressed: () {
              _showTypeForm(context, appTheme);
            },
          ),
        ],
      ),
      body: types.isEmpty
          ? Center(
              child: Text(
                'No types found',
                style: TextStyle(color: appTheme.textBody),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                return Container(
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
                        child: Text(
                          type.name,
                          style: TextStyle(
                            color: appTheme.textHeading,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Edit'),
                            onTap: () {
                              _showTypeForm(context, appTheme, type);
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('Delete'),
                            onTap: () {
                              HiveService.deleteJewelleryType(type.id);
                              _loadTypes();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showTypeForm(BuildContext context, AppTheme appTheme, [JewelleryType? type]) {
    final nameController = TextEditingController(text: type?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == null ? 'Add Type' : 'Edit Type',
          style: TextStyle(color: appTheme.textHeading),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Type Name',
            labelStyle: TextStyle(color: appTheme.textBody),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => GoRouter.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              final newType = JewelleryType(
                id: type?.id ?? HiveService.getNextJewelleryTypeId(),
                name: nameController.text,
                createdAt: type?.createdAt ?? now,
                updatedAt: now,
              );
              HiveService.saveJewelleryType(newType);
              GoRouter.of(context).pop();
              _loadTypes();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }
}
