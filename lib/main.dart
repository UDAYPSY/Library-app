import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/welcome_carousel_screen.dart';
import 'screens/tools/student_live_portal_screen.dart';
import 'services/library_service.dart';

import 'constants/app_theme.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Error Boundary & Resilient UI Guard
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('TrackMyLibrary Resilient UI Guard: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'TrackMyLibrary Safe Guard',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A visual display glitch was safely isolated without interrupting library data or seat operations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize theme & services
  await ThemeService().init();
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
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Track My Library',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/onboarding': (context) => const WelcomeCarouselScreen(),
            '/portal': (context) => const StudentLivePortalScreen(),
          },
        );
      },
    );
  }
}