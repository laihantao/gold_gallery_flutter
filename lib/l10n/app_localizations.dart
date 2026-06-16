import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_notifier.dart';

// ── Supported locales ─────────────────────────────────────────────────────────

enum AppLocale { en, zhCN, ms }

extension AppLocaleX on AppLocale {
  Locale toFlutterLocale() => switch (this) {
        AppLocale.en => const Locale('en'),
        AppLocale.zhCN => const Locale('zh', 'CN'),
        AppLocale.ms => const Locale('ms'),
      };

  String get displayName => switch (this) {
        AppLocale.en => 'English',
        AppLocale.zhCN => '简体中文',
        AppLocale.ms => 'Bahasa Melayu',
      };

  String get flagEmoji => switch (this) {
        AppLocale.en => '🇬🇧',
        AppLocale.zhCN => '🇨🇳',
        AppLocale.ms => '🇲🇾',
      };
}

// ── Translations ──────────────────────────────────────────────────────────────
//
// All user-visible strings live here, keyed by getter name.
// To add a new locale, extend the switch in [_t] and add getters where needed.
// To add a new string, add a getter using [_t].

class AppLocalizations {
  final AppLocale locale;
  const AppLocalizations(this.locale);

  bool get isZhCN => locale == AppLocale.zhCN;

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get navHome => _t(en: 'Home', zh: '主页', ms: 'Utama');
  String get navDashboard =>
      _t(en: 'Dashboard', zh: '仪表盘', ms: 'Papan Pemuka');
  String get navListing => _t(en: 'Listing', zh: '列表', ms: 'Senarai');
  String get navSettings => _t(en: 'Settings', zh: '设置', ms: 'Tetapan');

  // ── Home ────────────────────────────────────────────────────────────────────
  String get homeTitle =>
      _t(en: 'Gold Price Today', zh: '今日金价', ms: 'Harga Emas Hari Ini');
  String get homePriceTrendHint => _t(
        en: 'Tap a card to view its price trend',
        zh: '点击卡片查看价格走势',
        ms: 'Ketik kad untuk lihat trend',
      );
  String get refreshTooltip =>
      _t(en: 'Refresh prices', zh: '刷新价格', ms: 'Muat semula harga');

  // ── Dashboard ───────────────────────────────────────────────────────────────
  String get dashboardTitle =>
      _t(en: 'Dashboard', zh: '仪表盘', ms: 'Papan Pemuka');
  String get portfolioOverview =>
      _t(en: 'Portfolio Overview', zh: '投资组合总览', ms: 'Gambaran Portfolio');
  String get totalItems =>
      _t(en: 'Total Items', zh: '总数量', ms: 'Jumlah Item');
  String get portfolioValue =>
      _t(en: 'Portfolio Value', zh: '总价值', ms: 'Nilai Portfolio');
  String get byJewelleryType =>
      _t(en: 'By Jewellery Type', zh: '按珠宝类型', ms: 'Mengikut Jenis');
  String get byOwner =>
      _t(en: 'By Owner', zh: '按拥有者', ms: 'Mengikut Pemilik');
  String get recentlyAdded =>
      _t(en: 'Recently Added', zh: '最新添加', ms: 'Baru Ditambah');
  String get noItemsYet =>
      _t(en: 'No items added yet', zh: '暂无商品', ms: 'Tiada item lagi');
  String get untitled =>
      _t(en: 'Untitled', zh: '未命名', ms: 'Tidak Bertajuk');

  String itemCount(int n) => switch (locale) {
        AppLocale.en => '$n item${n == 1 ? '' : 's'}',
        AppLocale.zhCN => '$n 件',
        AppLocale.ms => '$n item',
      };

  // ── Listing ─────────────────────────────────────────────────────────────────
  String get listingTitle =>
      _t(en: 'Jewellery Listing', zh: '珠宝列表', ms: 'Senarai Barang Kemas');
  String get filterBrand => _t(en: 'Brand', zh: '品牌', ms: 'Jenama');
  String get filterPurity => _t(en: 'Purity', zh: '纯度', ms: 'Ketulenan');
  String get filterType => _t(en: 'Type', zh: '类型', ms: 'Jenis');
  String get filterAll => _t(en: 'All', zh: '全部', ms: 'Semua');
  String get filterReset => _t(en: 'Reset', zh: '重置', ms: 'Reset');
  String get noJewelleryFound =>
      _t(en: 'No jewellery found', zh: '未找到珠宝', ms: 'Tiada barang kemas');
  String get searchHint => _t(
        en: 'Search by name, brand, type, owner…',
        zh: '按名称、品牌、类型、拥有者搜索…',
        ms: 'Cari nama, jenama, jenis, pemilik…',
      );
  String get sortBy => _t(en: 'Sort by', zh: '排序方式', ms: 'Susun mengikut');
  String get sortByDate =>
      _t(en: 'Date of Purchase', zh: '购买日期', ms: 'Tarikh Beli');
  String get sortByName =>
      _t(en: 'Name (A–Z / Z–A)', zh: '名称 (A–Z / Z–A)', ms: 'Nama (A–Z / Z–A)');
  String get selectOwner =>
      _t(en: 'Select Owner', zh: '选择拥有者', ms: 'Pilih Pemilik');

  String itemsFound(int n) => switch (locale) {
        AppLocale.en => '$n item${n == 1 ? '' : 's'} found',
        AppLocale.zhCN => '找到 $n 件',
        AppLocale.ms => '$n item dijumpai',
      };

  // Card info labels (also used in listing cards)
  String get labelDate => _t(en: 'Date', zh: '日期', ms: 'Tarikh');
  String get labelType => _t(en: 'Type', zh: '类型', ms: 'Jenis');

  // ── Details ─────────────────────────────────────────────────────────────────
  String get detailsTitle => _t(en: 'Details', zh: '详情', ms: 'Butiran');
  String get jewelleryNotFound => _t(
        en: 'Jewellery not found',
        zh: '未找到珠宝',
        ms: 'Barang kemas tidak dijumpai',
      );
  String get editButton => _t(en: 'Edit', zh: '编辑', ms: 'Edit');
  String get deleteButton => _t(en: 'Delete', zh: '删除', ms: 'Padam');
  String get deleteTitle =>
      _t(en: 'Delete Jewellery', zh: '删除珠宝', ms: 'Padam Barang Kemas');
  String get deleteConfirm => _t(
        en: 'Are you sure you want to delete this jewellery?',
        zh: '确定要删除这件珠宝吗？',
        ms: 'Pasti nak padam barang kemas ini?',
      );
  String get cancelButton => _t(en: 'Cancel', zh: '取消', ms: 'Batal');
  String get saveButton => _t(en: 'Save', zh: '保存', ms: 'Simpan');

  // Details table row labels
  String get rowName => _t(en: 'Name', zh: '名称', ms: 'Nama');
  String get rowDateOfPurchase =>
      _t(en: 'Date of Purchase', zh: '购买日期', ms: 'Tarikh Beli');
  String get rowBrand => _t(en: 'Brand', zh: '品牌', ms: 'Jenama');
  String get rowPurity => _t(en: 'Purity', zh: '纯度', ms: 'Ketulenan');
  String get rowOwner => _t(en: 'Owner', zh: '拥有者', ms: 'Pemilik');
  String get rowPayer => _t(en: 'Payer', zh: '付款人', ms: 'Pembayar');
  String get rowJewelleryType =>
      _t(en: 'Jewellery Type', zh: '珠宝类型', ms: 'Jenis Barang');
  String get rowSize => _t(en: 'Size', zh: '尺寸', ms: 'Saiz');
  String get rowCurrency => _t(en: 'Currency', zh: '货币', ms: 'Mata Wang');
  String get rowPricePerGram =>
      _t(en: 'Price Per Gram', zh: '每克价格', ms: 'Harga/Gram');
  String get rowWeight => _t(en: 'Weight', zh: '重量', ms: 'Berat');
  String get rowLaborFees =>
      _t(en: 'Labor Fees', zh: '工费', ms: 'Upah Kerja');
  String get rowTotalPrice =>
      _t(en: 'Total Price', zh: '总价格', ms: 'Harga Jumlah');
  String get rowPurchaseLocation =>
      _t(en: 'Purchase Location', zh: '购买地点', ms: 'Lokasi Beli');
  String get rowRemarks => _t(en: 'Remarks', zh: '备注', ms: 'Catatan');

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle => _t(en: 'Settings', zh: '设置', ms: 'Tetapan');
  String get themeSection => _t(en: 'Theme', zh: '主题', ms: 'Tema');
  String get languageSection => _t(en: 'Language', zh: '语言', ms: 'Bahasa');
  String get usersSection => _t(en: 'Users', zh: '用户', ms: 'Pengguna');
  String get brandsSection => _t(en: 'Brands', zh: '品牌', ms: 'Jenama');
  String get jewelleryTypesSection =>
      _t(en: 'Jewellery Types', zh: '珠宝类型', ms: 'Jenis Kemas');
  String get priceHistorySection =>
      _t(en: 'Price History', zh: '价格历史', ms: 'Sejarah Harga');
  String get dataSection => _t(en: 'Data', zh: '数据', ms: 'Data');
  String get manageUsers =>
      _t(en: 'Manage Users', zh: '管理用户', ms: 'Urus Pengguna');
  String get manageBrands =>
      _t(en: 'Manage Brands', zh: '管理品牌', ms: 'Urus Jenama');
  String get manageTypes =>
      _t(en: 'Manage Types', zh: '管理类型', ms: 'Urus Jenis');
  String get syncHistoryDesc => _t(
        en: 'Pull missing gold price records from the cloud to fill any gaps in your history charts.',
        zh: '从云端同步缺失的金价记录，填补历史图表的空白。',
        ms: 'Tarik rekod harga emas yang hilang dari awan untuk lengkapkan carta sejarah.',
      );
  String get syncHistory =>
      _t(en: 'Sync Price History', zh: '同步价格历史', ms: 'Segerak Sejarah Harga');
  String get syncing => _t(en: 'Syncing…', zh: '同步中…', ms: 'Menyegerak…');
  String get exportData =>
      _t(en: 'Export Data', zh: '导出数据', ms: 'Eksport Data');
  String get exportShare =>
      _t(en: 'Share', zh: '分享', ms: 'Kongsi');
  String get exportSaveDevice =>
      _t(en: 'Save', zh: '保存', ms: 'Simpan');
  String get exporting =>
      _t(en: 'Exporting…', zh: '导出中…', ms: 'Mengeksport…');
  String get importData =>
      _t(en: 'Import Data', zh: '导入数据', ms: 'Import Data');
  String get importing =>
      _t(en: 'Importing…', zh: '导入中…', ms: 'Mengimport…');
  String get exportPdf =>
      _t(en: 'Export Inventory PDF', zh: '导出库存PDF', ms: 'Eksport PDF');
  String get generatingPdf =>
      _t(en: 'Generating PDF…', zh: '生成PDF中…', ms: 'Menjana PDF…');

  // Settings snackbar messages
  String get syncUpToDate => _t(
        en: 'Price history is already up to date',
        zh: '价格历史已是最新',
        ms: 'Sejarah harga sudah terkini',
      );
  String syncedCount(int n) => switch (locale) {
        AppLocale.en => 'Synced $n record${n == 1 ? '' : 's'} of price history',
        AppLocale.zhCN => '已同步 $n 条价格记录',
        AppLocale.ms => 'Disegerak $n rekod sejarah harga',
      };
  String get syncFailed => _t(
        en: 'Sync failed — check your connection',
        zh: '同步失败，请检查网络',
        ms: 'Gagal segerak — semak sambungan',
      );
  String get exportCancelled =>
      _t(en: 'Export cancelled', zh: '导出已取消', ms: 'Eksport dibatalkan');
  String get exportShared => _t(
        en: 'JSON backup shared successfully',
        zh: 'JSON备份分享成功',
        ms: 'Sandaran JSON dikongsi berjaya',
      );
  String exportSaved(String filename) => switch (locale) {
        AppLocale.en => 'Backup saved: $filename',
        AppLocale.zhCN => '备份已保存：$filename',
        AppLocale.ms => 'Sandaran disimpan: $filename',
      };
  String get exportSuccess => _t(
        en: 'JSON backup exported successfully',
        zh: 'JSON备份导出成功',
        ms: 'Sandaran JSON dieksport berjaya',
      );
  String exportFailed(Object e) => switch (locale) {
        AppLocale.en => 'Export failed: $e',
        AppLocale.zhCN => '导出失败：$e',
        AppLocale.ms => 'Eksport gagal: $e',
      };
  String get importCancelled =>
      _t(en: 'Import cancelled', zh: '导入已取消', ms: 'Import dibatalkan');
  String importSuccess(int n) => switch (locale) {
        AppLocale.en => 'Imported $n record${n == 1 ? '' : 's'} successfully',
        AppLocale.zhCN => '成功导入 $n 条记录',
        AppLocale.ms => 'Berjaya import $n rekod',
      };
  String importFailed(Object e) => switch (locale) {
        AppLocale.en => 'Import failed: $e',
        AppLocale.zhCN => '导入失败：$e',
        AppLocale.ms => 'Import gagal: $e',
      };
  String get pdfSuccess =>
      _t(en: 'PDF generated successfully', zh: 'PDF生成成功', ms: 'PDF berjaya dijana');
  String pdfFailed(Object e) => switch (locale) {
        AppLocale.en => 'PDF export failed: $e',
        AppLocale.zhCN => 'PDF导出失败：$e',
        AppLocale.ms => 'Eksport PDF gagal: $e',
      };

  // ── Theme names (proper-noun translations) ───────────────────────────────────
  String get themeNameParchment =>
      _t(en: 'Aureate', zh: '暖金', ms: 'Keemasan');
  String get themeNameSky => _t(en: 'Sky', zh: '天蓝', ms: 'Langit');
  String get themeNameBlush => _t(en: 'Blush', zh: '玫瑰', ms: 'Merona');

  // ── Product form ─────────────────────────────────────────────────────────────
  String get addProduct =>
      _t(en: 'Add Product', zh: '添加产品', ms: 'Tambah Produk');
  String get editProduct =>
      _t(en: 'Edit Product', zh: '编辑产品', ms: 'Edit Produk');
  String get selectPlaceholder =>
      _t(en: 'Select', zh: '选择', ms: 'Pilih');
  String get dateOfPurchase =>
      _t(en: 'Date of Purchase', zh: '购买日期', ms: 'Tarikh Beli');
  String get productName =>
      _t(en: 'Product Name', zh: '产品名称', ms: 'Nama Produk');
  String get measurementUnit =>
      _t(en: 'Measurement Unit', zh: '计量单位', ms: 'Unit Ukuran');
  String get photosLabel => _t(en: 'Photos', zh: '照片', ms: 'Foto');
  String get addPhotos =>
      _t(en: 'Add Photos', zh: '添加照片', ms: 'Tambah Foto');
  String get saveProduct =>
      _t(en: 'Save Product', zh: '保存产品', ms: 'Simpan Produk');

  // ── Active / inactive toggle ─────────────────────────────────────────────────
  String get activeLabel => _t(en: 'Active', zh: '启用', ms: 'Aktif');
  String get inactiveLabel =>
      _t(en: 'Inactive', zh: '停用', ms: 'Tidak Aktif');

  // ── Validation ───────────────────────────────────────────────────────────────
  String get typeNameRequired => _t(
        en: 'English name is required',
        zh: '英文名称为必填项',
        ms: 'Nama Inggeris diperlukan',
      );

  // ── User form ────────────────────────────────────────────────────────────────
  String get addUser => _t(en: 'Add User', zh: '添加用户', ms: 'Tambah Pengguna');
  String get editUser =>
      _t(en: 'Edit User', zh: '编辑用户', ms: 'Edit Pengguna');
  String get dateOfBirth =>
      _t(en: 'Date of Birth', zh: '出生日期', ms: 'Tarikh Lahir');

  // ── User deletion ────────────────────────────────────────────────────────────
  String get deleteUserTitle =>
      _t(en: 'Cannot Delete User', zh: '无法删除用户', ms: 'Tidak Boleh Padam');
  String userHasItems(int n) => switch (locale) {
        AppLocale.en =>
          'This user owns $n item${n == 1 ? '' : 's'} and cannot be deleted.',
        AppLocale.zhCN => '该用户拥有 $n 件珠宝，无法删除。',
        AppLocale.ms =>
          'Pengguna ini memiliki $n item dan tidak boleh dipadam.',
      };

  // ── Manage pages ─────────────────────────────────────────────────────────────
  String get noBrandsFound =>
      _t(en: 'No brands found', zh: '未找到品牌', ms: 'Tiada jenama');
  String get addBrand =>
      _t(en: 'Add Brand', zh: '添加品牌', ms: 'Tambah Jenama');
  String get editBrand =>
      _t(en: 'Edit Brand', zh: '编辑品牌', ms: 'Edit Jenama');
  String get brandName =>
      _t(en: 'Brand Name', zh: '品牌名称', ms: 'Nama Jenama');
  String get brandDesc =>
      _t(en: 'Description', zh: '描述', ms: 'Keterangan');
  String get noTypesFound =>
      _t(en: 'No types found', zh: '未找到类型', ms: 'Tiada jenis');
  String get iconLabel => _t(en: 'Icon', zh: '图标', ms: 'Ikon');
  String get addType =>
      _t(en: 'Add Type', zh: '添加类型', ms: 'Tambah Jenis');
  String get editType =>
      _t(en: 'Edit Type', zh: '编辑类型', ms: 'Edit Jenis');
  String get typeNameEn =>
      _t(en: 'Name (English)', zh: '名称（英文）', ms: 'Nama (Inggeris)');
  String get typeNameZh =>
      _t(en: 'Name (中文)', zh: '名称（中文）', ms: 'Nama (中文)');
  String get typeNameMs =>
      _t(en: 'Name (Melayu)', zh: '名称（马来文）', ms: 'Nama (Melayu)');

  // ── Price History ────────────────────────────────────────────────────────────
  String get historySection =>
      _t(en: 'History', zh: '历史', ms: 'Sejarah');
  String get loadingHistory =>
      _t(en: 'Loading history…', zh: '加载历史中…', ms: 'Memuatkan sejarah…');
  String get chartEmpty =>
      _t(en: 'Not enough history yet', zh: '暂无足够数据', ms: 'Data belum mencukupi');
  String get chartEmptyDesc => _t(
        en: 'Prices are recorded once a day.\nCheck back after a few refreshes.',
        zh: '每天记录一次价格。\n多刷新几次后再来看看。',
        ms: 'Harga direkod sekali sehari.\nSemak semula selepas muat semula.',
      );
  String get gold916 => _t(en: '916 Gold', zh: '916 金', ms: '916 Emas');
  String get gold999 => _t(en: '999 Gold', zh: '999 金', ms: '999 Emas');

  // ── Gold price card ──────────────────────────────────────────────────────────
  String get errTimeout =>
      _t(en: 'Request timed out', zh: '请求超时', ms: 'Permintaan tamat masa');
  String get errParse =>
      _t(en: 'Could not read price', zh: '无法读取价格', ms: 'Tidak dapat baca harga');
  String get errUnavailable =>
      _t(en: 'Site unavailable', zh: '网站不可用', ms: 'Laman tidak tersedia');
  String get errFetch =>
      _t(en: 'Fetch failed', zh: '获取失败', ms: 'Gagal dapatkan');
  String get priceStalePrefix =>
      _t(en: 'Last · ', zh: '最后 · ', ms: 'Terakhir · ');

  // ── Private helper ───────────────────────────────────────────────────────────

  String _t({required String en, required String zh, required String ms}) =>
      switch (locale) {
        AppLocale.en => en,
        AppLocale.zhCN => zh,
        AppLocale.ms => ms,
      };
}

// ── BuildContext extension ────────────────────────────────────────────────────
//
// Use [context.l10n] anywhere inside a widget build method.
// It uses watch<> so the widget rebuilds automatically on locale change.

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => watch<LocaleNotifier>().localizations;
}
