import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the native "Save As" document picker (ACTION_CREATE_DOCUMENT on Android)
/// so the user can choose the save location and filename.
/// Returns the saved path, or null if the user cancelled.
Future<String?> saveJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  final nameWithoutExt = fileName.endsWith('.json')
      ? fileName.substring(0, fileName.length - 5)
      : fileName;

  return FileSaver.instance.saveAs(
    name: nameWithoutExt,
    bytes: jsonBytes,
    fileExtension: 'json',
    mimeType: MimeType.json,
  );
}

/// Opens the OS share sheet so the user can choose where to send the file.
Future<String> shareJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(jsonBytes, mimeType: 'application/json', name: fileName)],
    subject: 'Gold Gallery JSON backup',
  ));
  return 'shared';
}
