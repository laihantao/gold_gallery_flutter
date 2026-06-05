import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/hive_service.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      appBar: AppHeader(title: 'Gold Gallery', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Gold Price',
              style: TextStyle(
                color: appTheme.textHeading,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brands.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final brand = brands[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appTheme.backgroundSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: appTheme.borderColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.name,
                        style: TextStyle(
                          color: appTheme.textHeading,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PriceItem(
                            label: '916',
                            price: '0',
                            appTheme: appTheme,
                          ),
                          _PriceItem(
                            label: '999',
                            price: '0',
                            appTheme: appTheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 1) {
      GoRouter.of(context).go('/listing');
    } else if (index == 2) {
      GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
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

class _PriceItem extends StatelessWidget {
  final String label;
  final String price;
  final AppTheme appTheme;

  const _PriceItem({
    required this.label,
    required this.price,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textBody,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RM $price',
          style: TextStyle(
            color: goldPrice,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
