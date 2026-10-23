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

    test('Multi-month advance registration calculates duration, total fee and validUntil', () async {
      final monthlyFee = 500;
      final durationMonths = 5;
      final expectedTotal = monthlyFee * durationMonths; // 2500

      await service.assignSeatAndRegisterStudent(
        seatNumber: 15,
        studentName: 'Neha Kumari',
        phone: '9876599991',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        monthlyFee: monthlyFee,
        feeAmount: expectedTotal,
        duesAmount: 0,
        durationMonths: durationMonths,
        status: 'ACTIVE',
      );

      final student = service.findStudentByPhone('9876599991');
      expect(student, isNotNull);
      expect(student!.monthlyFee, equals(monthlyFee));
      expect(student.duesAmount, equals(0));
      expect(student.status, equals('ACTIVE'));
      expect(student.feeDueDate, isNotNull);
      final differenceDays = student.feeDueDate!.difference(DateTime.now()).inDays;
      expect(differenceDays, greaterThanOrEqualTo(145));
    });

    test('Payment status determination for Full Paid, Partial Paid, and Unpaid', () async {
      // 1. Full Paid: Amount Paid == Total Fee -> Status ACTIVE, Dues 0
      await service.assignSeatAndRegisterStudent(
        seatNumber: 16,
        studentName: 'Sanjay Kumar',
        phone: '9876599992',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        feeAmount: 1000,
        duesAmount: 0,
        status: 'ACTIVE',
      );
      final fullPaid = service.findStudentByPhone('9876599992');
      expect(fullPaid, isNotNull);
      expect(fullPaid!.duesAmount, equals(0));
      expect(fullPaid.status, equals('ACTIVE'));

      // 2. Partial Paid: 0 < Amount Paid < Total Fee -> Status DUES, Dues > 0
      await service.assignSeatAndRegisterStudent(
        seatNumber: 17,
        studentName: 'Rohan Mehra',
        phone: '9876599993',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        feeAmount: 300,
        duesAmount: 200,
        status: 'DUES',
      );
      final partialPaid = service.findStudentByPhone('9876599993');
      expect(partialPaid, isNotNull);
      expect(partialPaid!.duesAmount, equals(200));
      expect(partialPaid.status, equals('DUES'));

      // 3. Unpaid: Amount Paid == 0 -> Status DUES, Dues == Total Fee
      await service.assignSeatAndRegisterStudent(
        seatNumber: 18,
        studentName: 'Divya Sharma',
        phone: '9876599994',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        feeAmount: 0,
        duesAmount: 500,
        status: 'DUES',
      );
      final unpaid = service.findStudentByPhone('9876599994');
      expect(unpaid, isNotNull);
      expect(unpaid!.duesAmount, equals(500));
      expect(unpaid.status, equals('DUES'));
    });

    test('Vacating a student frees seat ONLY for that shift, preserving other shift occupant', () async {
      final seatNum = 20;

      // Register Student M in Morning Shift
      await service.assignSeatAndRegisterStudent(
        seatNumber: seatNum,
        studentName: 'Manish Pandey',
        phone: '9876588881',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        studentId: 'std_test_m',
      );
      final stdM = service.findStudentByPhone('9876588881')!;

      // Register Student E in Evening Shift on same seat
      await service.assignSeatAndRegisterStudent(
        seatNumber: seatNum,
        studentName: 'Esha Gupta',
        phone: '9876588882',
        shift: 'Evening Shift',
        deviceUserId: 'Admin',
        studentId: 'std_test_e',
      );
      final stdE = service.findStudentByPhone('9876588882')!;

      expect(service.isSeatOccupied(seatNum, shift: 'Morning Shift'), isTrue);
      expect(service.isSeatOccupied(seatNum, shift: 'Evening Shift'), isTrue);

      // Vacate Morning Shift occupant
      await service.vacateSeat(seatNum, stdM.id);

      // Morning shift should now be vacant
      expect(service.isSeatOccupied(seatNum, shift: 'Morning Shift'), isFalse);
      expect(service.getStudentForSeat(seatNum, shift: 'Morning Shift'), isNull);

      // Evening shift should REMAIN occupied by Student E!
      expect(service.isSeatOccupied(seatNum, shift: 'Evening Shift'), isTrue);
      final eveningOccupant = service.getStudentForSeat(seatNum, shift: 'Evening Shift');
      expect(eveningOccupant?.id, equals(stdE.id));
      expect(eveningOccupant?.name, equals('Esha Gupta'));
    });

    test('Marking dues and fee payment reconciliation', () async {
      await service.assignSeatAndRegisterStudent(
        seatNumber: 22,
        studentName: 'Kunal Kapoor',
        phone: '9876577771',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        feeAmount: 500,
        duesAmount: 0,
        status: 'ACTIVE',
      );
      final std = service.findStudentByPhone('9876577771')!;

      // Mark dues of ₹300
      await service.markStudentDues(std.id, 300);
      var updated = service.findStudentByPhone('9876577771');
      expect(updated?.duesAmount, equals(300));
      expect(updated?.status, equals('DUES'));

      // Record payment of ₹300 -> should reconcile dues to 0 and set status ACTIVE
      await service.recordPayment(
        studentId: std.id,
        studentName: std.name,
        phone: std.phone,
        seatNumber: 22,
        shift: 'Morning Shift',
        amount: 300,
        paymentMode: 'UPI',
      );

      updated = service.findStudentByPhone('9876577771');
      expect(updated?.duesAmount, equals(0));
      expect(updated?.status, equals('ACTIVE'));
    });

    test('Assign seat to existing student works smoothly', () async {
      await service.assignSeatAndRegisterStudent(
        seatNumber: 25,
        studentName: 'Aman Verma',
        phone: '9876566661',
        shift: 'Morning Shift',
        deviceUserId: 'Admin',
        feeAmount: 600,
        duesAmount: 0,
        status: 'ACTIVE',
      );
      final aman = service.findStudentByPhone('9876566661')!;
      expect(aman.seatNumber, equals(25));

      // Re-assign Aman to Seat 26 for Evening Shift
      await service.assignSeatToExistingStudent(
        newSeatNumber: 26,
        studentId: aman.id,
        shift: 'Evening Shift',
        sectionName: 'Main Hall',
      );

      final updatedAman = service.findStudentByPhone('9876566661')!;
      expect(updatedAman.seatNumber, equals(26));
      expect(updatedAman.shift, equals('Evening Shift'));
      // Old seat 25 should be vacated
      expect(service.isSeatOccupied(25, shift: 'Morning Shift'), isFalse);
      // New seat 26 occupied
      expect(service.isSeatOccupied(26, shift: 'Evening Shift'), isTrue);
    });

    test('Shift update: upgrade, downgrade excess credit, and upgrade back to same level', () async {
      // 1. Student registers for 800/mo Full Day shift and pays 800
      await service.assignSeatAndRegisterStudent(
        seatNumber: 28,
        studentName: 'Vikram Seth',
        phone: '9876555551',
        shift: 'Full Day',
        deviceUserId: 'Admin',
        monthlyFee: 800,
        feeAmount: 800,
        duesAmount: 0,
        status: 'ACTIVE',
      );
      final vikram = service.findStudentByPhone('9876555551')!;
      expect(vikram.monthlyFee, equals(800));
      expect(vikram.duesAmount, equals(0));

      // 2. Downgrade to Morning (500/mo) -> dues remain 0, excess credit note logged
      await service.updateStudent(
        studentId: vikram.id,
        name: vikram.name,
        phone: vikram.phone,
        shift: 'Morning Shift',
        monthlyFee: 500,
        duesAmount: 0,
        status: 'ACTIVE',
        note: 'Shift changed: Full Day → Morning Shift (₹500/mo). ₹300 excess credit to adjust in next month.',
      );

      final downgraded = service.findStudentByPhone('9876555551')!;
      expect(downgraded.shift, equals('Morning Shift'));
      expect(downgraded.monthlyFee, equals(500));
      expect(downgraded.duesAmount, equals(0));

      // 3. Upgrade back to Full Day (800/mo) -> since student previously paid 800 for current cycle, dues should be 0
      await service.updateStudent(
        studentId: vikram.id,
        name: vikram.name,
        phone: vikram.phone,
        shift: 'Full Day',
        monthlyFee: 800,
        duesAmount: 0,
        status: 'ACTIVE',
        note: 'Shift updated: Full Day. Same price tier (₹800/mo).',
      );

      final upgradedBack = service.findStudentByPhone('9876555551')!;
      expect(upgradedBack.shift, equals('Full Day'));
      expect(upgradedBack.monthlyFee, equals(800));
      expect(upgradedBack.duesAmount, equals(0));
      expect(upgradedBack.status, equals('ACTIVE'));
    });
  });
}
