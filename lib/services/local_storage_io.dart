import 'dart:convert';
import 'dart:io';

class LocalStoreImpl {
  static final Map<String, String> _memory = {};
  static bool _initialized = false;
  static File? _storageFile;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    try {
      Directory dir = Directory.systemTemp;
      if (Platform.isAndroid) {
        final prodDir = Directory('/data/data/com.trackmylibrary.app/files');
        final altProdDir = Directory('/data/user/0/com.trackmylibrary.app/files');
        final legacyDir = Directory('/data/data/com.example.library_manager/files');
        final altLegacyDir = Directory('/data/user/0/com.example.library_manager/files');

        if (await prodDir.exists()) {
          dir = prodDir;
        } else if (await altProdDir.exists()) {
          dir = altProdDir;
        } else if (await legacyDir.exists()) {
          dir = legacyDir;
        } else if (await altLegacyDir.exists()) {
          dir = altLegacyDir;
        }
      }
      _storageFile = File('${dir.path}/app_local_store.json');
      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        if (content.isNotEmpty) {
          final decoded = json.decode(content);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              _memory[k.toString()] = v.toString();
            });
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> saveString(String key, String value) async {
    await _ensureInit();
    _memory[key] = value;
    try {
      if (_storageFile != null) {
        await _storageFile!.writeAsString(json.encode(_memory));
      }
    } catch (_) {}
  }

  static Future<String?> getString(String key) async {
    await _ensureInit();
    return _memory[key];
  }

  static Future<void> remove(String key) async {
    await _ensureInit();
    _memory.remove(key);
    try {
      if (_storageFile != null) {
        await _storageFile!.writeAsString(json.encode(_memory));
      }
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    await _ensureInit();
    _memory.clear();
    try {
      if (_storageFile != null && await _storageFile!.exists()) {
        await _storageFile!.delete();
      }
    } catch (_) {}
  }
}
