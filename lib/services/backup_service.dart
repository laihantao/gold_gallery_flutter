import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../models/index.dart';
import 'backup_download.dart';
import 'hive_service.dart';

class BackupImportResult {
  final Map<String, int> counts;

  const BackupImportResult(this.counts);

  int get totalImported => counts.values.fold(0, (sum, count) => sum + count);
}

class BackupService {
  static const String _format = 'my_gold_gallery_json_backup';
  static const int _version = 1;

  static Future<String?> exportBackup() async {
    final fileName =
        'gold_gallery_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final jsonBytes = _buildBackupBytes();
    return saveJsonBackupFile(fileName, jsonBytes);
  }

  static Future<BackupImportResult?> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Gold Gallery JSON Backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;
    if (bytes == null) {
      throw const FormatException('Unable to read selected JSON file.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    final boxes = _readAndValidateBackup(decoded);
    final counts = await HiveService.importRawData(boxes);
    return BackupImportResult(counts);
  }

  static Uint8List _buildBackupBytes() {
    final backupData = {
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'boxes': HiveService.exportRawData(),
    };

    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(backupData)),
    );
  }

  static Map<String, dynamic> _readAndValidateBackup(dynamic decoded) {
    if (decoded is! Map) {
      throw const FormatException('Backup JSON must be an object.');
    }

    final backup = Map<String, dynamic>.from(decoded);
    final boxes = backup['boxes'] is Map
        ? Map<String, dynamic>.from(backup['boxes'])
        : Map<String, dynamic>.from(backup);

    final normalized = <String, dynamic>{
      HiveService.boxUser: _validateRecords(
        boxes[HiveService.boxUser],
        HiveService.boxUser,
        (json) => User.fromJson(json).toJson(),
      ),
      HiveService.boxBrand: _validateRecords(
        boxes[HiveService.boxBrand],
        HiveService.boxBrand,
        (json) => Brand.fromJson(json).toJson(),
      ),
      HiveService.boxJewelleryType: _validateRecords(
        boxes[HiveService.boxJewelleryType],
        HiveService.boxJewelleryType,
        (json) => JewelleryType.fromJson(json).toJson(),
      ),
      HiveService.boxCurrency: _validateRecords(
        boxes[HiveService.boxCurrency],
        HiveService.boxCurrency,
        (json) => Currency.fromJson(json).toJson(),
      ),
      HiveService.boxJewellery: _validateRecords(
        boxes[HiveService.boxJewellery],
        HiveService.boxJewellery,
        _normalizeJewellery,
      ),
    };

    return normalized;
  }

  static List<Map<String, dynamic>> _validateRecords(
    dynamic values,
    String boxName,
    Map<String, dynamic> Function(Map<String, dynamic>) normalize,
  ) {
    if (values == null) return [];
    if (values is! List) {
      throw FormatException('Backup field "$boxName" must be a list.');
    }

    final records = <Map<String, dynamic>>[];
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value is! Map) {
        throw FormatException('Record $index in "$boxName" must be an object.');
      }

      final json = Map<String, dynamic>.from(value);
      if (json['id'] == null) {
        throw FormatException('Record $index in "$boxName" is missing id.');
      }

      try {
        records.add(normalize(json));
      } catch (e) {
        throw FormatException('Record $index in "$boxName" is invalid: $e');
      }
    }

    return records;
  }

  static Map<String, dynamic> _normalizeJewellery(Map<String, dynamic> json) {
    final normalized = Jewellery.fromJson(json).toJson();
    final photos = json['jewelleryPhoto'];

    normalized['jewelleryPhoto'] = photos is List
        ? photos.whereType<String>().where((photo) => photo.isNotEmpty).toList()
        : <String>[];

    return normalized;
  }
}
