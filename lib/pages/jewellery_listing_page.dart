import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../components/bottom_navigation.dart';
import '../models/index.dart';
import '../providers/jewellery_listing_notifier.dart';
import '../theme/theme_notifier.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/jewellery_card.dart';

class JewelleryListingPage extends StatelessWidget {
  const JewelleryListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JewelleryListingNotifier()..load(),
      child: const _JewelleryListingView(),
    );
  }
}

class _JewelleryListingView extends StatelessWidget {
  const _JewelleryListingView();

  Future<void> _openDetails(
    BuildContext context,
    JewelleryListingNotifier notifier,
    int jewelleryId,
  ) async {
    await GoRouter.of(context).push('/details', extra: jewelleryId);
    if (context.mounted) {
      notifier.refresh();
    }
  }

  Future<void> _onNavTap(BuildContext context, int index) async {
    final notifier = context.read<JewelleryListingNotifier>();

    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
      case 1:
        break;
      case 2:
        await GoRouter.of(context).push('/add-product', extra: {'mode': 'add'});
        if (context.mounted) notifier.refresh();
      case 3:
        GoRouter.of(context).go('/users');
      case 4:
        GoRouter.of(context).go('/settings');
    }
  }

  void _showSortSheet(BuildContext context, JewelleryListingNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _SortOptionTile(
                title: 'Date of Purchase',
                field: SortField.date,
                notifier: notifier,
              ),
              _SortOptionTile(
                title: 'Product Name (A–Z / Z–A)',
                field: SortField.name,
                notifier: notifier,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      appBar: const AppHeader(title: 'Jewellery Listing', showBackButton: false),
      body: Consumer<JewelleryListingNotifier>(
        builder: (context, notifier, _) {
          final filteredItems = notifier.filteredItems;
          final sortArrow =
              notifier.sortDirection == SortDirection.desc ? '↓' : '↑';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterChipBar(
                options: notifier.filterOptions,
                selectedValues: notifier.selectedFilters,
                onFilterChanged: notifier.updateFilter,
                onReset: notifier.resetFilters,
                availableOwners:
                    notifier.hasMultipleOwners ? notifier.availableOwners : null,
                selectedOwnerId: notifier.selectedOwnerId,
                selectedOwnerName: notifier.selectedOwnerName,
                onSortTap: () => _showSortSheet(context, notifier),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '${notifier.sortField.label} $sortArrow',
                  style: TextStyle(
                    fontSize: 11,
                    color: appTheme.textBody,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  '${filteredItems.length} item${filteredItems.length == 1 ? '' : 's'} found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No jewellery found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return JewelleryCard(
                            item: item,
                            onTap: () => _openDetails(
                              context,
                              notifier,
                              item.jewellery.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String title;
  final SortField field;
  final JewelleryListingNotifier notifier;

  const _SortOptionTile({
    required this.title,
    required this.field,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = notifier.sortField == field;
    Widget? trailing;

    if (isActive) {
      trailing = Icon(
        notifier.sortDirection == SortDirection.desc
            ? Icons.arrow_downward
            : Icons.arrow_upward,
      );
    }

    return ListTile(
      title: Text(title),
      trailing: trailing,
      onTap: () {
        notifier.updateSort(field);
        Navigator.pop(context);
      },
    );
  }
}
