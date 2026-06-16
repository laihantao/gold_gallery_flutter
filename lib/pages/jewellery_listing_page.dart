import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/jewellery_listing_notifier.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/jewellery_card.dart';

class JewelleryListingPage extends StatelessWidget {
  /// Pre-applied type filter name (English) — passed from Dashboard.
  final String? initialType;

  /// Pre-applied owner id (as string) — passed from Dashboard.
  final String? initialOwnerId;

  /// Incremented by MainShellPage after an add-product push returns so the
  /// view can refresh the list without a full widget recreation.
  final int refreshNonce;

  const JewelleryListingPage({
    super.key,
    this.initialType,
    this.initialOwnerId,
    this.refreshNonce = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JewelleryListingNotifier()
        ..load(initialType: initialType, initialOwnerId: initialOwnerId),
      child: _JewelleryListingView(refreshNonce: refreshNonce),
    );
  }
}

class _JewelleryListingView extends StatefulWidget {
  final int refreshNonce;

  const _JewelleryListingView({this.refreshNonce = 0});

  @override
  State<_JewelleryListingView> createState() => _JewelleryListingViewState();
}

class _JewelleryListingViewState extends State<_JewelleryListingView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_JewelleryListingView old) {
    super.didUpdateWidget(old);
    if (old.refreshNonce != widget.refreshNonce) {
      context.read<JewelleryListingNotifier>().refresh();
    }
  }

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

  void _showSortSheet(BuildContext context, JewelleryListingNotifier notifier,
      AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.sortBy,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _SortOptionTile(
                title: l10n.sortByDate,
                field: SortField.date,
                notifier: notifier,
              ),
              _SortOptionTile(
                title: l10n.sortByName,
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
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(title: l10n.listingTitle, showBackButton: false),
      body: Consumer<JewelleryListingNotifier>(
        builder: (context, notifier, _) {
          final filteredItems = notifier.filteredItems;
          final sortArrow =
              notifier.sortDirection == SortDirection.desc ? '↓' : '↑';
          final sortLabel = _sortFieldLabel(notifier.sortField, l10n);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SearchBar(
                  controller: _searchController,
                  appTheme: appTheme,
                  hintText: l10n.searchHint,
                  onChanged: notifier.updateSearch,
                ),
              ),

              // ── Filter chips ────────────────────────────────
              FilterChipBar(
                options: notifier.filterOptionsFor(l10n),
                selectedValues: notifier.selectedFilters,
                onFilterChanged: notifier.updateFilter,
                onReset: () {
                  notifier.resetFilters();
                  _searchController.clear();
                  notifier.updateSearch('');
                },
                availableOwners:
                    notifier.hasMultipleOwners ? notifier.availableOwners : null,
                selectedOwnerId: notifier.selectedOwnerId,
                selectedOwnerName: notifier.selectedOwnerName,
                onSortTap: () => _showSortSheet(context, notifier, l10n),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '$sortLabel $sortArrow',
                  style: TextStyle(fontSize: 11, color: appTheme.textBody),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.itemsFound(filteredItems.length),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: appTheme.inkLight),
                ),
              ),

              // ── List ────────────────────────────────────────
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_outlined,
                                size: 48, color: appTheme.inkLight),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noJewelleryFound,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: appTheme.inkLight),
                            ),
                          ],
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
    );
  }
}

String _sortFieldLabel(SortField field, AppLocalizations l10n) => switch (field) {
      SortField.date => l10n.labelDate,
      SortField.name => l10n.rowName,
    };

// ── Search bar widget ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AppTheme appTheme;
  final String hintText;
  final void Function(String) onChanged;

  const _SearchBar({
    required this.controller,
    required this.appTheme,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: appTheme.inkDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: appTheme.inkLight, fontSize: 13),
        prefixIcon:
            Icon(Icons.search_outlined, color: appTheme.inkLight, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.clear_outlined,
                  color: appTheme.inkLight, size: 18),
            );
          },
        ),
        filled: true,
        fillColor: appTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Sort tile ─────────────────────────────────────────────────────────────────

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
