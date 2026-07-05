import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../providers/jewellery_listing_notifier.dart';
import '../services/collection_service.dart';
import '../services/hive_service.dart';
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
      create: (_) =>
          JewelleryListingNotifier()
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
  // null = "All Items" tab; non-null = selected collection id
  String? _selectedCollectionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_JewelleryListingView old) {
    super.didUpdateWidget(old);
    if (old.refreshNonce != widget.refreshNonce) {
      // Defer to after this frame — calling notifyListeners() synchronously
      // from didUpdateWidget (which runs mid-rebuild) trips the framework's
      // '_dirty' assertion when a listener rebuilds during the same pass.
      final notifier = context.read<JewelleryListingNotifier>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.refresh();
      });
    }
  }

  void _showManageCollectionsSheet(
    BuildContext context,
    CollectionNotifier collectionNotifier,
    AppTheme appTheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ManageCollectionsSheet(
        collectionNotifier: collectionNotifier,
        appTheme: appTheme,
      ),
    );
  }

  void _showAddToCollectionSheet(BuildContext context, int jewelleryId) {
    final collectionNotifier = context.read<CollectionNotifier>();
    final appTheme = context.read<ThemeNotifier>().currentTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddToCollectionSheet(
        jewelleryId: jewelleryId,
        collectionNotifier: collectionNotifier,
        appTheme: appTheme,
      ),
    );
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

  void _showSortSheet(
    BuildContext context,
    JewelleryListingNotifier notifier,
    AppLocalizations l10n,
  ) {
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
    final collectionNotifier = context.watch<CollectionNotifier>();
    final collections = collectionNotifier.collections;

    return Scaffold(
      appBar: AppHeader(title: l10n.listingTitle, showBackButton: false),
      body: Consumer<JewelleryListingNotifier>(
        builder: (context, notifier, _) {
          // Compute filtered items (optionally limited to a collection)
          final allFiltered = notifier.filteredItems;
          final filteredItems = _selectedCollectionId == null
              ? allFiltered
              : () {
                  final col = collections.firstWhere(
                    (c) => c.id == _selectedCollectionId,
                    orElse: () => Collection(
                      id: '',
                      name: '',
                      jewelleryIds: [],
                      createdAt: DateTime.now(),
                    ),
                  );
                  return allFiltered
                      .where((i) => col.jewelleryIds.contains(i.jewellery.id))
                      .toList();
                }();
          final sortArrow = notifier.sortDirection == SortDirection.desc
              ? '↓'
              : '↑';
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

              // ── Collections segmented toggle ─────────────────
              _CollectionToggle(
                collections: collections,
                selectedId: _selectedCollectionId,
                appTheme: appTheme,
                onSelect: (id) => setState(() => _selectedCollectionId = id),
                onManage: () => _showManageCollectionsSheet(
                  context,
                  collectionNotifier,
                  appTheme,
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
                availableOwners: notifier.hasMultipleOwners
                    ? notifier.availableOwners
                    : null,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: appTheme.inkLight),
                ),
              ),

              // ── List ────────────────────────────────────────
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 48,
                              color: appTheme.inkLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noJewelleryFound,
                              style: Theme.of(context).textTheme.bodyLarge
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
                            onLongPress: () => _showAddToCollectionSheet(
                              context,
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

String _sortFieldLabel(SortField field, AppLocalizations l10n) =>
    switch (field) {
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
        prefixIcon: Icon(
          Icons.search_outlined,
          color: appTheme.inkLight,
          size: 20,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(
                Icons.clear_outlined,
                color: appTheme.inkLight,
                size: 18,
              ),
            );
          },
        ),
        filled: true,
        fillColor: appTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
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

// ── Collection segmented toggle ───────────────────────────────────────────────

class _CollectionToggle extends StatelessWidget {
  final List<Collection> collections;
  final String? selectedId;
  final AppTheme appTheme;
  final ValueChanged<String?> onSelect;
  final VoidCallback onManage;

  const _CollectionToggle({
    required this.collections,
    required this.selectedId,
    required this.appTheme,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _CollectionChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isActive: selectedId == null,
            appTheme: appTheme,
            onTap: () => onSelect(null),
          ),
          ...collections.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CollectionChip(
                label: c.name,
                icon: Icons.folder_outlined,
                isActive: selectedId == c.id,
                appTheme: appTheme,
                onTap: () => onSelect(c.id),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onManage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: appTheme.border.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: appTheme.primaryDark,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Manage',
                    style: TextStyle(
                      color: appTheme.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _CollectionChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? appTheme.primary : appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? appTheme.primaryDark : appTheme.border,
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? Colors.white : appTheme.inkMid,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : appTheme.inkDark,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add to collection sheet ───────────────────────────────────────────────────

class _AddToCollectionSheet extends StatelessWidget {
  final int jewelleryId;
  final CollectionNotifier collectionNotifier;
  final AppTheme appTheme;

  const _AddToCollectionSheet({
    required this.jewelleryId,
    required this.collectionNotifier,
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    final j = HiveService.getJewellery(jewelleryId);
    final collections = collectionNotifier.collections;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: appTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: appTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add "${j?.name ?? 'Item'}" to Collection',
                    style: TextStyle(
                      color: appTheme.inkDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: appTheme.border),
          if (collections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No collections yet. Tap "Manage" in the listing to create one.',
                style: TextStyle(color: appTheme.inkLight, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...collections.map((c) {
              final isIn = collectionNotifier.isInCollection(c.id, jewelleryId);
              return ListTile(
                leading: Icon(
                  isIn ? Icons.folder_rounded : Icons.folder_outlined,
                  color: isIn ? appTheme.primary : appTheme.inkMid,
                ),
                title: Text(
                  c.name,
                  style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                ),
                subtitle: Text(
                  '${c.jewelleryIds.length} items',
                  style: TextStyle(color: appTheme.inkLight, fontSize: 11),
                ),
                trailing: isIn
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: appTheme.primary,
                        size: 20,
                      )
                    : null,
                onTap: () async {
                  if (isIn) {
                    await collectionNotifier.removeFromCollection(
                      c.id,
                      jewelleryId,
                    );
                  } else {
                    await collectionNotifier.addToCollection(c.id, jewelleryId);
                  }
                  if (!context.mounted) return;
                  // Capture messenger before popping so we can show the
                  // snackbar after.
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: appTheme.snackBarBg,
                      content: Text(
                        isIn
                            ? 'Removed from "${c.name}"'
                            : 'Added to "${c.name}"',
                      ),
                    ),
                  );
                },
              );
            }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Manage collections sheet ──────────────────────────────────────────────────

class _ManageCollectionsSheet extends StatefulWidget {
  final CollectionNotifier collectionNotifier;
  final AppTheme appTheme;

  const _ManageCollectionsSheet({
    required this.collectionNotifier,
    required this.appTheme,
  });

  @override
  State<_ManageCollectionsSheet> createState() =>
      _ManageCollectionsSheetState();
}

class _ManageCollectionsSheetState extends State<_ManageCollectionsSheet> {
  final _ctrl = TextEditingController();
  AppTheme get appTheme => widget.appTheme;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await widget.collectionNotifier.createCollection(name);
    _ctrl.clear();
    if (!mounted) return;
    setState(() {}); // refresh the in-sheet collections list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: appTheme.snackBarBg,
        content: Text('Collection "$name" created'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collections = widget.collectionNotifier.collections;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_special_outlined,
                    color: appTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Collections',
                    style: TextStyle(
                      color: appTheme.inkDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: appTheme.border),

            // New collection input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'New collection name…',
                        hintStyle: TextStyle(
                          color: appTheme.inkLight,
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: appTheme.primaryBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: appTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: appTheme.border,
                            width: 0.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: appTheme.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _create,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (collections.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (_, i) {
                    final c = collections[i];
                    return ListTile(
                      leading: Icon(
                        Icons.folder_rounded,
                        color: appTheme.primary,
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(color: appTheme.inkDark, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${c.jewelleryIds.length} items',
                        style: TextStyle(
                          color: appTheme.inkLight,
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: appTheme.error,
                          size: 18,
                        ),
                        onPressed: () async {
                          await widget.collectionNotifier.deleteCollection(
                            c.id,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No collections yet. Create one above.',
                  style: TextStyle(
                    color: appTheme.inkLight,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
