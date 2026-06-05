import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../components/app_header.dart';
import '../components/buttons.dart';

class ProductFormPage extends StatefulWidget {
  final String mode;
  final int? productId;

  const ProductFormPage({
    Key? key,
    required this.mode,
    this.productId,
  }) : super(key: key);

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late TextEditingController _dateController;
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _measurementController;
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
  String? _selectedCurrencyId;
  String? _selectedMeasurement;
  List<String> _selectedPhotos = [];
  List<XFile> _selectedXFiles = [];  // Store XFile for web preview
  bool _autoCalculateTotal = true;

  List<Brand> brands = [];
  List<JewelleryType> types = [];
  List<User> users = [];
  List<Currency> currencies = [];

  Jewellery? _existingJewellery;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    _nameController = TextEditingController();
    _sizeController = TextEditingController();
    _measurementController = TextEditingController();
    _pricePerGramController = TextEditingController();
    _weightController = TextEditingController();
    _laborFeesController = TextEditingController();
    _totalPriceController = TextEditingController();
    _locationController = TextEditingController();
    _remarksController = TextEditingController();

    _loadData();
  }

  void _loadData() {
    brands = HiveService.getAllBrands();
    brands.sort((a, b) => a.name.compareTo(b.name));
    types = HiveService.getAllJewelleryTypes();
    users = HiveService.getAllUsers();
    currencies = HiveService.getAllCurrencies();

    // Set default currency to id 1
    _selectedCurrencyId = '1';

    if (widget.mode == 'edit' && widget.productId != null) {
      _existingJewellery = HiveService.getJewellery(widget.productId!);
      if (_existingJewellery != null) {
        _dateController.text = DateFormat('dd/MM/yyyy').format(_existingJewellery!.date);
        _nameController.text = _existingJewellery!.name;
        _selectedBrand = _existingJewellery!.brand;
        _selectedPurity = _existingJewellery!.goldPurity;
        _selectedPayerId = _existingJewellery!.payerId;
        _selectedOwnerId = _existingJewellery!.ownerId;
        _selectedTypeId = _existingJewellery!.jewelleryTypeId;
        _sizeController.text = _existingJewellery!.size?.toString() ?? '';
        _measurementController.text = _existingJewellery!.measurement?.toString() ?? '';
        _pricePerGramController.text = _existingJewellery!.pricePerGram?.toString() ?? '';
        _weightController.text = _existingJewellery!.weight?.toString() ?? '';
        _laborFeesController.text = _existingJewellery!.laborFees?.toString() ?? '';
        _totalPriceController.text = _existingJewellery!.totalPrice?.toString() ?? '';
        _locationController.text = _existingJewellery!.purchaseLocation ?? '';
        _remarksController.text = _existingJewellery!.remarks ?? '';
        _selectedPhotos = _existingJewellery!.jewelleryPhoto ?? [];
      }
    }

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
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images.map((img) => img.path).toList());
        _selectedXFiles.addAll(images);  // Store XFile for web display
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      if (index < _selectedXFiles.length) {
        _selectedXFiles.removeAt(index);
      }
    });
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

      // Convert images to base64 for persistence
      List<String>? encodedImages;
      if (_selectedXFiles.isNotEmpty) {
        encodedImages = [];
        for (var xfile in _selectedXFiles) {
          final bytes = await xfile.readAsBytes();
          final base64String = base64Encode(bytes);
          encodedImages.add(base64String);
        }
      }

      final jewellery = Jewellery(
        id: _existingJewellery?.id ?? HiveService.getNextJewelleryId(),
        date: date,
        name: _nameController.text,
        payerId: _selectedPayerId,
        ownerId: _selectedOwnerId,
        size: double.tryParse(_sizeController.text),
        measurement: double.tryParse(_measurementController.text),
        jewelleryTypeId: _selectedTypeId,
        brand: _selectedBrand ?? '',
        goldPurity: _selectedPurity ?? '916',
        pricePerGram: int.tryParse(_pricePerGramController.text),
        weight: double.tryParse(_weightController.text),
        laborFees: double.tryParse(_laborFeesController.text),
        totalPrice: double.tryParse(_totalPriceController.text),
        purchaseLocation: _locationController.text,
        jewelleryPhoto: encodedImages,
        remarks: _remarksController.text,
        createdAt: _existingJewellery?.createdAt ?? now,
        updatedAt: now,
      );

      HiveService.saveJewellery(jewellery);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully')),
      );
      if (mounted) {
        GoRouter.of(context).pop();
      }
    } catch (e) {
      _showValidationError('Error saving product: $e');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _sizeController.dispose();
    _measurementController.dispose();
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
    final appTheme = _getAppTheme(context);

    return Scaffold(
      appBar: AppHeader(title: widget.mode == 'add' ? 'Add Product' : 'Edit Product'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormField('Date of Purchase *', _dateController, appTheme, onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
              }
            }),
            const SizedBox(height: 16),
            _buildFormField('Product Name *', _nameController, appTheme),
            const SizedBox(height: 16),
            _buildDropdown(
              'Brand',
              _selectedBrand,
              brands.map((b) => b.name).toList(),
              (value) => setState(() => _selectedBrand = value),
              appTheme,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Purity',
              _selectedPurity,
              ['916', '999'],
              (value) => setState(() => _selectedPurity = value),
              appTheme,
            ),
            const SizedBox(height: 16),
            _buildUserDropdown('Owner', _selectedOwnerId, users, (value) {
              setState(() => _selectedOwnerId = value);
            }, appTheme),
            const SizedBox(height: 16),
            _buildUserDropdown('Payer', _selectedPayerId, users, (value) {
              setState(() => _selectedPayerId = value);
            }, appTheme),
            const SizedBox(height: 16),
            _buildTypeDropdown('Jewellery Type', _selectedTypeId, types, (value) {
              setState(() => _selectedTypeId = value);
            }, appTheme),
            const SizedBox(height: 16),
            _buildFormField('Size', _sizeController, appTheme,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Measurement Unit',
              _selectedMeasurement,
              ['', 'mm', 'cm'],
              (value) => setState(() => _selectedMeasurement = value),
              appTheme,
            ),
            const SizedBox(height: 16),
            _buildCurrencyDropdown('Currency', _selectedCurrencyId, currencies, (value) {
              setState(() => _selectedCurrencyId = value);
            }, appTheme),
            const SizedBox(height: 16),
            _buildFormField('Price Per Gram', _pricePerGramController, appTheme,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => _calculateTotalPrice(),
            ),
            const SizedBox(height: 16),
            _buildFormField('Weight', _weightController, appTheme,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => _calculateTotalPrice(),
            ),
            const SizedBox(height: 16),
            _buildFormField('Labor Fees', _laborFeesController, appTheme,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => _calculateTotalPrice(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFormField('Total Price', _totalPriceController, appTheme, enabled: !_autoCalculateTotal),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: !_autoCalculateTotal,
                  onChanged: (value) {
                    setState(() => _autoCalculateTotal = !value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormField('Purchase Location', _locationController, appTheme),
            const SizedBox(height: 16),
            Text(
              'Photos',
              style: TextStyle(
                color: appTheme.textHeading,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedPhotos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Add Photos',
              onPressed: _pickImages,
            ),
            const SizedBox(height: 16),
            _buildFormField('Remarks', _remarksController, appTheme, maxLines: 3),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save Product',
              onPressed: _savProduct,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.accentPrimary),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
          style: TextStyle(color: appTheme.textHeading),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
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
          value: value,
          items: [
            const DropdownMenuItem(value: null, child: Text('Select')),
            ...items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
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
          value: value,
          items: [
            const DropdownMenuItem(value: null, child: Text('Select')),
            ...items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
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
          value: value,
          items: [
            const DropdownMenuItem(value: null, child: Text('Select')),
            ...items.map((item) => DropdownMenuItem(
              value: item.id.toString(),
              child: Text('${item.symbol} - ${item.name}'),
            )),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appTheme.borderColor.withValues(alpha: 0.3)),
            ),
            filled: true,
            fillColor: appTheme.backgroundSurface,
          ),
        ),
      ],
    );
  }

  AppTheme _getAppTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (primary == GoldTheme.accentPrimary) return AppTheme.gold;
    if (primary == BlushTheme.accentPrimary) return AppTheme.blush;
    if (primary == SkyTheme.accentPrimary) return AppTheme.sky;
    return AppTheme.gold;
  }

  Widget _buildImageWidget(String imagePath, int index, {required BoxFit fit, required AppTheme appTheme}) {
    // For web, try to use XFile data if available
    if (kIsWeb && index < _selectedXFiles.length) {
      return FutureBuilder<Uint8List>(
        future: _selectedXFiles[index].readAsBytes(),
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
