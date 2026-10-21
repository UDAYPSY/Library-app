import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/services/excel_import_service.dart';
import 'package:library_manager/services/library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryService service;

  setUp(() async {
    service = LibraryService();
    service.ensureInitialized();
    await service.clearAllData();
  });

  group('Excel & CSV Spreadsheet Import Tests', () {
    test('generateTemplateCsv outputs standard valid CSV header', () {
      final template = ExcelImportService.generateTemplateCsv();
      expect(template, contains('Full Name'));
      expect(template, contains('Phone Number'));
      expect(template, contains('Shift'));
      expect(template, contains('Seat Number'));
      expect(template, contains('Monthly Fee'));
    });

    test('parseAndImport successfully parses standard CSV rows', () {
      const csvInput = '''
Full Name,Phone Number,Shift,Seat Number,Monthly Fee,Father Name,Address
Vikram Seth,9871122334,Full Day,,800,Rajendra Seth,Patna
Meera Joshi,9872233445,Evening,,600,Kailash Joshi,Kankarbagh
''';

      final initialCount = service.currentStudents.length;
      final result = ExcelImportService.parseAndImport(csvInput, service);

      expect(result.successfullyImported, equals(2));
      expect(result.errorMessages, isEmpty);
      expect(service.currentStudents.length, equals(initialCount + 2));

      final vikram = service.findStudentByPhone('9871122334');
      expect(vikram, isNotNull);
      expect(vikram!.name, equals('Vikram Seth'));
      expect(vikram.shift, equals('Full Day'));
      expect(vikram.monthlyFee, equals(800));

      final meera = service.findStudentByPhone('9872233445');
      expect(meera, isNotNull);
      expect(meera!.name, equals('Meera Joshi'));
      expect(meera.shift, equals('Evening'));
    });

    test('parseAndImport handles Tab-Separated Values (TSV) directly from Microsoft Excel', () {
      final tsvInput = 'Full Name\tPhone Number\tShift\tSeat Number\tMonthly Fee\n'
          'Arjun Kapoor\t9873344556\tMorning\t\t500\n';

      final result = ExcelImportService.parseAndImport(tsvInput, service);
      expect(result.successfullyImported, equals(1));

      final arjun = service.findStudentByPhone('9873344556');
      expect(arjun, isNotNull);
      expect(arjun!.name, equals('Arjun Kapoor'));
      expect(arjun.shift, equals('Morning'));
    });

    test('parseAndImport records errors for invalid rows', () {
      const badInput = '''
Full Name,Phone Number,Shift,Seat Number,Monthly Fee
,9870000000,Full Day,,800
Invalid Phone Student,1234,Full Day,,800
''';

      final result = ExcelImportService.parseAndImport(badInput, service);
      expect(result.successfullyImported, equals(0));
      expect(result.errorMessages.length, equals(2));
      expect(result.errorMessages[0], contains('Student name is missing'));
      expect(result.errorMessages[1], contains('Phone number must have at least 10 digits'));
    });
  });
}
