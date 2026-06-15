import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/index.dart';

class HiveService {
  static const String boxJewellery = 'jewellery';
  static const String boxUser = 'user';
  static const String boxBrand = 'brand';
  static const String boxJewelleryType = 'jewellery_type';
  static const String boxCurrency = 'currency';

  static late Box<String> _jeweleryBox;
  static late Box<String> _userBox;
  static late Box<String> _brandBox;
  static late Box<String> _jewelleryTypeBox;
  static late Box<String> _currencyBox;

  static Future<void> initialize() async {
    _jeweleryBox = await Hive.openBox<String>(boxJewellery);
    _userBox = await Hive.openBox<String>(boxUser);
    _brandBox = await Hive.openBox<String>(boxBrand);
    _jewelleryTypeBox = await Hive.openBox<String>(boxJewelleryType);
    _currencyBox = await Hive.openBox<String>(boxCurrency);

    await _seedData();
  }

  static Future<void> _seedData() async {
    await _seedBrands();
    await _seedCurrency();
    await _seedJewelleryTypes();
  }

  static Future<void> _seedBrands() async {
    if (_brandBox.isEmpty) {
      final String jsonString = await rootBundle.loadString(
        'assets/data/init_brands.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final now = DateTime.now();
      for (final item in jsonList) {
        final brand = Brand(
          id: item['id'],
          name: item['name'],
          logo: item['logo'],
          description: item['description'],
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        );
        await _brandBox.put(brand.id.toString(), jsonEncode(brand.toJson()));
      }
    }
  }

  static Future<void> _seedCurrency() async {
    if (_currencyBox.isEmpty) {
      final String jsonString = await rootBundle.loadString(
        'assets/data/init_currency.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (final item in jsonList) {
        final currency = Currency.fromJson(Map<String, dynamic>.from(item));
        await _currencyBox.put(
          currency.id.toString(),
          jsonEncode(currency.toJson()),
        );
      }
    }
  }

  static Future<void> _seedJewelleryTypes() async {
    if (_jewelleryTypeBox.isEmpty) {
      final String jsonString = await rootBundle.loadString(
        'assets/data/init_jewellery_types.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final now = DateTime.now();
      for (final item in jsonList) {
        final type = JewelleryType(
          id: item['id'],
          name: item['name'] ?? '',
          nameZh: item['nameZh'] ?? '',
          nameMs: item['nameMs'] ?? '',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        );
        await _jewelleryTypeBox.put(
          type.id.toString(),
          jsonEncode(type.toJson()),
        );
      }
    }
  }

  // Jewellery methods
  static Future<void> saveJewellery(Jewellery jewellery) async {
    await _jeweleryBox.put(
      jewellery.id.toString(),
      jsonEncode(jewellery.toJson()),
    );
  }

  static Future<void> deleteJewellery(int id) async {
    await _jeweleryBox.delete(id.toString());
  }

  static Jewellery? getJewellery(int id) {
    final json = _jeweleryBox.get(id.toString());
    if (json == null) return null;
    return Jewellery.fromJson(jsonDecode(json));
  }

  static List<Jewellery> getAllJewellery() {
    final List<Jewellery> items = [];
    for (final json in _jeweleryBox.values) {
      items.add(Jewellery.fromJson(jsonDecode(json)));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static int getNextJewelleryId() {
    if (_jeweleryBox.isEmpty) return 1;
    int maxId = 0;
    for (final json in _jeweleryBox.values) {
      final jewellery = Jewellery.fromJson(jsonDecode(json));
      if (jewellery.id > maxId) maxId = jewellery.id;
    }
    return maxId + 1;
  }

  // User methods
  static Future<void> saveUser(User user) async {
    await _userBox.put(user.id.toString(), jsonEncode(user.toJson()));
  }

  static Future<void> deleteUser(int id) async {
    await _userBox.delete(id.toString());
  }

  /// Returns how many jewellery records reference [userId] as owner or payer.
  static int getLinkedJewelleryCount(int userId) {
    int count = 0;
    for (final json in _jeweleryBox.values) {
      final j = Jewellery.fromJson(jsonDecode(json));
      if (j.ownerId == userId || j.payerId == userId) count++;
    }
    return count;
  }

  static User? getUser(int id) {
    final json = _userBox.get(id.toString());
    if (json == null) return null;
    return User.fromJson(jsonDecode(json));
  }

  static List<User> getAllUsers() {
    final List<User> items = [];
    for (final json in _userBox.values) {
      items.add(User.fromJson(jsonDecode(json)));
    }
    return items;
  }

  static int getNextUserId() {
    if (_userBox.isEmpty) return 1;
    int maxId = 0;
    for (final json in _userBox.values) {
      final user = User.fromJson(jsonDecode(json));
      if (user.id > maxId) maxId = user.id;
    }
    return maxId + 1;
  }

  // Brand methods
  static Future<void> saveBrand(Brand brand) async {
    await _brandBox.put(brand.id.toString(), jsonEncode(brand.toJson()));
  }

  static Future<void> deleteBrand(int id) async {
    await _brandBox.delete(id.toString());
  }

  static Brand? getBrand(int id) {
    final json = _brandBox.get(id.toString());
    if (json == null) return null;
    return Brand.fromJson(jsonDecode(json));
  }

  static List<Brand> getAllBrands() {
    final List<Brand> items = [];
    for (final json in _brandBox.values) {
      items.add(Brand.fromJson(jsonDecode(json)));
    }
    return items;
  }

  static int getNextBrandId() {
    if (_brandBox.isEmpty) return 1;
    int maxId = 0;
    for (final json in _brandBox.values) {
      final brand = Brand.fromJson(jsonDecode(json));
      if (brand.id > maxId) maxId = brand.id;
    }
    return maxId + 1;
  }

  // JewelleryType methods
  static Future<void> saveJewelleryType(JewelleryType type) async {
    await _jewelleryTypeBox.put(type.id.toString(), jsonEncode(type.toJson()));
  }

  static Future<void> deleteJewelleryType(int id) async {
    await _jewelleryTypeBox.delete(id.toString());
  }

  static JewelleryType? getJewelleryType(int id) {
    final json = _jewelleryTypeBox.get(id.toString());
    if (json == null) return null;
    return JewelleryType.fromJson(jsonDecode(json));
  }

  static List<JewelleryType> getAllJewelleryTypes() {
    final List<JewelleryType> items = [];
    for (final json in _jewelleryTypeBox.values) {
      items.add(JewelleryType.fromJson(jsonDecode(json)));
    }
    return items;
  }

  static int getNextJewelleryTypeId() {
    if (_jewelleryTypeBox.isEmpty) return 1;
    int maxId = 0;
    for (final json in _jewelleryTypeBox.values) {
      final type = JewelleryType.fromJson(jsonDecode(json));
      if (type.id > maxId) maxId = type.id;
    }
    return maxId + 1;
  }

  // Currency methods
  static Currency? getCurrency(int id) {
    final json = _currencyBox.get(id.toString());
    if (json == null) return null;
    return Currency.fromJson(jsonDecode(json));
  }

  static List<Currency> getAllCurrencies() {
    final List<Currency> items = [];
    for (final json in _currencyBox.values) {
      items.add(Currency.fromJson(jsonDecode(json)));
    }
    return items;
  }

  static Currency? getCurrencyByCode(String code) {
    final normalized = code.toUpperCase();
    for (final json in _currencyBox.values) {
      final currency = Currency.fromJson(jsonDecode(json));
      if (currency.code.toUpperCase() == normalized) {
        return currency;
      }
    }

    if (normalized == 'MYR') {
      for (final json in _currencyBox.values) {
        final currency = Currency.fromJson(jsonDecode(json));
        if (currency.symbol == 'RM') return currency;
      }
    }

    return null;
  }

  static Map<String, List<Map<String, dynamic>>> exportRawData() {
    return {
      boxJewellery: _decodeBoxValues(_jeweleryBox),
      boxUser: _decodeBoxValues(_userBox),
      boxBrand: _decodeBoxValues(_brandBox),
      boxJewelleryType: _decodeBoxValues(_jewelleryTypeBox),
      boxCurrency: _decodeBoxValues(_currencyBox),
    };
  }

  static Future<Map<String, int>> importRawData(
    Map<String, dynamic> boxes,
  ) async {
    final importedCounts = <String, int>{};

    importedCounts[boxUser] = await _upsertBoxValues(_userBox, boxes[boxUser]);
    importedCounts[boxBrand] = await _upsertBoxValues(
      _brandBox,
      boxes[boxBrand],
    );
    importedCounts[boxJewelleryType] = await _upsertBoxValues(
      _jewelleryTypeBox,
      boxes[boxJewelleryType],
    );
    importedCounts[boxCurrency] = await _upsertBoxValues(
      _currencyBox,
      boxes[boxCurrency],
    );
    importedCounts[boxJewellery] = await _upsertBoxValues(
      _jeweleryBox,
      boxes[boxJewellery],
    );

    return importedCounts;
  }

  static List<Map<String, dynamic>> _decodeBoxValues(Box<String> box) {
    return box.values
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
  }

  static Future<int> _upsertBoxValues(Box<String> box, dynamic values) async {
    if (values is! List) return 0;

    var count = 0;
    for (final value in values) {
      if (value is! Map) continue;

      final item = Map<String, dynamic>.from(value);
      final id = item['id'];
      if (id == null) continue;

      await box.put(id.toString(), jsonEncode(item));
      count++;
    }

    return count;
  }
}
