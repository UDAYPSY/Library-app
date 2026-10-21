import 'file_export_stub.dart'
    if (dart.library.html) 'file_export_web.dart'
    if (dart.library.io) 'file_export_io.dart';

class FileExportService {
  /// Triggers a native file download or save on the user's platform.
  /// On Web: Prompts browser download of the file.
  /// On Android: Writes to the Download directory.
  static Future<bool> download({
    required String fileName,
    required String content,
    String mimeType = 'text/csv;charset=utf-8',
  }) async {
    return await saveAndDownloadFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
    );
  }
}
