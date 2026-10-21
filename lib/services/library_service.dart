import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/library_models.dart';

class LibraryService {
  // Singleton pattern for centralized app state
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  // Active configuration models
  LibraryProfile profile = LibraryProfile();
  List<SectionConfig> sections = [
    SectionConfig(id: 'sec_1', name: 'Main Hall', startSeat: 1, endSeat: 35),
  ];
  List<ShiftConfig> shifts = [
    ShiftConfig(
      id: 'shift_1',
      name: 'Full Day',
      startsAt: '06:00 AM',
      endsAt: '10:00 PM',
      monthlyFee: 500,
      isActive: true,
      isSystemSlot: true,
    ),
    ShiftConfig(
      id: 'shift_2',
      name: '24 Hours',
      startsAt: '12:00 AM',
      endsAt: '11:59 PM',
      monthlyFee: 1500,
      isActive: false,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_3',
      name: 'Evening Shift',
      startsAt: '02:00 PM',
      endsAt: '10:00 PM',
      monthlyFee: 600,
      isActive: false,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_4',
      name: 'Morning Shift',
      startsAt: '06:00 AM',
      endsAt: '02:00 PM',
      monthlyFee: 600,
      isActive: false,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_5',
      name: 'Night Shift',
      startsAt: '10:00 PM',
      endsAt: '06:00 AM',
      monthlyFee: 500,
      isActive: false,
      isSystemSlot: false,
    ),
  ];

  void toggleShiftActive(String shiftId) {
    final idx = shifts.indexWhere((s) => s.id == shiftId);
    if (idx != -1) {
      shifts[idx].isActive = !shifts[idx].isActive;
    }
  }

  void updateShift(ShiftConfig updated) {
    final idx = shifts.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      shifts[idx] = updated;
    }
  }

  void addShift(ShiftConfig newShift) {
    shifts.add(newShift);
  }

  int get totalSeatsCount {
    int total = 0;
    for (var s in sections) {
      total += s.totalSeats;
    }
    return total > 0 ? total : 35;
  }

  // In-memory mock fallback state
  static late List<SeatInfo> _mockSeats;
  static final List<StudentInfo> _mockStudents = [];
  static final List<ExpenseItem> _mockExpenses = [];
  static final List<PaymentTransaction> _mockPayments = [];

  static final StreamController<List<SeatInfo>> _mockSeatsController =
      StreamController<List<SeatInfo>>.broadcast();
  static final StreamController<List<StudentInfo>> _mockStudentsController =
      StreamController<List<StudentInfo>>.broadcast();
  static final StreamController<List<ExpenseItem>> _mockExpensesController =
      StreamController<List<ExpenseItem>>.broadcast();
  static final StreamController<List<PaymentTransaction>> _mockPaymentsController =
      StreamController<List<PaymentTransaction>>.broadcast();

  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    _initialized = true;
  }

  Future<void> clearAllData() async {
    _mockStudents.clear();
    _mockPayments.clear();
    _mockExpenses.clear();
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    _mockStudentsController.add(List.unmodifiable(_mockStudents));
    _mockPaymentsController.add(List.unmodifiable(_mockPayments));
    _mockExpensesController.add(List.unmodifiable(_mockExpenses));
    _mockSeatsController.add(List.unmodifiable(_mockSeats));
  }

  void updateSectionsAndRebuildSeats(List<SectionConfig> newSections) {
    sections = newSections;
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    _mockSeatsController.add(List.unmodifiable(_mockSeats));
  }

  bool get isFirebaseConnected => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Real-time seat stream (Cloud Firestore or In-Memory Demo)
  Stream<List<SeatInfo>> streamSeats() {
    ensureInitialized();
    if (isFirebaseConnected) {
      return _db.collection('seats').snapshots().map((snapshot) {
        final seatMap = <int, SeatInfo>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final seatNum = (data['seat_number'] as num?)?.toInt();
          if (seatNum != null) {
            seatMap[seatNum] = SeatInfo.fromMap(seatNum, data);
          }
        }
        return List.generate(totalSeatsCount, (index) {
          final num = index + 1;
          return seatMap[num] ?? SeatInfo(seatNumber: num);
        });
      });
    } else {
      Timer.run(() {
        if (!_mockSeatsController.isClosed) {
          _mockSeatsController.add(List.unmodifiable(_mockSeats));
        }
      });
      return _mockSeatsController.stream;
    }
  }

  // Real-time student list stream
  Stream<List<StudentInfo>> streamStudents() {
    ensureInitialized();
    if (isFirebaseConnected) {
      return _db
          .collection('students')
          .orderBy('joined_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((d) => StudentInfo.fromFirestore(d.id, d.data()))
            .toList();
      });
    } else {
      Timer.run(() {
        if (!_mockStudentsController.isClosed) {
          _mockStudentsController.add(List.unmodifiable(_mockStudents));
        }
      });
      return _mockStudentsController.stream;
    }
  }

  // Real-time expenses stream
  Stream<List<ExpenseItem>> streamExpenses() {
    ensureInitialized();
    if (isFirebaseConnected) {
      return _db
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((d) => ExpenseItem.fromFirestore(d.id, d.data()))
            .toList();
      });
    } else {
      Timer.run(() {
        if (!_mockExpensesController.isClosed) {
          _mockExpensesController.add(List.unmodifiable(_mockExpenses));
        }
      });
      return _mockExpensesController.stream;
    }
  }

  // Add Expense
  Future<void> addExpense({
    required String title,
    required String category,
    required int amount,
    required DateTime date,
    String paymentMode = 'Cash',
    String note = '',
  }) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final docRef = _db.collection('expenses').doc();
      await docRef.set({
        'id': docRef.id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'payment_mode': paymentMode,
        'note': note,
      });
    } else {
      _mockExpenses.insert(
        0,
        ExpenseItem(
          id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          category: category,
          amount: amount,
          date: date,
          paymentMode: paymentMode,
          note: note,
        ),
      );
      _mockExpensesController.add(List.unmodifiable(_mockExpenses));
    }
  }

  // Stream Payment Transactions
  Stream<List<PaymentTransaction>> streamPayments() {
    if (isFirebaseConnected) {
      return _db
          .collection('payments')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PaymentTransaction.fromFirestore(doc.id, doc.data()))
              .toList());
    } else {
      ensureInitialized();
      Future.microtask(() => _mockPaymentsController.add(List.unmodifiable(_mockPayments)));
      return _mockPaymentsController.stream;
    }
  }

  Future<void> recordPayment({
    required String studentName,
    String? studentId,
    String? phone,
    int? seatNumber,
    String shift = 'Full Day',
    required int amount,
    DateTime? date,
    String paymentMode = 'UPI',
    String notes = '',
  }) async {
    ensureInitialized();
    final payDate = date ?? DateTime.now();
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    if (isFirebaseConnected) {
      await _db.collection('payments').doc(paymentId).set({
        'payment_id': paymentId,
        'student_id': studentId ?? '',
        'student_name': studentName,
        'student_phone': phone ?? '',
        'seat_number': seatNumber,
        'shift': shift,
        'amount': amount,
        'date': Timestamp.fromDate(payDate),
        'payment_mode': paymentMode,
        'notes': notes,
      });
    } else {
      _mockPayments.insert(
        0,
        PaymentTransaction(
          id: paymentId,
          studentId: studentId ?? '',
          studentName: studentName,
          studentPhone: phone ?? '',
          seatNumber: seatNumber,
          shift: shift,
          amount: amount,
          date: payDate,
          paymentMode: paymentMode,
          notes: notes,
        ),
      );
      _mockPaymentsController.add(List.unmodifiable(_mockPayments));
    }
  }

  // Atomic Seat Assignment Transaction
  Future<void> assignSeatAndRegisterStudent({
    int? seatNumber,
    required String studentName,
    required String phone,
    required String shift,
    required String deviceUserId,
    int feeAmount = 500,
    String paymentMode = 'UPI',
    String status = 'ACTIVE',
    DateTime? joiningDate,
    String note = '',
    int duesAmount = 0,
  }) async {
    ensureInitialized();
    final now = joiningDate ?? DateTime.now();
    final validUntil = now.add(const Duration(days: 30));

    if (isFirebaseConnected) {
      final studentDocRef = _db.collection('students').doc();
      final paymentDocRef = _db.collection('payments').doc();

      await _db.runTransaction((transaction) async {
        if (seatNumber != null) {
          final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
          final seatSnapshot = await transaction.get(seatDocRef);

          if (seatSnapshot.exists) {
            final data = seatSnapshot.data();
            if (data != null && data['is_occupied'] == true) {
              throw Exception('Seat $seatNumber is already occupied!');
            }
          }

          transaction.set(
            seatDocRef,
            {
              'seat_number': seatNumber,
              'is_occupied': true,
              'student_id': studentDocRef.id,
              'student_name': studentName,
              'shift': shift,
              'last_updated_by': deviceUserId,
            },
            SetOptions(merge: true),
          );
        }

        // 1. Create Student record
        transaction.set(studentDocRef, {
          'id': studentDocRef.id,
          'name': studentName,
          'phone': phone,
          'seat_number': seatNumber,
          'shift': shift,
          'fee_due_date': Timestamp.fromDate(validUntil),
          'status': status,
          'joined_at': Timestamp.fromDate(now),
          'monthly_fee': feeAmount,
          'payment_mode': paymentMode,
          'note': note,
          'dues_amount': duesAmount,
        });

        // 2. Log payment if not trial and fee > 0
        if (status != 'TRIAL' && feeAmount > 0) {
          transaction.set(paymentDocRef, {
            'payment_id': paymentDocRef.id,
            'student_id': studentDocRef.id,
            'student_name': studentName,
            'amount': feeAmount,
            'date': Timestamp.fromDate(now),
            'valid_until': Timestamp.fromDate(validUntil),
            'collected_by': deviceUserId,
            'payment_mode': paymentMode,
          });
        }
      });
    } else {
      // In-memory mock assignment
      final studentId = 'std_${DateTime.now().millisecondsSinceEpoch}';
      if (seatNumber != null) {
        final index = seatNumber - 1;
        if (index >= 0 && index < _mockSeats.length) {
          if (_mockSeats[index].isOccupied) {
            throw Exception('Seat $seatNumber is already occupied!');
          }
          _mockSeats[index] = SeatInfo(
            seatNumber: seatNumber,
            isOccupied: true,
            studentId: studentId,
            studentName: studentName,
            shift: shift,
          );
          _mockSeatsController.add(List.unmodifiable(_mockSeats));
        }
      }

      _mockStudents.insert(
        0,
        StudentInfo(
          id: studentId,
          name: studentName,
          phone: phone,
          seatNumber: seatNumber,
          shift: shift,
          status: status,
          feeDueDate: validUntil,
          joinedAt: now,
          monthlyFee: feeAmount,
          paymentMode: paymentMode,
          note: note,
          duesAmount: duesAmount,
        ),
      );

      if (status != 'TRIAL' && feeAmount > 0) {
        _mockPayments.insert(
          0,
          PaymentTransaction(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            studentId: studentId,
            studentName: studentName,
            studentPhone: phone,
            seatNumber: seatNumber,
            shift: shift,
            amount: feeAmount,
            date: now,
            paymentMode: paymentMode,
            notes: 'Registration fee',
          ),
        );
        _mockPaymentsController.add(List.unmodifiable(_mockPayments));
      }

      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }
  }

  // Vacate Seat
  Future<void> vacateSeat(int seatNumber, String? studentId) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final batch = _db.batch();
      final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');

      batch.update(seatDocRef, {
        'is_occupied': false,
        'student_id': null,
        'student_name': null,
        'shift': null,
      });

      if (studentId != null && studentId.trim().isNotEmpty) {
        final studentDocRef = _db.collection('students').doc(studentId.trim());
        batch.update(studentDocRef, {
          'status': 'INACTIVE',
          'seat_number': null,
        });
      }

      await batch.commit();
    } else {
      final index = seatNumber - 1;
      if (index >= 0 && index < _mockSeats.length) {
        _mockSeats[index] = SeatInfo(seatNumber: seatNumber);
        if (studentId != null && studentId.isNotEmpty) {
          final studentIndex =
              _mockStudents.indexWhere((s) => s.id == studentId);
          if (studentIndex != -1) {
            final s = _mockStudents[studentIndex];
            _mockStudents[studentIndex] = StudentInfo(
              id: s.id,
              name: s.name,
              phone: s.phone,
              seatNumber: null,
              shift: s.shift,
              status: 'INACTIVE',
              feeDueDate: s.feeDueDate,
              joinedAt: s.joinedAt,
              monthlyFee: s.monthlyFee,
              paymentMode: s.paymentMode,
            );
          }
        }
        _mockSeatsController.add(List.unmodifiable(_mockSeats));
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Move Student to Inactive (frees seat, keeps record in INACTIVE tab)
  Future<void> markStudentInactive(String studentId, int? seatNumber) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final batch = _db.batch();
      final studentDocRef = _db.collection('students').doc(studentId);
      batch.update(studentDocRef, {
        'status': 'INACTIVE',
        'seat_number': null,
      });
      if (seatNumber != null) {
        final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
        batch.update(seatDocRef, {
          'is_occupied': false,
          'student_id': null,
          'student_name': null,
          'shift': null,
        });
      }
      await batch.commit();
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        _mockStudents[idx] = _mockStudents[idx].copyWith(
          status: 'INACTIVE',
          seatNumber: null,
        );
      }
      if (seatNumber != null && seatNumber > 0 && seatNumber <= _mockSeats.length) {
        _mockSeats[seatNumber - 1] = SeatInfo(seatNumber: seatNumber);
        _mockSeatsController.add(List.unmodifiable(_mockSeats));
      }
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }
  }

  // Delete Student alias to markStudentInactive (moves student to INACTIVE tab)
  Future<void> deleteStudent(String studentId, int? seatNumber) async {
    await markStudentInactive(studentId, seatNumber);
  }

  // Permanently purge student from records
  Future<void> permanentlyDeleteStudent(String studentId, int? seatNumber) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final batch = _db.batch();
      final studentDocRef = _db.collection('students').doc(studentId);
      batch.delete(studentDocRef);
      if (seatNumber != null) {
        final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
        batch.update(seatDocRef, {
          'is_occupied': false,
          'student_id': null,
          'student_name': null,
          'shift': null,
        });
      }
      await batch.commit();
    } else {
      _mockStudents.removeWhere((s) => s.id == studentId);
      if (seatNumber != null && seatNumber > 0 && seatNumber <= _mockSeats.length) {
        _mockSeats[seatNumber - 1] = SeatInfo(seatNumber: seatNumber);
        _mockSeatsController.add(List.unmodifiable(_mockSeats));
      }
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }
  }

  // Mark Student as Trial
  Future<void> markStudentTrial(String studentId) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      await _db.collection('students').doc(studentId).update({
        'status': 'TRIAL',
        'dues_amount': 0,
      });
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        _mockStudents[idx] = _mockStudents[idx].copyWith(
          status: 'TRIAL',
          duesAmount: 0,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Mark Student with Dues
  Future<void> markStudentDues(
    String studentId,
    int duesAmount, [
    DateTime? dueDate,
  ]) async {
    ensureInitialized();
    final dDate = dueDate ?? DateTime.now();
    if (isFirebaseConnected) {
      await _db.collection('students').doc(studentId).update({
        'status': 'DUES',
        'dues_amount': duesAmount,
        'fee_due_date': Timestamp.fromDate(dDate),
      });
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        _mockStudents[idx] = _mockStudents[idx].copyWith(
          status: 'DUES',
          duesAmount: duesAmount,
          feeDueDate: dDate,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Reactivate / Restore Inactive Student
  Future<void> reactivateStudent(
    String studentId, [
    int? seatNumber,
  ]) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final batch = _db.batch();
      final studentDocRef = _db.collection('students').doc(studentId);
      final updates = <String, dynamic>{
        'status': 'ACTIVE',
        'dues_amount': 0,
      };
      if (seatNumber != null) {
        updates['seat_number'] = seatNumber;
        final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
        batch.update(seatDocRef, {
          'is_occupied': true,
          'student_id': studentId,
        });
      }
      batch.update(studentDocRef, updates);
      await batch.commit();
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final s = _mockStudents[idx];
        if (seatNumber != null && seatNumber > 0 && seatNumber <= _mockSeats.length) {
          _mockSeats[seatNumber - 1] = SeatInfo(
            seatNumber: seatNumber,
            isOccupied: true,
            studentId: studentId,
            studentName: s.name,
            shift: s.shift,
          );
          _mockSeatsController.add(List.unmodifiable(_mockSeats));
        }
        _mockStudents[idx] = s.copyWith(
          status: 'ACTIVE',
          seatNumber: seatNumber ?? s.seatNumber,
          duesAmount: 0,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Update Student details (Name, Phone, Shift, Seat, Note, Status, Due Date, etc.)
  Future<void> updateStudent({
    required String studentId,
    required String name,
    required String phone,
    required String shift,
    int? seatNumber,
    String note = '',
    int? monthlyFee,
    int? duesAmount,
    String? status,
    DateTime? feeDueDate,
  }) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      final studentDocRef = _db.collection('students').doc(studentId);
      final updates = <String, dynamic>{
        'name': name,
        'phone': phone,
        'shift': shift,
        'note': note,
      };
      if (seatNumber != null) updates['seat_number'] = seatNumber;
      if (monthlyFee != null) updates['monthly_fee'] = monthlyFee;
      if (duesAmount != null) updates['dues_amount'] = duesAmount;
      if (status != null) updates['status'] = status;
      if (feeDueDate != null) updates['fee_due_date'] = Timestamp.fromDate(feeDueDate);
      await studentDocRef.update(updates);
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final s = _mockStudents[idx];
        _mockStudents[idx] = s.copyWith(
          name: name,
          phone: phone,
          shift: shift,
          seatNumber: seatNumber ?? s.seatNumber,
          note: note,
          monthlyFee: monthlyFee ?? s.monthlyFee,
          duesAmount: duesAmount ?? s.duesAmount,
          status: status ?? s.status,
          feeDueDate: feeDueDate ?? s.feeDueDate,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Quick Fee Collection & Dues Clearance
  Future<void> collectStudentFee({
    required String studentId,
    required int amount,
    required String paymentMode,
    String notes = 'Monthly Fee Collection',
  }) async {
    ensureInitialized();
    final now = DateTime.now();
    final validUntil = now.add(const Duration(days: 30));

    if (isFirebaseConnected) {
      final studentDocRef = _db.collection('students').doc(studentId);
      final paymentDocRef = _db.collection('payments').doc();
      final batch = _db.batch();

      batch.update(studentDocRef, {
        'status': 'ACTIVE',
        'dues_amount': 0,
        'fee_due_date': Timestamp.fromDate(validUntil),
        'payment_mode': paymentMode,
      });

      batch.set(paymentDocRef, {
        'payment_id': paymentDocRef.id,
        'student_id': studentId,
        'amount': amount,
        'date': Timestamp.fromDate(now),
        'valid_until': Timestamp.fromDate(validUntil),
        'payment_mode': paymentMode,
        'notes': notes,
      });

      await batch.commit();
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final s = _mockStudents[idx];
        _mockStudents[idx] = s.copyWith(
          status: 'ACTIVE',
          duesAmount: 0,
          feeDueDate: validUntil,
          paymentMode: paymentMode,
        );
        _mockPayments.insert(
          0,
          PaymentTransaction(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            studentId: studentId,
            studentName: s.name,
            studentPhone: s.phone,
            seatNumber: s.seatNumber ?? 1,
            shift: s.shift,
            amount: amount,
            date: now,
            paymentMode: paymentMode,
            notes: notes,
          ),
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        _mockPaymentsController.add(List.unmodifiable(_mockPayments));
      }
    }
  }
}