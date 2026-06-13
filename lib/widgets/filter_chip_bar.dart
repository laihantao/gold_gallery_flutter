import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_option.dart';
import '../models/user.dart';
import '../theme/theme_notifier.dart';

class FilterChipBar extends StatelessWidget {
  final List<FilterOption> options;
  final Map<String, String?> selectedValues;
  final void Function(String key, String? value) onFilterChanged;
  final VoidCallback onReset;
  final List<User>? availableOwners;
  final String? selectedOwnerId;
  final String? selectedOwnerName;
  final VoidCallback? onSortTap;

  const FilterChipBar({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onFilterChanged,
    required this.onReset,
    this.availableOwners,
    this.selectedOwnerId,
    this.selectedOwnerName,
    this.onSortTap,
  });

  bool get _showOwnerChip =>
      availableOwners != null && availableOwners!.length > 1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < options.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _ChipTouchTarget(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 72),
                child: _AurumFilterChip(
                  option: options[index],
                  selectedValue: selectedValues[options[index].value],
                  onChanged: (value) =>
                      onFilterChanged(options[index].value, value),
                ),
              ),
            ),
          ],
          if (_showOwnerChip) ...[
            const SizedBox(width: 8),
            _ChipTouchTarget(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 72),
                child: _OwnerFilterChip(
                  selectedOwnerId: selectedOwnerId,
                  selectedOwnerName: selectedOwnerName,
                  owners: availableOwners!,
                  onChanged: (value) => onFilterChanged('owner', value),
                ),
              ),
            ),
          ],
          if (onSortTap != null) ...[
            const SizedBox(width: 8),
            _ChipTouchTarget(child: _SortFilterChip(onTap: onSortTap!)),
          ],
          const SizedBox(width: 8),
          _ChipTouchTarget(child: _ResetFilterChip(onReset: onReset)),
        ],
      ),
    );
  }
}

class _ChipTouchTarget extends StatelessWidget {
  final Widget child;

  const _ChipTouchTarget({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(child: child),
    );
  }
}

class _AurumFilterChip extends StatelessWidget {
  final FilterOption option;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const _AurumFilterChip({
    required this.option,
    required this.selectedValue,
    required this.onChanged,
  });

  bool get _isActive =>
      selectedValue != null && selectedValue!.trim().isNotEmpty;

  Future<void> _showChoices(BuildContext context) async {
    if (option.choices.isEmpty) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height,
        offset.dx + box.size.width,
        offset.dy,
      ),
      items: option.choices
          .map(
            (choice) => PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            ),
          )
          .toList(),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final inactiveBackground = appTheme.backgroundSubtle;
    final label = _isActive ? '${option.label}: $selectedValue' : option.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_isActive) {
            onChanged(null);
          } else {
            _showChoices(context);
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _isActive ? appTheme.accentPrimary : inactiveBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appTheme.accentPrimary.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 16,
                color: _isActive
                    ? appTheme.backgroundPrimary
                    : appTheme.accentSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: _isActive
                      ? appTheme.backgroundPrimary
                      : appTheme.accentSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isActive ? Icons.close : Icons.expand_more,
                size: 16,
                color: _isActive
                    ? appTheme.backgroundPrimary
                    : appTheme.accentSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerFilterChip extends StatelessWidget {
  final String? selectedOwnerId;
  final String? selectedOwnerName;
  final List<User> owners;
  final ValueChanged<String?> onChanged;

  const _OwnerFilterChip({
    required this.selectedOwnerId,
    required this.selectedOwnerName,
    required this.owners,
    required this.onChanged,
  });

  bool get _isActive =>
      selectedOwnerId != null && selectedOwnerId!.trim().isNotEmpty;

  Future<void> _showOwnerSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<User>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Owner',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: owners.length,
                  itemBuilder: (context, index) {
                    final owner = owners[index];
                    return ListTile(
                      title: Text(owner.name),
                      onTap: () => Navigator.pop(context, owner),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onChanged(selected.id.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final inactiveBackground = appTheme.backgroundSubtle;
    final label = _isActive ? (selectedOwnerName ?? 'Owner') : 'Owner';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_isActive) {
            onChanged(null);
          } else {
            _showOwnerSheet(context);
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _isActive ? appTheme.accentPrimary : inactiveBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appTheme.accentPrimary.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: _isActive
                    ? appTheme.backgroundPrimary
                    : appTheme.accentSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: _isActive
                      ? appTheme.backgroundPrimary
                      : appTheme.accentSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isActive ? Icons.close : Icons.expand_more,
                size: 16,
                color: _isActive
                    ? appTheme.backgroundPrimary
                    : appTheme.accentSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortFilterChip extends StatelessWidget {
  final VoidCallback onTap;

  const _SortFilterChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final inactiveBackground = appTheme.backgroundSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: inactiveBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appTheme.accentPrimary.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 18,
                color: appTheme.accentSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetFilterChip extends StatelessWidget {
  final VoidCallback onReset;

  const _ResetFilterChip({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final inactiveBackground = appTheme.backgroundSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onReset,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: inactiveBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: appTheme.accentPrimary.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.refresh,
            size: 18,
            color: appTheme.accentSecondary,
          ),
        ),
      ),
    );
  }
}
