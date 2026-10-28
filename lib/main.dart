import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/welcome_carousel_screen.dart';
import 'screens/public/student_self_registration_screen.dart';
import 'screens/tools/student_live_portal_screen.dart';
import 'services/disaster_recovery_service.dart';
import 'services/library_service.dart';

import 'constants/app_theme.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Crashlytics & Error Boundary Guard
  FlutterError.onError = (FlutterErrorDetails details) {
    if (Firebase.apps.isNotEmpty) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (_) {}
    }
    debugPrint('TrackMyLibrary Resilient UI Guard: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (Firebase.apps.isNotEmpty) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    }
    return true;
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

    // Task 1.6: Firebase App Check activation
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
          webProvider: ReCaptchaV3Provider('6Ld_placeholder_recaptcha_site_key'),
        );
      } catch (e) {
        debugPrint('Firebase App Check activation note: $e');
      }
    }

    // Task 1.2: Check active FirebaseAuth user for auto-login session
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final svc = LibraryService();
      svc.currentUserId = currentUser.uid;
      svc.profile.libraryId = currentUser.uid;
      svc.currentUserEmail = currentUser.email ?? '';
      svc.currentUserRole = 'Admin';
      svc.isAuthenticated = true;
      DisasterRecoveryService(service: svc).runAutomatedBackupCycle();
    }
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }

  runApp(const TrackMyLibraryApp());
}

class TrackMyLibraryApp extends StatelessWidget {
  const TrackMyLibraryApp({super.key});

  static String determineInitialRoute() {
    try {
      final frag = Uri.base.fragment;
      final path = Uri.base.path;
      final query = Uri.base.queryParameters;
      if (frag.contains('portal') || path.endsWith('/portal') || query.containsKey('verify')) {
        return '/portal';
      }
      if (frag.contains('join') || frag.contains('register') || path.endsWith('/join') || path.endsWith('/register')) {
        return '/join';
      }
    } catch (_) {}
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        final initial = determineInitialRoute();
        return MaterialApp(
          title: 'Track My Library',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          initialRoute: initial,
          onGenerateInitialRoutes: (initialRoute) {
            final target = determineInitialRoute();
            if (target == '/portal') {
              return [MaterialPageRoute(builder: (_) => const StudentLivePortalScreen())];
            }
            if (target == '/join') {
              return [MaterialPageRoute(builder: (_) => const StudentSelfRegistrationScreen())];
            }
            return [MaterialPageRoute(builder: (_) => const LoginScreen())];
          },
          routes: {
            '/': (context) => const LoginScreen(),
            '/onboarding': (context) => const WelcomeCarouselScreen(),
            '/portal': (context) => const StudentLivePortalScreen(),
            '/join': (context) => const StudentSelfRegistrationScreen(),
            '/register': (context) => const StudentSelfRegistrationScreen(),
          },
          onGenerateRoute: (settings) {
            final name = settings.name ?? '/';
            final uri = Uri.parse(name.startsWith('/') ? name : '/$name');
            if (uri.path == '/portal' || uri.path.endsWith('/portal')) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const StudentLivePortalScreen(),
              );
            }
            if (uri.path == '/join' || uri.path == '/register' || uri.path.endsWith('/join') || uri.path.endsWith('/register')) {
              final libId = uri.queryParameters['lib'];
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => StudentSelfRegistrationScreen(libraryId: libId),
              );
            }
            if (uri.path == '/onboarding') {
              return MaterialPageRoute(settings: settings, builder: (_) => const WelcomeCarouselScreen());
            }
            return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
          },
        );
      },
    );
  }
}