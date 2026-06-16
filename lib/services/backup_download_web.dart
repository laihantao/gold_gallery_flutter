// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> saveJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  final blob = html.Blob([jsonBytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none'
      ..click();
    return 'downloaded';
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}

/// Web has no share sheet — fall back to the same download trigger.
Future<String> shareJsonBackupFile(String fileName, Uint8List jsonBytes) async {
  return await saveJsonBackupFile(fileName, jsonBytes) ?? 'downloaded';
}
