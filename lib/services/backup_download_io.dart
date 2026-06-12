import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  try {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Gold Gallery JSON Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return null;

    await File(savePath).writeAsBytes(jsonBytes, flush: true);
    return savePath;
  } on UnimplementedError {
    return _shareJsonBackup(fileName, jsonBytes);
  } on UnsupportedError {
    return _shareJsonBackup(fileName, jsonBytes);
  } on MissingPluginException {
    return _shareJsonBackup(fileName, jsonBytes);
  }
}

Future<String> _shareJsonBackup(String fileName, Uint8List jsonBytes) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(jsonBytes, mimeType: 'application/json', name: fileName)],
    subject: 'Gold Gallery JSON backup',
    text: 'Gold Gallery JSON backup export',
  ));

  return 'shared';
}
