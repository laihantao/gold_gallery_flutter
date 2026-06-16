import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  try {
    final dir = await _getSaveDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(jsonBytes, flush: true);
    return file.path;
  } catch (_) {
    return _shareJsonBackup(fileName, jsonBytes);
  }
}

Future<Directory> _getSaveDirectory() async {
  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext;
  }
  return getApplicationDocumentsDirectory();
}

Future<String> _shareJsonBackup(String fileName, Uint8List jsonBytes) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(jsonBytes, mimeType: 'application/json', name: fileName)],
    subject: 'Gold Gallery JSON backup',
    text: 'Gold Gallery JSON backup export',
  ));

  return 'shared';
}
