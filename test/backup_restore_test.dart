import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryService service;

  setUp(() {
    service = LibraryService();
    service.ensureInitialized();
  });

  group('Database Full Backup and Disaster Recovery Tests', () {
    test('exportFullBackupJson generates valid JSON schema with all entities', () {
      final jsonString = service.exportFullBackupJson();
      expect(jsonString, isNotEmpty);

      final decoded = json.decode(jsonString);
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['app'], equals('TrackMyLibrary'));
      expect(decoded['version'], equals('2.0.0'));
      expect(decoded['profile'], isNotNull);
      expect(decoded['sections'], isList);
      expect(decoded['shifts'], isList);
      expect(decoded['branches'], isList);
      expect(decoded['staff'], isList);
      expect(decoded['students'], isList);
      expect(decoded['payments'], isList);
      expect(decoded['expenses'], isList);
      expect(decoded['stats'], isNotNull);
    });

    test('restoreFromBackupJson rehydrates complete state safely', () async {
      final sampleBackup = {
        'app': 'TrackMyLibrary',
        'version': '2.0.0',
        'exported_at': '2026-10-21T12:00:00.000Z',
        'profile': {
          'library_name': 'Restored Elite Library',
          'city': 'Varanasi Central',
          'admin_name': 'Prof. Anand',
          'admin_phone': '9876500000',
        },
        'sections': [
          {'id': 'sec_res_1', 'name': 'First Floor', 'start_seat': 1, 'end_seat': 20}
        ],
        'shifts': [
          {
            'id': 'shift_res_1',
            'name': '24 Hours VIP',
            'starts_at': '12:00 AM',
            'ends_at': '11:59 PM',
            'monthly_fee': 1800,
            'is_active': true,
          }
        ],
        'branches': [
          {'id': 'br_res_1', 'name': 'Varanasi Campus', 'address': 'Lanka, Varanasi', 'total_seats': 20}
        ],
        'staff': [
          {'id': 'st_res_1', 'name': 'Ankit Desk', 'phone': '9876511111', 'role': 'Receptionist & Desk'}
        ],
        'students': [
          {
            'id': 'std_res_1',
            'name': 'Deepak Verma',
            'phone': '9876522222',
            'seat_number': 2,
            'shift': '24 Hours VIP',
            'status': 'Active',
            'monthly_fee': 1800,
            'dues_amount': 0,
          }
        ],
        'payments': [
          {
            'payment_id': 'pmt_res_1',
            'student_id': 'std_res_1',
            'student_name': 'Deepak Verma',
            'amount': 1800,
            'payment_mode': 'UPI',
            'date': '2026-10-21T10:00:00.000Z',
          }
        ],
        'expenses': [
          {
            'id': 'exp_res_1',
            'title': 'Newspaper Subscription',
            'category': 'Books',
            'amount': 450,
            'payment_mode': 'Cash',
            'date': '2026-10-21T09:00:00.000Z',
          }
        ],
      };

      final result = await service.restoreFromBackupJson(json.encode(sampleBackup));
      expect(result['success'], isTrue);
      expect(result['students'], equals(1));
      expect(result['payments'], equals(1));
      expect(result['expenses'], equals(1));

      // Verify rehydrated state
      expect(service.profile.libraryName, equals('Restored Elite Library'));
      expect(service.profile.city, equals('Varanasi Central'));
      expect(service.isSeatOccupied(2), isTrue);

      final student = service.findStudentByPhone('9876522222');
      expect(student, isNotNull);
      expect(student!.name, equals('Deepak Verma'));
    });

    test('restoreFromBackupJson handles invalid input gracefully', () async {
      final resultBad = await service.restoreFromBackupJson('not valid json at all');
      expect(resultBad['success'], isFalse);
      expect(resultBad['error'], isNotNull);
    });
  });
}
