import 'dart:html' as html;

class LocalStoreImpl {
  static Future<void> saveString(String key, String value) async {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static Future<String?> getString(String key) async {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}
