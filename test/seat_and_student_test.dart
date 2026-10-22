import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryService service;

  setUp(() async {
    service = LibraryService();
    service.ensureInitialized();
    await service.clearAllData();
  });

  group('Seat Allocation and Student Management Tests', () {
    test('Phone normalization handles various Indian format inputs', () {
      expect(LibraryService.normalizePhone('9876543210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('+91 98765 43210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('+91-98765-43210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('09876543210'), equals('9876543210'));
      expect(LibraryService.normalizePhone('919876543210'), equals('9876543210'));
    });

    test('Duplicate phone detection across active students', () async {
      final student = StudentInfo(
        id: 'std_dup_1',
        name: 'Amit Patel',
        phone: '9876512345',
        shift: 'Full Day',
        seatNumber: 3,
        monthlyFee: 800,
        status: 'Active',
      );
      await service.addStudent(student);

      // Testing duplicate checks
      expect(service.isDuplicateStudentPhone('9876512345'), isTrue);
      expect(service.isDuplicateStudentPhone('+91 98765-12345'), isTrue);
      expect(service.isDuplicateStudentPhone('09876512345'), isTrue);

      // During edit, excluding self should return false
      expect(service.isDuplicateStudentPhone('9876512345', excludeStudentId: 'std_dup_1'), isFalse);

      // Unique phone should return false
      expect(service.isDuplicateStudentPhone('9123456789'), isFalse);
    });

    test('Seat collision check and student association', () async {
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
      await service.addStudent(student);

      expect(service.isSeatOccupied(seatNum), isTrue);

      final occupant = service.getStudentForSeat(seatNum);
      expect(occupant, isNotNull);
      expect(occupant!.name, equals('Kavita Roy'));
      expect(occupant!.phone, equals('9786543210'));
    });

    test('Shift conflict rules detect overlapping vs non-overlapping shifts', () {
      // Non-overlapping shifts can share the same seat
      expect(LibraryService.doShiftsConflict('Morning Shift', 'Evening Shift'), isFalse);
      expect(LibraryService.doShiftsConflict('Morning Shift', 'Night Shift'), isFalse);
      expect(LibraryService.doShiftsConflict('Evening Shift', 'Night Shift'), isFalse);

      // Same shifts conflict
      expect(LibraryService.doShiftsConflict('Morning Shift', 'Morning Shift'), isTrue);
      expect(LibraryService.doShiftsConflict('Evening Shift', 'Evening Shift'), isTrue);

      // Full Day and 24 Hours conflict with all other shifts
      expect(LibraryService.doShiftsConflict('Full Day', 'Morning Shift'), isTrue);
      expect(LibraryService.doShiftsConflict('Morning Shift', 'Full Day'), isTrue);
      expect(LibraryService.doShiftsConflict('24 Hours', 'Evening Shift'), isTrue);
    });

    test('Shift-wise seat allocation allows different students in different shifts on same seat', () async {
      final seatNum = 12;

      // Register Student 1 in Morning Shift on Seat 12
      await service.assignSeatAndRegisterStudent(
        seatNumber: seatNum,
        studentName: 'Rahul Sharma',
        phone: '9876500001',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
      );

      // Seat 12 is occupied in Morning Shift
      expect(service.isSeatOccupied(seatNum, shift: 'Morning Shift'), isTrue);
      // Seat 12 is NOT occupied in Evening Shift
      expect(service.isSeatOccupied(seatNum, shift: 'Evening Shift'), isFalse);

      // Register Student 2 in Evening Shift on same Seat 12 -> should succeed!
      await service.assignSeatAndRegisterStudent(
        seatNumber: seatNum,
        studentName: 'Priya Verma',
        phone: '9876500002',
        shift: 'Evening Shift',
        deviceUserId: 'Admin',
      );

      // Both students successfully occupy Seat 12 in their respective shifts
      final morningStudent = service.getStudentForSeat(seatNum, shift: 'Morning Shift');
      final eveningStudent = service.getStudentForSeat(seatNum, shift: 'Evening Shift');
      expect(morningStudent?.name, equals('Rahul Sharma'));
      expect(eveningStudent?.name, equals('Priya Verma'));

      // Trying to assign a 3rd student in Morning Shift on Seat 12 should throw collision exception
      expect(
        () async => await service.assignSeatAndRegisterStudent(
          seatNumber: seatNum,
          studentName: 'Aman Gupta',
          phone: '9876500003',
          shift: 'Morning Shift',
          deviceUserId: 'Admin',
        ),
        throwsException,
      );

      // Trying to assign Full Day on Seat 12 should throw collision exception because shifts conflict
      expect(
        () async => await service.assignSeatAndRegisterStudent(
          seatNumber: seatNum,
          studentName: 'Vikram Singh',
          phone: '9876500004',
          shift: 'Full Day',
          deviceUserId: 'Admin',
        ),
        throwsException,
      );
    });
  });
}
