import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time seat stream
  Stream<QuerySnapshot> streamSeats() {
    return _db.collection('seats').orderBy('seat_number').snapshots();
  }

  // Real-time student list stream
  Stream<QuerySnapshot> streamStudents() {
    return _db.collection('students').orderBy('joined_at', descending: true).snapshots();
  }

  // Atomic Seat Assignment Transaction (Prevents double-booking across 10 devices)
  Future<void> assignSeatAndRegisterStudent({
    required int seatNumber,
    required String studentName,
    required String phone,
    required String shift,
    required String deviceUserId,
  }) async {
    final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
    final studentDocRef = _db.collection('students').doc();
    final paymentDocRef = _db.collection('payments').doc();

    await _db.runTransaction((transaction) async {
      final seatSnapshot = await transaction.get(seatDocRef);

      if (seatSnapshot.exists && seatSnapshot.get('is_occupied') == true) {
        throw Exception('Seat $seatNumber was just occupied by another manager!');
      }

      final now = DateTime.now();
      final validUntil = now.add(const Duration(days: 30));

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
      transaction.set(seatDocRef, {
        'seat_number': seatNumber,
        'is_occupied': true,
        'student_id': studentDocRef.id,
        'student_name': studentName,
        'shift': shift,
        'last_updated_by': deviceUserId,
      }, SetOptions(merge: true));

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
  }

  // Vacate Seat
  Future<void> vacateSeat(int seatNumber, String studentId) async {
    final batch = _db.batch();
    final seatDocRef = _db.collection('seats').doc('seat_$seatNumber');
    final studentDocRef = _db.collection('students').doc(studentId);

    batch.update(seatDocRef, {
      'is_occupied': false,
      'student_id': null,
      'student_name': null,
    });

    batch.update(studentDocRef, {
      'status': 'INACTIVE',
      'seat_number': null,
    });

    await batch.commit();
  }
}