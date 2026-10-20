import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// To connect your own live Firebase project:
/// 1. Go to https://console.firebase.google.com/
/// 2. Create a project and register an Android app (package: com.example.library_manager)
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
    apiKey: 'AIzaSyDemoPlaceholderKeyForBuild000000',
    appId: '1:100000000000:web:demo000000000000000000',
    messagingSenderId: '100000000000',
    projectId: 'demo-library-project',
    authDomain: 'demo-library-project.firebaseapp.com',
    storageBucket: 'demo-library-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderKeyForBuild000000',
    appId: '1:100000000000:android:demo000000000000000000',
    messagingSenderId: '100000000000',
    projectId: 'demo-library-project',
    storageBucket: 'demo-library-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderKeyForBuild000000',
    appId: '1:100000000000:ios:demo000000000000000000',
    messagingSenderId: '100000000000',
    projectId: 'demo-library-project',
    storageBucket: 'demo-library-project.appspot.com',
    iosBundleId: 'com.example.libraryManager',
  );
}
