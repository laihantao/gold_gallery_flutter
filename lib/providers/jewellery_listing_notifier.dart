import 'package:flutter/material.dart';

import '../models/index.dart';
import '../services/hive_service.dart';

class JewelleryListingNotifier extends ChangeNotifier {
  String? selectedBrand;
  String? selectedPurity;
  String? selectedType;
  String? selectedOwnerId;
  String _searchQuery = '';

  SortField _sortField = SortField.date;
  SortDirection _sortDirection = SortDirection.desc;

  List<Jewellery> _allItems = [];
  List<Brand> brands = [];
  List<JewelleryType> types = [];
  List<User> _availableOwners = [];

  SortField get sortField => _sortField;
  SortDirection get sortDirection => _sortDirection;
  String get searchQuery => _searchQuery;
  List<User> get availableOwners => List.unmodifiable(_availableOwners);
  bool get hasMultipleOwners => _availableOwners.length > 1;

  Map<String, String?> get selectedFilters => {
        'brand': selectedBrand,
        'purity': selectedPurity,
        'type': selectedType,
        'owner': selectedOwnerId,
      };

  String? get selectedOwnerName {
    if (selectedOwnerId == null) return null;
    final ownerId = int.tryParse(selectedOwnerId!);
    if (ownerId == null) return null;
    for (final owner in _availableOwners) {
      if (owner.id == ownerId) return owner.name;
    }
    return HiveService.getUser(ownerId)?.name;
  }

  List<FilterOption> get filterOptions => [
        FilterOption(
          value: 'brand',
          label: 'Brand',
          icon: Icons.sell_outlined,
          choices: brands.map((brand) => brand.name).toList(),
        ),
        FilterOption(
          value: 'purity',
          label: 'Purity',
          icon: Icons.diamond_outlined,
          choices: const ['916', '999'],
        ),
        FilterOption(
          value: 'type',
          label: 'Type',
          icon: Icons.category_outlined,
          choices: types.map((type) => type.name).toList(),
        ),
      ];

  List<JewelleryDisplayItem> get filteredItems {
    var result = List<Jewellery>.from(_allItems);

    if (selectedBrand != null && selectedBrand!.isNotEmpty) {
      result = result.where((item) => item.brand == selectedBrand).toList();
    }

    if (selectedPurity != null && selectedPurity!.isNotEmpty) {
      result =
          result.where((item) => item.goldPurity == selectedPurity).toList();
    }

    if (selectedType != null && selectedType!.isNotEmpty) {
      final typeId = _typeIdForName(selectedType!);
      if (typeId != null) {
        result =
            result.where((item) => item.jewelleryTypeId == typeId).toList();
      }
    }

    if (selectedOwnerId != null && selectedOwnerId!.isNotEmpty) {
      final ownerId = int.tryParse(selectedOwnerId!);
      if (ownerId != null) {
        result = result.where((item) => item.ownerId == ownerId).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((item) {
        final typeName = types
            .where((t) => t.id == item.jewelleryTypeId)
            .map((t) => t.name.toLowerCase())
            .firstOrNull ?? '';
        final ownerName = _availableOwners
            .where((u) => u.id == item.ownerId)
            .map((u) => u.name.toLowerCase())
            .firstOrNull ?? '';
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.brand.toLowerCase().contains(_searchQuery) ||
            (item.remarks?.toLowerCase().contains(_searchQuery) ?? false) ||
            (item.purchaseLocation?.toLowerCase().contains(_searchQuery) ??
                false) ||
            typeName.contains(_searchQuery) ||
            ownerName.contains(_searchQuery);
      }).toList();
    }

    result.sort((a, b) {
      final comparison = switch (_sortField) {
        SortField.date => a.date.compareTo(b.date),
        SortField.name =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return _sortDirection == SortDirection.asc ? comparison : -comparison;
    });

    return result.map(_toDisplayItem).toList();
  }

  void load({String? initialType, String? initialOwnerId}) {
    brands = HiveService.getAllBrands();
    types = HiveService.getAllJewelleryTypes();
    _availableOwners = HiveService.getAllUsers();
    _allItems = HiveService.getAllJewellery();
    if (initialType != null) selectedType = initialType;
    if (initialOwnerId != null) selectedOwnerId = initialOwnerId;
    notifyListeners();
  }

  void refresh() => load();

  void resetFilters() {
    selectedBrand = null;
    selectedPurity = null;
    selectedType = null;
    selectedOwnerId = null;
    notifyListeners();
  }

  void updateFilter(String key, String? value) {
    switch (key) {
      case 'brand':
        selectedBrand = value;
      case 'purity':
        selectedPurity = value;
      case 'type':
        selectedType = value;
      case 'owner':
        selectedOwnerId = value;
    }
    notifyListeners();
  }

  void updateOwnerFilter(String? ownerId) {
    selectedOwnerId = ownerId;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void updateSort(SortField field) {
    if (_sortField == field) {
      _sortDirection = _sortDirection == SortDirection.desc
          ? SortDirection.asc
          : SortDirection.desc;
    } else {
      _sortField = field;
      _sortDirection = SortDirection.desc;
    }
    notifyListeners();
  }

  JewelleryDisplayItem _toDisplayItem(Jewellery jewellery) {
    final ownerName = jewellery.ownerId != null
        ? HiveService.getUser(jewellery.ownerId!)?.name ?? '—'
        : '—';

    return JewelleryDisplayItem(
      jewellery: jewellery,
      currencySymbol: _currencySymbolFor(jewellery),
      ownerName: ownerName,
    );
  }

  String _currencySymbolFor(Jewellery jewellery) {
    if (jewellery.currencyId != null) {
      return HiveService.getCurrency(jewellery.currencyId!)?.symbol ?? 'RM';
    }
    return HiveService.getCurrencyByCode('MYR')?.symbol ?? 'RM';
  }

  int? _typeIdForName(String name) {
    for (final type in types) {
      if (type.name == name) return type.id;
    }
    return null;
  }
}
