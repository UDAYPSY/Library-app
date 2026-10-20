import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class SeatInfo {
  final int seatNumber;
  final bool isOccupied;
  final String studentName;
  final String studentId;
  final String shift;

  const SeatInfo({
    required this.seatNumber,
    this.isOccupied = false,
    this.studentName = '',
    this.studentId = '',
    this.shift = '',
  });

  factory SeatInfo.fromMap(int seatNumber, Map<String, dynamic>? data) {
    if (data == null) {
      return SeatInfo(seatNumber: seatNumber);
    }
    return SeatInfo(
      seatNumber: (data['seat_number'] as num?)?.toInt() ?? seatNumber,
      isOccupied: data['is_occupied'] == true,
      studentName: (data['student_name'] as String?) ?? '',
      studentId: (data['student_id'] as String?) ?? '',
      shift: (data['shift'] as String?) ?? 'Full Day',
    );
  }
}

class StudentInfo {
  final String id;
  final String name;
  final String phone;
  final int? seatNumber;
  final String shift;
  final String status;
  final DateTime? feeDueDate;
  final DateTime? joinedAt;

  const StudentInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.seatNumber,
    this.shift = 'Full Day',
    this.status = 'ACTIVE',
    this.feeDueDate,
    this.joinedAt,
  });

  factory StudentInfo.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return StudentInfo(
      id: id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      seatNumber: (data['seat_number'] as num?)?.toInt(),
      shift: (data['shift'] as String?) ?? 'Full Day',
      status: (data['status'] as String?) ?? 'ACTIVE',
      feeDueDate: parseDate(data['fee_due_date']),
      joinedAt: parseDate(data['joined_at']),
    );
  }
}

class LibraryService {
  static const int totalSeatsCount = 50;

  // In-memory mock fallback state for offline preview mode
  static final List<SeatInfo> _mockSeats = List.generate(
    totalSeatsCount,
    (index) => SeatInfo(seatNumber: index + 1),
  );
  static final List<StudentInfo> _mockStudents = [];

  static final StreamController<List<SeatInfo>> _mockSeatsController =
      StreamController<List<SeatInfo>>.broadcast();
  static final StreamController<List<StudentInfo>> _mockStudentsController =
      StreamController<List<StudentInfo>>.broadcast();

  bool get isFirebaseConnected => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    return FirebaseFirestore.instance;
  }

  // Real-time seat stream (Cloud Firestore or In-Memory Demo)
  Stream<List<SeatInfo>> streamSeats() {
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
      // Return stream with initial sync
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

  // Atomic Seat Assignment Transaction
  Future<void> assignSeatAndRegisterStudent({
    required int seatNumber,
    required String studentName,
    required String phone,
    required String shift,
    required String deviceUserId,
  }) async {
    final now = DateTime.now();
    final validUntil = now.add(const Duration(days: 30));

    if (isFirebaseConnected) {
      final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
      final studentDocRef = _db.collection('students').doc();
      final paymentDocRef = _db.collection('payments').doc();

      await _db.runTransaction((transaction) async {
        final seatSnapshot = await transaction.get(seatDocRef);

        if (seatSnapshot.exists) {
          final data = seatSnapshot.data();
          if (data != null && data['is_occupied'] == true) {
            throw Exception('Seat $seatNumber is already occupied!');
          }
        }

        // 1. Create Student record
        transaction.set(studentDocRef, {
          'id': studentDocRef.id,
          'name': studentName,
          'phone': phone,
          'seat_number': seatNumber,
          'shift': shift,
          'fee_due_date': Timestamp.fromDate(validUntil),
          'status': 'ACTIVE',
          'joined_at': Timestamp.fromDate(now),
        });

        // 2. Lock Seat
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

        // 3. Log initial ₹500 fee
        transaction.set(paymentDocRef, {
          'payment_id': paymentDocRef.id,
          'student_id': studentDocRef.id,
          'student_name': studentName,
          'amount': 500,
          'date': Timestamp.fromDate(now),
          'valid_until': Timestamp.fromDate(validUntil),
          'collected_by': deviceUserId,
        });
      });
    } else {
      // In-memory mock assignment
      final index = seatNumber - 1;
      if (index >= 0 && index < _mockSeats.length) {
        if (_mockSeats[index].isOccupied) {
          throw Exception('Seat $seatNumber is already occupied!');
        }
        final studentId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
        _mockSeats[index] = SeatInfo(
          seatNumber: seatNumber,
          isOccupied: true,
          studentId: studentId,
          studentName: studentName,
          shift: shift,
        );
        _mockStudents.insert(
          0,
          StudentInfo(
            id: studentId,
            name: studentName,
            phone: phone,
            seatNumber: seatNumber,
            shift: shift,
            status: 'ACTIVE',
            feeDueDate: validUntil,
            joinedAt: now,
          ),
        );
        _mockSeatsController.add(List.unmodifiable(_mockSeats));
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }

  // Vacate Seat
  Future<void> vacateSeat(int seatNumber, String? studentId) async {
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
            );
          }
        }
        _mockSeatsController.add(List.unmodifiable(_mockSeats));
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }
  }
}