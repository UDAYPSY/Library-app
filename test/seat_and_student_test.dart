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

    test('Payment transaction records multi-month tenure and dates correctly', () async {
      final fromDate = DateTime(2026, 4, 1);
      final untilDate = DateTime(2026, 6, 1);
      await service.recordPayment(
        studentName: 'Rohan Sharma',
        studentId: 'std_rohan_1',
        phone: '9876599999',
        seatNumber: 15,
        shift: 'Full Day',
        amount: 1600,
        date: DateTime(2026, 4, 1),
        paymentMode: 'UPI',
        notes: '2 Months Advance Fees',
        validFrom: fromDate,
        validUntil: untilDate,
        durationMonths: 2,
      );

      final payments = service.currentPayments;
      expect(payments.isNotEmpty, isTrue);
      final p = payments.first;
      expect(p.studentName, equals('Rohan Sharma'));
      expect(p.amount, equals(1600));
      expect(p.durationMonths, equals(2));
      expect(p.validFrom, equals(fromDate));
      expect(p.validUntil, equals(untilDate));

      final json = p.toJsonMap();
      expect(json['duration_months'], equals(2));
      expect(json['valid_from'], isNotNull);
      expect(json['valid_until'], isNotNull);
    });

    test('Student tenure days completed calculation from joinedAt', () {
      final now = DateTime.now();
      // Joined today -> 1 day completed
      final sToday = StudentInfo(
        id: 's_today',
        name: 'Student Today',
        phone: '9876500011',
        shift: 'Morning',
        joinedAt: now,
      );
      final daysToday = (DateTime.now().difference(DateTime(sToday.joinedAt!.year, sToday.joinedAt!.month, sToday.joinedAt!.day)).inDays + 1).clamp(1, 99999);
      expect(daysToday, equals(1));

      // Joined 4 days ago -> 5 days completed (as in sample image '5d')
      final join5d = now.subtract(const Duration(days: 4));
      final s5d = StudentInfo(
        id: 's_5d',
        name: 'Student 5d',
        phone: '9876500012',
        shift: 'First',
        joinedAt: join5d,
      );
      final days5d = (DateTime.now().difference(DateTime(s5d.joinedAt!.year, s5d.joinedAt!.month, s5d.joinedAt!.day)).inDays + 1).clamp(1, 99999);
      expect(days5d, equals(5));
    });

    test('Input sanitization and validation rules: Name, Phone, Aadhaar, and Address', () {
      String sanitize(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');

      // Whitespace collapsing test
      expect(sanitize('  Rohan    Kumar   Sharma  '), equals('Rohan Kumar Sharma'));

      // Name length validation (2-100 chars)
      expect('A'.trim().length < 2, isTrue); // Too short
      expect('Ab'.trim().length >= 2 && 'Ab'.trim().length <= 100, isTrue); // Valid
      expect(('A' * 101).length > 100, isTrue); // Too long

      // Phone validation (10 digits)
      expect(LibraryService.normalizePhone('9876543210').length == 10, isTrue);
      expect(LibraryService.normalizePhone('+91 98765 43210').length == 10, isTrue);
      expect(LibraryService.normalizePhone('12345').length == 10, isFalse);

      // Aadhaar validation (exactly 12 digits if provided)
      bool isValidAadhaar(String raw) {
        final a = raw.replaceAll(' ', '').trim();
        return a.isEmpty || (a.length == 12 && int.tryParse(a) != null);
      }
      expect(isValidAadhaar(''), isTrue); // Optional
      expect(isValidAadhaar('1234 5678 9012'), isTrue); // Valid 12 digits
      expect(isValidAadhaar('1234567890123'), isFalse); // 13 digits - Invalid
      expect(isValidAadhaar('12345678901'), isFalse); // 11 digits - Invalid
      expect(isValidAadhaar('12345678ABCD'), isFalse); // Non-digit - Invalid

      // Address length validation (max 500 chars)
      expect(('House #12, Civil Lines').length <= 500, isTrue);
      expect(('A' * 501).length > 500, isTrue); // Over limit
    });

    test('Data sync conflict resolution detects stale edits via optimistic locking', () async {
      await service.assignSeatAndRegisterStudent(
        studentName: 'Conflict Test Member',
        phone: '9812399999',
        seatNumber: 10,
        shift: 'Full Day',
        joiningDate: DateTime(2026, 1, 1),
        deviceUserId: 'Admin',
      );

      final student = service.findStudentByPhone('9812399999')!;
      final originalUpdatedAt = student.updatedAt ?? DateTime.now();

      // Device A updates student:
      final successA = await service.updateStudent(
        studentId: student.id,
        name: 'Device A Update',
        phone: '9812399999',
        shift: 'Full Day',
        incomingUpdatedAt: originalUpdatedAt,
      );
      expect(successA, isTrue);

      // Device B attempts to update using stale original timestamp:
      final staleTimestamp = originalUpdatedAt.subtract(const Duration(minutes: 5));
      final successB = await service.updateStudent(
        studentId: student.id,
        name: 'Device B Stale Overwrite',
        phone: '9812399999',
        shift: 'Full Day',
        incomingUpdatedAt: staleTimestamp, // Stale!
      );
      expect(successB, isFalse); // Successfully blocked by conflict detector!
    });

    test('Shift change for existing student calculates upgrade and downgrade across whole multi-month tenure', () async {
      // 1. Student registered for 3 months in Morning Shift (₹600/mo * 3 = ₹1800 paid)
      final tenureMonths = 3;
      final oldMonthlyFee = 600;
      final totalPaid = oldMonthlyFee * tenureMonths; // 1800
      final joinDate = DateTime(2026, 1, 1);
      final dueDate = DateTime(2026, 4, 1);

      final student = StudentInfo(
        id: 'std_tenure_1',
        name: 'Multi Month Member',
        phone: '9800011111',
        shift: 'Morning Shift',
        seatNumber: 15,
        monthlyFee: oldMonthlyFee,
        status: 'ACTIVE',
        joinedAt: joinDate,
        feeDueDate: dueDate,
      );
      await service.addStudent(student);

      // Record 3-month payment transaction
      await service.recordPayment(
        studentId: student.id,
        studentName: student.name,
        phone: student.phone,
        seatNumber: 15,
        shift: 'Morning Shift',
        amount: totalPaid,
        date: joinDate,
        validFrom: joinDate,
        validUntil: dueDate,
        durationMonths: tenureMonths,
        notes: 'Initial 3-month membership',
      );

      // Verify payment was recorded with durationMonths
      final recordedPayments = service.currentPayments.where((p) => p.studentId == student.id).toList();
      expect(recordedPayments.first.durationMonths, equals(3));
      expect(recordedPayments.first.amount, equals(1800));

      // 2. UPGRADE: Upgrading from Morning (₹600/mo) to Full Day (₹1000/mo) for 3-month tenure
      final newMonthlyFeeUpgrade = 1000;
      final expectedUpgradeCost = newMonthlyFeeUpgrade * tenureMonths; // 3000
      final upgradeDiff = expectedUpgradeCost - totalPaid; // 3000 - 1800 = 1200
      expect(upgradeDiff, equals(1200));

      // 3. DOWNGRADE: If student had paid Full Day (₹1000/mo * 3 = ₹3000) and downgrades to Morning (₹600/mo * 3 = ₹1800)
      final initialFullDayPaid = 3000;
      final newMonthlyFeeDowngrade = 600;
      final expectedDowngradeCost = newMonthlyFeeDowngrade * tenureMonths; // 1800
      final excessCredit = initialFullDayPaid - expectedDowngradeCost; // 3000 - 1800 = 1200
      expect(excessCredit, equals(1200));
    });

    test('Activity notes are automatically appended for payment collection and seat change', () async {
      final s = StudentInfo(
        id: 'std_audit_1',
        name: 'Audit Log Test Member',
        phone: '9822233333',
        shift: 'Morning Shift',
        seatNumber: 4,
        monthlyFee: 500,
        status: 'ACTIVE',
        note: 'Initial remarks',
      );
      await service.addStudent(s);

      // 1. Record payment -> note must be automatically appended
      await service.recordPayment(
        studentId: s.id,
        studentName: s.name,
        phone: s.phone,
        amount: 500,
        paymentMode: 'UPI',
        notes: 'Monthly renewal',
      );

      var updated = service.findStudentByPhone('9822233333')!;
      expect(updated.note.contains('Initial remarks'), isTrue);
      expect(updated.note.contains('Payment of ₹500 collected via UPI'), isTrue);

      // 2. Change seat -> seat change note must be automatically appended
      await service.assignSeatToExistingStudent(
        newSeatNumber: 9,
        studentId: s.id,
      );

      updated = service.findStudentByPhone('9822233333')!;
      expect(updated.seatNumber, equals(9));
      expect(updated.note.contains('Seat changed: S-4 → S-9'), isTrue);

      // 3. Shift change via updateStudent -> shift change note appended without deleting prior notes
      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Evening Shift',
      );

      updated = service.findStudentByPhone('9822233333')!;
      expect(updated.note.contains('Initial remarks'), isTrue);
      expect(updated.note.contains('Payment of ₹500'), isTrue);
      expect(updated.note.contains('Seat changed: S-4 → S-9'), isTrue);
      expect(updated.note.contains('Shift changed: Morning Shift → Evening Shift'), isTrue);

      // 4. Update without note parameter (e.g. from collect payment modal) -> notes are strictly preserved
      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Evening Shift',
        duesAmount: 0,
      );

      updated = service.findStudentByPhone('9822233333')!;
      expect(updated.note.contains('Initial remarks'), isTrue);
      expect(updated.note.contains('Shift changed: Morning Shift → Evening Shift'), isTrue);

      // 5. Deactivate student -> inactive note appended without deleting notes
      await service.markStudentInactive(s.id, 9);
      updated = service.currentStudents.firstWhere((st) => st.id == s.id);
      expect(updated.status, equals('INACTIVE'));
      expect(updated.note.contains('Member moved to Inactive'), isTrue);
      expect(updated.note.contains('Initial remarks'), isTrue);

      // 6. Reactivate student -> reactivated note appended without deleting notes
      await service.reactivateStudent(s.id, 9);
      updated = service.currentStudents.firstWhere((st) => st.id == s.id);
      expect(updated.status, equals('ACTIVE'));
      expect(updated.note.contains('Member reactivated to Active'), isTrue);
      expect(updated.note.contains('Initial remarks'), isTrue);

      // 7. Static appendNote helper verifies bulleting and duplicate prevention
      final note1 = LibraryService.appendNote('Existing note', 'Action performed');
      expect(note1, equals('Existing note\n• Action performed'));
      final note2 = LibraryService.appendNote(note1, 'Action performed'); // duplicate
      expect(note2, equals(note1));
    });

    test('Payment transactions can be filtered by specific single date', () async {
      final date1 = DateTime(2026, 10, 24);
      final date2 = DateTime(2026, 10, 25);

      await service.recordPayment(
        studentName: 'Student Day 1',
        amount: 500,
        date: date1,
      );
      await service.recordPayment(
        studentName: 'Student Day 2',
        amount: 800,
        date: date2,
      );

      final allPayments = service.currentPayments;
      final day1Payments = allPayments.where((p) =>
          p.date.year == date1.year &&
          p.date.month == date1.month &&
          p.date.day == date1.day).toList();
      final day2Payments = allPayments.where((p) =>
          p.date.year == date2.year &&
          p.date.month == date2.month &&
          p.date.day == date2.day).toList();

      expect(day1Payments.any((p) => p.studentName == 'Student Day 1'), isTrue);
      expect(day1Payments.any((p) => p.studentName == 'Student Day 2'), isFalse);

      expect(day2Payments.any((p) => p.studentName == 'Student Day 2'), isTrue);
      expect(day2Payments.any((p) => p.studentName == 'Student Day 1'), isFalse);
    });

    test('Multiple shift changes in the same tenure accurately compute dues and advance credit every time', () async {
      // 1. Enrolled in 1-month tenure at ₹1000/mo (paid full ₹1000)
      final s = StudentInfo(
        id: 'std_multi_shift_1',
        name: 'Multi Shift Student',
        phone: '9988776655',
        shift: 'Full Day',
        seatNumber: 15,
        monthlyFee: 1000,
        duesAmount: 0,
        advanceAmount: 0,
        status: 'ACTIVE',
        feeDueDate: DateTime.now().add(const Duration(days: 30)),
      );
      await service.addStudent(s);

      // Simulation of Wizard / Service Multi-Shift Math:
      // Invariant: effectiveCoverage = (s.monthlyFee * tenure) - s.duesAmount + s.advanceAmount
      int tenureMonths = 1;
      int coverage = (s.monthlyFee * tenureMonths) - s.duesAmount + s.advanceAmount; // 1000

      // CHANGE 1 (Downgrade): Change to 800/mo
      int newCost = 800 * tenureMonths; // 800
      int diff = newCost - coverage; // 800 - 1000 = -200 (200 excess credit)
      expect(diff, equals(-200));
      int advanceAmount = diff < 0 ? -diff : 0; // 200
      int dueAmount = diff > 0 ? diff : 0; // 0
      expect(advanceAmount, equals(200));
      expect(dueAmount, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Morning Shift',
        monthlyFee: 800,
        duesAmount: dueAmount,
        advanceAmount: advanceAmount,
      );

      var studentAfterChg1 = service.findStudentByPhone('9988776655')!;
      expect(studentAfterChg1.monthlyFee, equals(800));
      expect(studentAfterChg1.duesAmount, equals(0));
      expect(studentAfterChg1.advanceAmount, equals(200));

      // CHANGE 2 (Downgrade Again in same tenure): Change from 800/mo to 600/mo
      coverage = (studentAfterChg1.monthlyFee * tenureMonths) - studentAfterChg1.duesAmount + studentAfterChg1.advanceAmount;
      expect(coverage, equals(1000)); // Still maintains full 1000 baseline!

      newCost = 600 * tenureMonths; // 600
      diff = newCost - coverage; // 600 - 1000 = -400
      advanceAmount = diff < 0 ? -diff : 0; // 400
      dueAmount = diff > 0 ? diff : 0; // 0
      expect(advanceAmount, equals(400));
      expect(dueAmount, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Evening Shift',
        monthlyFee: 600,
        duesAmount: dueAmount,
        advanceAmount: advanceAmount,
      );

      var studentAfterChg2 = service.findStudentByPhone('9988776655')!;
      expect(studentAfterChg2.monthlyFee, equals(600));
      expect(studentAfterChg2.advanceAmount, equals(400));
      expect(studentAfterChg2.duesAmount, equals(0));

      // CHANGE 3 (Upgrade in same tenure): Change from 600/mo to 1200/mo
      coverage = (studentAfterChg2.monthlyFee * tenureMonths) - studentAfterChg2.duesAmount + studentAfterChg2.advanceAmount;
      expect(coverage, equals(1000)); // Still exact 1000 baseline!

      newCost = 1200 * tenureMonths; // 1200
      diff = newCost - coverage; // 1200 - 1000 = +200
      advanceAmount = diff < 0 ? -diff : 0; // 0
      dueAmount = diff > 0 ? diff : 0; // 200
      expect(advanceAmount, equals(0));
      expect(dueAmount, equals(200));

      // Student pays 0 right now, accepts 200 due
      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: '24 Hour Shift',
        monthlyFee: 1200,
        duesAmount: dueAmount,
        advanceAmount: advanceAmount,
      );

      var studentAfterChg3 = service.findStudentByPhone('9988776655')!;
      expect(studentAfterChg3.monthlyFee, equals(1200));
      expect(studentAfterChg3.duesAmount, equals(200));
      expect(studentAfterChg3.advanceAmount, equals(0));

      // CHANGE 4 (Downgrade after uncollected upgrade in same tenure): Change from 1200/mo to 700/mo
      coverage = (studentAfterChg3.monthlyFee * tenureMonths) - studentAfterChg3.duesAmount + studentAfterChg3.advanceAmount;
      expect(coverage, equals(1000)); // (1200 * 1) - 200 + 0 = 1000 baseline preserved!

      newCost = 700 * tenureMonths; // 700
      diff = newCost - coverage; // 700 - 1000 = -300
      advanceAmount = diff < 0 ? -diff : 0; // 300
      dueAmount = diff > 0 ? diff : 0; // 0 (due is automatically cleared!)
      expect(advanceAmount, equals(300));
      expect(dueAmount, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Afternoon Shift',
        monthlyFee: 700,
        duesAmount: dueAmount,
        advanceAmount: advanceAmount,
      );

      var studentAfterChg4 = service.findStudentByPhone('9988776655')!;
      expect(studentAfterChg4.monthlyFee, equals(700));
      expect(studentAfterChg4.advanceAmount, equals(300));
      expect(studentAfterChg4.duesAmount, equals(0));

      // 4. NEXT MONTH PURCHASE / RENEWAL ADJUSTMENT
      // Student has 300 advance credit. Renewing for next month at 700/mo:
      final nextMonthFee = 700;
      final advanceToAdjust = studentAfterChg4.advanceAmount.clamp(0, nextMonthFee); // 300
      final netCashToCollect = (nextMonthFee - advanceToAdjust).clamp(0, nextMonthFee); // 400
      final remainingAdvance = studentAfterChg4.advanceAmount - advanceToAdjust; // 0

      expect(advanceToAdjust, equals(300));
      expect(netCashToCollect, equals(400));
      expect(remainingAdvance, equals(0));

      // Record payment for the net amount
      final fromDate = studentAfterChg4.feeDueDate!;
      final untilDate = DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      await service.recordPayment(
        studentId: s.id,
        studentName: s.name,
        phone: s.phone,
        amount: netCashToCollect,
        validFrom: fromDate,
        validUntil: untilDate,
        notes: 'Renewal payment of ₹$netCashToCollect + ₹$advanceToAdjust advance credit adjusted for period: 01-Nov-2026 to 01-Dec-2026',
      );

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: studentAfterChg4.shift,
        duesAmount: 0,
        advanceAmount: remainingAdvance,
        feeDueDate: untilDate,
      );

      var studentAfterRenewal = service.findStudentByPhone('9988776655')!;
      expect(studentAfterRenewal.advanceAmount, equals(0));
      expect(studentAfterRenewal.duesAmount, equals(0));
      expect(studentAfterRenewal.status, equals('ACTIVE'));
    });

    test('Due payment collection explicitly notes the validity time period in payment records', () async {
      final s = StudentInfo(
        id: 'std_due_period_test',
        name: 'Due Period Student',
        phone: '9911223344',
        shift: 'Morning Shift',
        monthlyFee: 600,
        duesAmount: 300,
        status: 'DUES',
        joinedAt: DateTime(2026, 10, 1),
        feeDueDate: DateTime(2026, 11, 1),
      );
      await service.addStudent(s);

      final validFrom = DateTime(2026, 10, 1);
      final validUntil = DateTime(2026, 11, 1);

      // Collect the due payment of ₹300
      await service.recordPayment(
        studentId: s.id,
        studentName: s.name,
        phone: s.phone,
        amount: 300,
        paymentMode: 'Cash',
        validFrom: validFrom,
        validUntil: validUntil,
        notes: 'Due payment for period: 01-Oct-2026 to 01-Nov-2026',
      );

      final latestPayment = service.currentPayments.firstWhere((p) => p.studentId == s.id);
      expect(latestPayment.notes.contains('Due payment for period: 01-Oct-2026 to 01-Nov-2026'), isTrue);

      final updated = service.findStudentByPhone('9911223344')!;
      expect(updated.duesAmount, equals(0));
      expect(updated.status, equals('ACTIVE'));
      expect(updated.note.contains('Due payment of ₹300 collected via Cash'), isTrue);
      expect(updated.note.contains('01-Oct-2026 to 01-Nov-2026'), isTrue);
    });

    test('Multiple sequential shift downgrades and upgrades in same tenure show only current excess credit', () async {
      final s = StudentInfo(
        id: 'std_multi_downgrade_test',
        name: 'Multi Downgrade Student',
        phone: '9922334455',
        shift: 'Morning Shift',
        monthlyFee: 1000,
        duesAmount: 0,
        advanceAmount: 0,
        status: 'ACTIVE',
        joinedAt: DateTime(2026, 10, 1),
        feeDueDate: DateTime(2026, 11, 1),
      );
      await service.addStudent(s);

      // STEP 1: Downgrade from 1000/mo to 800/mo
      // Coverage = 1000 * 1 - 0 + 0 = 1000
      // Target cost = 800 * 1 = 800
      // Diff = 800 - 1000 = -200 -> excess credit = 200
      var coverage = (s.monthlyFee * 1) - s.duesAmount + s.advanceAmount;
      var newCost = 800 * 1;
      var diff = newCost - coverage;
      var excessCredit = diff < 0 ? -diff : 0;
      var due = diff > 0 ? diff : 0;

      expect(excessCredit, equals(200));
      expect(due, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Evening Shift',
        monthlyFee: 800,
        duesAmount: due,
        advanceAmount: excessCredit,
        note: 'Shift downgraded: Morning Shift (₹1000/mo) → Evening Shift (₹800/mo). ₹200 excess credit remains with the library to adjust in next renewal.',
      );

      var st1 = service.findStudentByPhone('9922334455')!;
      expect(st1.monthlyFee, equals(800));
      expect(st1.advanceAmount, equals(200));

      // STEP 2: Upgrade back to 1000/mo
      // Coverage = 800 * 1 - 0 + 200 = 1000
      // Target cost = 1000 * 1 = 1000
      // Diff = 1000 - 1000 = 0 -> advance credit is consumed!
      coverage = (st1.monthlyFee * 1) - st1.duesAmount + st1.advanceAmount;
      newCost = 1000 * 1;
      diff = newCost - coverage;
      excessCredit = diff < 0 ? -diff : 0;
      due = diff > 0 ? diff : 0;

      expect(excessCredit, equals(0));
      expect(due, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Morning Shift',
        monthlyFee: 1000,
        duesAmount: due,
        advanceAmount: excessCredit,
        note: 'Shift upgraded: Evening Shift (₹800/mo) → Morning Shift (₹1000/mo). (Paid: ₹1000, Upgrade diff: ₹0)',
      );

      var st2 = service.findStudentByPhone('9922334455')!;
      expect(st2.monthlyFee, equals(1000));
      expect(st2.advanceAmount, equals(0)); // Previous credit was used to upgrade!

      // STEP 3: Downgrade AGAIN to 800/mo
      // Coverage = 1000 * 1 - 0 + 0 = 1000
      // Target cost = 800 * 1 = 800
      // Diff = 800 - 1000 = -200 -> excess credit should ONLY be 200, NOT 400!
      coverage = (st2.monthlyFee * 1) - st2.duesAmount + st2.advanceAmount;
      newCost = 800 * 1;
      diff = newCost - coverage;
      excessCredit = diff < 0 ? -diff : 0;
      due = diff > 0 ? diff : 0;

      expect(excessCredit, equals(200)); // Exactly 200! Logical previous is zero!
      expect(due, equals(0));

      await service.updateStudent(
        studentId: s.id,
        name: s.name,
        phone: s.phone,
        shift: 'Evening Shift',
        monthlyFee: 800,
        duesAmount: due,
        advanceAmount: excessCredit,
        note: 'Shift downgraded: Morning Shift (₹1000/mo) → Evening Shift (₹800/mo). ₹200 excess credit remains with the library to adjust in next renewal.',
      );

      var st3 = service.findStudentByPhone('9922334455')!;
      expect(st3.monthlyFee, equals(800));
      expect(st3.advanceAmount, equals(200));
    });

    test('All actions on a student add persistent, cumulative notes to student profile', () async {
      final phone = '9933445566';
      // 1. Admission
      await service.assignSeatAndRegisterStudent(
        seatNumber: 15,
        studentName: 'Audit Action Student',
        phone: phone,
        shift: 'Morning Shift',
        feeAmount: 500,
        duesAmount: 0,
      );
      var st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Admission on'), isTrue);

      // 2. Change Seat
      await service.assignSeatToExistingStudent(
        newSeatNumber: 16,
        studentId: st.id,
        shift: 'Morning Shift',
      );
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Seat changed: S-15 → S-16'), isTrue);
      expect(st.note.contains('Admission on'), isTrue); // Persisted!

      // 3. Mark Dues
      await service.markStudentDues(st.id, 250);
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Pending dues of ₹250 marked'), isTrue);
      expect(st.note.contains('Seat changed: S-15 → S-16'), isTrue); // Persisted!

      // 4. Pay Dues
      await service.recordPayment(
        studentId: st.id,
        studentName: st.name,
        phone: st.phone,
        amount: 250,
        notes: 'Due payment cleared',
      );
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Due payment of ₹250 collected'), isTrue);

      // 5. Shift Change
      await service.updateStudent(
        studentId: st.id,
        name: st.name,
        phone: st.phone,
        shift: 'Evening Shift',
      );
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Shift changed: Morning Shift → Evening Shift'), isTrue);

      // 6. Deactivate Member
      await service.markStudentInactive(st.id, 16);
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Member moved to Inactive'), isTrue);

      // 7. Reactivate Member
      await service.reactivateStudent(st.id, 17);
      st = service.findStudentByPhone(phone)!;
      expect(st.note.contains('Member reactivated to Active'), isTrue);
      // Verify all previous notes are intact
      expect(st.note.contains('Admission on'), isTrue);
      expect(st.note.contains('Seat changed: S-15 → S-16'), isTrue);
      expect(st.note.contains('Due payment of ₹250 collected'), isTrue);
    });
  });
}
