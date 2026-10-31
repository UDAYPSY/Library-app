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

  static Future<void> clearAll() async {
    try {
      final keysToRemove = <String>[];
      for (final key in html.window.localStorage.keys) {
        if (!key.startsWith('firebase:') && !key.startsWith('__firebase')) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        html.window.localStorage.remove(key);
      }
    } catch (_) {}
  }

  static void reloadWindow() {
    try {
      html.window.location.reload();
    } catch (_) {}
  }
}
