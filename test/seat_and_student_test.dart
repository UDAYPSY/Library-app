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

  group('Seat Allocation and Student Management Tests', () {
    test('Phone normalization handles various Indian format inputs', () {
      expect(LibraryService.normalizePhone('9876543210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('+91 98765 43210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('+91-98765-43210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('09876543210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('919876543210'), equals('9876543210'));
    });

    test('Duplicate phone detection across active students', () {
      final student = StudentInfo(
        id: 'std_dup_1',
        name: 'Amit Patel',
        phone: '9876512345',
        shift: 'Full Day',
        seatNumber: 3,
        monthlyFee: 800,
        status: 'Active',
      );
      service.addStudent(student);

      // Testing duplicate checks
      expect(service.isDuplicateStudentPhone('9876512345'), isTrue);
      expect(service.isDuplicateStudentPhone('+91 98765-12345'), isTrue);
      expect(service.isDuplicateStudentPhone('09876512345'), isTrue);

      // During edit, excluding self should return false
      expect(service.isDuplicateStudentPhone('9876512345', excludeStudentId: 'std_dup_1'), isFalse);

      // Unique phone should return false
      expect(service.isDuplicateStudentPhone('9123456789'), isFalse);
    });

    test('Seat collision check and student association', () {
      final seatNum = 8;
      final student = StudentInfo(
        id: 'std_seat_8',
        name: 'Kavita Roy',
        phone: '9786543210',
        shift: 'Morning',
        seatNumber: seatNum,
        monthlyFee: 600,
        status: 'Active',
      );
      service.addStudent(student);

      expect(service.isSeatOccupied(seatNum), isTrue);

      final occupant = service.getStudentForSeat(seatNum);
      expect(occupant, isNotNull);
      expect(occupant!.name, equals('Kavita Roy'));
      expect(occupant!.phone, equals('9786543210'));
    });
  });
}
