import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';

class CollectionNotifier extends ChangeNotifier {
  static const _prefKey = 'collections_v1';

  List<Collection> _collections = [];
  List<Collection> get collections => List.unmodifiable(_collections);

  CollectionNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _collections = list
          .map((e) => Collection.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      jsonEncode(_collections.map((c) => c.toJson()).toList()),
    );
  }

  /// Case-insensitive, whitespace-trimmed duplicate check. Pass [excludeId]
  /// to ignore a specific collection (e.g. the one being renamed).
  bool nameExists(String name, {String? excludeId}) {
    final target = name.trim().toLowerCase();
    return _collections.any(
      (c) => c.id != excludeId && c.name.trim().toLowerCase() == target,
    );
  }

  Future<void> createCollection(String name) async {
    final c = Collection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      jewelleryIds: [],
      createdAt: DateTime.now(),
    );
    _collections.add(c);
    await _save();
    notifyListeners();
  }

  Future<void> renameCollection(String id, String newName) async {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    _collections[idx] = _collections[idx].copyWith(name: newName.trim());
    await _save();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    _collections.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> addToCollection(String collectionId, int jewelleryId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx < 0) return;
    final ids = List<int>.from(_collections[idx].jewelleryIds);
    if (!ids.contains(jewelleryId)) {
      ids.add(jewelleryId);
      _collections[idx] = _collections[idx].copyWith(jewelleryIds: ids);
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeFromCollection(
      String collectionId, int jewelleryId) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx < 0) return;
    final ids =
        _collections[idx].jewelleryIds.where((id) => id != jewelleryId).toList();
    _collections[idx] = _collections[idx].copyWith(jewelleryIds: ids);
    await _save();
    notifyListeners();
  }

  bool isInCollection(String collectionId, int jewelleryId) {
    final c = _collections.firstWhere((c) => c.id == collectionId,
        orElse: () => Collection(
            id: '', name: '', jewelleryIds: [], createdAt: DateTime.now()));
    return c.jewelleryIds.contains(jewelleryId);
  }

  List<String> collectionsContaining(int jewelleryId) => _collections
      .where((c) => c.jewelleryIds.contains(jewelleryId))
      .map((c) => c.name)
      .toList();
}
