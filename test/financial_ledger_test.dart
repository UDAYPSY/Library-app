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

  group('Financial Ledger & Payment Reconciliation Tests', () {
    test('Student fee collection decreases dues and records payment transaction', () async {
      // 1. Add student with dues
      final testStudent = StudentInfo(
        id: 'test_std_001',
        name: 'Rahul Sharma',
        phone: '9876543210',
        shift: 'Full Day',
        seatNumber: 1,
        monthlyFee: 800,
        duesAmount: 800,
        status: 'Active',
        joinedAt: DateTime(2026, 1, 1),
      );
      await service.addStudent(testStudent);

      expect(service.isSeatOccupied(1), isTrue);

      // 2. Collect fee of 800
      final initialPaymentCount = service.currentPayments.length;
      await service.collectStudentFee(
        studentId: testStudent.id,
        amount: 800,
        paymentMode: 'UPI',
        notes: 'Monthly renewal fee paid via UPI',
      );

      // 3. Verify payment ledger recorded
      expect(service.currentPayments.length, equals(initialPaymentCount + 1));
      final lastPayment = service.currentPayments.first;
      expect(lastPayment.studentId, equals('test_std_001'));
      expect(lastPayment.studentName, equals('Rahul Sharma'));
      expect(lastPayment.amount, equals(800));
      expect(lastPayment.paymentMode, equals('UPI'));

      // 4. Verify student dues cleared
      final updatedStudent = service.findStudentByPhone('9876543210');
      expect(updatedStudent, isNotNull);
      expect(updatedStudent!.duesAmount, equals(0));
    });

    test('Adding and deleting expense item', () async {
      final initialExpenses = service.currentExpenses.length;

      await service.addExpense(
        title: 'High-Speed Wi-Fi Bill',
        category: 'Utilities',
        amount: 1499,
        date: DateTime.now(),
        paymentMode: 'UPI',
        note: 'Monthly internet broadband',
      );
      expect(service.currentExpenses.length, equals(initialExpenses + 1));
      final addedExp = service.currentExpenses.first;
      expect(addedExp.title, equals('High-Speed Wi-Fi Bill'));

      // Delete expense
      service.deleteExpense(addedExp.id);
      expect(service.currentExpenses.any((e) => e.id == addedExp.id), isFalse);
    });

    test('Payment transaction query by student ID and phone', () async {
      await service.recordPayment(
        studentId: 'std_lookup_99',
        studentName: 'Pooja Verma',
        phone: '9988776655',
        seatNumber: 5,
        shift: 'Evening',
        amount: 600,
        date: DateTime.now(),
        paymentMode: 'Cash',
      );

      final foundById = service.getLastPaymentForStudent(studentId: 'std_lookup_99');
      expect(foundById, isNotNull);
      expect(foundById!.amount, equals(600));

      final foundByPhone = service.getLastPaymentForStudent(phone: '9988776655');
      expect(foundByPhone, isNotNull);
      expect(foundByPhone!.studentName, equals('Pooja Verma'));
    });

    test('Filtering payments by student name returns exact matching transactions', () async {
      await service.recordPayment(
        studentId: 'std_01',
        studentName: 'Amit Patel',
        phone: '9111111111',
        seatNumber: 10,
        shift: 'Morning',
        amount: 500,
        date: DateTime.now(),
        paymentMode: 'UPI',
      );
      await service.recordPayment(
        studentId: 'std_02',
        studentName: 'Sneha Rao',
        phone: '9222222222',
        seatNumber: 12,
        shift: 'Evening',
        amount: 700,
        date: DateTime.now(),
        paymentMode: 'Cash',
      );
      await service.recordPayment(
        studentId: 'std_01',
        studentName: 'Amit Patel',
        phone: '9111111111',
        seatNumber: 10,
        shift: 'Morning',
        amount: 500,
        date: DateTime.now().subtract(const Duration(days: 30)),
        paymentMode: 'UPI',
      );

      final amitPayments = service.currentPayments.where((p) => p.studentName == 'Amit Patel').toList();
      expect(amitPayments.length, equals(2));
      expect(amitPayments.every((p) => p.studentName == 'Amit Patel'), isTrue);

      final snehaPayments = service.currentPayments.where((p) => p.studentName == 'Sneha Rao').toList();
      expect(snehaPayments.length, equals(1));
      expect(snehaPayments.first.amount, equals(700));
    });
  });
}
