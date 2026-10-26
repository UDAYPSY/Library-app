import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// To connect your own live Firebase project:
/// 1. Go to https://console.firebase.google.com/
/// 2. Create a project and register an Android app (package: com.trackmylibrary.app)
///    or Web app.
/// 3. Replace the placeholder values below with your credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Returns true once valid Firebase credentials have been supplied.
  static bool get isConfigured {
    return android.apiKey != 'AIzaSyDemoPlaceholderKeyForBuild000000' &&
        android.projectId != 'demo-library-project';
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMuQVapymALYnE3jJDbHM4hINLX6fAotU',
    appId: '1:984519580974:web:a497c0a098c52ff694eebf',
    messagingSenderId: '984519580974',
    projectId: 'trackmylib-171b7',
    authDomain: 'trackmylib-171b7.firebaseapp.com',
    storageBucket: 'trackmylib-171b7.firebasestorage.app',
    measurementId: 'G-VVQ884B8RB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtB6XKqzqYJgcJ26G6_vOwudqW5Ox2E9s',
    appId: '1:984519580974:android:28f76102d394eff794eebf',
    messagingSenderId: '984519580974',
    projectId: 'trackmylib-171b7',
    storageBucket: 'trackmylib-171b7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMuQVapymALYnE3jJDbHM4hINLX6fAotU',
    appId: '1:984519580974:ios:a497c0a098c52ff694eebf',
    messagingSenderId: '984519580974',
    projectId: 'trackmylib-171b7',
    storageBucket: 'trackmylib-171b7.firebasestorage.app',
    iosBundleId: 'com.trackmylibrary.app',
  );
}
