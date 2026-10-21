import 'dart:convert';
import 'dart:html' as html;

Future<bool> saveAndDownloadFile({
  required String fileName,
  required String content,
  required String mimeType,
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
    return true;
  } catch (e) {
    return false;
  }
}
