import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveAndDownloadFile({
  required String fileName,
  required String content,
  required String mimeType,
  String? targetGoogleAccount,
}) async {
  try {
    Directory? targetDir;
    try {
      targetDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      targetDir = Directory.systemTemp;
    }

    final bytes = utf8.encode('\uFEFF$content');

    // Attempt direct write to public Android Download directory
    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          final publicFile = File('${publicDownload.path}/$fileName');
          await publicFile.writeAsBytes(bytes);
        }
      } catch (_) {}
      try {
        final externalDownloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (externalDownloads != null && externalDownloads.isNotEmpty) {
          final extFile = File('${externalDownloads.first.path}/$fileName');
          await extFile.writeAsBytes(bytes);
        }
      } catch (_) {}
    }

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final shareSubject = targetGoogleAccount != null && targetGoogleAccount.isNotEmpty
        ? 'TrackMyLibrary Master Backup -> $targetGoogleAccount'
        : fileName;
    final shareText = targetGoogleAccount != null && targetGoogleAccount.isNotEmpty
        ? 'Master Disaster Recovery Backup strictly bound to Google Drive: $targetGoogleAccount. Upload only to this designated drive.'
        : 'Exported file: $fileName';

    // Invoke system Share / Export dialog to allow user to Save to Device, Open in Excel, or Share
    await Share.shareXFiles(
      [XFile(file.path, name: fileName, mimeType: mimeType)],
      subject: shareSubject,
      text: shareText,
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
    return true;
  } catch (e) {
    return false;
  }
}
