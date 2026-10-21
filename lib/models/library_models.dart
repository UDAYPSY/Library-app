import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryProfile {
  String libraryName;
  String city;
  String adminName;
  String adminEmail;
  String adminPhone;
  String logoEmblem;
  String? logoBase64;
  String? logoUrl;
  String tagline;

  bool get hasCustomLogo => (logoBase64 != null && logoBase64!.isNotEmpty) || (logoUrl != null && logoUrl!.isNotEmpty);
  int whatsappCredits;
  int messagesSentCount;
  bool whatsappNotifications;
  bool autoFeeReminders;
  bool autoWelcomeMessage;
  bool autoPaymentReceipt;
  bool remind3DaysBefore;
  bool remindOnExpiry;
  bool remindAfterExpiry;
  String welcomeTemplate;
  String reminderTemplate;
  String receiptTemplate;

  LibraryProfile({
    this.libraryName = 'Patna Central Library',
    this.city = 'City Center, Main St',
    this.adminName = 'Nivi',
    this.adminEmail = 'udaypratapsi2022@gmail.com',
    this.adminPhone = '94574 64850',
    this.logoEmblem = 'Book & Torch',
    this.logoBase64,
    this.logoUrl,
    this.tagline = 'Silence • Focus • Success',
    this.whatsappCredits = 150,
    this.messagesSentCount = 24,
    this.whatsappNotifications = true,
    this.autoFeeReminders = true,
    this.autoWelcomeMessage = true,
    this.autoPaymentReceipt = true,
    this.remind3DaysBefore = true,
    this.remindOnExpiry = true,
    this.remindAfterExpiry = true,
    this.welcomeTemplate = 'Hello {student_name}, welcome to {library_name}! Your reserved seat is Seat S-{seat_number} ({shift}). Happy studying!',
    this.reminderTemplate = 'Dear {student_name}, this is a gentle reminder that your seat fee of ₹{due_amount} at {library_name} is due on {due_date}. Thank you!',
    this.receiptTemplate = 'Payment Received! Dear {student_name}, we have received ₹{amount} via {mode} for your seat renewal at {library_name}. Valid until {valid_until}.',
  });

  Map<String, dynamic> toMap() {
    return {
      'library_name': libraryName,
      'city': city,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_phone': adminPhone,
      'logo_emblem': logoEmblem,
      'logo_base64': logoBase64,
      'logo_url': logoUrl,
      'tagline': tagline,
      'whatsapp_credits': whatsappCredits,
      'messages_sent_count': messagesSentCount,
      'whatsapp_notifications': whatsappNotifications,
      'auto_fee_reminders': autoFeeReminders,
      'auto_welcome_message': autoWelcomeMessage,
      'auto_payment_receipt': autoPaymentReceipt,
      'remind_3_days_before': remind3DaysBefore,
      'remind_on_expiry': remindOnExpiry,
      'remind_after_expiry': remindAfterExpiry,
      'welcome_template': welcomeTemplate,
      'reminder_template': reminderTemplate,
      'receipt_template': receiptTemplate,
    };
  }

  factory LibraryProfile.fromMap(Map<String, dynamic> map) {
    return LibraryProfile(
      libraryName: map['library_name'] ?? 'Patna Central Library',
      city: map['city'] ?? 'City Center, Main St',
      adminName: map['admin_name'] ?? 'Nivi',
      adminEmail: map['admin_email'] ?? '',
      adminPhone: map['admin_phone'] ?? '',
      logoEmblem: map['logo_emblem'] ?? 'Book & Torch',
      logoBase64: map['logo_base64'] as String?,
      logoUrl: map['logo_url'] as String?,
      tagline: map['tagline'] ?? 'Silence • Focus • Success',
      whatsappCredits: (map['whatsapp_credits'] as num?)?.toInt() ?? 150,
      messagesSentCount: (map['messages_sent_count'] as num?)?.toInt() ?? 24,
      whatsappNotifications: map['whatsapp_notifications'] ?? true,
      autoFeeReminders: map['auto_fee_reminders'] ?? true,
      autoWelcomeMessage: map['auto_welcome_message'] ?? true,
      autoPaymentReceipt: map['auto_payment_receipt'] ?? true,
      remind3DaysBefore: map['remind_3_days_before'] ?? true,
      remindOnExpiry: map['remind_on_expiry'] ?? true,
      remindAfterExpiry: map['remind_after_expiry'] ?? true,
      welcomeTemplate: map['welcome_template'] ?? 'Hello {student_name}, welcome to {library_name}! Your reserved seat is Seat S-{seat_number} ({shift}). Happy studying!',
      reminderTemplate: map['reminder_template'] ?? 'Dear {student_name}, this is a gentle reminder that your seat fee of ₹{due_amount} at {library_name} is due on {due_date}. Thank you!',
      receiptTemplate: map['receipt_template'] ?? 'Payment Received! Dear {student_name}, we have received ₹{amount} via {mode} for your seat renewal at {library_name}. Valid until {valid_until}.',
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
  bool isActive;
  bool isSystemSlot;

  ShiftConfig({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    this.monthlyFee = 500,
    this.isActive = true,
    this.isSystemSlot = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'monthly_fee': monthlyFee,
      'is_active': isActive,
      'is_system_slot': isSystemSlot,
    };
  }

  factory ShiftConfig.fromMap(Map<String, dynamic> map) {
    return ShiftConfig(
      id: map['id'] ?? 'shift_1',
      name: map['name'] ?? 'Full Day',
      startsAt: map['starts_at'] ?? '06:00 AM',
      endsAt: map['ends_at'] ?? '10:00 PM',
      monthlyFee: (map['monthly_fee'] as num?)?.toInt() ?? 500,
      isActive: map['is_active'] ?? true,
      isSystemSlot: map['is_system_slot'] ?? false,
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

  final String note;
  final int duesAmount;
  final String sectionName;

  final String fatherName;
  final String address;
  final String aadhaarNumber;
  final String preparationFor;
  final String gender;
  final String? photoBase64;

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
    this.note = '',
    this.duesAmount = 0,
    this.sectionName = 'Main Hall',
    this.fatherName = '',
    this.address = '',
    this.aadhaarNumber = '',
    this.preparationFor = '',
    this.gender = 'Male',
    this.photoBase64,
  });

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  bool get hasDues {
    if (status == 'INACTIVE' || status == 'TRIAL') return false;
    if (status == 'DUES' || duesAmount > 0) return true;
    if (feeDueDate != null && feeDueDate!.isBefore(DateTime.now())) return true;
    return false;
  }

  int get effectiveDues {
    if (duesAmount > 0) return duesAmount;
    if (hasDues) return monthlyFee;
    return 0;
  }

  StudentInfo copyWith({
    String? id,
    String? name,
    String? phone,
    int? seatNumber,
    String? shift,
    String? status,
    DateTime? feeDueDate,
    DateTime? joinedAt,
    int? monthlyFee,
    String? paymentMode,
    String? note,
    int? duesAmount,
    String? sectionName,
    String? fatherName,
    String? address,
    String? aadhaarNumber,
    String? preparationFor,
    String? gender,
    String? photoBase64,
  }) {
    return StudentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      seatNumber: seatNumber ?? this.seatNumber,
      shift: shift ?? this.shift,
      status: status ?? this.status,
      feeDueDate: feeDueDate ?? this.feeDueDate,
      joinedAt: joinedAt ?? this.joinedAt,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      duesAmount: duesAmount ?? this.duesAmount,
      sectionName: sectionName ?? this.sectionName,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      preparationFor: preparationFor ?? this.preparationFor,
      gender: gender ?? this.gender,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'seat_number': seatNumber,
      'shift': shift,
      'status': status,
      'fee_due_date': feeDueDate?.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
      'monthly_fee': monthlyFee,
      'payment_mode': paymentMode,
      'note': note,
      'dues_amount': duesAmount,
      'section_name': sectionName,
      'father_name': fatherName,
      'address': address,
      'aadhaar_number': aadhaarNumber,
      'preparation_for': preparationFor,
      'gender': gender,
      'photo_base64': photoBase64,
    };
  }

  factory StudentInfo.fromMap(Map<String, dynamic> map) =>
      StudentInfo.fromFirestore((map['id'] as String?) ?? '', map);

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
      note: (data['note'] as String?) ?? '',
      duesAmount: (data['dues_amount'] as num?)?.toInt() ?? 0,
      sectionName: (data['section_name'] as String?) ?? 'Main Hall',
      fatherName: (data['father_name'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      aadhaarNumber: (data['aadhaar_number'] as String?) ?? '',
      preparationFor: (data['preparation_for'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? 'Male',
      photoBase64: data['photo_base64'] as String?,
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

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
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

  Map<String, dynamic> toJsonMap() {
    return {
      'payment_id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_phone': studentPhone,
      'seat_number': seatNumber,
      'shift': shift,
      'amount': amount,
      'date': date.toIso8601String(),
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

