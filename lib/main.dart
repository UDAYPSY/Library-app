import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseReady = false;
  String? firebaseError;

  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseReady = true;
    } else {
      // Try initializing with native configuration (google-services.json) if present
      try {
        await Firebase.initializeApp();
        isFirebaseReady = true;
      } catch (_) {
        // Safe fallback: project credentials not yet supplied in firebase_options.dart
        firebaseError =
            'Firebase credentials not yet configured. Running in preview mode. Update lib/firebase_options.dart with your Firebase project keys to enable cloud sync.';
      }
    }
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(LibraryApp(
    isFirebaseReady: isFirebaseReady,
    firebaseError: firebaseError,
  ));
}

class LibraryApp extends StatelessWidget {
  final bool isFirebaseReady;
  final String? firebaseError;

  const LibraryApp({
    super.key,
    this.isFirebaseReady = false,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Seat Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: DashboardScreen(
        isFirebaseReady: isFirebaseReady,
        firebaseError: firebaseError,
      ),
    );
  }
}