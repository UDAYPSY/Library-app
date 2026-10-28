import 'package:cloud_firestore/cloud_firestore.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? role;
  final String? userName;
  final String? userId;

  const AuthResult({
    required this.success,
    this.message,
    this.role,
    this.userName,
    this.userId,
  });
}

class LibraryProfile {
  String libraryId;
  String libraryName;
  String city;
  String adminName;
  String adminEmail;
  String adminPhone;
  String upiId;
  String logoEmblem;
  String? logoBase64;
  String? logoUrl;
  String tagline;
  String portalBaseUrl;

  String get effectiveUpiId {
    if (upiId.trim().isNotEmpty) return upiId.trim();
    final cleanPhone = adminPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length >= 10) {
      final p10 = cleanPhone.substring(cleanPhone.length - 10);
      return '$p10@upi';
    }
    return '9457464850@upi';
  }

  String generateUpiPaymentUrl({
    required int amount,
    required String studentName,
    String? note,
  }) {
    final vpa = effectiveUpiId;
    final name = Uri.encodeComponent(libraryName.isNotEmpty ? libraryName : 'Library');
    final memo = Uri.encodeComponent(note ?? 'Fee: $studentName');
    return 'upi://pay?pa=$vpa&pn=$name&am=$amount&cu=INR&tn=$memo';
  }

  bool get hasCustomLogo => (logoBase64 != null && logoBase64!.isNotEmpty) || (logoUrl != null && logoUrl!.isNotEmpty);
  String get address => city;
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
  String followupTemplate;
  String seatChangeTemplate;
  String shiftChangeTemplate;
  String seatAllotmentTemplate;
  DateTime? trialStartedAt;
  DateTime? subscriptionExpiresAt;

  bool get isTrialExpired {
    if (subscriptionExpiresAt != null && subscriptionExpiresAt!.isAfter(DateTime.now())) return false;
    if (trialStartedAt == null) return false;
    return DateTime.now().difference(trialStartedAt!).inDays > 30;
  }

  int get trialDaysRemaining {
    if (trialStartedAt == null) return 30;
    return (30 - DateTime.now().difference(trialStartedAt!).inDays).clamp(0, 30);
  }

  LibraryProfile({
    this.libraryId = 'lib_patna_central',
    this.libraryName = 'Patna Central Library',
    this.city = 'City Center, Main St',
    this.adminName = 'Admin',
    this.adminEmail = 'manageyourlib@gmail.com',
    this.adminPhone = '9457464850',
    this.upiId = '9457464850@upi',
    this.logoEmblem = 'Book & Torch',
    this.logoBase64,
    this.logoUrl,
    this.tagline = 'Silence • Focus • Success',
    this.portalBaseUrl = 'https://udaypsy.github.io/Library-app',
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
    this.followupTemplate = 'Hello {student_name}, this is a follow-up from {library_name} regarding your seat S-{seat_number} ({shift}). Let us know if you need any assistance with your membership.',
    this.seatChangeTemplate = 'Hello {student_name}, your seat at {library_name} has been updated to Seat S-{seat_number} ({shift}). Happy studying!',
    this.shiftChangeTemplate = 'Hello {student_name}, your study shift at {library_name} has been updated to {shift} (Seat S-{seat_number}). Reach out if you have any questions!',
    this.seatAllotmentTemplate = 'Welcome {student_name}! Your seat S-{seat_number} has been allocated under {shift} at {library_name}. Please present this confirmation at reception.',
    this.trialStartedAt,
    this.subscriptionExpiresAt,
  });

  LibraryProfile copyWith({
    String? libraryId,
    String? libraryName,
    String? city,
    String? adminName,
    String? adminEmail,
    String? adminPhone,
    String? upiId,
    String? logoEmblem,
    String? logoBase64,
    String? logoUrl,
    String? tagline,
    String? portalBaseUrl,
    int? whatsappCredits,
    int? messagesSentCount,
    bool? whatsappNotifications,
    bool? autoFeeReminders,
    bool? autoWelcomeMessage,
    bool? autoPaymentReceipt,
    bool? remind3DaysBefore,
    bool? remindOnExpiry,
    bool? remindAfterExpiry,
    String? welcomeTemplate,
    String? reminderTemplate,
    String? receiptTemplate,
    String? followupTemplate,
    String? seatChangeTemplate,
    String? shiftChangeTemplate,
    String? seatAllotmentTemplate,
    DateTime? trialStartedAt,
    DateTime? subscriptionExpiresAt,
  }) {
    return LibraryProfile(
      libraryId: libraryId ?? this.libraryId,
      libraryName: libraryName ?? this.libraryName,
      city: city ?? this.city,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      adminPhone: adminPhone ?? this.adminPhone,
      upiId: upiId ?? this.upiId,
      logoEmblem: logoEmblem ?? this.logoEmblem,
      logoBase64: logoBase64 ?? this.logoBase64,
      logoUrl: logoUrl ?? this.logoUrl,
      tagline: tagline ?? this.tagline,
      portalBaseUrl: portalBaseUrl ?? this.portalBaseUrl,
      whatsappCredits: whatsappCredits ?? this.whatsappCredits,
      messagesSentCount: messagesSentCount ?? this.messagesSentCount,
      whatsappNotifications: whatsappNotifications ?? this.whatsappNotifications,
      autoFeeReminders: autoFeeReminders ?? this.autoFeeReminders,
      autoWelcomeMessage: autoWelcomeMessage ?? this.autoWelcomeMessage,
      autoPaymentReceipt: autoPaymentReceipt ?? this.autoPaymentReceipt,
      remind3DaysBefore: remind3DaysBefore ?? this.remind3DaysBefore,
      remindOnExpiry: remindOnExpiry ?? this.remindOnExpiry,
      remindAfterExpiry: remindAfterExpiry ?? this.remindAfterExpiry,
      welcomeTemplate: welcomeTemplate ?? this.welcomeTemplate,
      reminderTemplate: reminderTemplate ?? this.reminderTemplate,
      receiptTemplate: receiptTemplate ?? this.receiptTemplate,
      followupTemplate: followupTemplate ?? this.followupTemplate,
      seatChangeTemplate: seatChangeTemplate ?? this.seatChangeTemplate,
      shiftChangeTemplate: shiftChangeTemplate ?? this.shiftChangeTemplate,
      seatAllotmentTemplate: seatAllotmentTemplate ?? this.seatAllotmentTemplate,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'library_id': libraryId,
      'library_name': libraryName,
      'city': city,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_phone': adminPhone,
      'upi_id': upiId,
      'logo_emblem': logoEmblem,
      'logo_base64': logoBase64,
      'logo_url': logoUrl,
      'tagline': tagline,
      'portal_base_url': portalBaseUrl,
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
      'followup_template': followupTemplate,
      'seat_change_template': seatChangeTemplate,
      'shift_change_template': shiftChangeTemplate,
      'seat_allotment_template': seatAllotmentTemplate,
      'trial_started_at': trialStartedAt?.toIso8601String(),
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
    };
  }

  factory LibraryProfile.fromMap(Map<String, dynamic> map) {
    return LibraryProfile(
      libraryId: map['library_id'] ?? 'lib_patna_central',
      libraryName: map['library_name'] ?? 'Patna Central Library',
      city: map['city'] ?? 'City Center, Main St',
      adminName: map['admin_name'] ?? 'Admin',
      adminEmail: map['admin_email'] ?? '',
      adminPhone: map['admin_phone'] ?? '',
      upiId: map['upi_id'] ?? '9457464850@upi',
      logoEmblem: map['logo_emblem'] ?? 'Book & Torch',
      logoBase64: map['logo_base64'] as String?,
      logoUrl: map['logo_url'] as String?,
      tagline: map['tagline'] ?? 'Silence • Focus • Success',
      portalBaseUrl: map['portal_base_url'] ?? 'https://udaypsy.github.io/Library-app',
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
      followupTemplate: map['followup_template'] ?? 'Hello {student_name}, this is a follow-up from {library_name} regarding your seat S-{seat_number} ({shift}). Let us know if you need any assistance with your membership.',
      seatChangeTemplate: map['seat_change_template'] ?? 'Hello {student_name}, your seat at {library_name} has been updated to Seat S-{seat_number} ({shift}). Happy studying!',
      shiftChangeTemplate: map['shift_change_template'] ?? 'Hello {student_name}, your study shift at {library_name} has been updated to {shift} (Seat S-{seat_number}). Reach out if you have any questions!',
      seatAllotmentTemplate: map['seat_allotment_template'] ?? 'Welcome {student_name}! Your seat S-{seat_number} has been allocated under {shift} at {library_name}. Please present this confirmation at reception.',
      trialStartedAt: map['trial_started_at'] != null ? DateTime.tryParse(map['trial_started_at']) : null,
      subscriptionExpiresAt: map['subscription_expires_at'] != null ? DateTime.tryParse(map['subscription_expires_at']) : null,
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
  final int advanceAmount;
  final String sectionName;

  final String fatherName;
  final String address;
  final String aadhaarNumber;
  final String preparationFor;
  final String gender;
  final String? photoBase64;
  final DateTime? updatedAt;

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
    this.advanceAmount = 0,
    this.sectionName = 'Main Hall',
    this.fatherName = '',
    this.address = '',
    this.aadhaarNumber = '',
    this.preparationFor = '',
    this.gender = 'Male',
    this.photoBase64,
    this.updatedAt,
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

  static const Object _sentinel = Object();

  StudentInfo copyWith({
    String? id,
    String? name,
    String? phone,
    Object? seatNumber = _sentinel,
    bool clearSeatNumber = false,
    String? shift,
    String? status,
    DateTime? feeDueDate,
    DateTime? joinedAt,
    int? monthlyFee,
    String? paymentMode,
    String? note,
    int? duesAmount,
    int? advanceAmount,
    String? sectionName,
    String? fatherName,
    String? address,
    String? aadhaarNumber,
    String? preparationFor,
    String? gender,
    String? photoBase64,
    DateTime? updatedAt,
  }) {
    return StudentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      seatNumber: clearSeatNumber
          ? null
          : (identical(seatNumber, _sentinel)
              ? this.seatNumber
              : seatNumber as int?),
      shift: shift ?? this.shift,
      status: status ?? this.status,
      feeDueDate: feeDueDate ?? this.feeDueDate,
      joinedAt: joinedAt ?? this.joinedAt,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      duesAmount: duesAmount ?? this.duesAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      sectionName: sectionName ?? this.sectionName,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      preparationFor: preparationFor ?? this.preparationFor,
      gender: gender ?? this.gender,
      photoBase64: photoBase64 ?? this.photoBase64,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'advance_amount': advanceAmount,
      'section_name': sectionName,
      'father_name': fatherName,
      'address': address,
      'aadhaar_number': aadhaarNumber,
      'preparation_for': preparationFor,
      'gender': gender,
      'photo_base64': photoBase64,
      'updated_at': updatedAt?.toIso8601String(),
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
      advanceAmount: (data['advance_amount'] as num?)?.toInt() ?? 0,
      sectionName: (data['section_name'] as String?) ?? 'Main Hall',
      fatherName: (data['father_name'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      aadhaarNumber: (data['aadhaar_number'] as String?) ?? '',
      preparationFor: (data['preparation_for'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? 'Male',
      photoBase64: data['photo_base64'] as String?,
      updatedAt: parseDate(data['updated_at']),
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
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? durationMonths;

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
    this.validFrom,
    this.validUntil,
    this.durationMonths,
  });

  PaymentTransaction copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentPhone,
    int? seatNumber,
    String? shift,
    int? amount,
    DateTime? date,
    String? paymentMode,
    String? notes,
    DateTime? validFrom,
    DateTime? validUntil,
    int? durationMonths,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhone: studentPhone ?? this.studentPhone,
      seatNumber: seatNumber ?? this.seatNumber,
      shift: shift ?? this.shift,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      durationMonths: durationMonths ?? this.durationMonths,
    );
  }

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
      if (validFrom != null) 'valid_from': Timestamp.fromDate(validFrom!),
      if (validUntil != null) 'valid_until': Timestamp.fromDate(validUntil!),
      if (durationMonths != null) 'duration_months': durationMonths,
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
      if (validFrom != null) 'valid_from': validFrom!.toIso8601String(),
      if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
      if (durationMonths != null) 'duration_months': durationMonths,
    };
  }

  factory PaymentTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
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
      validFrom: parseOptionalDate(data['valid_from']),
      validUntil: parseOptionalDate(data['valid_until']),
      durationMonths: (data['duration_months'] as num?)?.toInt(),
    );
  }
}

class StaffMember {
  final String id;
  final String name;
  final String phone;
  final String role;
  final DateTime addedAt;
  final bool isActive;
  final String? email;
  final String? pinHash;

  const StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'Receptionist',
    required this.addedAt,
    this.isActive = true,
    this.email,
    this.pinHash,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    DateTime? addedAt,
    bool? isActive,
    String? email,
    String? pinHash,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      pinHash: pinHash ?? this.pinHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'added_at': addedAt.toIso8601String(),
      'is_active': isActive,
      'email': email,
      'pin_hash': pinHash,
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Receptionist',
      addedAt: map['added_at'] != null ? (DateTime.tryParse(map['added_at']) ?? DateTime.now()) : DateTime.now(),
      isActive: map['is_active'] ?? true,
      email: map['email'] as String?,
      pinHash: (map['pin_hash'] ?? map['pin']) as String?,
    );
  }
}

class LibraryBranch {
  final String id;
  final String name;
  final String address;
  final int totalSeats;
  final bool isDefault;

  const LibraryBranch({
    required this.id,
    required this.name,
    required this.address,
    this.totalSeats = 35,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'total_seats': totalSeats,
      'is_default': isDefault,
    };
  }

  factory LibraryBranch.fromMap(Map<String, dynamic> map) {
    return LibraryBranch(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Main Branch',
      address: map['address'] ?? '',
      totalSeats: (map['total_seats'] as num?)?.toInt() ?? 35,
      isDefault: map['is_default'] ?? false,
    );
  }
}

class RegistrationRequest {
  final String id;
  final String studentName;
  final String phone;
  final String fatherName;
  final String address;
  final String aadhaarNumber;
  final String preparationFor;
  final String gender;
  final String shift;
  final String? photoBase64;
  final DateTime createdAt;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'
  final String libraryId;
  final String? rejectionReason;
  final int? preferredMonthlyFee;

  const RegistrationRequest({
    required this.id,
    required this.studentName,
    required this.phone,
    this.fatherName = '',
    this.address = '',
    this.aadhaarNumber = '',
    this.preparationFor = 'Competitive Exams',
    this.gender = 'Male',
    this.shift = 'Full Day',
    this.photoBase64,
    required this.createdAt,
    this.status = 'PENDING',
    this.libraryId = '',
    this.rejectionReason,
    this.preferredMonthlyFee,
  });

  RegistrationRequest copyWith({
    String? id,
    String? studentName,
    String? phone,
    String? fatherName,
    String? address,
    String? aadhaarNumber,
    String? preparationFor,
    String? gender,
    String? shift,
    String? photoBase64,
    DateTime? createdAt,
    String? status,
    String? libraryId,
    String? rejectionReason,
    int? preferredMonthlyFee,
  }) {
    return RegistrationRequest(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      phone: phone ?? this.phone,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      preparationFor: preparationFor ?? this.preparationFor,
      gender: gender ?? this.gender,
      shift: shift ?? this.shift,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      libraryId: libraryId ?? this.libraryId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      preferredMonthlyFee: preferredMonthlyFee ?? this.preferredMonthlyFee,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_name': studentName,
      'name': studentName,
      'phone': phone,
      'father_name': fatherName,
      'address': address,
      'aadhaar_number': aadhaarNumber,
      'preparation_for': preparationFor,
      'gender': gender,
      'shift': shift,
      'photo_base64': photoBase64,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'library_id': libraryId,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (preferredMonthlyFee != null) 'preferred_monthly_fee': preferredMonthlyFee,
    };
  }

  factory RegistrationRequest.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return RegistrationRequest(
      id: map['id'] ?? '',
      studentName: map['student_name'] ?? map['name'] ?? '',
      phone: map['phone'] ?? '',
      fatherName: map['father_name'] ?? '',
      address: map['address'] ?? '',
      aadhaarNumber: map['aadhaar_number'] ?? '',
      preparationFor: map['preparation_for'] ?? 'Competitive Exams',
      gender: map['gender'] ?? 'Male',
      shift: map['shift'] ?? 'Full Day',
      photoBase64: map['photo_base64'] as String?,
      createdAt: parseDate(map['created_at']),
      status: map['status'] ?? 'PENDING',
      libraryId: map['library_id'] ?? '',
      rejectionReason: map['rejection_reason'] as String?,
      preferredMonthlyFee: (map['preferred_monthly_fee'] as num?)?.toInt(),
    );
  }
}


