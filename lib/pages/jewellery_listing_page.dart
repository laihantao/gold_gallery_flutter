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
import '../widgets/money_text.dart';

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
  // Collapsible collection + filter section. Defaults to collapsed; not
  // persisted across app launches (intentionally view-local state).
  bool _filtersExpanded = false;

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

  /// Lightweight "group these now" flow — a single-field dialog to create a
  /// collection inline. Full management (rename/delete) lives in Settings.
  Future<void> _showCreateCollectionDialog(
    BuildContext context,
    CollectionNotifier collectionNotifier,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.newCollectionTitle,
          style: TextStyle(
            color: appTheme.inkDark,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          style: TextStyle(color: appTheme.inkDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.newCollectionHint,
            hintStyle: TextStyle(color: appTheme.inkLight, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: appTheme.inkLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.createLabel),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;
    if (collectionNotifier.nameExists(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: appTheme.error,
          content: Text(l10n.collectionNameExists),
        ),
      );
      return;
    }
    await collectionNotifier.createCollection(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: appTheme.snackBarBg,
        content: Text(l10n.collectionCreated(name)),
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
      appBar: AppHeader(
        title: l10n.listingTitle,
        showBackButton: false,
        actions: [PrivacyToggleButton(color: appTheme.inkDark)],
      ),
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

          // Active narrowing = collection selection + filter values. Used for
          // the collapsed-state badge (count) and summary strip (values).
          final selectedCollectionName = _selectedCollectionId == null
              ? null
              : collections
                    .where((c) => c.id == _selectedCollectionId)
                    .map((c) => c.name)
                    .firstOrNull;
          final activeValues = <String>[
            if (selectedCollectionName != null &&
                selectedCollectionName.isNotEmpty)
              selectedCollectionName,
            if ((notifier.selectedBrand ?? '').isNotEmpty)
              notifier.selectedBrand!,
            if ((notifier.selectedPurity ?? '').isNotEmpty)
              notifier.selectedPurity!,
            if ((notifier.selectedType ?? '').isNotEmpty)
              notifier.selectedType!,
            if ((notifier.selectedOwnerName ?? '').isNotEmpty)
              notifier.selectedOwnerName!,
          ];
          final activeCount = activeValues.length;
          final showStrip = !_filtersExpanded && activeCount > 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar + collapse toggle ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchBar(
                        controller: _searchController,
                        appTheme: appTheme,
                        hintText: l10n.searchHint,
                        onChanged: notifier.updateSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterToggleButton(
                      expanded: _filtersExpanded,
                      badgeCount: activeCount,
                      appTheme: appTheme,
                      tooltip: l10n.filtersLabel,
                      onTap: () => setState(
                        () => _filtersExpanded = !_filtersExpanded,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active-filter summary strip (collapsed only) ─
              if (showStrip)
                _ActiveFilterStrip(
                  values: activeValues,
                  appTheme: appTheme,
                  clearLabel: l10n.clearLabel,
                  onExpand: () => setState(() => _filtersExpanded = true),
                  onClear: () {
                    notifier.resetFilters();
                    setState(() => _selectedCollectionId = null);
                  },
                ),

              // ── Collapsible: collection toggle + filter chips ─
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _filtersExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CollectionToggle(
                            collections: collections,
                            selectedId: _selectedCollectionId,
                            allLabel: l10n.filterAll,
                            appTheme: appTheme,
                            onSelect: (id) =>
                                setState(() => _selectedCollectionId = id),
                            onCreate: () => _showCreateCollectionDialog(
                              context,
                              collectionNotifier,
                              appTheme,
                              l10n,
                            ),
                          ),
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
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),

              // ── Item count + sort control (always visible) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.itemsFound(filteredItems.length),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: appTheme.inkLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _SortControl(
                      label: '$sortLabel $sortArrow',
                      appTheme: appTheme,
                      onTap: () => _showSortSheet(context, notifier, l10n),
                    ),
                  ],
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

// ── Sort control (item-count row, right side) ─────────────────────────────────

class _SortControl extends StatelessWidget {
  final String label;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _SortControl({
    required this.label,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 16, color: appTheme.accentSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: appTheme.accentSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Collapse toggle button (right of search bar) ──────────────────────────────

class _FilterToggleButton extends StatelessWidget {
  final bool expanded;
  final int badgeCount;
  final AppTheme appTheme;
  final String tooltip;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.expanded,
    required this.badgeCount,
    required this.appTheme,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: appTheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appTheme.border, width: 1),
                ),
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.expand_more,
                    color: appTheme.inkMid,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: appTheme.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: appTheme.surface, width: 1.5),
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Active-filter summary strip (shown only when collapsed) ────────────────────

class _ActiveFilterStrip extends StatelessWidget {
  final List<String> values;
  final AppTheme appTheme;
  final String clearLabel;
  final VoidCallback onExpand;
  final VoidCallback onClear;

  const _ActiveFilterStrip({
    required this.values,
    required this.appTheme,
    required this.clearLabel,
    required this.onExpand,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            // Tapping the strip body re-expands the filter section.
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 15,
                        color: appTheme.accentSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          values.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: appTheme.textHeading,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      clearLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: appTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.close,
                      size: 14,
                      color: appTheme.accentPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  final String allLabel;
  final AppTheme appTheme;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCreate;

  const _CollectionToggle({
    required this.collections,
    required this.selectedId,
    required this.allLabel,
    required this.appTheme,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _CollectionChip(
            label: allLabel,
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
          // Lightweight "+" chip — quick create-collection (group items now).
          GestureDetector(
            onTap: onCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: appTheme.border.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: appTheme.primaryDark,
                size: 16,
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
