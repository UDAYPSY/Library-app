import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryProfile {
  String libraryName;
  String city;
  String adminName;
  String adminEmail;
  String adminPhone;

  LibraryProfile({
    this.libraryName = 'Patna Central Library',
    this.city = 'City Center, Main St',
    this.adminName = 'Nivi',
    this.adminEmail = 'udaypratapsi2022@gmail.com',
    this.adminPhone = '94574 64850',
  });

  Map<String, dynamic> toMap() {
    return {
      'library_name': libraryName,
      'city': city,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_phone': adminPhone,
    };
  }

  factory LibraryProfile.fromMap(Map<String, dynamic> map) {
    return LibraryProfile(
      libraryName: map['library_name'] ?? 'Patna Central Library',
      city: map['city'] ?? 'City Center, Main St',
      adminName: map['admin_name'] ?? 'Nivi',
      adminEmail: map['admin_email'] ?? '',
      adminPhone: map['admin_phone'] ?? '',
    );
  }
}

class SectionConfig {
  String id;
  String name;
  int startSeat;
  int endSeat;

  SectionConfig({
    required this.id,
    required this.name,
    this.startSeat = 1,
    this.endSeat = 35,
  });

  int get totalSeats => (endSeat >= startSeat && startSeat > 0) ? (endSeat - startSeat + 1) : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_seat': startSeat,
      'end_seat': endSeat,
      'total_seats': totalSeats,
    };
  }

  factory SectionConfig.fromMap(Map<String, dynamic> map) {
    return SectionConfig(
      id: map['id'] ?? 'sec_1',
      name: map['name'] ?? 'Main Hall',
      startSeat: (map['start_seat'] as num?)?.toInt() ?? 1,
      endSeat: (map['end_seat'] as num?)?.toInt() ?? 35,
    );
  }
}

class ShiftConfig {
  String id;
  String name;
  String startsAt;
  String endsAt;
  int monthlyFee;

  ShiftConfig({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    this.monthlyFee = 500,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'monthly_fee': monthlyFee,
    };
  }

  factory ShiftConfig.fromMap(Map<String, dynamic> map) {
    return ShiftConfig(
      id: map['id'] ?? 'shift_1',
      name: map['name'] ?? 'Full Day',
      startsAt: map['starts_at'] ?? '06:00 AM',
      endsAt: map['ends_at'] ?? '10:00 PM',
      monthlyFee: (map['monthly_fee'] as num?)?.toInt() ?? 500,
    );
  }
}

class SeatInfo {
  final int seatNumber;
  final bool isOccupied;
  final String studentName;
  final String studentId;
  final String shift;
  final String sectionName;

  const SeatInfo({
    required this.seatNumber,
    this.isOccupied = false,
    this.studentName = '',
    this.studentId = '',
    this.shift = '',
    this.sectionName = 'Main Hall',
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
      sectionName: (data['section_name'] as String?) ?? 'Main Hall',
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
  final int monthlyFee;
  final String paymentMode;

  const StudentInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.seatNumber,
    this.shift = 'Full Day',
    this.status = 'ACTIVE',
    this.feeDueDate,
    this.joinedAt,
    this.monthlyFee = 500,
    this.paymentMode = 'UPI',
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
      monthlyFee: (data['monthly_fee'] as num?)?.toInt() ?? 500,
      paymentMode: (data['payment_mode'] as String?) ?? 'UPI',
    );
  }
}

class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime date;
  final String paymentMode;
  final String note;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.paymentMode = 'Cash',
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'payment_mode': paymentMode,
      'note': note,
    };
  }

  factory ExpenseItem.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExpenseItem(
      id: id,
      title: (data['title'] as String?) ?? 'Expense',
      category: (data['category'] as String?) ?? 'General',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: parseDate(data['date']),
      paymentMode: (data['payment_mode'] as String?) ?? 'Cash',
      note: (data['note'] as String?) ?? '',
    );
  }
}

class PaymentTransaction {
  final String id;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final int? seatNumber;
  final String shift;
  final int amount;
  final DateTime date;
  final String paymentMode;
  final String notes;

  const PaymentTransaction({
    required this.id,
    this.studentId = '',
    required this.studentName,
    this.studentPhone = '',
    this.seatNumber,
    this.shift = 'Full Day',
    required this.amount,
    required this.date,
    this.paymentMode = 'UPI',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_phone': studentPhone,
      'seat_number': seatNumber,
      'shift': shift,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'payment_mode': paymentMode,
      'notes': notes,
    };
  }

  factory PaymentTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentTransaction(
      id: id,
      studentId: (data['student_id'] as String?) ?? '',
      studentName: (data['student_name'] as String?) ?? '',
      studentPhone: (data['student_phone'] as String?) ?? '',
      seatNumber: (data['seat_number'] as num?)?.toInt(),
      shift: (data['shift'] as String?) ?? 'Full Day',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: parseDate(data['date']),
      paymentMode: (data['payment_mode'] as String?) ?? 'UPI',
      notes: (data['notes'] as String?) ?? (data['note'] as String?) ?? '',
    );
  }
}

