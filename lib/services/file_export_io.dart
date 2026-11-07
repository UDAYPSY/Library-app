import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Attempt direct write to public Android Download directory for permanent local offline copy
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

    // If targetGoogleAccount is specified, this is a Google Drive Master Backup:
    if (targetGoogleAccount != null && targetGoogleAccount.trim().isNotEmpty) {
      final cleanAccount = targetGoogleAccount.trim();
      bool directDriveSucceeded = false;
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.trackmylibrary.app/drive_backup');
          final dynamic result = await platform.invokeMethod('backupToGoogleDriveOnly', {
            'filePath': file.path,
            'fileName': fileName,
            'targetEmail': cleanAccount,
            'mimeType': mimeType,
          });
          if (result == true) {
            directDriveSucceeded = true;
          }
        } catch (_) {
          // Native method channel call failed or in unit tests
        }
      }

      // If direct Google Drive package intent was not triggered or device is non-Android,
      // invoke Share.shareXFiles so the user can tap "Save to Drive" directly with 100% reliability
      if (!directDriveSucceeded) {
        await Share.shareXFiles(
          [XFile(file.path, name: fileName, mimeType: mimeType)],
          subject: fileName,
          text: 'Save Master Backup to Google Drive ($cleanAccount)',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
      return true;
    }

    // For general non-Drive file exports (e.g. student CSVs, fee reports), invoke standard system share
    await Share.shareXFiles(
      [XFile(file.path, name: fileName, mimeType: mimeType)],
      subject: fileName,
      text: 'Exported file: $fileName',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
    return true;
  } catch (e) {
    return false;
  }
}

