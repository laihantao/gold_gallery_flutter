import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';
import '../components/form_section.dart';

class ProductFormPage extends StatefulWidget {
  final String mode;
  final int? productId;

  const ProductFormPage({super.key, required this.mode, this.productId});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late TextEditingController _dateController;
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _pricePerGramController;
  late TextEditingController _weightController;
  late TextEditingController _laborFeesController;
  late TextEditingController _totalPriceController;
  late TextEditingController _locationController;
  late TextEditingController _remarksController;

  String? _selectedBrand;
  String? _selectedPurity = '916';
  int? _selectedTypeId;
  int? _selectedPayerId;
  int? _selectedOwnerId;
  Currency? _selectedCurrency;
  String? _selectedMeasurementUnit;
  List<String> _selectedPhotos = [];
  final List<XFile> _selectedXFiles = []; // Store XFile for web preview
  bool _autoCalculateTotal = true;

  List<Brand> brands = [];
  List<JewelleryType> types = [];
  List<User> users = [];
  List<Currency> currencies = [];

  Jewellery? _existingJewellery;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    _nameController = TextEditingController();
    _sizeController = TextEditingController();
    _pricePerGramController = TextEditingController();
    _weightController = TextEditingController();
    _laborFeesController = TextEditingController();
    _totalPriceController = TextEditingController();
    _locationController = TextEditingController();
    _remarksController = TextEditingController();

    _loadData();
  }

  void _loadData() {
    if (!mounted) return;

    brands = HiveService.getAllBrands()
        .where((b) => b.isActive)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    types = HiveService.getAllJewelleryTypes()
        .where((t) => t.isActive)
        .toList();
    users = HiveService.getAllUsers()
        .where((u) => u.isActive)
        .toList();
    currencies = HiveService.getAllCurrencies();
    _selectedCurrency = _findCurrencyByCode('MYR') ??
        (currencies.isNotEmpty ? currencies.first : null);

    if (widget.mode == 'edit' && widget.productId != null) {
      _existingJewellery = HiveService.getJewellery(widget.productId!);
      if (_existingJewellery != null) {
        _dateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(_existingJewellery!.date);
        _nameController.text = _existingJewellery!.name;
        _selectedBrand = _existingJewellery!.brand;
        _selectedPurity = _existingJewellery!.goldPurity;
        _selectedPayerId = _existingJewellery!.payerId;
        _selectedOwnerId = _existingJewellery!.ownerId;
        _selectedTypeId = _existingJewellery!.jewelleryTypeId;
        _sizeController.text = _existingJewellery!.size?.toString() ?? '';
        _selectedMeasurementUnit = _existingJewellery!.measurementUnit;
        _pricePerGramController.text =
            _existingJewellery!.pricePerGram?.toString() ?? '';
        _weightController.text = _existingJewellery!.weight?.toString() ?? '';
        _laborFeesController.text = _existingJewellery!.laborFees != null
            ? _existingJewellery!.laborFees!.toStringAsFixed(2)
            : '';
        _totalPriceController.text =
            _existingJewellery!.totalPrice?.toString() ?? '';
        _locationController.text = _existingJewellery!.purchaseLocation ?? '';
        _remarksController.text = _existingJewellery!.remarks ?? '';
        _selectedPhotos = List<String>.from(_existingJewellery!.jewelleryPhoto);
        _selectedCurrency = _findCurrencyById(_existingJewellery!.currencyId) ??
            _findCurrencyByCode('MYR') ??
            (currencies.isNotEmpty ? currencies.first : null);
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  void _calculateTotalPrice() {
    if (!_autoCalculateTotal) return;

    final pricePerGram = int.tryParse(_pricePerGramController.text);
    final weight = double.tryParse(_weightController.text);
    final laborFees = double.tryParse(_laborFeesController.text);

    if (pricePerGram != null && weight != null && laborFees != null) {
      final total = (pricePerGram * weight) + laborFees;
      _totalPriceController.text = total.toStringAsFixed(2);
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (!mounted) return;

    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images.map((img) => img.path).toList());
        _selectedXFiles.addAll(images); // Store XFile for web display
      });
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _selectedPhotos.length) return;

    setState(() {
      final removedPath = _selectedPhotos[index];
      _selectedPhotos.removeAt(index);

      final xFileIndex = _selectedXFiles.indexWhere(
        (file) => file.path == removedPath,
      );
      if (xFileIndex >= 0) {
        _selectedXFiles.removeAt(xFileIndex);
      } else if (index < _selectedXFiles.length &&
          !_looksLikeBase64Image(removedPath)) {
        _selectedXFiles.removeAt(index);
      }
    });
  }

  bool _looksLikeBase64Image(String imagePath) {
    return _decodeBase64ImageBytes(imagePath) != null;
  }

  Uint8List? _decodeBase64ImageBytes(String imagePath) {
    final source = imagePath.trim();
    final commaIndex = source.indexOf(',');
    final payload = source.startsWith('data:image') && commaIndex >= 0
        ? source.substring(commaIndex + 1)
        : source;

    if (payload.length < 100 ||
        payload.startsWith('file:') ||
        payload.contains(r'\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(payload)) {
      return null;
    }

    if (payload.startsWith('/') && !payload.startsWith('/9j/')) {
      return null;
    }

    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  XFile? _xFileForPath(String imagePath) {
    for (final file in _selectedXFiles) {
      if (file.path == imagePath) return file;
    }
    return null;
  }

  Future<List<String>> _encodePhotosForSave() async {
    final List<String> encodedImages = [];

    for (final imagePath in _selectedPhotos) {
      if (_looksLikeBase64Image(imagePath)) {
        encodedImages.add(imagePath);
        continue;
      }

      final matchingXFile = _xFileForPath(imagePath);
      if (matchingXFile != null) {
        encodedImages.add(base64Encode(await matchingXFile.readAsBytes()));
        continue;
      }

      if (!kIsWeb) {
        final file = File(imagePath);
        if (file.existsSync()) {
          encodedImages.add(base64Encode(await file.readAsBytes()));
        }
      }
    }

    return encodedImages;
  }

  void _savProduct() async {
    // Validation
    if (_nameController.text.isEmpty) {
      _showValidationError('Product name is required');
      return;
    }

    try {
      final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      final now = DateTime.now();

      final encodedImages = await _encodePhotosForSave();

      final jewellery = Jewellery(
        id: _existingJewellery?.id ?? HiveService.getNextJewelleryId(),
        date: date,
        name: _nameController.text,
        payerId: _selectedPayerId,
        ownerId: _selectedOwnerId,
        size: double.tryParse(_sizeController.text),
        measurementUnit: _selectedMeasurementUnit?.isNotEmpty == true
            ? _selectedMeasurementUnit
            : null,
        jewelleryTypeId: _selectedTypeId,
        brand: _selectedBrand ?? '',
        goldPurity: _selectedPurity ?? '916',
        pricePerGram: int.tryParse(_pricePerGramController.text),
        weight: double.tryParse(_weightController.text),
        laborFees: double.tryParse(_laborFeesController.text),
        totalPrice: double.tryParse(_totalPriceController.text),
        currencyId: _selectedCurrency?.id,
        purchaseLocation: _locationController.text,
        jewelleryPhoto: encodedImages,
        remarks: _remarksController.text,
        createdAt: _existingJewellery?.createdAt ?? now,
        updatedAt: now,
      );

      HiveService.saveJewellery(jewellery);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
      GoRouter.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showValidationError('Error saving product: $e');
    }
  }

  Currency? _findCurrencyByCode(String code) {
    for (final currency in currencies) {
      if (currency.code.toUpperCase() == code.toUpperCase()) {
        return currency;
      }
    }
    return null;
  }

  Currency? _findCurrencyById(int? id) {
    if (id == null) return null;
    for (final currency in currencies) {
      if (currency.id == id) return currency;
    }
    return HiveService.getCurrency(id);
  }

  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _sizeController.dispose();
    _pricePerGramController.dispose();
    _weightController.dispose();
    _laborFeesController.dispose();
    _totalPriceController.dispose();
    _locationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: widget.mode == 'add' ? l10n.addProduct : l10n.editProduct,
        colored: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormSection(
              title: l10n.sectionBasicInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    '${l10n.productName} *',
                    _nameController,
                    appTheme,
                  ),
                  const SizedBox(height: 14),
                  _fieldRow(
                    _buildDropdown(
                      l10n.rowBrand,
                      _selectedBrand,
                      brands.map((b) => b.name).toList(),
                      (value) => setState(() => _selectedBrand = value),
                      appTheme,
                      l10n,
                    ),
                    _buildDropdown(
                      l10n.rowPurity,
                      _selectedPurity,
                      ['916', '999'],
                      (value) => setState(() => _selectedPurity = value),
                      appTheme,
                      l10n,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldRow(
                    _buildUserDropdown(l10n.rowOwner, _selectedOwnerId, users,
                        (value) {
                      setState(() => _selectedOwnerId = value);
                    }, appTheme, l10n),
                    _buildUserDropdown(l10n.rowPayer, _selectedPayerId, users,
                        (value) {
                      setState(() => _selectedPayerId = value);
                    }, appTheme, l10n),
                  ),
                  const SizedBox(height: 14),
                  _buildTypeDropdown(
                      l10n.rowJewelleryType, _selectedTypeId, types, (value) {
                    setState(() => _selectedTypeId = value);
                  }, appTheme, l10n),
                  const SizedBox(height: 14),
                  _fieldRow(
                    _buildFormField(
                      l10n.rowSize,
                      _sizeController,
                      appTheme,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    _buildDropdown(
                      l10n.measurementUnit,
                      _selectedMeasurementUnit,
                      ['', 'mm', 'cm'],
                      (value) =>
                          setState(() => _selectedMeasurementUnit = value),
                      appTheme,
                      l10n,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FormSection(
              title: l10n.sectionPricing,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    '${l10n.dateOfPurchase} *',
                    _dateController,
                    appTheme,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildCurrencyDropdown(
                    l10n.rowCurrency,
                    _selectedCurrency?.id.toString(),
                    currencies,
                    (value) {
                      setState(() {
                        _selectedCurrency =
                            _findCurrencyById(int.tryParse(value ?? ''));
                      });
                    },
                    appTheme,
                  ),
                  const SizedBox(height: 14),
                  _fieldRow(
                    _buildFormField(
                      l10n.rowPricePerGram,
                      _pricePerGramController,
                      appTheme,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _calculateTotalPrice(),
                    ),
                    _buildFormField(
                      l10n.rowWeight,
                      _weightController,
                      appTheme,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => _calculateTotalPrice(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFormField(
                    l10n.rowLaborFees,
                    _laborFeesController,
                    appTheme,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => _calculateTotalPrice(),
                  ),
                  const SizedBox(height: 14),
                  _buildTotalPriceField(appTheme, l10n),
                  const SizedBox(height: 14),
                  _buildFormField(
                      l10n.rowPurchaseLocation, _locationController, appTheme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FormSection(
              title: l10n.sectionPhotosNotes,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedPhotos.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: appTheme.backgroundSubtle,
                              ),
                              child: _buildImageWidget(
                                _selectedPhotos[index],
                                index,
                                fit: BoxFit.cover,
                                appTheme: appTheme,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  GhostButton(label: l10n.addPhotos, onPressed: _pickImages),
                  const SizedBox(height: 14),
                  _buildFormField(
                    l10n.rowRemarks,
                    _remarksController,
                    appTheme,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: l10n.saveProduct, onPressed: _savProduct),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Two fields side by side with the standard gap, used throughout the form.
  Widget _fieldRow(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }

  /// Total Price field with an inline "manual calculate" toggle in its label
  /// row — toggling it flips [_autoCalculateTotal] exactly like the checkbox
  /// it replaces.
  Widget _buildTotalPriceField(AppTheme appTheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.rowTotalPrice,
                style: TextStyle(
                  color: appTheme.textHeading,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () =>
                  setState(() => _autoCalculateTotal = !_autoCalculateTotal),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _autoCalculateTotal
                        ? Icons.check_box_outline_blank_rounded
                        : Icons.check_box_rounded,
                    size: 16,
                    color: _autoCalculateTotal
                        ? appTheme.textBody.withValues(alpha: 0.5)
                        : appTheme.accentPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.manualCalculate,
                    style: TextStyle(
                      color: appTheme.textBody.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _totalPriceController,
          enabled: !_autoCalculateTotal,
          decoration: _fieldDecoration(appTheme),
          style: TextStyle(color: appTheme.textHeading),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    AppTheme appTheme, {
    int maxLines = 1,
    bool enabled = true,
    VoidCallback? onTap,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          decoration: _fieldDecoration(appTheme),
          style: TextStyle(color: appTheme.textHeading),
        ),
      ],
    );
  }

  /// Shared text-field chrome (border/fill colours) used across every field
  /// in this form, so all inputs stay visually consistent in one place.
  InputDecoration _fieldDecoration(AppTheme appTheme) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: appTheme.borderColor.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: appTheme.borderColor.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: appTheme.accentPrimary),
      ),
      filled: true,
      fillColor: appTheme.backgroundSurface,
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: appTheme.borderColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: appTheme.borderColor.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildUserDropdown(
    String label,
    int? value,
    List<User> items,
    Function(int?) onChanged,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: value,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.selectPlaceholder)),
            ...items.map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
            ),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: appTheme.borderColor.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(
    String label,
    int? value,
    List<JewelleryType> items,
    Function(int?) onChanged,
    AppTheme appTheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          initialValue: value,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.selectPlaceholder)),
            ...items.map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text(item.localizedName(l10n.locale)),
              ),
            ),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: appTheme.borderColor.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(
    String label,
    String? value,
    List<Currency> items,
    Function(String?) onChanged,
    AppTheme appTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appTheme.textHeading,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: value,
          items: [
            DropdownMenuItem(
                value: null, child: Text(context.l10n.selectPlaceholder)),
            ...items.map(
              (item) => DropdownMenuItem(
                value: item.id.toString(),
                child: Text('${item.symbol} - ${item.name}'),
              ),
            ),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: appTheme.borderColor.withValues(alpha: 0.3),
              ),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(
    String imagePath,
    int index, {
    required BoxFit fit,
    required AppTheme appTheme,
  }) {
    if (_looksLikeBase64Image(imagePath)) {
      try {
        final bytes = _decodeBase64ImageBytes(imagePath);
        if (bytes == null) {
          return Icon(Icons.image, color: appTheme.accentSecondary);
        }
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image, color: appTheme.accentSecondary);
          },
        );
      } catch (e) {
        return Icon(Icons.image, color: appTheme.accentSecondary);
      }
    }

    // For web, try to use XFile data if available
    final matchingXFile = _xFileForPath(imagePath);
    if (kIsWeb && matchingXFile != null) {
      return FutureBuilder<Uint8List>(
        future: matchingXFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image, color: appTheme.accentSecondary);
              },
            );
          } else if (snapshot.hasError) {
            return Icon(Icons.image, color: appTheme.accentSecondary);
          }
          return Container(
            color: appTheme.backgroundSubtle,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    // For native platforms, use File directly
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.image, color: appTheme.accentSecondary);
          },
        );
      } else {
        return Icon(Icons.image, color: appTheme.accentSecondary);
      }
    } catch (e) {
      return Icon(Icons.image, color: appTheme.accentSecondary);
    }
  }
}
