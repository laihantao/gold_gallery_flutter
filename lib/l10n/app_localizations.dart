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
  String get navDashboard => _t(en: 'Dashboard', zh: '仪表盘', ms: 'Papan Pemuka');
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
  String get totalItems => _t(en: 'Total Items', zh: '总数量', ms: 'Jumlah Item');
  String get portfolioValue =>
      _t(en: 'Portfolio Value', zh: '总价值', ms: 'Nilai Portfolio');
  String get byJewelleryType =>
      _t(en: 'By Jewellery Type', zh: '按珠宝类型', ms: 'Mengikut Jenis');
  String get byOwner => _t(en: 'By Owner', zh: '按拥有者', ms: 'Mengikut Pemilik');
  String get recentlyAdded =>
      _t(en: 'Recently Added', zh: '最新添加', ms: 'Baru Ditambah');
  String get noItemsYet =>
      _t(en: 'No items added yet', zh: '暂无商品', ms: 'Tiada item lagi');
  String get untitled => _t(en: 'Untitled', zh: '未命名', ms: 'Tidak Bertajuk');
  String get sectionMarketValue =>
      _t(en: 'Market Value', zh: '市场价值', ms: 'Nilai Pasaran');
  String get viewPortfolioTrend => _t(
    en: 'View Portfolio Trend',
    zh: '查看投资组合走势',
    ms: 'Lihat Trend Portfolio',
  );

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

  // Collapsible filter section
  String get filtersLabel => _t(en: 'Filters', zh: '筛选', ms: 'Penapis');
  String get clearLabel => _t(en: 'Clear', zh: '清除', ms: 'Kosongkan');

  // Value privacy toggle (eye)
  String get hideValues => _t(en: 'Hide values', zh: '隐藏金额', ms: 'Sembunyi nilai');
  String get showValues => _t(en: 'Show values', zh: '显示金额', ms: 'Tunjuk nilai');

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
  String get rowLaborFees => _t(en: 'Labor Fees', zh: '工费', ms: 'Upah Kerja');
  String get rowTotalPrice =>
      _t(en: 'Total Price', zh: '总价格', ms: 'Harga Jumlah');
  String get rowPurchaseLocation =>
      _t(en: 'Purchase Location', zh: '购买地点', ms: 'Lokasi Beli');
  String get rowRemarks => _t(en: 'Remarks', zh: '备注', ms: 'Catatan');

  // Details — section labels
  String get sectionPurchase => _t(en: 'Purchase', zh: '购买信息', ms: 'Pembelian');

  // Details — purity chip / row suffix, e.g. "999 Gold"
  String purityGoldLabel(String purity) => switch (locale) {
    AppLocale.en => '$purity Gold',
    AppLocale.zhCN => '$purity 金',
    AppLocale.ms => '$purity Emas',
  };

  // Details — purchase card "More/Less details" toggle
  String get moreDetailsLabel =>
      _t(en: 'More details', zh: '更多详情', ms: 'Butiran lanjut');
  String get lessDetailsLabel =>
      _t(en: 'Less details', zh: '收起详情', ms: 'Kurang butiran');

  // Details — notes card
  String get notesLabel => _t(en: 'Notes', zh: '备注', ms: 'Nota');

  // Details — market value hero
  String get currentMarketValueLabel =>
      _t(en: 'Current market value', zh: '当前市场价值', ms: 'Nilai pasaran semasa');
  String get addWeightHint => _t(
    en: 'Add weight to this item',
    zh: '请为此商品添加重量',
    ms: 'Tambah berat untuk item ini',
  );
  String get fetchPricesHint => _t(
    en: 'Fetch prices on the Home tab',
    zh: '请在主页获取价格',
    ms: 'Dapatkan harga di tab Utama',
  );
  String noLiveFeedFor(String brand) => switch (locale) {
    AppLocale.en => '$brand has no live feed',
    AppLocale.zhCN => '$brand 无实时报价',
    AppLocale.ms => '$brand tiada harga langsung',
  };
  String vsPaidLabel(String amount) => switch (locale) {
    AppLocale.en => 'vs $amount paid',
    AppLocale.zhCN => '对比已付 $amount',
    AppLocale.ms => 'vs $amount dibayar',
  };

  // Details — market breakdown card
  String get marketBreakdownLabel =>
      _t(en: 'Market breakdown', zh: '市场明细', ms: 'Pecahan Pasaran');
  String noLivePriceFeedFor(String brand) => switch (locale) {
    AppLocale.en => '$brand has no live price feed.',
    AppLocale.zhCN => '$brand 暂无实时价格来源。',
    AppLocale.ms => '$brand tiada sumber harga langsung.',
  };
  String enterTodayPriceHint(String purity, String symbol) => switch (locale) {
    AppLocale.en => "Enter today's $purity gold price ($symbol/g):",
    AppLocale.zhCN => '请输入今日 $purity 金价（$symbol/克）：',
    AppLocale.ms => 'Masukkan harga emas $purity hari ini ($symbol/g):',
  };
  String get applyLabel => _t(en: 'Apply', zh: '应用', ms: 'Guna');
  String get estimationOnlyHint => _t(
    en: 'This price is for estimation only and is not saved.',
    zh: '此价格仅供估算，不会被保存。',
    ms: 'Harga ini hanya untuk anggaran dan tidak disimpan.',
  );
  String get colPerGram => _t(en: 'Per Gram', zh: '每克', ms: 'Se Gram');
  String get colTotal => _t(en: 'Total', zh: '总计', ms: 'Jumlah');
  String get mvPurchasedLabel => _t(en: 'Purchased', zh: '购入价', ms: 'Dibeli');
  String get mvCurrentLabel => _t(en: 'Current', zh: '当前', ms: 'Semasa');
  String get changeLabel => _t(en: 'Change', zh: '变动', ms: 'Perubahan');
  String get estBuybackLabel =>
      _t(en: 'Est. Buyback', zh: '预估回收价', ms: 'Anggaran Beli Balik');
  String get buybackHint => _t(
    en: 'Excl. labor fees · Drag to adjust deduction rate',
    zh: '不含工费 · 拖动调整扣除比例',
    ms: 'Tidak termasuk upah · Seret untuk laras kadar potongan',
  );

  // Details — collections section
  String get collectionsLabel =>
      _t(en: 'Collections', zh: '收藏夹', ms: 'Koleksi');
  String get addLabel => _t(en: 'Add', zh: '添加', ms: 'Tambah');
  String get notInAnyCollectionHint => _t(
    en: 'Not in any collection yet.',
    zh: '尚未加入任何收藏夹。',
    ms: 'Belum dalam mana-mana koleksi.',
  );
  String get addToCollectionTitle =>
      _t(en: 'Add to Collection', zh: '添加到收藏夹', ms: 'Tambah ke Koleksi');
  String get noCollectionsListingHint => _t(
    en: 'No collections yet. Create one from the Listing tab.',
    zh: '暂无收藏夹，请在列表页创建。',
    ms: 'Tiada koleksi lagi. Cipta satu dari tab Senarai.',
  );

  // Manage collections (sheet + settings entry + quick create)
  String get manageCollections =>
      _t(en: 'Manage Collections', zh: '管理收藏夹', ms: 'Urus Koleksi');
  String get newCollectionTitle =>
      _t(en: 'New Collection', zh: '新建收藏夹', ms: 'Koleksi Baharu');
  String get newCollectionHint => _t(
    en: 'New collection name…',
    zh: '新收藏夹名称…',
    ms: 'Nama koleksi baharu…',
  );
  String get noCollectionsCreateHint => _t(
    en: 'No collections yet. Create one above.',
    zh: '暂无收藏夹，请在上方创建。',
    ms: 'Tiada koleksi lagi. Cipta satu di atas.',
  );
  String get createLabel => _t(en: 'Create', zh: '创建', ms: 'Cipta');
  String collectionCreated(String name) => switch (locale) {
    AppLocale.en => 'Collection "$name" created',
    AppLocale.zhCN => '已创建收藏夹“$name”',
    AppLocale.ms => 'Koleksi "$name" dicipta',
  };
  String get renameCollectionTitle =>
      _t(en: 'Rename Collection', zh: '重命名收藏夹', ms: 'Namakan Semula Koleksi');
  String get collectionNameExists => _t(
    en: 'A collection with that name already exists',
    zh: '已有同名收藏夹',
    ms: 'Koleksi dengan nama itu sudah wujud',
  );
  String collectionRenamed(String name) => switch (locale) {
    AppLocale.en => 'Renamed to "$name"',
    AppLocale.zhCN => '已重命名为“$name”',
    AppLocale.ms => 'Dinamakan semula kepada "$name"',
  };

  // Share card (Certificate design)
  String get certificateOfOwnership =>
      _t(en: 'CERTIFICATE OF OWNERSHIP', zh: '所有权证书', ms: 'SIJIL PEMILIKAN');
  String get purchasedDateLabel =>
      _t(en: 'Purchased', zh: '购买日期', ms: 'Tarikh Beli');
  String get totalPaidCaps =>
      _t(en: 'TOTAL PAID', zh: '总支付', ms: 'JUMLAH DIBAYAR');
  String generatedOn(String date) => switch (locale) {
    AppLocale.en => 'Generated $date',
    AppLocale.zhCN => '生成于 $date',
    AppLocale.ms => 'Dijana $date',
  };

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle => _t(en: 'Settings', zh: '设置', ms: 'Tetapan');
  String get themeSection => _t(en: 'Theme', zh: '主题', ms: 'Tema');
  String get priceAlertsSection =>
      _t(en: 'Price Alerts', zh: '价格提醒', ms: 'Amaran Harga');
  String get priceAlertsDesc => _t(
    en: 'Set price thresholds per brand and purity. You will receive a notification when prices cross your targets.',
    zh: '为每个品牌和纯度设置价格阈值，价格突破目标时将收到通知。',
    ms: 'Tetapkan ambang harga untuk setiap jenama. Anda akan dimaklumkan apabila harga melangkaui sasaran.',
  );
  String get managePriceAlerts =>
      _t(en: 'Manage Price Alerts', zh: '管理价格提醒', ms: 'Urus Amaran Harga');
  String get testNotifButton => _t(
    en: 'Test Alert Notification',
    zh: '测试提醒通知',
    ms: 'Uji Notifikasi Amaran',
  );
  String get testNotifTitle => _t(
    en: 'Send Test Notification',
    zh: '发送测试通知',
    ms: 'Hantar Notifikasi Ujian',
  );
  String get testNotifDesc => _t(
    en: 'Select a brand and purity to send a test OS notification, verifying that alerts are working on your device.',
    zh: '选择品牌和纯度，发送测试通知以验证设备上的提醒功能是否正常。',
    ms: 'Pilih jenama dan ketulenan untuk menghantar notifikasi ujian, mengesahkan amaran berfungsi di peranti anda.',
  );
  String get sendTestNotif =>
      _t(en: 'Send Test', zh: '发送测试', ms: 'Hantar Ujian');
  String get sending => _t(en: 'Sending…', zh: '发送中…', ms: 'Menghantar…');
  String get testNotifSent => _t(
    en: 'Test notification sent! Check your status bar.',
    zh: '测试通知已发送！请查看状态栏。',
    ms: 'Notifikasi ujian dihantar! Semak bar status anda.',
  );
  String get notifPermDenied => _t(
    en: 'Notification permission denied. Please enable it in device settings.',
    zh: '通知权限被拒绝，请在设备设置中启用。',
    ms: 'Kebenaran notifikasi ditolak. Sila aktifkan dalam tetapan peranti.',
  );
  String get noAlertsConfigured => _t(
    en: 'No price alerts configured',
    zh: '暂无价格提醒',
    ms: 'Tiada amaran harga',
  );
  String get noAlertsHint => _t(
    en: 'Tap the bell icon on any brand card on the home page to set up an alert.',
    zh: '点击主页品牌卡片上的铃铛图标来设置提醒。',
    ms: 'Ketik ikon loceng pada kad jenama di halaman utama untuk tetapkan amaran.',
  );
  String get deleteAlertTitle =>
      _t(en: 'Remove Alert', zh: '删除提醒', ms: 'Padam Amaran');
  String deleteAlertConfirm(String shop, String purity) => switch (locale) {
    AppLocale.en => 'Remove the $purity price alert for $shop?',
    AppLocale.zhCN => '确定删除 $shop 的 $purity 价格提醒吗？',
    AppLocale.ms => 'Padam amaran harga $purity untuk $shop?',
  };
  String alertDeleted(String shop, String purity) => switch (locale) {
    AppLocale.en => 'Price alert deleted — $shop $purity',
    AppLocale.zhCN => '价格提醒已删除 — $shop $purity',
    AppLocale.ms => 'Amaran harga dipadam — $shop $purity',
  };
  String get languageSection => _t(en: 'Language', zh: '语言', ms: 'Bahasa');
  String get usersSection => _t(en: 'Users', zh: '用户', ms: 'Pengguna');
  String get brandsSection => _t(en: 'Brands', zh: '品牌', ms: 'Jenama');
  String get jewelleryTypesSection =>
      _t(en: 'Jewellery Types', zh: '珠宝类型', ms: 'Jenis Kemas');
  String get priceHistorySection =>
      _t(en: 'Price History', zh: '价格历史', ms: 'Sejarah Harga');
  String get dataSection => _t(en: 'Data', zh: '数据', ms: 'Data');
  String get generalSection => _t(en: 'General', zh: '常规', ms: 'Umum');
  String get priceDataSection =>
      _t(en: 'Price Data', zh: '价格数据', ms: 'Data Harga');
  String get securitySection => _t(en: 'Security', zh: '安全', ms: 'Keselamatan');
  String get appPinLockTitle =>
      _t(en: 'App PIN Lock', zh: '应用PIN锁', ms: 'Kunci PIN Aplikasi');
  String get appPinLockDesc => _t(
    en: 'Require a 4-digit PIN on startup',
    zh: '启动时需要4位PIN码',
    ms: 'Perlukan PIN 4 digit semasa mula',
  );
  String get changePin => _t(en: 'Change PIN', zh: '更改PIN', ms: 'Tukar PIN');
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
  String get exportShare => _t(en: 'Share', zh: '分享', ms: 'Kongsi');
  String get exportSaveDevice => _t(en: 'Save', zh: '保存', ms: 'Simpan');
  String get exporting => _t(en: 'Exporting…', zh: '导出中…', ms: 'Mengeksport…');
  String get importData => _t(en: 'Import Data', zh: '导入数据', ms: 'Import Data');
  String get importing => _t(en: 'Importing…', zh: '导入中…', ms: 'Mengimport…');
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
  String get pdfSuccess => _t(
    en: 'PDF generated successfully',
    zh: 'PDF生成成功',
    ms: 'PDF berjaya dijana',
  );
  String get pdfSaved => _t(
    en: 'PDF saved successfully!',
    zh: 'PDF已保存成功！',
    ms: 'PDF berjaya disimpan!',
  );
  String pdfFailed(Object e) => switch (locale) {
    AppLocale.en => 'PDF export failed: $e',
    AppLocale.zhCN => 'PDF导出失败：$e',
    AppLocale.ms => 'Eksport PDF gagal: $e',
  };

  // ── Update / OTA ─────────────────────────────────────────────────────────────
  String updateFoundTitle(String version) => switch (locale) {
    AppLocale.en => 'New update found: $version',
    AppLocale.zhCN => '发现新版本 $version',
    AppLocale.ms => 'Kemas kini baharu ditemui: $version',
  };
  String get updateLater => _t(en: 'Later', zh: '稍后', ms: 'Kemudian');
  String get updateNow =>
      _t(en: 'Update Now', zh: '立即更新', ms: 'Kemas Kini Sekarang');
  String get updateDownloading =>
      _t(en: 'Downloading…', zh: '下载中…', ms: 'Memuat turun…');
  String get updateInstalling =>
      _t(en: 'Installing…', zh: '正在安装…', ms: 'Memasang…');
  String get updateDownloadFailed => _t(
    en: 'Download failed. Please check your connection and try again.',
    zh: '下载失败，请检查网络后重试。',
    ms: 'Muat turun gagal. Sila semak sambungan dan cuba lagi.',
  );
  String get updatePermissionRequired => _t(
    en: 'Please enable the "Install unknown apps" permission to finish updating.',
    zh: '需要开启"安装未知应用"权限才能完成更新。',
    ms: 'Sila aktifkan kebenaran "Pasang aplikasi tidak dikenali" untuk selesaikan kemas kini.',
  );
  String get updateFailed => _t(
    en: 'Update failed. Please try again later.',
    zh: '更新失败，请稍后重试。',
    ms: 'Kemas kini gagal. Sila cuba lagi kemudian.',
  );
  String get checkForUpdate =>
      _t(en: 'Check for Updates', zh: '检查更新', ms: 'Semak Kemas Kini');
  String get checkingForUpdate =>
      _t(en: 'Checking…', zh: '检查中…', ms: 'Menyemak…');
  String get updateUpToDate => _t(
    en: "You're on the latest version",
    zh: '已是最新版本',
    ms: 'Anda menggunakan versi terkini',
  );
  String get updateOffline => _t(
    en: "You're offline — can't check for updates",
    zh: '您处于离线状态，无法检查更新',
    ms: 'Anda di luar talian — tidak dapat menyemak kemas kini',
  );
  String get updateTimeout => _t(
    en: 'Connection timed out — your network may be too slow',
    zh: '连接超时，您的网络可能太慢',
    ms: 'Sambungan tamat masa — rangkaian anda mungkin terlalu perlahan',
  );
  String get updateServerError => _t(
    en: "Couldn't reach the update server. Please try again later.",
    zh: '无法连接更新服务器，请稍后重试。',
    ms: 'Tidak dapat menghubungi pelayan kemas kini. Sila cuba lagi kemudian.',
  );
  String get updateRateLimited => _t(
    en: 'Update server is busy (too many requests). Please try again in a few minutes.',
    zh: '更新服务器繁忙（请求过多），请几分钟后重试。',
    ms: 'Pelayan kemas kini sibuk (terlalu banyak permintaan). Cuba lagi dalam beberapa minit.',
  );

  // ── Theme names (proper-noun translations) ───────────────────────────────────
  String get themeNameParchment => _t(en: 'Aureate', zh: '暖金', ms: 'Keemasan');
  String get themeNameSky => _t(en: 'Sky', zh: '天蓝', ms: 'Langit');
  String get themeNameBlush => _t(en: 'Blush', zh: '玫瑰', ms: 'Merona');

  // ── Product form ─────────────────────────────────────────────────────────────
  String get addProduct =>
      _t(en: 'Add Product', zh: '添加产品', ms: 'Tambah Produk');
  String get editProduct =>
      _t(en: 'Edit Product', zh: '编辑产品', ms: 'Edit Produk');
  String get selectPlaceholder => _t(en: 'Select', zh: '选择', ms: 'Pilih');
  String get dateOfPurchase =>
      _t(en: 'Date of Purchase', zh: '购买日期', ms: 'Tarikh Beli');
  String get productName =>
      _t(en: 'Product Name', zh: '产品名称', ms: 'Nama Produk');
  String get measurementUnit =>
      _t(en: 'Measurement Unit', zh: '计量单位', ms: 'Unit Ukuran');
  String get photosLabel => _t(en: 'Photos', zh: '照片', ms: 'Foto');
  String get addPhotos => _t(en: 'Add Photos', zh: '添加照片', ms: 'Tambah Foto');
  String get saveProduct =>
      _t(en: 'Save Product', zh: '保存产品', ms: 'Simpan Produk');
  String get sectionBasicInfo =>
      _t(en: 'Basic Info', zh: '基本信息', ms: 'Maklumat Asas');
  String get sectionPricing => _t(en: 'Pricing', zh: '价格', ms: 'Harga');
  String get sectionPhotosNotes =>
      _t(en: 'Photos & Notes', zh: '照片与备注', ms: 'Foto & Nota');
  String get manualCalculate =>
      _t(en: 'Manual calculate', zh: '手动计算', ms: 'Kira Manual');

  // ── Active / inactive toggle ─────────────────────────────────────────────────
  String get activeLabel => _t(en: 'Active', zh: '启用', ms: 'Aktif');
  String get inactiveLabel => _t(en: 'Inactive', zh: '停用', ms: 'Tidak Aktif');

  // ── Validation ───────────────────────────────────────────────────────────────
  String get typeNameRequired => _t(
    en: 'English name is required',
    zh: '英文名称为必填项',
    ms: 'Nama Inggeris diperlukan',
  );

  // ── User form ────────────────────────────────────────────────────────────────
  String get addUser => _t(en: 'Add User', zh: '添加用户', ms: 'Tambah Pengguna');
  String get editUser => _t(en: 'Edit User', zh: '编辑用户', ms: 'Edit Pengguna');
  String get dateOfBirth =>
      _t(en: 'Date of Birth', zh: '出生日期', ms: 'Tarikh Lahir');

  // ── User deletion ────────────────────────────────────────────────────────────
  String get deleteUserTitle =>
      _t(en: 'Cannot Delete User', zh: '无法删除用户', ms: 'Tidak Boleh Padam');
  String userHasItems(int n) => switch (locale) {
    AppLocale.en =>
      'This user owns $n item${n == 1 ? '' : 's'} and cannot be deleted.',
    AppLocale.zhCN => '该用户拥有 $n 件珠宝，无法删除。',
    AppLocale.ms => 'Pengguna ini memiliki $n item dan tidak boleh dipadam.',
  };

  // ── Manage pages ─────────────────────────────────────────────────────────────
  String get noBrandsFound =>
      _t(en: 'No brands found', zh: '未找到品牌', ms: 'Tiada jenama');
  String get addBrand => _t(en: 'Add Brand', zh: '添加品牌', ms: 'Tambah Jenama');
  String get editBrand => _t(en: 'Edit Brand', zh: '编辑品牌', ms: 'Edit Jenama');
  String get brandName => _t(en: 'Brand Name', zh: '品牌名称', ms: 'Nama Jenama');
  String get brandDesc => _t(en: 'Description', zh: '描述', ms: 'Keterangan');
  String get noTypesFound =>
      _t(en: 'No types found', zh: '未找到类型', ms: 'Tiada jenis');
  String get iconLabel => _t(en: 'Icon', zh: '图标', ms: 'Ikon');
  String get addType => _t(en: 'Add Type', zh: '添加类型', ms: 'Tambah Jenis');
  String get editType => _t(en: 'Edit Type', zh: '编辑类型', ms: 'Edit Jenis');
  String get typeNameEn =>
      _t(en: 'Name (English)', zh: '名称（英文）', ms: 'Nama (Inggeris)');
  String get typeNameZh => _t(en: 'Name (中文)', zh: '名称（中文）', ms: 'Nama (中文)');
  String get typeNameMs =>
      _t(en: 'Name (Melayu)', zh: '名称（马来文）', ms: 'Nama (Melayu)');

  // ── Price History ────────────────────────────────────────────────────────────
  String get historySection => _t(en: 'History', zh: '历史', ms: 'Sejarah');
  String get loadingHistory =>
      _t(en: 'Loading history…', zh: '加载历史中…', ms: 'Memuatkan sejarah…');
  String get chartEmpty => _t(
    en: 'Not enough history yet',
    zh: '暂无足够数据',
    ms: 'Data belum mencukupi',
  );
  String get chartEmptyDesc => _t(
    en: 'Prices are recorded once a day.\nCheck back after a few refreshes.',
    zh: '每天记录一次价格。\n多刷新几次后再来看看。',
    ms: 'Harga direkod sekali sehari.\nSemak semula selepas muat semula.',
  );
  String get gold916 => _t(en: '916 Gold', zh: '916 金', ms: '916 Emas');
  String get gold999 => _t(en: '999 Gold', zh: '999 金', ms: '999 Emas');
  String get historyTodayLabel => _t(en: 'Today', zh: '今天', ms: 'Hari ini');

  // ── Export PDF page ──────────────────────────────────────────────────────────
  String get exportPdfTitle =>
      _t(en: 'Export PDF', zh: '导出PDF', ms: 'Eksport PDF');
  String get formatTable => _t(en: 'Table', zh: '表格', ms: 'Jadual');
  String get formatProductCard =>
      _t(en: 'Product Card', zh: '产品卡片', ms: 'Kad Produk');
  String get columnsSection => _t(en: 'Columns', zh: '字段', ms: 'Lajur');
  String get imageSection => _t(en: 'Image', zh: '图片', ms: 'Imej');
  String get dateRangeSection =>
      _t(en: 'Date Range', zh: '日期范围', ms: 'Julat Tarikh');
  String get groupingSection => _t(en: 'Grouping', zh: '分组', ms: 'Kumpulan');
  String get selectAllLabel => _t(en: 'Select All', zh: '全选', ms: 'Pilih Semua');
  String get includeThumbnailLabel => _t(
    en: 'Include product thumbnail',
    zh: '包含产品缩略图',
    ms: 'Sertakan imej kecil produk',
  );
  String get noUsersFound =>
      _t(en: 'No users found.', zh: '未找到用户。', ms: 'Tiada pengguna.');
  String get dateFromLabel => _t(en: 'From', zh: '从', ms: 'Dari');
  String get dateToLabel => _t(en: 'To', zh: '至', ms: 'Hingga');
  String get noDateFilterLabel =>
      _t(en: 'No filter', zh: '不限', ms: 'Tiada tapisan');
  String get groupByUserLabel => _t(
    en: 'Group by User (separate table per owner)',
    zh: '按拥有者分组（每位拥有者单独列表）',
    ms: 'Kumpul ikut pemilik (jadual berasingan setiap pemilik)',
  );
  String get previewButton => _t(en: 'Preview', zh: '预览', ms: 'Pratonton');
  String get labelPrice => _t(en: 'Price', zh: '价格', ms: 'Harga');
  String pageOf(int page, int total) => switch (locale) {
    AppLocale.en => 'Page $page of $total',
    AppLocale.zhCN => '第 $page 页 · 共 $total 页',
    AppLocale.ms => 'Halaman $page / $total',
  };
  String get noContentToPreview => _t(
    en: 'No content to preview.',
    zh: '暂无可预览内容。',
    ms: 'Tiada kandungan untuk pratonton.',
  );
  String get saveToDevice =>
      _t(en: 'Save to device', zh: '保存到设备', ms: 'Simpan ke peranti');

  // ── Gold price card ──────────────────────────────────────────────────────────
  String get errTimeout =>
      _t(en: 'Request timed out', zh: '请求超时', ms: 'Permintaan tamat masa');
  String get errParse => _t(
    en: 'Could not read price',
    zh: '无法读取价格',
    ms: 'Tidak dapat baca harga',
  );
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
