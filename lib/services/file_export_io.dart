import 'dart:convert';
import 'dart:io';

Future<bool> saveAndDownloadFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    Directory? targetDir;
    if (Platform.isAndroid) {
      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        targetDir = androidDownload;
      }
    }
    targetDir ??= Directory.systemTemp;

    final file = File('${targetDir.path}/$fileName');
    final bytes = utf8.encode('\uFEFF$content');
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    return false;
  }
}
