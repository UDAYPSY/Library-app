import 'dart:convert';
import 'dart:html' as html;

Future<bool> saveAndDownloadFile({
  required String fileName,
  required String content,
  required String mimeType,
  String? targetGoogleAccount,
}) async {
  try {
    // Prefix UTF-8 BOM so Microsoft Excel recognizes encoding immediately
    final bytes = utf8.encode('\uFEFF$content');
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    if (targetGoogleAccount != null && targetGoogleAccount.trim().isNotEmpty) {
      final cleanAccount = targetGoogleAccount.trim();
      final driveUrl = 'https://accounts.google.com/AccountChooser?Email=${Uri.encodeComponent(cleanAccount)}&continue=${Uri.encodeComponent("https://drive.google.com")}';
      html.window.open(driveUrl, '_blank');
    }
    return true;
  } catch (e) {
    return false;
  }
}
