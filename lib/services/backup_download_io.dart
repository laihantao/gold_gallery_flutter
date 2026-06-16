import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves [jsonBytes] directly to device storage. Returns the saved path, or
/// null if the write failed (caller may then fall back or show an error).
Future<String?> saveJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  try {
    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(jsonBytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// Opens the OS share sheet so the user can choose where to send the file.
Future<String> shareJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(jsonBytes, mimeType: 'application/json', name: fileName)],
    subject: 'Gold Gallery JSON backup',
  ));
  return 'shared';
}

Future<Directory> _getSaveDirectory() async {
  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext;
  }
  return getApplicationDocumentsDirectory();
}
