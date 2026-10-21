import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/tools/student_live_portal_screen.dart';
import 'services/library_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service in-memory baseline
  LibraryService().ensureInitialized();

  // Safe Firebase Initialization
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        debugPrint('Running in high-fidelity preview mode.');
      }
    }
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }

  runApp(const TrackMyLibraryApp());
}

class TrackMyLibraryApp extends StatelessWidget {
  const TrackMyLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track My Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          primary: AppColors.primaryTeal,
          secondary: AppColors.mintAccent,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textNavy,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/portal': (context) => const StudentLivePortalScreen(),
      },
    );
  }
}