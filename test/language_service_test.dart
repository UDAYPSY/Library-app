import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/constants/app_strings.dart';
import 'package:library_manager/services/language_service.dart';
import 'package:library_manager/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset local storage for language key
    await LocalStorageService.saveString('app_language', 'en');
    await LanguageService().setLanguage(AppLanguage.en);
  });

  group('LanguageService & Localization Tests', () {
    test('Default language is English', () {
      final service = LanguageService();
      expect(service.currentLanguage, equals(AppLanguage.en));
      expect(service.isHindi, isFalse);
      expect(service.currentLanguageCode, equals('en'));
      expect(service.currentLanguageName, equals('English'));
    });

    test('Translations return English strings by default', () {
      final service = LanguageService();
      expect(service.t('nav_home'), equals('Home'));
      expect(service.t('nav_seats'), equals('Seats'));
      expect(service.t('collect_payment'), equals('Collect Payment'));
      expect(service.t('clear_due_only'), equals('Clear Due Only'));
    });

    test('Switching to Hindi updates language, notifies listeners and persists', () async {
      final service = LanguageService();
      bool notified = false;
      void listener() => notified = true;

      service.addListener(listener);

      await service.setLanguage(AppLanguage.hi);
      expect(service.currentLanguage, equals(AppLanguage.hi));
      expect(service.isHindi, isTrue);
      expect(service.currentLanguageCode, equals('hi'));
      expect(service.currentLanguageName, equals('हिंदी (Hindi)'));
      expect(notified, isTrue);

      // Verify persistence to LocalStorageService
      final saved = await LocalStorageService.getString('app_language');
      expect(saved, equals('hi'));

      // Check Hindi translations
      expect(service.t('nav_home'), equals('होम'));
      expect(service.t('nav_seats'), equals('सीटें'));
      expect(service.t('collect_payment'), equals('फीस जमा करें'));
      expect(service.t('clear_due_only'), equals('केवल बकाया जमा करें'));
      expect(service.t('space_grid'), equals('सीट व्यवस्था'));
      expect(service.t('management'), equals('प्रबंधन'));
      expect(service.t('find_student_or_seat'), equals('छात्र या सीट संख्या खोजें...'));
      expect(service.t('filled'), equals('भरी हुई'));
      expect(service.t('vacant'), equals('खाली'));
      expect(service.t('students'), equals('छात्र'));
      expect(service.t('total_seats_label'), equals('कुल सीटें'));
      expect(service.t('shift_label'), equals('शिफ्ट'));
      expect(service.t('status_label'), equals('स्थिति'));
      expect(service.t('dues_label'), equals('बकाया'));
      expect(service.t('paid'), equals('जमा'));
      expect(service.t('unpaid'), equals('बकाया'));
      expect(service.t('trial'), equals('ट्रायल'));
      expect(service.t('record_payment'), equals('भुगतान दर्ज करें'));
      expect(service.t('total_fee'), equals('कुल फीस'));
      expect(service.t('non_editable'), equals('अपरिवर्तनीय'));

      service.removeListener(listener);
    });

    test('toggleLanguage toggles between English and Hindi', () async {
      final service = LanguageService();
      expect(service.currentLanguage, equals(AppLanguage.en));

      await service.toggleLanguage();
      expect(service.currentLanguage, equals(AppLanguage.hi));

      await service.toggleLanguage();
      expect(service.currentLanguage, equals(AppLanguage.en));
    });

    test('Fallback handling for unknown keys', () {
      final service = LanguageService();
      expect(service.t('unknown_key_xyz', fallback: 'Default Text'), equals('Default Text'));
      expect(service.t('unknown_key_xyz'), equals('unknown_key_xyz'));
      expect(AppStrings.get('unknown_key_xyz', AppLanguage.en, fallback: 'Default Text'), equals('Default Text'));
    });
  });
}
