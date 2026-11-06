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
    // Strictly isolate to Google Drive for the onboarding account.
    // DO NOT invoke the generic system share sheet that allows sharing via WhatsApp, Bluetooth, etc.
    if (targetGoogleAccount != null && targetGoogleAccount.trim().isNotEmpty) {
      final cleanAccount = targetGoogleAccount.trim();
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
            return true;
          }
        } catch (_) {
          // Native method channel call failed or in unit tests
        }

        // Fallback when Google Drive app is not installed or method channel fails:
        // Launch Google Drive web interface directly with account selector for the target onboarding email
        try {
          final driveUri = Uri.parse(
            'https://accounts.google.com/AccountChooser?Email=${Uri.encodeComponent(cleanAccount)}&continue=${Uri.encodeComponent("https://drive.google.com")}',
          );
          if (await canLaunchUrl(driveUri)) {
            await launchUrl(driveUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
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

