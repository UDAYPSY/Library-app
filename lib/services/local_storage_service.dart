import 'local_storage_stub.dart'
    if (dart.library.html) 'local_storage_web.dart'
    if (dart.library.io) 'local_storage_io.dart';

class LocalStorageService {
  static Future<void> saveString(String key, String value) =>
      LocalStoreImpl.saveString(key, value);

  static Future<String?> getString(String key) =>
      LocalStoreImpl.getString(key);

  static Future<void> remove(String key) =>
      LocalStoreImpl.remove(key);

  static Future<void> clearAll() =>
      LocalStoreImpl.clearAll();
}
