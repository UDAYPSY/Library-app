import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/constants/app_colors.dart';
import 'package:library_manager/constants/app_theme.dart';
import 'package:library_manager/services/local_storage_service.dart';
import 'package:library_manager/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset local storage for theme key
    await LocalStorageService.saveString('app_theme_mode', 'Light');
    await ThemeService().setThemeMode(ThemeMode.light);
  });

  group('ThemeService Tests', () {
    test('Default ThemeMode is Light and themeModeName is Light', () {
      final service = ThemeService();
      expect(service.themeMode, equals(ThemeMode.light));
      expect(service.themeModeName, equals('Light'));
    });

    test('setThemeMode updates themeMode and notifies listeners', () async {
      final service = ThemeService();
      bool notified = false;
      void listener() => notified = true;

      service.addListener(listener);

      await service.setThemeMode(ThemeMode.dark);
      expect(service.themeMode, equals(ThemeMode.dark));
      expect(service.themeModeName, equals('Dark'));
      expect(notified, isTrue);

      // Verify persistence to LocalStorageService
      final saved = await LocalStorageService.getString('app_theme_mode');
      expect(saved, equals('Dark'));

      // Switch to System
      notified = false;
      await service.setThemeMode(ThemeMode.system);
      expect(service.themeMode, equals(ThemeMode.system));
      expect(service.themeModeName, equals('System'));
      expect(notified, isTrue);

      final savedSystem = await LocalStorageService.getString('app_theme_mode');
      expect(savedSystem, equals('System'));

      // Switch back to Light
      notified = false;
      await service.setThemeMode(ThemeMode.light);
      expect(service.themeMode, equals(ThemeMode.light));
      expect(service.themeModeName, equals('Light'));
      expect(notified, isTrue);

      final savedLight = await LocalStorageService.getString('app_theme_mode');
      expect(savedLight, equals('Light'));

      service.removeListener(listener);
    });
  });

  group('AppTheme Specifications', () {
    test('lightTheme has correct brightness and Material 3 flags', () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, equals(Brightness.light));
      expect(light.useMaterial3, isTrue);
      expect(light.scaffoldBackgroundColor, equals(AppColors.scaffoldBg));
      expect(light.cardColor, equals(AppColors.cardWhite));
    });

    test('darkTheme has correct brightness and Slate dark tokens', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, equals(Brightness.dark));
      expect(dark.useMaterial3, isTrue);
      expect(dark.scaffoldBackgroundColor, equals(AppColors.darkScaffoldBg));
      expect(dark.cardColor, equals(AppColors.darkCardBg));
    });
  });

  group('Dynamic AppColors Adaptive Helpers', () {
    testWidgets('AppColors returns light tokens in light mode', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('Light Mode Test'));
            },
          ),
        ),
      );

      expect(AppColors.isDark(capturedContext), isFalse);
      expect(AppColors.scaffold(capturedContext), equals(AppColors.scaffoldBg));
      expect(AppColors.card(capturedContext), equals(AppColors.cardWhite));
      expect(AppColors.cardBorderColor(capturedContext), equals(AppColors.cardBorder));
      expect(AppColors.text(capturedContext), equals(AppColors.textNavy));
      expect(AppColors.textMutedColor(capturedContext), equals(AppColors.textMuted));
      expect(AppColors.textSubtleColor(capturedContext), equals(AppColors.textSubtle));
      expect(AppColors.subSurface(capturedContext), equals(const Color(0xFFF1F5F9)));
      expect(AppColors.inputBg(capturedContext), equals(const Color(0xFFFBFDFF)));
      expect(AppColors.inputBorderColor(capturedContext), equals(AppColors.inputBorder));
      expect(AppColors.divider(capturedContext), equals(const Color(0xFFF1F5F9)));
    });

    testWidgets('AppColors returns dark tokens in dark mode', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('Dark Mode Test'));
            },
          ),
        ),
      );

      expect(AppColors.isDark(capturedContext), isTrue);
      expect(AppColors.scaffold(capturedContext), equals(AppColors.darkScaffoldBg));
      expect(AppColors.card(capturedContext), equals(AppColors.darkCardBg));
      expect(AppColors.cardBorderColor(capturedContext), equals(AppColors.darkCardBorder));
      expect(AppColors.text(capturedContext), equals(AppColors.darkTextPrimary));
      expect(AppColors.textMutedColor(capturedContext), equals(AppColors.darkTextMuted));
      expect(AppColors.textSubtleColor(capturedContext), equals(AppColors.darkTextSubtle));
      expect(AppColors.subSurface(capturedContext), equals(AppColors.darkSubSurface));
      expect(AppColors.inputBg(capturedContext), equals(AppColors.darkInputBg));
      expect(AppColors.inputBorderColor(capturedContext), equals(AppColors.darkInputBorder));
      expect(AppColors.divider(capturedContext), equals(AppColors.darkDivider));
    });

    testWidgets('ThemeService.isDarkMode resolves correctly across modes', (tester) async {
      final service = ThemeService();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      // Light mode forced
      await tester.runAsync(() async {
        await service.setThemeMode(ThemeMode.light);
      });
      expect(service.isDarkMode(capturedContext), isFalse);

      // Dark mode forced
      await tester.runAsync(() async {
        await service.setThemeMode(ThemeMode.dark);
      });
      expect(service.isDarkMode(capturedContext), isTrue);
    });
  });
}
