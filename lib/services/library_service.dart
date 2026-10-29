import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../models/library_models.dart';
import 'local_storage_service.dart';
import 'biometric_auth_service.dart';

class LibraryService {
  // Static activity logger & note helper (persists all notes without overwriting)
  static String appendNote(String? currentNote, String newEntry) {
    var cur = (currentNote ?? '').trim();
    final raw = newEntry.trim();
    if (raw.isEmpty) return cur;

    final lines = raw.split('\n');
    for (var line in lines) {
      var entry = line.trim();
      while (entry.startsWith('•')) {
        entry = entry.substring(1).trim();
      }
      if (entry.isEmpty) continue;
      if (cur.contains(entry)) continue;
      cur = cur.isEmpty ? '• $entry' : '$cur\n• $entry';
    }
    return cur;
  }

  // Static security and hashing utilities
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String inputPin, String? storedHash) {
    if (storedHash == null || storedHash.isEmpty) return false;
    return hashPin(inputPin) == storedHash;
  }

  // Singleton pattern for centralized app state
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();
  static int _uniqueIdCounter = 0;

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
      isActive: true,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_3',
      name: 'Evening Shift',
      startsAt: '02:00 PM',
      endsAt: '10:00 PM',
      monthlyFee: 600,
      isActive: true,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_4',
      name: 'Morning Shift',
      startsAt: '06:00 AM',
      endsAt: '02:00 PM',
      monthlyFee: 600,
      isActive: true,
      isSystemSlot: false,
    ),
    ShiftConfig(
      id: 'shift_5',
      name: 'Night Shift',
      startsAt: '10:00 PM',
      endsAt: '06:00 AM',
      monthlyFee: 500,
      isActive: true,
      isSystemSlot: false,
    ),
  ];

  List<StaffMember> staffList = [];

  List<LibraryBranch> branches = [
    const LibraryBranch(
      id: 'branch_1',
      name: 'Main Campus (Central)',
      address: '',
      totalSeats: 35,
      isDefault: true,
    ),
  ];
  String activeBranchId = 'branch_1';

  LibraryBranch get currentBranch {
    try {
      return branches.firstWhere((b) => b.id == activeBranchId);
    } catch (_) {
      return branches.isNotEmpty
          ? branches.first
          : const LibraryBranch(id: 'branch_1', name: 'Main Campus', address: 'Main Branch', totalSeats: 35);
    }
  }

  void switchBranch(String branchId) {
    if (branches.any((b) => b.id == branchId)) {
      activeBranchId = branchId;
      final b = currentBranch;
      profile.libraryName = b.name;
      profile.city = b.address;
      _saveLocalState();
      notifyStreamControllers();
    }
  }

  void addBranch(LibraryBranch branch) {
    branches.add(branch);
    _saveLocalState();
    notifyStreamControllers();
  }

  void removeBranch(String branchId) {
    if (branches.length > 1) {
      branches.removeWhere((b) => b.id == branchId);
      if (activeBranchId == branchId) {
        activeBranchId = branches.first.id;
        final b = currentBranch;
        profile.libraryName = b.name;
        profile.city = b.address;
      }
      _saveLocalState();
      notifyStreamControllers();
    }
  }

  void addStaffMember(StaffMember staff) {
    staffList.add(staff);
    _saveLocalState();
  }

  void removeStaffMember(String staffId) {
    staffList.removeWhere((s) => s.id == staffId);
    _saveLocalState();
  }

  void toggleStaffActive(String staffId) {
    final idx = staffList.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      final cur = staffList[idx];
      staffList[idx] = StaffMember(
        id: cur.id,
        name: cur.name,
        phone: cur.phone,
        role: cur.role,
        addedAt: cur.addedAt,
        isActive: !cur.isActive,
      );
      _saveLocalState();
    }
  }

  void toggleShiftActive(String shiftId) {
    final idx = shifts.indexWhere((s) => s.id == shiftId);
    if (idx != -1) {
      shifts[idx].isActive = !shifts[idx].isActive;
      _saveLocalState();
    }
  }

  void updateShift(ShiftConfig updated) {
    final idx = shifts.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      shifts[idx] = updated;
      _saveLocalState();
    }
  }

  void addShift(ShiftConfig newShift) {
    shifts.add(newShift);
    _saveLocalState();
  }

  bool deleteShift(String shiftId) {
    ensureInitialized();
    final idx = shifts.indexWhere((s) => s.id == shiftId);
    if (idx != -1) {
      final target = shifts[idx];
      if (target.isSystemSlot) return false;
      shifts.removeAt(idx);
      _saveLocalState();
      return true;
    }
    return false;
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
  static final List<RegistrationRequest> _mockRegistrationRequests = [];

  static final StreamController<List<SeatInfo>> _mockSeatsController =
      StreamController<List<SeatInfo>>.broadcast();
  static final StreamController<List<StudentInfo>> _mockStudentsController =
      StreamController<List<StudentInfo>>.broadcast();
  static final StreamController<List<ExpenseItem>> _mockExpensesController =
      StreamController<List<ExpenseItem>>.broadcast();
  static final StreamController<List<PaymentTransaction>> _mockPaymentsController =
      StreamController<List<PaymentTransaction>>.broadcast();
  static final StreamController<List<RegistrationRequest>> _mockRegistrationRequestsController =
      StreamController<List<RegistrationRequest>>.broadcast();

  bool _initialized = false;
  bool _loadedFromLocalStorage = false;

  void ensureInitialized() {
    if (_initialized) return;
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    _initialized = true;
    _loadFromLocalStorage();
    restoreSession();
  }

  void _syncSeatsWithStudents() {
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    for (int seatNum = 1; seatNum <= totalSeatsCount; seatNum++) {
      final occupants = _mockStudents.where(
        (s) => s.seatNumber == seatNum && s.status != 'INACTIVE',
      ).toList();
      if (occupants.isNotEmpty) {
        final names = occupants.map((s) => s.name).join(', ');
        final shiftNames = occupants.map((s) => s.shift).toSet().join(', ');
        _mockSeats[seatNum - 1] = SeatInfo(
          seatNumber: seatNum,
          isOccupied: true,
          studentName: names,
          studentId: occupants.first.id,
          shift: shiftNames,
          sectionName: occupants.first.sectionName,
        );
      }
    }
    if (!_mockSeatsController.isClosed) {
      _mockSeatsController.add(List.unmodifiable(_mockSeats));
    }
  }

  Future<void> _loadFromLocalStorage() async {
    if (_loadedFromLocalStorage) return;
    _loadedFromLocalStorage = true;
    try {
      final profileStr = await LocalStorageService.getString('app_library_profile');
      if (profileStr != null && profileStr.isNotEmpty) {
        final decoded = json.decode(profileStr);
        if (decoded is Map<String, dynamic>) {
          profile = LibraryProfile.fromMap(decoded);
        }
      }

      final sectionsStr = await LocalStorageService.getString('app_library_sections');
      if (sectionsStr != null && sectionsStr.isNotEmpty) {
        final decoded = json.decode(sectionsStr);
        if (decoded is List && decoded.isNotEmpty) {
          sections = decoded.map((s) => SectionConfig.fromMap(Map<String, dynamic>.from(s))).toList();
        }
      }

      final shiftsStr = await LocalStorageService.getString('app_library_shifts');
      if (shiftsStr != null && shiftsStr.isNotEmpty) {
        final decoded = json.decode(shiftsStr);
        if (decoded is List && decoded.isNotEmpty) {
          shifts = decoded.map((s) => ShiftConfig.fromMap(Map<String, dynamic>.from(s))).toList();
        }
      }

      final studentsStr = await LocalStorageService.getString('app_library_students');
      if (studentsStr != null && studentsStr.isNotEmpty) {
        final decoded = json.decode(studentsStr);
        if (decoded is List && decoded.isNotEmpty) {
          _mockStudents.clear();
          for (var item in decoded) {
            final map = Map<String, dynamic>.from(item);
            _mockStudents.add(StudentInfo.fromFirestore(map['id']?.toString() ?? '', map));
          }
          _syncSeatsWithStudents();
          if (!_mockStudentsController.isClosed) {
            _mockStudentsController.add(List.unmodifiable(_mockStudents));
          }
        }
      }

      final paymentsStr = await LocalStorageService.getString('app_library_payments');
      if (paymentsStr != null && paymentsStr.isNotEmpty) {
        final decoded = json.decode(paymentsStr);
        if (decoded is List && decoded.isNotEmpty) {
          _mockPayments.clear();
          for (var item in decoded) {
            final map = Map<String, dynamic>.from(item);
            _mockPayments.add(PaymentTransaction.fromFirestore(map['payment_id']?.toString() ?? '', map));
          }
          if (!_mockPaymentsController.isClosed) {
            _mockPaymentsController.add(List.unmodifiable(_mockPayments));
          }
        }
      }

      final expensesStr = await LocalStorageService.getString('app_library_expenses');
      if (expensesStr != null && expensesStr.isNotEmpty) {
        final decoded = json.decode(expensesStr);
        if (decoded is List && decoded.isNotEmpty) {
          _mockExpenses.clear();
          for (var item in decoded) {
            final map = Map<String, dynamic>.from(item);
            _mockExpenses.add(ExpenseItem.fromFirestore(map['id']?.toString() ?? '', map));
          }
          if (!_mockExpensesController.isClosed) {
            _mockExpensesController.add(List.unmodifiable(_mockExpenses));
          }
        }
      }

      final staffStr = await LocalStorageService.getString('app_library_staff');
      if (staffStr != null && staffStr.isNotEmpty) {
        final decoded = json.decode(staffStr);
        if (decoded is List && decoded.isNotEmpty) {
          staffList = decoded.map((s) => StaffMember.fromMap(Map<String, dynamic>.from(s))).toList();
        }
      }

      final branchesStr = await LocalStorageService.getString('app_library_branches');
      if (branchesStr != null && branchesStr.isNotEmpty) {
        final decoded = json.decode(branchesStr);
        if (decoded is List && decoded.isNotEmpty) {
          branches = decoded.map((b) => LibraryBranch.fromMap(Map<String, dynamic>.from(b))).toList();
        }
      }

      final activeBranchStr = await LocalStorageService.getString('app_library_active_branch');
      if (activeBranchStr != null && activeBranchStr.isNotEmpty) {
        activeBranchId = activeBranchStr;
      }

      final reqsStr = await LocalStorageService.getString('app_library_registration_requests');
      if (reqsStr != null && reqsStr.isNotEmpty) {
        final decoded = json.decode(reqsStr);
        if (decoded is List && decoded.isNotEmpty) {
          _mockRegistrationRequests.clear();
          for (var item in decoded) {
            _mockRegistrationRequests.add(RegistrationRequest.fromMap(Map<String, dynamic>.from(item)));
          }
          if (!_mockRegistrationRequestsController.isClosed) {
            _mockRegistrationRequestsController.add(List.unmodifiable(_mockRegistrationRequests));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalState() async {
    try {
      await LocalStorageService.saveString('app_library_profile', json.encode(profile.toMap()));
      await LocalStorageService.saveString('app_library_sections', json.encode(sections.map((s) => s.toMap()).toList()));
      await LocalStorageService.saveString('app_library_shifts', json.encode(shifts.map((s) => s.toMap()).toList()));
      await LocalStorageService.saveString('app_library_students', json.encode(_mockStudents.map((s) => s.toMap()).toList()));
      await LocalStorageService.saveString('app_library_payments', json.encode(_mockPayments.map((p) => p.toJsonMap()).toList()));
      await LocalStorageService.saveString('app_library_expenses', json.encode(_mockExpenses.map((e) => e.toJsonMap()).toList()));
      await LocalStorageService.saveString('app_library_staff', json.encode(staffList.map((s) => s.toMap()).toList()));
      await LocalStorageService.saveString('app_library_branches', json.encode(branches.map((b) => b.toMap()).toList()));
      await LocalStorageService.saveString('app_library_active_branch', activeBranchId);
      await LocalStorageService.saveString('app_library_registration_requests', json.encode(_mockRegistrationRequests.map((r) => r.toMap()).toList()));
    } catch (_) {}
  }

  /// Public persistence helper ensuring all changes to profile, seats, shifts & staff are stored locally
  Future<void> persistAll() async {
    await _saveLocalState();
    if (isFirebaseConnected && currentUserId != null) {
      try {
        await _db.collection('libraries').doc(tenantId).set(profile.toMap(), SetOptions(merge: true));
        await _tenantCol('settings').doc('branding').set(profile.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Update and persist library profile metadata
  Future<void> saveProfile(LibraryProfile newProfile) async {
    profile = newProfile;
    await _saveLocalState();
    if (isFirebaseConnected && currentUserId != null) {
      try {
        await _db.collection('libraries').doc(tenantId).set(profile.toMap(), SetOptions(merge: true));
        await _tenantCol('settings').doc('branding').set(profile.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void _migrateSchema(Map<String, dynamic> data, {required int fromVersion}) {
    if (fromVersion < 2 && data['students'] is List) {
      for (final s in data['students']) {
        if (s is Map) {
          s.putIfAbsent('gender', () => 'Male');
        }
      }
    }
    if (fromVersion < 3 && data['students'] is List) {
      for (final s in data['students']) {
        if (s is Map) {
          s.putIfAbsent('updated_at', () => null);
        }
      }
    }
    if (fromVersion < 4 && data['students'] is List) {
      for (final s in data['students']) {
        if (s is Map) {
          s.putIfAbsent('advance_amount', () => 0);
        }
      }
    }
  }

  String exportFullBackupJson() {
    ensureInitialized();
    final backupData = {
      'app': 'TrackMyLibrary',
      'version': '2.0.0',
      'schemaVersion': 3,
      'exported_at': DateTime.now().toIso8601String(),
      'profile': profile.toMap(),
      'sections': sections.map((s) => s.toMap()).toList(),
      'shifts': shifts.map((s) => s.toMap()).toList(),
      'branches': branches.map((b) => b.toMap()).toList(),
      'staff': staffList.map((m) => m.toMap()).toList(),
      'students': _mockStudents.map((s) => s.toMap()).toList(),
      'payments': _mockPayments.map((p) => p.toJsonMap()).toList(),
      'expenses': _mockExpenses.map((e) => e.toJsonMap()).toList(),
      'stats': {
        'total_students': _mockStudents.length,
        'total_payments': _mockPayments.length,
        'total_expenses': _mockExpenses.length,
        'total_seats': totalSeatsCount,
      }
    };
    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<Map<String, dynamic>> restoreFromBackupJson(String jsonString) async {
    ensureInitialized();
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'error': 'Invalid backup format: Root is not a valid JSON object.'};
      }

      final schemaVer = (decoded['schemaVersion'] as num?)?.toInt() ?? 1;
      _migrateSchema(decoded, fromVersion: schemaVer);

      if (decoded['profile'] is Map) {
        profile = LibraryProfile.fromMap(Map<String, dynamic>.from(decoded['profile']));
      }

      if (decoded['sections'] is List) {
        final secList = (decoded['sections'] as List)
            .map((s) => SectionConfig.fromMap(Map<String, dynamic>.from(s)))
            .toList();
        if (secList.isNotEmpty) {
          sections = secList;
        }
      }

      if (decoded['shifts'] is List) {
        final shiftList = (decoded['shifts'] as List)
            .map((s) => ShiftConfig.fromMap(Map<String, dynamic>.from(s)))
            .toList();
        if (shiftList.isNotEmpty) {
          shifts = shiftList;
        }
      }

      int restoredStudents = 0;
      if (decoded['students'] is List) {
        _mockStudents.clear();
        for (var item in decoded['students']) {
          final map = Map<String, dynamic>.from(item);
          _mockStudents.add(StudentInfo.fromFirestore(map['id']?.toString() ?? '', map));
          restoredStudents++;
        }
        _syncSeatsWithStudents();
        if (!_mockStudentsController.isClosed) {
          _mockStudentsController.add(List.unmodifiable(_mockStudents));
        }
      }

      int restoredPayments = 0;
      if (decoded['payments'] is List) {
        _mockPayments.clear();
        for (var item in decoded['payments']) {
          final map = Map<String, dynamic>.from(item);
          _mockPayments.add(PaymentTransaction.fromFirestore(map['payment_id']?.toString() ?? '', map));
          restoredPayments++;
        }
        if (!_mockPaymentsController.isClosed) {
          _mockPaymentsController.add(List.unmodifiable(_mockPayments));
        }
      }

      int restoredExpenses = 0;
      if (decoded['expenses'] is List) {
        _mockExpenses.clear();
        for (var item in decoded['expenses']) {
          final map = Map<String, dynamic>.from(item);
          _mockExpenses.add(ExpenseItem.fromFirestore(map['id']?.toString() ?? '', map));
          restoredExpenses++;
        }
        if (!_mockExpensesController.isClosed) {
          _mockExpensesController.add(List.unmodifiable(_mockExpenses));
        }
      }

      if (decoded['staff'] is List) {
        staffList = (decoded['staff'] as List)
            .map((s) => StaffMember.fromMap(Map<String, dynamic>.from(s)))
            .toList();
      }

      if (decoded['branches'] is List) {
        branches = (decoded['branches'] as List)
            .map((b) => LibraryBranch.fromMap(Map<String, dynamic>.from(b)))
            .toList();
      }

      await _saveLocalState();

      return {
        'success': true,
        'students': restoredStudents,
        'payments': restoredPayments,
        'expenses': restoredExpenses,
        'library_name': profile.libraryName,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }


  Future<void> clearAllData() async {
    if (isFirebaseConnected) {
      final tenantIdsToDelete = <String>{
        tenantId,
        if (profile.libraryId.isNotEmpty) profile.libraryId,
        if (currentUserId != null && currentUserId!.isNotEmpty) currentUserId!,
        if (FirebaseAuth.instance.currentUser != null) FirebaseAuth.instance.currentUser!.uid,
        'default_library',
      };
      final collections = ['payments', 'students', 'seats', 'expenses', 'staff', 'branches', 'registration_requests'];
      for (final tId in tenantIdsToDelete) {
        for (final col in collections) {
          try {
            final colRef = _db.collection('libraries').doc(tId).collection(col);
            final snaps = await colRef.get();
            if (snaps.docs.isNotEmpty) {
              for (var i = 0; i < snaps.docs.length; i += 400) {
                final batch = _db.batch();
                final end = (i + 400 < snaps.docs.length) ? i + 400 : snaps.docs.length;
                for (var j = i; j < end; j++) {
                  batch.delete(snaps.docs[j].reference);
                }
                await batch.commit();
              }
            }
          } catch (_) {
            try {
              final colRef = _db.collection('libraries').doc(tId).collection(col);
              final snaps = await colRef.get();
              for (final doc in snaps.docs) {
                try {
                  await doc.reference.delete();
                } catch (_) {}
              }
            } catch (_) {}
          }
        }
      }
    }
    _mockStudents.clear();
    _mockPayments.clear();
    _mockExpenses.clear();
    _mockRegistrationRequests.clear();
    staffList.clear();
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    if (!_mockStudentsController.isClosed) {
      _mockStudentsController.add(const []);
    }
    if (!_mockPaymentsController.isClosed) {
      _mockPaymentsController.add(const []);
    }
    if (!_mockExpensesController.isClosed) {
      _mockExpensesController.add(const []);
    }
    if (!_mockRegistrationRequestsController.isClosed) {
      _mockRegistrationRequestsController.add(const []);
    }
    if (!_mockSeatsController.isClosed) {
      _mockSeatsController.add(List.unmodifiable(_mockSeats));
    }
    notifyStreamControllers();
    await LocalStorageService.remove('app_library_students');
    await LocalStorageService.remove('app_library_payments');
    await LocalStorageService.remove('app_library_expenses');
    await LocalStorageService.remove('app_library_staff');
    await LocalStorageService.remove('app_library_registration_requests');
  }

  // Permanently delete user account, wipe cloud tenant data, delete Firebase user, and purge all local storage
  Future<void> deleteAccountPermanently() async {
    ensureInitialized();

    if (isFirebaseConnected) {
      final tenantIdsToDelete = <String>{
        tenantId,
        if (profile.libraryId.isNotEmpty) profile.libraryId,
        if (currentUserId != null && currentUserId!.isNotEmpty) currentUserId!,
        if (FirebaseAuth.instance.currentUser != null) FirebaseAuth.instance.currentUser!.uid,
        'default_library',
      };

      final collections = [
        'payments', // Wipe payments first to ensure zero residual revenue records
        'students',
        'seats',
        'expenses',
        'staff',
        'settings',
        'backups',
        'branches',
        'registration_requests',
      ];

      for (final tId in tenantIdsToDelete) {
        for (final col in collections) {
          try {
            final colRef = _db.collection('libraries').doc(tId).collection(col);
            final snaps = await colRef.get();
            if (snaps.docs.isNotEmpty) {
              for (var i = 0; i < snaps.docs.length; i += 400) {
                final batch = _db.batch();
                final end = (i + 400 < snaps.docs.length) ? i + 400 : snaps.docs.length;
                for (var j = i; j < end; j++) {
                  batch.delete(snaps.docs[j].reference);
                }
                await batch.commit();
              }
            }
          } catch (_) {
            try {
              final colRef = _db.collection('libraries').doc(tId).collection(col);
              final snaps = await colRef.get();
              for (final doc in snaps.docs) {
                try {
                  await doc.reference.delete();
                } catch (_) {}
              }
            } catch (_) {}
          }
        }

        // Delete parent library root document
        try {
          await _db.collection('libraries').doc(tId).delete();
        } catch (_) {}
      }

      // Delete Firebase user auth account if possible, or sign out cleanly
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (_) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
    }

    // Reset all in-memory collections cleanly
    _mockStudents.clear();
    _mockPayments.clear();
    _mockExpenses.clear();
    _mockRegistrationRequests.clear();
    staffList.clear();
    branches.clear();
    sections = [
      SectionConfig(id: 'sec_1', name: 'Main Hall', startSeat: 1, endSeat: 35),
    ];
    _mockSeats = List.generate(
      totalSeatsCount,
      (index) => SeatInfo(seatNumber: index + 1),
    );
    profile = LibraryProfile(
      libraryId: '',
      libraryName: '',
      city: '',
      adminName: '',
      adminEmail: '',
      adminPhone: '',
      upiId: '',
    );
    isAuthenticated = false;
    currentUserId = null;
    currentUserRole = 'Admin';
    currentUserName = '';
    currentUserEmail = '';
    activeBranchId = 'branch_main';
    _loadedFromLocalStorage = false;
    _initialized = false;

    // Notify all UI streams of complete reset
    if (!_mockStudentsController.isClosed) {
      _mockStudentsController.add(const []);
    }
    if (!_mockPaymentsController.isClosed) {
      _mockPaymentsController.add(const []);
    }
    if (!_mockExpensesController.isClosed) {
      _mockExpensesController.add(const []);
    }
    if (!_mockRegistrationRequestsController.isClosed) {
      _mockRegistrationRequestsController.add(const []);
    }
    if (!_mockSeatsController.isClosed) {
      _mockSeatsController.add(List.unmodifiable(_mockSeats));
    }
    notifyStreamControllers();

    // Explicitly purge every known key to prevent any persistence leaks
    await LocalStorageService.remove('app_library_students');
    await LocalStorageService.remove('app_library_payments');
    await LocalStorageService.remove('app_library_expenses');
    await LocalStorageService.remove('app_library_staff');
    await LocalStorageService.remove('app_library_profile');
    await LocalStorageService.remove('app_library_sections');
    await LocalStorageService.remove('app_library_shifts');
    await LocalStorageService.remove('app_library_branches');
    await LocalStorageService.remove('app_library_active_branch');
    await LocalStorageService.remove('app_library_registration_requests');
    await LocalStorageService.remove('app_setup_completed');
    await LocalStorageService.remove('app_active_session');
    await LocalStorageService.remove('app_last_login_identifier');
    await LocalStorageService.remove('app_admin_password');
    await LocalStorageService.remove('app_admin_password_hash');
    await LocalStorageService.remove('gdrive_auto_backup_enabled');
    await LocalStorageService.remove('gdrive_backup_email');

    // Completely wipe persistent local storage (memory cache, JSON file, web localStorage)
    await LocalStorageService.clearAll();
  }

  bool deleteSection(String sectionName) {
    ensureInitialized();
    if (sections.length <= 1) return false;
    final idx = sections.indexWhere((s) => s.name.toLowerCase() == sectionName.toLowerCase());
    if (idx != -1) {
      sections.removeAt(idx);
      updateSectionsAndRebuildSeats(sections);
      return true;
    }
    return false;
  }

  void updateSectionsAndRebuildSeats(List<SectionConfig> newSections) {
    sections = newSections;
    _syncSeatsWithStudents();
    _saveLocalState();
  }

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  bool isDuplicateStudentPhone(String phone, {String? excludeStudentId}) {
    final norm = normalizePhone(phone);
    if (norm.isEmpty) return false;
    return _mockStudents.any((s) {
      if (excludeStudentId != null && s.id == excludeStudentId) return false;
      // Do not consider temporary unallocated QR self-registrations as duplicate conflicts
      if (s.status == 'UNALLOCATED' && s.seatNumber == null) return false;
      return normalizePhone(s.phone) == norm;
    });
  }

  StudentInfo? findStudentByPhone(String phone) {
    final norm = normalizePhone(phone);
    if (norm.isEmpty) return null;
    try {
      return _mockStudents.firstWhere((s) => normalizePhone(s.phone) == norm);
    } catch (_) {
      return null;
    }
  }

  /// Determines whether two shifts overlap or conflict.
  /// Full Day / 24 Hours conflicts with all shifts.
  /// Identical shifts conflict.
  /// Non-overlapping shifts (e.g. Morning vs Evening vs Night) do not conflict.
  static bool doShiftsConflict(String shiftA, String shiftB, {List<ShiftConfig>? allShifts}) {
    final a = shiftA.trim().toLowerCase();
    final b = shiftB.trim().toLowerCase();

    if (a.isEmpty || b.isEmpty) return true;
    if (a == b) return true;

    final isAFull = a.contains('full') || a.contains('24') || a.contains('whole');
    final isBFull = b.contains('full') || b.contains('24') || b.contains('whole');
    if (isAFull || isBFull) return true;

    if (allShifts != null && allShifts.isNotEmpty) {
      ShiftConfig? cfgA;
      ShiftConfig? cfgB;
      for (final s in allShifts) {
        final sName = s.name.trim().toLowerCase();
        if (sName == a || a.contains(sName) || sName.contains(a)) cfgA = s;
        if (sName == b || b.contains(sName) || sName.contains(b)) cfgB = s;
      }
      if (cfgA != null && cfgB != null && cfgA.startsAt.isNotEmpty && cfgB.startsAt.isNotEmpty) {
        final int? startA = _parseTimeToMinutes(cfgA.startsAt);
        final int? endA = _parseTimeToMinutes(cfgA.endsAt);
        final int? startB = _parseTimeToMinutes(cfgB.startsAt);
        final int? endB = _parseTimeToMinutes(cfgB.endsAt);
        if (startA != null && endA != null && startB != null && endB != null) {
          return _intervalsOverlap(startA, endA, startB, endB);
        }
      }
    }

    final isAMorning = a.contains('morning');
    final isBMorning = b.contains('morning');
    final isAEvening = a.contains('evening') || a.contains('afternoon');
    final isBEvening = b.contains('evening') || b.contains('afternoon');
    final isANight = a.contains('night');
    final isBNight = b.contains('night');

    if (isAMorning && (isBEvening || isBNight)) return false;
    if (isAEvening && (isBMorning || isBNight)) return false;
    if (isANight && (isBMorning || isAEvening)) return false;

    return false;
  }

  static int? _parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final digits = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = digits.split(':');
      if (parts.isEmpty) return null;
      int hour = int.parse(parts[0].trim());
      int min = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return hour * 60 + min;
    } catch (_) {
      return null;
    }
  }

  static bool _intervalsOverlap(int startA, int endA, int startB, int endB) {
    List<List<int>> intervalsA = endA <= startA
        ? [[startA, 1440], [0, endA]]
        : [[startA, endA]];
    List<List<int>> intervalsB = endB <= startB
        ? [[startB, 1440], [0, endB]]
        : [[startB, endB]];

    for (final iA in intervalsA) {
      for (final iB in intervalsB) {
        final maxStart = iA[0] > iB[0] ? iA[0] : iB[0];
        final minEnd = iA[1] < iB[1] ? iA[1] : iB[1];
        if (maxStart < minEnd) return true;
      }
    }
    return false;
  }

  bool isSeatOccupied(int seatNum, {String? shift, String? excludeStudentId}) {
    ensureInitialized();
    if (seatNum <= 0) return false;
    final activeOccupants = _mockStudents.where(
      (s) => s.seatNumber == seatNum && s.status != 'INACTIVE' && (excludeStudentId == null || s.id != excludeStudentId),
    ).toList();
    if (activeOccupants.isEmpty) return false;
    if (shift == null || shift.trim().isEmpty) {
      return true;
    }
    return activeOccupants.any((s) => doShiftsConflict(s.shift, shift, allShifts: shifts));
  }

  bool isSeatAvailableForShift(int seatNum, String? shift, {String? excludeStudentId}) {
    return !isSeatOccupied(seatNum, shift: shift, excludeStudentId: excludeStudentId);
  }

  StudentInfo? getStudentForSeat(int seatNum, {String? shift}) {
    ensureInitialized();
    final activeOccupants = _mockStudents.where((s) => s.seatNumber == seatNum && s.status != 'INACTIVE').toList();
    if (activeOccupants.isEmpty) return null;
    if (shift != null && shift.trim().isNotEmpty) {
      for (final s in activeOccupants) {
        if (doShiftsConflict(s.shift, shift, allShifts: shifts)) {
          return s;
        }
      }
      return null;
    }
    return activeOccupants.first;
  }

  List<StudentInfo> getStudentsForSeat(int seatNum) {
    ensureInitialized();
    return _mockStudents.where((s) => s.seatNumber == seatNum && s.status != 'INACTIVE').toList();
  }

  List<StudentInfo> get currentStudents => List.unmodifiable(_mockStudents);
  List<PaymentTransaction> get currentPayments => List.unmodifiable(_mockPayments);
  List<ExpenseItem> get currentExpenses => List.unmodifiable(_mockExpenses);
  List<RegistrationRequest> get currentRegistrationRequests => List.unmodifiable(_mockRegistrationRequests);

  Stream<List<RegistrationRequest>> streamRegistrationRequests() {
    if (isFirebaseConnected) {
      return _tenantCol('registration_requests')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => RegistrationRequest.fromMap({'id': d.id, ...d.data()}))
            .toList();
        _mockRegistrationRequests.clear();
        _mockRegistrationRequests.addAll(list);

        // Seamlessly sync pending QR admissions into the in-memory student directory
        bool studentsUpdated = false;
        for (final req in list) {
          if (req.status == 'PENDING') {
            final studentId = 'st_qr_${req.id}';
            final alreadyPresent = _mockStudents.any(
              (s) => s.id == studentId || (s.phone.isNotEmpty && normalizePhone(s.phone) == normalizePhone(req.phone)),
            );
            if (!alreadyPresent) {
              final dateStr = DateFormat('dd-MMM-yyyy').format(req.createdAt);
              _mockStudents.insert(0, StudentInfo(
                id: studentId,
                name: req.studentName,
                phone: req.phone,
                shift: req.shift,
                seatNumber: null,
                joinedAt: req.createdAt,
                duesAmount: 0,
                monthlyFee: req.preferredMonthlyFee ?? 0,
                status: 'UNALLOCATED',
                fatherName: req.fatherName,
                address: req.address,
                aadhaarNumber: req.aadhaarNumber,
                preparationFor: req.preparationFor,
                gender: req.gender,
                photoBase64: req.photoBase64,
                note: 'Registered via QR Admission Portal on $dateStr. Pending seat allotment.',
              ));
              studentsUpdated = true;
            }
          }
        }
        if (studentsUpdated) {
          _syncSeatsWithStudents();
          if (!_mockStudentsController.isClosed) {
            _mockStudentsController.add(List.unmodifiable(_mockStudents));
          }
        }

        return list;
      });
    } else {
      ensureInitialized();
      Future.microtask(() {
        if (!_mockRegistrationRequestsController.isClosed) {
          _mockRegistrationRequestsController.add(List.unmodifiable(_mockRegistrationRequests));
        }
      });
      return _mockRegistrationRequestsController.stream;
    }
  }

  void notifyRegistrationRequestsChanged() {
    if (!_mockRegistrationRequestsController.isClosed) {
      _mockRegistrationRequestsController.add(List.unmodifiable(_mockRegistrationRequests));
    }
  }

  // Submit self-registration request (called from public QR student registration web portal)
  Future<void> submitRegistrationRequest(RegistrationRequest req) async {
    ensureInitialized();
    final effectiveLibId = req.libraryId.isNotEmpty ? req.libraryId : tenantId;
    final updatedReq = req.copyWith(libraryId: effectiveLibId);

    if (isFirebaseConnected) {
      try {
        final payload = {
          ...updatedReq.toMap(),
          'name': updatedReq.studentName,
          'student_name': updatedReq.studentName,
        };
        await _db
            .collection('libraries')
            .doc(effectiveLibId)
            .collection('registration_requests')
            .doc(updatedReq.id)
            .set(payload);
      } catch (cloudErr) {
        debugPrint('Cloud sync note in submitRegistrationRequest: $cloudErr');
      }
    }

    _mockRegistrationRequests.removeWhere((r) => r.id == updatedReq.id);
    _mockRegistrationRequests.insert(0, updatedReq);
    notifyRegistrationRequestsChanged();

    // Immediately insert unallocated student entry so they are instantly visible in the Students Tab!
    final studentId = 'st_qr_${updatedReq.id}';
    final existingIdx = _mockStudents.indexWhere(
      (s) => s.id == studentId || (s.phone.isNotEmpty && normalizePhone(s.phone) == normalizePhone(updatedReq.phone)),
    );
    if (existingIdx == -1) {
      final now = DateTime.now();
      final dateStr = DateFormat('dd-MMM-yyyy').format(now);
      final newStudent = StudentInfo(
        id: studentId,
        name: updatedReq.studentName,
        phone: updatedReq.phone,
        shift: updatedReq.shift,
        seatNumber: null,
        joinedAt: now,
        duesAmount: 0,
        monthlyFee: updatedReq.preferredMonthlyFee ?? 0,
        status: 'UNALLOCATED',
        fatherName: updatedReq.fatherName,
        address: updatedReq.address,
        aadhaarNumber: updatedReq.aadhaarNumber,
        preparationFor: updatedReq.preparationFor,
        gender: updatedReq.gender,
        photoBase64: updatedReq.photoBase64,
        note: 'Registered via QR Admission Portal on $dateStr. Pending seat allotment.',
      );
      _mockStudents.insert(0, newStudent);
      _syncSeatsWithStudents();
      if (!_mockStudentsController.isClosed) {
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }
    }

    await _saveLocalState();
  }

  // Admin accepts self-registration request, allocates seat, and registers student
  Future<void> acceptRegistrationRequest({
    required String requestId,
    required int seatNumber,
    required int monthlyFee,
    required int feePaid,
    required String paymentMode,
    String? shiftOverride,
    String? note,
  }) async {
    ensureInitialized();
    final idx = _mockRegistrationRequests.indexWhere((r) => r.id == requestId);
    RegistrationRequest? req;
    if (idx != -1) {
      req = _mockRegistrationRequests[idx];
    } else if (isFirebaseConnected) {
      try {
        final doc = await _tenantCol('registration_requests').doc(requestId).get();
        if (doc.exists) {
          req = RegistrationRequest.fromMap({'id': doc.id, ...doc.data()!});
        }
      } catch (_) {}
    }

    if (req == null) return;

    final effectiveShift = shiftOverride ?? req.shift;
    final dues = (monthlyFee - feePaid).clamp(0, 999999);
    final status = dues == 0 ? 'ACTIVE' : 'DUES';

    // Remove temporary unallocated placeholder so confirmed student takes its place cleanly
    final tempStudentId = 'st_qr_$requestId';
    _mockStudents.removeWhere((s) => s.id == tempStudentId || (s.seatNumber == null && normalizePhone(s.phone) == normalizePhone(req!.phone)));

    await assignSeatAndRegisterStudent(
      seatNumber: seatNumber,
      studentName: req.studentName,
      phone: req.phone,
      shift: effectiveShift,
      deviceUserId: currentUserName,
      feeAmount: feePaid,
      duesAmount: dues,
      status: status,
      fatherName: req.fatherName,
      address: req.address,
      aadhaarNumber: req.aadhaarNumber,
      preparationFor: req.preparationFor,
      gender: req.gender,
      photoBase64: req.photoBase64,
      paymentMode: paymentMode,
      note: appendNote(req.address.isNotEmpty ? 'Address: ${req.address}' : '', note ?? 'Registered via QR Portal Self-Admission'),
    );

    if (isFirebaseConnected) {
      try {
        await _tenantCol('registration_requests').doc(requestId).update({
          'status': 'ACCEPTED',
          'seat_number': seatNumber,
        });
      } catch (_) {}
    }

    if (idx != -1) {
      _mockRegistrationRequests[idx] = _mockRegistrationRequests[idx].copyWith(status: 'ACCEPTED');
      notifyRegistrationRequestsChanged();
      await _saveLocalState();
    }
  }

  // Remove temporary unallocated QR self-registration placeholder cleanly
  void removeUnallocatedStudentForRequest(String requestId, {String? phone}) {
    ensureInitialized();
    final tempStudentId = 'st_qr_$requestId';
    _mockStudents.removeWhere((s) =>
        s.id == tempStudentId ||
        (phone != null && s.seatNumber == null && normalizePhone(s.phone) == normalizePhone(phone)));
    _syncSeatsWithStudents();
    if (!_mockStudentsController.isClosed) {
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }
  }

  // Mark registration request accepted after seat allotment & registration via wizard
  Future<void> markRegistrationRequestAccepted({
    required String requestId,
    int? seatNumber,
    String? phone,
  }) async {
    ensureInitialized();
    removeUnallocatedStudentForRequest(requestId, phone: phone);

    final idx = _mockRegistrationRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _mockRegistrationRequests[idx] = _mockRegistrationRequests[idx].copyWith(
        status: 'ACCEPTED',
      );
      notifyRegistrationRequestsChanged();
      await _saveLocalState();
    }

    if (isFirebaseConnected) {
      try {
        await _tenantCol('registration_requests').doc(requestId).update({
          'status': 'ACCEPTED',
          if (seatNumber != null) 'seat_number': seatNumber,
        });
      } catch (_) {}
    }
  }

  // Admin rejects registration request
  Future<void> rejectRegistrationRequest(String requestId, {String reason = ''}) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      try {
        await _tenantCol('registration_requests').doc(requestId).update({
          'status': 'REJECTED',
          'rejection_reason': reason,
        });
      } catch (_) {}
    }

    final tempStudentId = 'st_qr_$requestId';
    _mockStudents.removeWhere((s) => s.id == tempStudentId);
    if (!_mockStudentsController.isClosed) {
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }

    final idx = _mockRegistrationRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _mockRegistrationRequests[idx] = _mockRegistrationRequests[idx].copyWith(
        status: 'REJECTED',
        rejectionReason: reason,
      );
      notifyRegistrationRequestsChanged();
      await _saveLocalState();
    }
  }

  // Disaster recovery and sync accessors
  List<StudentInfo> get mockStudentsList => _mockStudents;
  List<PaymentTransaction> get mockPaymentsList => _mockPayments;
  List<ExpenseItem> get mockExpensesList => _mockExpenses;
  void syncSeatsWithStudents() {
    _syncSeatsWithStudents();
    if (!_mockSeatsController.isClosed) {
      _mockSeatsController.add(List.unmodifiable(_mockSeats));
    }
  }
  Future<void> saveLocalState() => _saveLocalState();
  void notifyStudentsChanged() {
    if (!_mockStudentsController.isClosed) {
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
    }
  }
  void notifyPaymentsChanged() {
    if (!_mockPaymentsController.isClosed) {
      _mockPaymentsController.add(List.unmodifiable(_mockPayments));
    }
  }
  Future<void> addPayment(PaymentTransaction p) async {
    _mockPayments.add(p);
    notifyPaymentsChanged();
    await _saveLocalState();
  }
  void notifyExpensesChanged() {
    if (!_mockExpensesController.isClosed) {
      _mockExpensesController.add(List.unmodifiable(_mockExpenses));
    }
  }

  void notifyStreamControllers() {
    notifyStudentsChanged();
    notifyPaymentsChanged();
    notifyExpensesChanged();
    notifyRegistrationRequestsChanged();
    if (!_mockSeatsController.isClosed) {
      _mockSeatsController.add(List.unmodifiable(_mockSeats));
    }
  }

  PaymentTransaction? getLastPaymentForStudent({String? studentId, String? phone, String? name}) {
    final normPhone = phone != null ? normalizePhone(phone) : null;
    for (var p in _mockPayments) {
      if (studentId != null && studentId.isNotEmpty && p.studentId == studentId) return p;
      if ((studentId == null || studentId.isEmpty) &&
          normPhone != null &&
          normPhone.isNotEmpty &&
          normalizePhone(p.studentPhone) == normPhone) {
        return p;
      }
    }
    return null;
  }

  bool get isFirebaseConnected => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  // Multi-Tenant Cloud Firestore Isolation
  String get tenantId {
    if (isFirebaseConnected && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }
    return profile.libraryId.isNotEmpty ? profile.libraryId : 'default_library';
  }

  void switchTenant(String newTenantId) {
    final clean = newTenantId.trim();
    if (clean.isNotEmpty) {
      profile = profile.copyWith(libraryId: clean);
    }
  }

  Future<LibraryProfile?> fetchTenantProfile(String targetTenantId) async {
    final clean = targetTenantId.trim();
    if (clean.isEmpty) return null;
    if (isFirebaseConnected) {
      try {
        final doc = await _db.collection('libraries').doc(clean).get();
        if (doc.exists && doc.data() != null) {
          final loaded = LibraryProfile.fromMap(doc.data()!);
          profile = loaded;
          return loaded;
        }
      } catch (_) {}
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _tenantCol(String collectionName) {
    return _db.collection('libraries').doc(tenantId).collection(collectionName);
  }

  // Active User Session & Role-Based Access Control (RBAC)
  String? currentUserId;
  String currentUserName = 'Admin';
  String currentUserEmail = '';
  String currentUserRole = 'Admin'; // 'Admin' or 'Receptionist'
  bool isAuthenticated = false;

  bool get isAdmin => currentUserRole == 'Admin';
  bool get isReceptionist => currentUserRole == 'Receptionist';

  Future<void> restoreSession() async {
    final sessionStr = await LocalStorageService.getString('app_active_session');
    if (sessionStr != null && sessionStr.isNotEmpty) {
      try {
        final map = json.decode(sessionStr);
        currentUserId = map['user_id'];
        currentUserEmail = map['email'] ?? '';
        currentUserRole = map['role'] ?? 'Admin';
        currentUserName = map['name'] ?? profile.adminName;
        if (map['library_id'] != null && (map['library_id'] as String).isNotEmpty) {
          profile.libraryId = map['library_id'];
        }
        isAuthenticated = true;
      } catch (_) {}
    }
    if (isFirebaseConnected && FirebaseAuth.instance.currentUser != null) {
      final fbUser = FirebaseAuth.instance.currentUser!;
      currentUserId = fbUser.uid;
      profile.libraryId = fbUser.uid;
      currentUserEmail = fbUser.email ?? currentUserEmail;
      isAuthenticated = true;
    }
  }

  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    ensureInitialized();
    final cleanId = identifier.trim();
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please enter your mobile/email and password.',
      );
    }

    // 1. If Firebase is connected and valid email is provided, attempt cloud authentication
    if (isFirebaseConnected && cleanId.contains('@')) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanId,
          password: cleanPass,
        );
        if (credential.user != null) {
          currentUserId = credential.user!.uid;
          profile.libraryId = credential.user!.uid; // Strictly bound to Firebase Auth UID
          currentUserEmail = credential.user!.email ?? cleanId;
          currentUserRole = (cleanId.toLowerCase() == profile.adminEmail.toLowerCase())
              ? 'Admin'
              : 'Receptionist';
          currentUserName = profile.adminName;
          isAuthenticated = true;
          await LocalStorageService.saveString(
            'app_active_session',
            json.encode({
              'user_id': currentUserId,
              'email': currentUserEmail,
              'role': currentUserRole,
              'name': currentUserName,
              'library_id': profile.libraryId,
            }),
          );
          return AuthResult(
            success: true,
            role: currentUserRole,
            userName: currentUserName,
            userId: currentUserId,
          );
        }
      } on FirebaseAuthException catch (e) {
        String msg = 'Authentication failed: ${e.message ?? e.code}';
        if (e.code == 'user-not-found') msg = 'No account found with this email.';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect password. Please verify and retry.';
        if (e.code == 'invalid-email') msg = 'The email address is badly formatted.';
        if (e.code == 'user-disabled') msg = 'This user account has been disabled.';
        if (e.code == 'operation-not-allowed') msg = 'Email/Password sign-in is disabled in Firebase Console. Please enable it under Authentication -> Sign-in method.';
        return AuthResult(success: false, message: msg);
      } catch (_) {}
    }

    // 2. Offline / Local Credentials Vault check
    // Check Admin Credentials
    final storedAdminHash = await LocalStorageService.getString('app_admin_password_hash');
    const defaultAdminHash = 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f';
    final isAdminMatch = (
        (profile.adminEmail.isNotEmpty && cleanId.toLowerCase() == profile.adminEmail.toLowerCase()) ||
        (profile.adminPhone.isNotEmpty && cleanId.replaceAll(RegExp(r'\D'), '') == profile.adminPhone.replaceAll(RegExp(r'\D'), '')) ||
        cleanId.toLowerCase() == 'admin' ||
        (currentUserId != null && cleanId == currentUserId)
    );

    if (isAdminMatch) {
      if (verifyPin(cleanPass, storedAdminHash ?? defaultAdminHash)) {
        currentUserId = 'admin_001';
        currentUserName = profile.adminName.isNotEmpty ? profile.adminName : 'Administrator';
        currentUserEmail = profile.adminEmail.isNotEmpty ? profile.adminEmail : cleanId;
        currentUserRole = 'Admin';
        isAuthenticated = true;
        await LocalStorageService.saveString(
          'app_active_session',
          json.encode({
            'user_id': currentUserId,
            'email': currentUserEmail,
            'role': currentUserRole,
            'name': currentUserName,
          }),
        );
        if (cleanId.isNotEmpty) {
          await LocalStorageService.saveString('app_last_login_identifier', cleanId);
        }
        return AuthResult(
          success: true,
          role: 'Admin',
          userName: currentUserName,
          userId: currentUserId,
        );
      } else {
        return const AuthResult(
          success: false,
          message: 'Incorrect password for administrator account.',
        );
      }
    }

    // Check Staff Credentials (Receptionist / Desk Staff)
    final normPhone = normalizePhone(cleanId);
    final staffMatches = staffList.where((s) =>
        normalizePhone(s.phone) == normPhone ||
        (s.email != null && s.email!.toLowerCase() == cleanId.toLowerCase()) ||
        s.id == cleanId);

    if (staffMatches.isNotEmpty) {
      final staff = staffMatches.first;
      if (!staff.isActive) {
        return const AuthResult(
          success: false,
          message: 'This staff account has been deactivated by the administrator.',
        );
      }

      const defaultStaffHash = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';
      final staffPinHash = staff.pinHash ?? defaultStaffHash;

      if (verifyPin(cleanPass, staffPinHash)) {
        currentUserId = staff.id;
        currentUserName = staff.name;
        currentUserEmail = staff.email ?? '${staff.phone}@staff.local';
        currentUserRole = staff.role.toLowerCase().contains('admin') ? 'Admin' : 'Receptionist';
        isAuthenticated = true;
        await LocalStorageService.saveString(
          'app_active_session',
          json.encode({
            'user_id': currentUserId,
            'email': currentUserEmail,
            'role': currentUserRole,
            'name': currentUserName,
          }),
        );
        return AuthResult(
          success: true,
          role: currentUserRole,
          userName: currentUserName,
          userId: currentUserId,
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Incorrect PIN/password for staff member ${staff.name}.',
        );
      }
    }

    return const AuthResult(
      success: false,
      message: 'Account not found. Please check credentials or register as new library admin.',
    );
  }

  /// Check whether the current user or device has completed library setup and configured a real library
  Future<bool> hasConfiguredLibrary() async {
    ensureInitialized();

    // 1. If connected to Firebase and authenticated with a cloud user (e.g. Google Sign-In),
    // check cloud Firestore first. If cloud has no library for this user, they MUST do library creation first!
    if (isFirebaseConnected && currentUserId != null) {
      try {
        final libDoc = await _db.collection('libraries').doc(tenantId).get();
        if (libDoc.exists && libDoc.data() != null) {
          final data = libDoc.data()!;
          final name = data['library_name']?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            profile = LibraryProfile.fromMap(data);
            await LocalStorageService.saveString('app_setup_completed', 'true');
            await _saveLocalState();
            return true;
          }
        }

        final brandingDoc = await _tenantCol('settings').doc('branding').get();
        if (brandingDoc.exists && brandingDoc.data() != null) {
          final data = brandingDoc.data()!;
          final name = data['library_name']?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            profile = LibraryProfile.fromMap(data);
            await LocalStorageService.saveString('app_setup_completed', 'true');
            await _saveLocalState();
            return true;
          }
        }

        // Firebase user exists in auth but has no library configured in Firestore yet
        return false;
      } catch (_) {}
    }

    // 2. Explicit setup completion flag in local storage
    final setupDone = await LocalStorageService.getString('app_setup_completed');
    if (setupDone == 'true') {
      final profileStr = await LocalStorageService.getString('app_library_profile');
      if (profileStr != null && profileStr.isNotEmpty) {
        try {
          final decoded = json.decode(profileStr);
          if (decoded is Map && decoded['library_name'] != null) {
            final name = decoded['library_name'].toString().trim();
            if (name.isNotEmpty) {
              return true;
            }
          }
        } catch (_) {}
      }
      if (profile.libraryName.isNotEmpty) {
        return true;
      }
      return false;
    }

    // 3. Custom library name in local storage (not empty and not default sample library)
    final profileStr = await LocalStorageService.getString('app_library_profile');
    if (profileStr != null && profileStr.isNotEmpty) {
      try {
        final decoded = json.decode(profileStr);
        if (decoded is Map && decoded['library_name'] != null) {
          final name = decoded['library_name'].toString().trim();
          if (name.isNotEmpty) {
            return true;
          }
        }
      } catch (_) {}
    }

    // 4. In-memory profile has a custom library name
    if (profile.libraryName.isNotEmpty) {
      return true;
    }

    return false;
  }

  Future<AuthResult> loginWithGoogle() async {
    ensureInitialized();
    if (isFirebaseConnected) {
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
        if (userCredential.user != null) {
          final user = userCredential.user!;
          currentUserId = user.uid;
          profile.libraryId = user.uid;
          currentUserEmail = user.email ?? '';
          final derivedName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (currentUserEmail.contains('@') ? currentUserEmail.split('@')[0] : 'Admin');
          currentUserName = derivedName;
          profile.adminName = derivedName;
          if (currentUserEmail.isNotEmpty) {
            profile.adminEmail = currentUserEmail;
          }
          currentUserRole = 'Admin';
          isAuthenticated = true;

          // Attempt to restore existing cloud library profile if user has previously configured one
          bool restoredCloudProfile = false;
          try {
            final libDoc = await _db.collection('libraries').doc(user.uid).get();
            if (libDoc.exists && libDoc.data() != null) {
              final data = libDoc.data()!;
              final name = data['library_name']?.toString().trim() ?? '';
              if (name.isNotEmpty) {
                profile = LibraryProfile.fromMap(data);
                await LocalStorageService.saveString('app_setup_completed', 'true');
                await _saveLocalState();
                restoredCloudProfile = true;
              }
            }
            if (!restoredCloudProfile) {
              final brandingDoc = await _db.collection('libraries').doc(user.uid).collection('settings').doc('branding').get();
              if (brandingDoc.exists && brandingDoc.data() != null) {
                final data = brandingDoc.data()!;
                final name = data['library_name']?.toString().trim() ?? '';
                if (name.isNotEmpty) {
                  profile = LibraryProfile.fromMap(data);
                  await LocalStorageService.saveString('app_setup_completed', 'true');
                  await _saveLocalState();
                  restoredCloudProfile = true;
                }
              }
            }
          } catch (_) {}

          if (!restoredCloudProfile) {
            // First time Google user or account was permanently deleted:
            // Ensure local state is clean so they are routed to library creation wizard
            profile.libraryName = '';
            profile.city = '';
            _mockStudents.clear();
            _mockPayments.clear();
            _mockExpenses.clear();
            _mockRegistrationRequests.clear();
            staffList.clear();
            branches.clear();
            await LocalStorageService.remove('app_setup_completed');
            await LocalStorageService.remove('app_library_profile');
          }

          await LocalStorageService.saveString(
            'app_active_session',
            json.encode({
              'user_id': currentUserId,
              'email': currentUserEmail,
              'role': currentUserRole,
              'name': currentUserName,
              'library_id': profile.libraryId,
            }),
          );
          if (currentUserEmail.isNotEmpty) {
            await LocalStorageService.saveString('app_last_login_identifier', currentUserEmail);
          }
            return AuthResult(
              success: true,
              role: 'Admin',
              userName: currentUserName,
              userId: currentUserId,
            );
          }
        } on FirebaseAuthException catch (e) {
        final errText = '${e.code} ${e.message ?? ''}'.toLowerCase();
        if (errText.contains('certificate hash') ||
            errText.contains('invalid-cert-hash') ||
            errText.contains('17093')) {
          return const AuthResult(
            success: false,
            message: 'Firebase certificate error: SHA-1 and SHA-256 fingerprints are missing in Firebase Console for com.trackmylibrary.app. Please add them under Project Settings > Your Apps.',
          );
        }
        if (errText.contains('invalid_app_id') ||
            errText.contains('invalid-app-credential') ||
            errText.contains('app-not-authorized') ||
            errText.contains('12500')) {
          return const AuthResult(
            success: false,
            message: 'Google Sign-In failed (invalid_APP_ID): Android package (com.trackmylibrary.app) and SHA-1 fingerprint must be added to your Firebase Console under Project Settings > Your Apps.',
          );
        }
        return AuthResult(success: false, message: 'Google Sign-In failed: ${e.message ?? e.code}');
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('certificate hash') || errStr.contains('invalid-cert-hash') || errStr.contains('17093')) {
          return const AuthResult(
            success: false,
            message: 'Firebase certificate error: SHA-1 and SHA-256 fingerprints are missing in Firebase Console for com.trackmylibrary.app.',
          );
        }
        if (errStr.contains('invalid_app_id') || errStr.contains('12500')) {
          return const AuthResult(
            success: false,
            message: 'Google Sign-In failed (invalid_APP_ID): Please register SHA-1 fingerprint for com.trackmylibrary.app in Firebase Console.',
          );
        }
        return AuthResult(success: false, message: 'Google Sign-In failed: $e');
      }
    }

    final googleEmail = profile.adminEmail.isNotEmpty
        ? profile.adminEmail
        : 'admin@library.local';
    currentUserId = 'google_user_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final derivedName = (profile.adminName.isNotEmpty && profile.adminName != 'Admin')
        ? profile.adminName
        : 'Administrator';
    currentUserName = derivedName;
    profile.adminName = derivedName;
    currentUserEmail = googleEmail;
    currentUserRole = 'Admin';
    isAuthenticated = true;
    await LocalStorageService.saveString(
      'app_active_session',
      json.encode({
        'user_id': currentUserId,
        'email': currentUserEmail,
        'role': currentUserRole,
        'name': currentUserName,
        'library_id': profile.libraryId,
      }),
    );
    await LocalStorageService.saveString('app_last_login_identifier', googleEmail);
    return AuthResult(
      success: true,
      role: 'Admin',
      userName: currentUserName,
      userId: currentUserId,
    );
  }

  Future<AuthResult> loginWithBiometrics() async {
    ensureInitialized();

    // 1. Check if device has registered local credentials
    final sessionStr = await LocalStorageService.getString('app_active_session');
    final lastIdentifier = await LocalStorageService.getString('app_last_login_identifier');
    final effectiveId = (lastIdentifier != null && lastIdentifier.isNotEmpty)
        ? lastIdentifier
        : (profile.adminEmail.isNotEmpty ? profile.adminEmail : '');

    if ((sessionStr == null || sessionStr.isEmpty) && effectiveId.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'No registered credentials found on this device. Please log in with Google or your credentials first.',
      );
    }

    // 2. Check if hardware biometric sensor is available
    final canUseHardware = await BiometricAuthService.canAuthenticate();
    if (!canUseHardware) {
      return const AuthResult(
        success: false,
        message: 'Biometric hardware sensor is not available or no fingerprint enrolled on this phone.',
      );
    }

    // 3. Prompt native phone OS biometric hardware sensor (BiometricPrompt)
    final biometricPassed = await BiometricAuthService.authenticate(
      reason: 'Scan your fingerprint or verify biometrics to log in to TrackMyLibrary',
    );

    if (!biometricPassed) {
      return const AuthResult(
        success: false,
        message: 'Fingerprint authentication was not completed or was cancelled.',
      );
    }

    // 4. Physical fingerprint verified! Restore active session or saved credential
    if (sessionStr != null && sessionStr.isNotEmpty) {
      await restoreSession();
      if (isAuthenticated) {
        return AuthResult(
          success: true,
          role: currentUserRole,
          userName: currentUserName,
          userId: currentUserId,
        );
      }
    }

    // Re-authenticate using local admin session
    currentUserId = 'admin_bio_001';
    currentUserName = (profile.adminName.isNotEmpty && profile.adminName != 'Admin')
        ? profile.adminName
        : 'Administrator';
    currentUserEmail = effectiveId;
    currentUserRole = 'Admin';
    isAuthenticated = true;
    await LocalStorageService.saveString(
      'app_active_session',
      json.encode({
        'user_id': currentUserId,
        'email': currentUserEmail,
        'role': currentUserRole,
        'name': currentUserName,
      }),
    );
    await LocalStorageService.saveString('app_last_login_identifier', effectiveId);
    return AuthResult(
      success: true,
      role: 'Admin',
      userName: currentUserName,
      userId: currentUserId,
    );
  }

  Future<AuthResult> registerAdminAccount({
    required String email,
    required String password,
    required String adminName,
    required String libraryName,
    String? phone,
  }) async {
    ensureInitialized();
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.length < 6) {
      return const AuthResult(
        success: false,
        message: 'Password must be at least 6 characters long.',
      );
    }

    if (isFirebaseConnected) {
      final currentFbUser = FirebaseAuth.instance.currentUser;
      if (currentFbUser != null &&
          currentFbUser.email != null &&
          currentFbUser.email!.toLowerCase() == cleanEmail.toLowerCase()) {
        // User is already authenticated (e.g. via Google Sign-In)
        currentUserId = currentFbUser.uid;
        profile.libraryId = currentFbUser.uid;
      } else {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
          if (credential.user != null) {
            currentUserId = credential.user!.uid;
            profile.libraryId = credential.user!.uid;
          }
        } on FirebaseAuthException catch (e) {
          String msg = 'Registration failed: ${e.message ?? e.code}';
          if (e.code == 'email-already-in-use') msg = 'This email is already registered. Please sign in directly from the login screen.';
          if (e.code == 'weak-password') msg = 'The password is too weak (min 6 characters required).';
          if (e.code == 'operation-not-allowed') msg = 'Email/Password sign-in is disabled in Firebase Console. Please enable it under Authentication -> Sign-in method.';
          return AuthResult(success: false, message: msg);
        } catch (_) {}
      }
    }

    profile.adminEmail = cleanEmail;
    profile.adminName = adminName.trim();
    profile.libraryName = libraryName.trim();
    if (phone != null && phone.isNotEmpty) {
      profile.adminPhone = phone.trim();
    }
    currentUserId ??= 'admin_${DateTime.now().millisecondsSinceEpoch}';
    if (profile.libraryId.isEmpty || profile.libraryId == 'lib_patna_central') {
      profile.libraryId = currentUserId!;
    }
    currentUserName = profile.adminName;
    currentUserEmail = cleanEmail;
    currentUserRole = 'Admin';
    isAuthenticated = true;

    await LocalStorageService.saveString('app_admin_password_hash', hashPin(cleanPass));
    await LocalStorageService.saveString(
      'app_active_session',
      json.encode({
        'user_id': currentUserId,
        'email': currentUserEmail,
        'role': currentUserRole,
        'name': currentUserName,
      }),
    );
    await _saveLocalState();
    if (isFirebaseConnected && currentUserId != null) {
      try {
        await _db.collection('libraries').doc(tenantId).set(profile.toMap(), SetOptions(merge: true));
        await _tenantCol('settings').doc('branding').set(profile.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
    return AuthResult(
      success: true,
      role: 'Admin',
      userName: currentUserName,
      userId: currentUserId,
    );
  }

  Future<void> signOut() async {
    if (isFirebaseConnected) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    currentUserId = null;
    currentUserName = 'Guest';
    currentUserEmail = '';
    currentUserRole = 'Admin';
    isAuthenticated = false;
    await LocalStorageService.remove('app_active_session');
  }

  Future<Map<String, dynamic>> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid ?? '';
      currentUserId = uid;
      if (uid.isNotEmpty) {
        profile.libraryId = uid;
      }
      currentUserRole = 'Admin';
      currentUserEmail = credential.user?.email ?? email.trim();
      currentUserName = profile.adminName.isNotEmpty ? profile.adminName : 'Administrator';
      isAuthenticated = true;
      await LocalStorageService.saveString(
        'app_active_session',
        json.encode({
          'user_id': currentUserId,
          'email': currentUserEmail,
          'role': currentUserRole,
          'name': currentUserName,
          'library_id': profile.libraryId,
        }),
      );
      return {'success': true, 'role': 'Admin', 'uid': uid};
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') message = 'Incorrect password.';
      if (e.code == 'too-many-requests') message = 'Too many attempts. Try again later.';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'Login error: $e'};
    }
  }

  Future<bool> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final storedHash = await LocalStorageService.getString('app_admin_password_hash');
    const defaultAdminHash = 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f';
    if (!verifyPin(currentPassword, storedHash ?? defaultAdminHash)) {
      return false;
    }
    await LocalStorageService.saveString('app_admin_password_hash', hashPin(newPassword));
    if (isFirebaseConnected && FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      } catch (_) {}
    }
    return true;
  }

  Future<AuthResult> sendPasswordReset(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please enter your registered admin email address.',
      );
    }
    if (!clean.contains('@')) {
      return const AuthResult(
        success: false,
        message: 'Staff PINs cannot be reset via email. Please ask your Library Administrator to reset your 4-digit PIN in Staff Settings.',
      );
    }
    if (isFirebaseConnected) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: clean);
        return const AuthResult(
          success: true,
          message: 'Password reset link sent to your registered email. Check your inbox.',
        );
      } on FirebaseAuthException catch (e) {
        String msg = 'Password reset failed: ${e.message ?? e.code}';
        if (e.code == 'user-not-found') msg = 'No registered admin account found with this email.';
        if (e.code == 'invalid-email') msg = 'Invalid email address format.';
        if (e.code == 'operation-not-allowed') msg = 'Email/Password sign-in is disabled in Firebase Console. Please enable it under Authentication -> Sign-in method.';
        return AuthResult(success: false, message: msg);
      } catch (e) {
        return AuthResult(success: false, message: 'Password recovery error: $e');
      }
    }
    return const AuthResult(
      success: true,
      message: 'In offline / local mode, your default administrator PIN is 1234. You can also sign in with Google.',
    );
  }

  // Real-time seat stream (Cloud Firestore or In-Memory Demo)
  Stream<List<SeatInfo>> streamSeats() {
    ensureInitialized();
    if (isFirebaseConnected) {
      return _tenantCol('seats').snapshots().map((snapshot) {
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
      return _tenantCol('students')
          .orderBy('joined_at', descending: true)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((d) => StudentInfo.fromFirestore(d.id, d.data()))
            .toList();
        _mockStudents.clear();
        _mockStudents.addAll(list);
        _syncSeatsWithStudents();
        return list;
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

  // Real-time expenses stream with optional limit
  Stream<List<ExpenseItem>> streamExpenses({int? limit}) {
    ensureInitialized();
    if (isFirebaseConnected) {
      var query = _tenantCol('expenses').orderBy('date', descending: true);
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((d) => ExpenseItem.fromFirestore(d.id, d.data()))
            .toList();
      });
    } else {
      Timer.run(() {
        if (!_mockExpensesController.isClosed) {
          final items = (limit != null && limit > 0)
              ? _mockExpenses.take(limit).toList()
              : _mockExpenses;
          _mockExpensesController.add(List.unmodifiable(items));
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
    final expId = 'exp_${DateTime.now().millisecondsSinceEpoch}';
    if (isFirebaseConnected) {
      await _tenantCol('expenses').doc(expId).set({
        'id': expId,
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
          id: expId,
          title: title,
          category: category,
          amount: amount,
          date: date,
          paymentMode: paymentMode,
          note: note,
        ),
      );
      _mockExpensesController.add(List.unmodifiable(_mockExpenses));
      await _saveLocalState();
    }
  }

  // Delete Expense
  Future<void> deleteExpense(String expenseId) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      try {
        await _tenantCol('expenses').doc(expenseId).delete();
      } catch (_) {}
    }
    _mockExpenses.removeWhere((e) => e.id == expenseId);
    _mockExpensesController.add(List.unmodifiable(_mockExpenses));
    await _saveLocalState();
  }

  // Financial ledger immutability: payments cannot be manually deleted
  Future<void> deletePayment(String paymentId, {bool reinstateStudentDues = false}) async {
    throw UnsupportedError(
      'Payment transactions are an immutable financial ledger and cannot be manually deleted.',
    );
  }

  // Stream Payment Transactions with optional limit
  Stream<List<PaymentTransaction>> streamPayments({int? limit}) {
    if (isFirebaseConnected) {
      var query = _tenantCol('payments').orderBy('date', descending: true);
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => PaymentTransaction.fromFirestore(doc.id, doc.data()))
          .toList());
    } else {
      ensureInitialized();
      Future.microtask(() {
        final items = (limit != null && limit > 0)
            ? _mockPayments.take(limit).toList()
            : _mockPayments;
        _mockPaymentsController.add(List.unmodifiable(items));
      });
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
    DateTime? validFrom,
    DateTime? validUntil,
    int? durationMonths,
  }) async {
    ensureInitialized();
    final payDate = date ?? DateTime.now();
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    // Format explicit period note for due collections
    String effectiveNotes = notes;
    String periodStr = '';
    if (validFrom != null && validUntil != null) {
      periodStr = '${DateFormat('dd-MMM-yyyy').format(validFrom)} to ${DateFormat('dd-MMM-yyyy').format(validUntil)}';
    } else if (validUntil != null) {
      final approxStart = date ?? DateTime.now();
      periodStr = '${DateFormat('dd-MMM-yyyy').format(approxStart)} to ${DateFormat('dd-MMM-yyyy').format(validUntil)}';
    }

    if (isFirebaseConnected) {
      if (studentId != null && studentId.isNotEmpty) {
        try {
          final studentDoc = await _tenantCol('students').doc(studentId).get();
          if (studentDoc.exists) {
            final data = studentDoc.data() ?? {};
            final curDues = (data['dues_amount'] as num?)?.toInt() ?? 0;
            final dueDateRaw = data['fee_due_date'];
            DateTime? currentDueDate;
            if (dueDateRaw is Timestamp) currentDueDate = dueDateRaw.toDate();

            final isDuePayment = curDues > 0 || notes.toLowerCase().contains('due');
            if (isDuePayment && periodStr.isNotEmpty && !notes.toLowerCase().contains('period')) {
              effectiveNotes = notes.isNotEmpty
                  ? '$notes • Due payment for period: $periodStr'
                  : 'Due payment for period: $periodStr';
            }

            final newDues = curDues > 0 ? (curDues - amount).clamp(0, 999999) : 0;
            final dateStr = DateFormat('dd-MMM-yyyy').format(payDate);
            final curNote = (data['note'] as String?) ?? '';
            final payLog = isDuePayment
                ? 'Due payment of ₹$amount collected via $paymentMode on $dateStr${periodStr.isNotEmpty ? " (Period: $periodStr)" : ""}${notes.isNotEmpty && !notes.contains(periodStr) ? " • $notes" : ""}.'
                : 'Payment of ₹$amount collected via $paymentMode on $dateStr${durationMonths != null && durationMonths > 0 ? " ($durationMonths mo tenure)" : ""}${notes.isNotEmpty ? " • $notes" : ""}.';
            final updatedNote = appendNote(curNote, payLog);

            final updates = <String, dynamic>{
              'dues_amount': newDues,
              'status': newDues == 0 ? 'ACTIVE' : 'DUES',
              'note': updatedNote,
            };
            if (currentDueDate != null && currentDueDate.isBefore(payDate) && newDues == 0) {
              updates['fee_due_date'] = Timestamp.fromDate(DateTime(payDate.year, payDate.month + 1, payDate.day));
            }
            await _tenantCol('students').doc(studentId).update(updates);
          }
        } catch (_) {}
      }

      await _tenantCol('payments').doc(paymentId).set({
        'payment_id': paymentId,
        'student_id': studentId ?? '',
        'student_name': studentName,
        'student_phone': phone ?? '',
        'seat_number': seatNumber,
        'shift': shift,
        'amount': amount,
        'date': Timestamp.fromDate(payDate),
        'payment_mode': paymentMode,
        'notes': effectiveNotes,
        if (validFrom != null) 'valid_from': Timestamp.fromDate(validFrom),
        if (validUntil != null) 'valid_until': Timestamp.fromDate(validUntil),
        if (durationMonths != null) 'duration_months': durationMonths,
      });
    } else {
      // Reconcile dues & activity log in student if registered
      final matchIdx = _mockStudents.indexWhere((s) =>
          (studentId != null && studentId.isNotEmpty && s.id == studentId) ||
          ((studentId == null || studentId.isEmpty) &&
              phone != null &&
              phone.isNotEmpty &&
              normalizePhone(s.phone) == normalizePhone(phone)));

      if (matchIdx != -1) {
        final s = _mockStudents[matchIdx];
        final currentDues = s.effectiveDues;
        final isDuePayment = currentDues > 0 || notes.toLowerCase().contains('due');
        if (isDuePayment && periodStr.isNotEmpty && !notes.toLowerCase().contains('period')) {
          effectiveNotes = notes.isNotEmpty
              ? '$notes • Due payment for period: $periodStr'
              : 'Due payment for period: $periodStr';
        }

        final newDues = currentDues > 0 ? (currentDues - amount).clamp(0, 999999) : 0;
        DateTime? updatedDueDate = s.feeDueDate;
        if (s.feeDueDate != null && s.feeDueDate!.isBefore(payDate) && newDues == 0) {
          updatedDueDate = DateTime(payDate.year, payDate.month + 1, payDate.day);
        }
        final dateStr = DateFormat('dd-MMM-yyyy').format(payDate);
        final payLog = isDuePayment
            ? 'Due payment of ₹$amount collected via $paymentMode on $dateStr${periodStr.isNotEmpty ? " (Period: $periodStr)" : ""}${notes.isNotEmpty && !notes.contains(periodStr) ? " • $notes" : ""}.'
            : 'Payment of ₹$amount collected via $paymentMode on $dateStr${durationMonths != null && durationMonths > 0 ? " ($durationMonths mo tenure)" : ""}${notes.isNotEmpty ? " • $notes" : ""}.';
        final updatedNote = appendNote(s.note, payLog);

        _mockStudents[matchIdx] = s.copyWith(
          duesAmount: newDues,
          status: newDues == 0 ? 'ACTIVE' : 'DUES',
          feeDueDate: updatedDueDate,
          note: updatedNote,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
      }

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
          notes: effectiveNotes,
          validFrom: validFrom,
          validUntil: validUntil,
          durationMonths: durationMonths,
        ),
      );
      _mockPaymentsController.add(List.unmodifiable(_mockPayments));

      await _saveLocalState();
    }
  }

  // Adjust last tenure payment transaction when student's shift changes
  // In case of downgrade: reduces last tenure purchase cost accordingly in payments tab & financial ledger
  // In case of upgrade using advance: restores last tenure purchase cost by advance credit consumed
  Future<void> adjustLastPaymentForShiftChange({
    required String studentId,
    String? phone,
    String? studentName,
    required String newShift,
    required int targetTenureCost,
    int advanceCredited = 0,
    int advanceConsumed = 0,
    String? noteDetails,
  }) async {
    ensureInitialized();
    final normPhone = phone != null ? normalizePhone(phone) : null;
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);

    if (isFirebaseConnected) {
      try {
        QuerySnapshot<Map<String, dynamic>> snap = await _tenantCol('payments')
            .where('student_id', isEqualTo: studentId)
            .get();

        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.docs;
        if (docs.isEmpty && studentId.isEmpty && phone != null && phone.isNotEmpty) {
          final phoneSnap = await _tenantCol('payments')
              .where('student_phone', isEqualTo: phone)
              .get();
          docs = phoneSnap.docs;
        }
        if (docs.isEmpty && studentId.isEmpty && normPhone != null && normPhone.isNotEmpty && normPhone != phone) {
          final normSnap = await _tenantCol('payments')
              .where('student_phone', isEqualTo: normPhone)
              .get();
          docs = normSnap.docs;
        }
        if (docs.isEmpty) {
          final allSnap = await _tenantCol('payments').limit(100).get();
          docs = allSnap.docs.where((d) {
            final data = d.data();
            final sId = data['student_id']?.toString() ?? '';
            final sPhone = data['student_phone']?.toString() ?? '';
            return (studentId.isNotEmpty && sId == studentId) ||
                (studentId.isEmpty && normPhone != null && normPhone.isNotEmpty && normalizePhone(sPhone) == normPhone);
          }).toList();
        }

        if (docs.isNotEmpty) {
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final aDate = a.data()['date'];
              final bDate = b.data()['date'];
              final aDt = aDate is Timestamp ? aDate.toDate() : (aDate is DateTime ? aDate : DateTime.now());
              final bDt = bDate is Timestamp ? bDate.toDate() : (bDate is DateTime ? bDate : DateTime.now());
              return bDt.compareTo(aDt);
            });
          final latestDoc = sortedDocs.first;
          final curData = latestDoc.data();
          final curShift = (curData['shift'] as String?) ?? '';

          // If this payment was already adjusted for newShift, avoid duplicate adjustment
          if (curShift.trim().toLowerCase() == newShift.trim().toLowerCase()) {
            return;
          }

          final curAmount = (curData['amount'] as num?)?.toInt() ?? 0;
          final curNotes = (curData['notes'] as String?) ?? '';

          int updatedAmount = curAmount;
          String adjustmentLog = '';
          if (advanceCredited > 0) {
            final diffAmount = (curAmount - advanceCredited).clamp(0, 9999999);
            updatedAmount = (targetTenureCost > 0 && targetTenureCost < curAmount)
                ? targetTenureCost
                : diffAmount;
            adjustmentLog = 'Shift downgraded to $newShift on $dateStr • Purchase cost adjusted from ₹$curAmount to ₹$updatedAmount (₹$advanceCredited credited to advance)';
          } else if (advanceConsumed > 0) {
            updatedAmount = (curAmount + advanceConsumed).clamp(0, targetTenureCost > 0 ? targetTenureCost : 9999999);
            adjustmentLog = 'Shift upgraded to $newShift on $dateStr • Purchase cost adjusted from ₹$curAmount to ₹$updatedAmount (₹$advanceConsumed advance applied)';
          } else {
            updatedAmount = (targetTenureCost > 0 && targetTenureCost < curAmount) ? targetTenureCost : curAmount;
            adjustmentLog = 'Shift updated to $newShift on $dateStr';
          }

          final updatedNotes = curNotes.isNotEmpty
              ? '$curNotes • $adjustmentLog'
              : adjustmentLog;

          await _tenantCol('payments').doc(latestDoc.id).update({
            'amount': updatedAmount,
            'shift': newShift,
            'notes': updatedNotes,
          });

          // Also keep in-memory _mockPayments and Stream in sync
          final mIdx = _mockPayments.indexWhere((p) => p.id == latestDoc.id);
          if (mIdx != -1) {
            _mockPayments[mIdx] = _mockPayments[mIdx].copyWith(
              amount: updatedAmount,
              shift: newShift,
              notes: updatedNotes,
            );
            _mockPaymentsController.add(List.unmodifiable(_mockPayments));
          }
        }
      } catch (_) {}
    } else {
      // In mock storage: find the MOST RECENT payment transaction by date for this student
      int bestIdx = -1;
      DateTime? latestDate;
      for (int i = 0; i < _mockPayments.length; i++) {
        final p = _mockPayments[i];
        final matches = (studentId.isNotEmpty && p.studentId == studentId) ||
            (studentId.isEmpty && normPhone != null && normalizePhone(p.studentPhone) == normPhone);
        if (matches) {
          if (latestDate == null || p.date.isAfter(latestDate)) {
            latestDate = p.date;
            bestIdx = i;
          }
        }
      }

      if (bestIdx != -1) {
        final p = _mockPayments[bestIdx];

        // If this payment was already adjusted for newShift, avoid duplicate adjustment
        if (p.shift.trim().toLowerCase() == newShift.trim().toLowerCase()) {
          return;
        }

        int updatedAmount = p.amount;
        String adjustmentLog = '';
        if (advanceCredited > 0) {
          final diffAmount = (p.amount - advanceCredited).clamp(0, 9999999);
          updatedAmount = (targetTenureCost > 0 && targetTenureCost < p.amount)
              ? targetTenureCost
              : diffAmount;
          adjustmentLog = 'Shift downgraded to $newShift on $dateStr • Purchase cost adjusted from ₹${p.amount} to ₹$updatedAmount (₹$advanceCredited credited to advance)';
        } else if (advanceConsumed > 0) {
          updatedAmount = (p.amount + advanceConsumed).clamp(0, targetTenureCost > 0 ? targetTenureCost : 9999999);
          adjustmentLog = 'Shift upgraded to $newShift on $dateStr • Purchase cost adjusted from ₹${p.amount} to ₹$updatedAmount (₹$advanceConsumed advance applied)';
        } else {
          updatedAmount = (targetTenureCost > 0 && targetTenureCost < p.amount) ? targetTenureCost : p.amount;
          adjustmentLog = 'Shift updated to $newShift on $dateStr';
        }

        final updatedNotes = p.notes.isNotEmpty
            ? '${p.notes} • $adjustmentLog'
            : adjustmentLog;

        _mockPayments[bestIdx] = p.copyWith(
          amount: updatedAmount,
          shift: newShift,
          notes: updatedNotes,
        );
        _mockPaymentsController.add(List.unmodifiable(_mockPayments));
        await _saveLocalState();
      }
    }
  }

  // Assign Seat to Existing Student (Enforces: 1 student can ONLY be on 1 seat)
  Future<void> assignSeatToExistingStudent({
    required int newSeatNumber,
    required String studentId,
    String? shift,
    String? sectionName,
    int feePaidNow = 0,
    String paymentMode = 'UPI',
    String deviceUserId = 'Desk_Manager',
  }) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      await _db.runTransaction((transaction) async {
        final studentDocRef = _tenantCol('students').doc(studentId);
        final studentSnap = await transaction.get(studentDocRef);
        if (!studentSnap.exists) {
          throw Exception('Student not found');
        }
        final sData = studentSnap.data()!;
        final oldSeat = (sData['seat_number'] as num?)?.toInt();
        final studentName = (sData['name'] as String?) ?? 'Student';
        final effectiveShift = shift ?? (sData['shift'] as String?) ?? 'Full Day';
        final effectiveSection = sectionName ?? (sData['section_name'] as String?) ?? 'Main Hall';

        // 1. Vacate old seat if exists and different
        if (oldSeat != null && oldSeat != newSeatNumber) {
          final oldSeatRef = _tenantCol('seats').doc('seat_$oldSeat');
          transaction.set(oldSeatRef, {
            'seat_number': oldSeat,
            'is_occupied': false,
            'student_id': null,
            'student_name': null,
            'shift': null,
          }, SetOptions(merge: true));
        }

        // 2. Assign new seat
        final newSeatRef = _tenantCol('seats').doc('seat_$newSeatNumber');
        transaction.set(newSeatRef, {
          'seat_number': newSeatNumber,
          'is_occupied': true,
          'student_id': studentId,
          'student_name': studentName,
          'shift': effectiveShift,
          'section_name': effectiveSection,
          'last_updated_by': deviceUserId,
        }, SetOptions(merge: true));

        // 3. Update student with seat and shift change activity notes
        final curNote = (sData['note'] as String?) ?? '';
        final oldShift = (sData['shift'] as String?) ?? '';
        final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
        String updatedNote = curNote;
        if (oldSeat != null && oldSeat != newSeatNumber) {
          updatedNote = appendNote(updatedNote, 'Seat changed: S-$oldSeat → S-$newSeatNumber ($effectiveShift) on $dateStr.');
        } else if (oldSeat == null) {
          updatedNote = appendNote(updatedNote, 'Seat assigned: S-$newSeatNumber ($effectiveShift) on $dateStr.');
        }
        if (oldShift.isNotEmpty && oldShift.toLowerCase() != effectiveShift.toLowerCase()) {
          updatedNote = appendNote(updatedNote, 'Shift changed: $oldShift → $effectiveShift on $dateStr.');
        }
        if (feePaidNow > 0) {
          updatedNote = appendNote(updatedNote, 'Payment of ₹$feePaidNow collected via $paymentMode on $dateStr.');
        }

        final updateData = <String, dynamic>{
          'seat_number': newSeatNumber,
          'shift': effectiveShift,
          'section_name': effectiveSection,
          'status': 'ACTIVE',
          'note': updatedNote,
        };
        if (feePaidNow > 0) {
          final payRef = _tenantCol('payments').doc();
          transaction.set(payRef, {
            'payment_id': payRef.id,
            'student_id': studentId,
            'student_name': studentName,
            'amount': feePaidNow,
            'date': Timestamp.now(),
            'payment_mode': paymentMode,
            'valid_until': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
            'collected_by': deviceUserId,
          });
          updateData['fee_due_date'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
          updateData['dues_amount'] = 0;
        }
        transaction.update(studentDocRef, updateData);
      });
    } else {
      final sIdx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (sIdx == -1) return;
      final s = _mockStudents[sIdx];
      final effectiveShift = shift ?? s.shift;
      final effectiveSection = sectionName ?? s.sectionName;

      // 1. Ensure this student vacates any previous seats across the entire library (enforcing 1 seat per student)
      for (int i = 0; i < _mockSeats.length; i++) {
        if (_mockSeats[i].studentId == studentId ||
            (_mockSeats[i].studentName.isNotEmpty &&
                _mockSeats[i].studentName.toLowerCase() == s.name.toLowerCase() &&
                _mockSeats[i].seatNumber != newSeatNumber)) {
          _mockSeats[i] = SeatInfo(seatNumber: _mockSeats[i].seatNumber);
        }
      }

      // 2. Clear only conflicting shift occupants from new seat
      for (int i = 0; i < _mockStudents.length; i++) {
        if (_mockStudents[i].id != studentId &&
            _mockStudents[i].seatNumber == newSeatNumber &&
            doShiftsConflict(_mockStudents[i].shift, effectiveShift, allShifts: shifts)) {
          _mockStudents[i] = _mockStudents[i].copyWith(seatNumber: null, clearSeatNumber: true);
        }
      }

      // 3. Assign new seat
      final newIdx = newSeatNumber - 1;
      if (newIdx >= 0 && newIdx < _mockSeats.length) {
        _mockSeats[newIdx] = SeatInfo(
          seatNumber: newSeatNumber,
          isOccupied: true,
          studentId: studentId,
          studentName: s.name,
          shift: effectiveShift,
          sectionName: effectiveSection,
        );
      }

      // 4. Update dues & log payment if fee paid now
      int updatedDues = s.duesAmount;
      DateTime? updatedDueDate = s.feeDueDate;
      String updatedStatus = s.status;

      if (feePaidNow > 0) {
        updatedDues = (updatedDues - feePaidNow).clamp(0, 999999);
        updatedDueDate = DateTime.now().add(const Duration(days: 30));
        if (updatedDues == 0 && updatedStatus == 'DUES') {
          updatedStatus = 'ACTIVE';
        }
        _mockPayments.insert(
          0,
          PaymentTransaction(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            studentId: studentId,
            studentName: s.name,
            studentPhone: s.phone,
            seatNumber: newSeatNumber,
            shift: effectiveShift,
            amount: feePaidNow,
            date: DateTime.now(),
            paymentMode: paymentMode,
            notes: 'Seat assignment payment',
          ),
        );
        _mockPaymentsController.add(List.unmodifiable(_mockPayments));
      }

      final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
      String updatedNote = s.note;
      if (s.seatNumber != null && s.seatNumber != newSeatNumber) {
        updatedNote = appendNote(updatedNote, 'Seat changed: S-${s.seatNumber} → S-$newSeatNumber ($effectiveShift) on $dateStr.');
      } else if (s.seatNumber == null) {
        updatedNote = appendNote(updatedNote, 'Seat assigned: S-$newSeatNumber ($effectiveShift) on $dateStr.');
      }
      if (s.shift.isNotEmpty && s.shift.toLowerCase() != effectiveShift.toLowerCase()) {
        updatedNote = appendNote(updatedNote, 'Shift changed: ${s.shift} → $effectiveShift on $dateStr.');
      }
      if (feePaidNow > 0) {
        updatedNote = appendNote(updatedNote, 'Payment of ₹$feePaidNow collected via $paymentMode on $dateStr.');
      }

      _mockStudents[sIdx] = s.copyWith(
        seatNumber: newSeatNumber,
        shift: effectiveShift,
        sectionName: effectiveSection,
        feeDueDate: updatedDueDate,
        duesAmount: updatedDues,
        status: updatedStatus,
        note: updatedNote,
      );

      _mockSeatsController.add(List.unmodifiable(_mockSeats));
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
      _saveLocalState();
    }
  }

  // Change Seat
  Future<void> changeSeat({
    required int fromSeatNumber,
    required int toSeatNumber,
    required String studentId,
    String? shift,
  }) async {
    await assignSeatToExistingStudent(
      newSeatNumber: toSeatNumber,
      studentId: studentId,
      shift: shift,
    );
  }

  /// Convenience helper for direct student registration or bulk onboarding
  Future<void> addStudent(StudentInfo student) async {
    await assignSeatAndRegisterStudent(
      studentId: student.id,
      seatNumber: student.seatNumber,
      studentName: student.name,
      phone: student.phone,
      shift: student.shift,
      deviceUserId: 'admin_bulk_import',
      feeAmount: 0,
      monthlyFee: student.monthlyFee,
      duesAmount: student.duesAmount,
      advanceAmount: student.advanceAmount,
      status: student.status,
      joiningDate: student.joinedAt ?? DateTime.now(),
      validUntil: student.feeDueDate,
      note: student.note,
      fatherName: student.fatherName,
      address: student.address,
      aadhaarNumber: student.aadhaarNumber,
      photoBase64: student.photoBase64,
    );
  }

  // Atomic Seat Assignment Transaction (prevents duplicate student entries)
  Future<void> assignSeatAndRegisterStudent({
    String? studentId,
    int? seatNumber,
    required String studentName,
    required String phone,
    required String shift,
    String deviceUserId = 'Admin',
    int feeAmount = 500,
    int? monthlyFee,
    String paymentMode = 'UPI',
    String status = 'ACTIVE',
    DateTime? joiningDate,
    DateTime? validUntil,
    DateTime? paymentDate,
    String note = '',
    int duesAmount = 0,
    int advanceAmount = 0,
    String fatherName = '',
    String address = '',
    String aadhaarNumber = '',
    String preparationFor = '',
    String gender = 'Male',
    String? photoBase64,
    int durationMonths = 1,
  }) async {
    ensureInitialized();

    final now = joiningDate ?? DateTime.now();
    final effectiveJoiningDate = now;
    final payDate = paymentDate ?? DateTime.now();
    final totalFee = feeAmount + duesAmount;
    final effectiveMonths = durationMonths > 0 ? durationMonths : 1;
    final effectiveMonthly = (monthlyFee != null && monthlyFee > 0)
        ? monthlyFee
        : (totalFee > 0
            ? (totalFee ~/ effectiveMonths > 0 ? totalFee ~/ effectiveMonths : totalFee)
            : 500);
    final effectiveValidUntil = validUntil ??
        ((duesAmount > 0 && feeAmount == 0)
            ? now // Due immediately if no initial fee was paid
            : DateTime(now.year, now.month + effectiveMonths, now.day));

    // Prevent duplicate student creation: if phone exists, update existing student!
    final existingStudent = findStudentByPhone(phone);
    if (existingStudent != null) {
      if (seatNumber != null) {
        await assignSeatToExistingStudent(
          newSeatNumber: seatNumber,
          studentId: existingStudent.id,
          shift: shift,
          feePaidNow: 0,
          paymentMode: paymentMode,
          deviceUserId: deviceUserId,
        );
      }
      await updateStudent(
        studentId: existingStudent.id,
        name: studentName,
        phone: phone,
        shift: shift,
        seatNumber: seatNumber,
        note: note,
        monthlyFee: effectiveMonthly,
        duesAmount: duesAmount,
        advanceAmount: advanceAmount,
        status: status,
        feeDueDate: effectiveValidUntil,
        fatherName: fatherName,
        address: address,
        aadhaarNumber: aadhaarNumber,
        preparationFor: preparationFor,
        gender: gender,
        photoBase64: photoBase64,
      );
      if (status != 'TRIAL' && feeAmount > 0) {
        await recordPayment(
          studentId: existingStudent.id,
          studentName: studentName,
          phone: phone,
          seatNumber: seatNumber,
          shift: shift,
          amount: feeAmount,
          date: payDate,
          paymentMode: paymentMode,
          notes: durationMonths > 1
              ? '$durationMonths Months Advance Fees'
              : 'Initial registration fee',
        );
      }
      return;
    }

    // Ensure seat is not already occupied by another student for the same or conflicting shift
    if (seatNumber != null && isSeatOccupied(seatNumber, shift: shift)) {
      final occ = getStudentForSeat(seatNumber, shift: shift);
      if (occ != null) {
        throw Exception('Seat S-$seatNumber is already occupied for shift "$shift" by ${occ.name}. It cannot be assigned.');
      }
    }

    if (isFirebaseConnected) {
      final studentDocRef = (studentId != null && studentId.isNotEmpty)
          ? _tenantCol('students').doc(studentId)
          : _tenantCol('students').doc();
      final paymentDocRef = _tenantCol('payments').doc();

      await _db.runTransaction((transaction) async {
        if (seatNumber != null) {
          final seatDocRef = _tenantCol('seats').doc('seat_$seatNumber');
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
        final dateStr = DateFormat('dd-MMM-yyyy').format(effectiveJoiningDate);
        final seatStr = seatNumber != null ? 'S-$seatNumber' : 'Unallocated';
        final admitLog = 'Admission on $dateStr: Shift $shift (Seat $seatStr, ₹$effectiveMonthly/mo)${feeAmount > 0 ? ", Initial fee ₹$feeAmount paid via $paymentMode" : ""}${duesAmount > 0 ? ", Pending dues ₹$duesAmount" : ""}.';
        final effectiveNote = appendNote(note, admitLog);

        transaction.set(studentDocRef, {
          'id': studentDocRef.id,
          'name': studentName,
          'phone': phone,
          'seat_number': seatNumber,
          'shift': shift,
          'fee_due_date': Timestamp.fromDate(effectiveValidUntil),
          'status': status,
          'joined_at': Timestamp.fromDate(now),
          'monthly_fee': effectiveMonthly,
          'payment_mode': paymentMode,
          'note': effectiveNote,
          'dues_amount': duesAmount,
          'advance_amount': advanceAmount,
          'father_name': fatherName,
          'address': address,
          'aadhaar_number': aadhaarNumber,
          'preparation_for': preparationFor,
          'gender': gender,
          'photo_base64': photoBase64,
        });

        // 2. Log payment if not trial and fee > 0
        if (status != 'TRIAL' && feeAmount > 0) {
          transaction.set(paymentDocRef, {
            'payment_id': paymentDocRef.id,
            'student_id': studentDocRef.id,
            'student_name': studentName,
            'student_phone': phone,
            'seat_number': seatNumber,
            'shift': shift,
            'amount': feeAmount,
            'date': Timestamp.fromDate(payDate),
            'valid_until': Timestamp.fromDate(effectiveValidUntil),
            'collected_by': deviceUserId,
            'payment_mode': paymentMode,
            'notes': durationMonths > 1
                ? '$durationMonths Months Advance Fees'
                : 'Initial registration fee',
          });
        }
      });
    } else {
      // In-memory mock assignment
      final effectiveStudentId = (studentId != null && studentId.isNotEmpty)
          ? studentId
          : 'std_${DateTime.now().millisecondsSinceEpoch}_${++_uniqueIdCounter}';
      if (seatNumber != null) {
        // Unassign seat only from previous occupants who have conflicting shifts
        for (int i = 0; i < _mockStudents.length; i++) {
          if (_mockStudents[i].seatNumber == seatNumber &&
              doShiftsConflict(_mockStudents[i].shift, shift, allShifts: shifts)) {
            _mockStudents[i] = _mockStudents[i].copyWith(seatNumber: null, clearSeatNumber: true);
          }
        }
      }

      final dateStr = DateFormat('dd-MMM-yyyy').format(effectiveJoiningDate);
      final seatStr = seatNumber != null ? 'S-$seatNumber' : 'Unallocated';
      final admitLog = 'Admission on $dateStr: Shift $shift (Seat $seatStr, ₹$effectiveMonthly/mo)${feeAmount > 0 ? ", Initial fee ₹$feeAmount paid via $paymentMode" : ""}${duesAmount > 0 ? ", Pending dues ₹$duesAmount" : ""}.';
      final effectiveNote = appendNote(note, admitLog);

      _mockStudents.insert(
        0,
        StudentInfo(
          id: effectiveStudentId,
          name: studentName,
          phone: phone,
          seatNumber: seatNumber,
          shift: shift,
          status: status,
          feeDueDate: effectiveValidUntil,
          joinedAt: now,
          monthlyFee: effectiveMonthly,
          paymentMode: paymentMode,
          note: effectiveNote,
          duesAmount: duesAmount,
          advanceAmount: advanceAmount,
          fatherName: fatherName,
          address: address,
          aadhaarNumber: aadhaarNumber,
          preparationFor: preparationFor,
          gender: gender,
          photoBase64: photoBase64,
        ),
      );

      if (status != 'TRIAL' && feeAmount > 0) {
        _mockPayments.insert(
          0,
          PaymentTransaction(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            studentId: effectiveStudentId,
            studentName: studentName,
            studentPhone: phone,
            seatNumber: seatNumber,
            shift: shift,
            amount: feeAmount,
            date: payDate,
            paymentMode: paymentMode,
            notes: durationMonths > 1
                ? '$durationMonths Months Advance Fees'
                : 'Initial registration fee',
            validFrom: effectiveJoiningDate,
            validUntil: effectiveValidUntil,
            durationMonths: durationMonths,
          ),
        );
        _mockPaymentsController.add(List.unmodifiable(_mockPayments));
      }

      _syncSeatsWithStudents();
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
      _saveLocalState();
    }
  }

  // Vacate Seat (Sets seat isOccupied: false, and student.seatNumber: null without marking inactive)
  Future<void> vacateSeat(int seatNumber, String? studentId) async {
    ensureInitialized();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final vacateLog = 'Seat unassigned / vacated from S-$seatNumber on $dateStr.';

    if (isFirebaseConnected) {
      final batch = _db.batch();

      if (studentId != null && studentId.trim().isNotEmpty) {
        final sId = studentId.trim();
        final studentDocRef = _tenantCol('students').doc(sId);
        try {
          final snap = await studentDocRef.get();
          if (snap.exists) {
            final curNote = (snap.data()?['note'] as String?) ?? '';
            final updatedNote = appendNote(curNote, vacateLog);
            batch.update(studentDocRef, {
              'seat_number': null,
              'note': updatedNote,
            });
          }
        } catch (_) {
          batch.update(studentDocRef, {'seat_number': null});
        }
      }

      final otherStudents = _mockStudents.where(
        (s) => s.seatNumber == seatNumber && s.id != studentId && s.status != 'INACTIVE',
      ).toList();

      final seatDocRef = _tenantCol('seats').doc('seat_$seatNumber');
      if (otherStudents.isNotEmpty) {
        final remaining = otherStudents.first;
        batch.update(seatDocRef, {
          'is_occupied': true,
          'student_id': remaining.id,
          'student_name': remaining.name,
          'shift': remaining.shift,
        });
      } else {
        batch.update(seatDocRef, {
          'is_occupied': false,
          'student_id': null,
          'student_name': null,
          'shift': null,
        });
      }

      await batch.commit();
    } else {
      if (studentId != null && studentId.isNotEmpty) {
        final studentIndex =
            _mockStudents.indexWhere((s) => s.id == studentId);
        if (studentIndex != -1) {
          final s = _mockStudents[studentIndex];
          final updatedNote = appendNote(s.note, vacateLog);
          _mockStudents[studentIndex] = s.copyWith(
            seatNumber: null,
            clearSeatNumber: true,
            note: updatedNote,
          );
        }
      }

      _syncSeatsWithStudents();
      _mockStudentsController.add(List.unmodifiable(_mockStudents));
      _saveLocalState();
    }
  }

  // Move Student to Inactive (frees seat, keeps record in INACTIVE tab)
  Future<void> markStudentInactive(String studentId, int? seatNumber) async {
    ensureInitialized();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final inactiveLog = seatNumber != null
        ? 'Member moved to Inactive on $dateStr (Seat S-$seatNumber freed).'
        : 'Member moved to Inactive on $dateStr.';

    if (isFirebaseConnected) {
      try {
        final batch = _db.batch();
        final studentDocRef = _tenantCol('students').doc(studentId);

        String updatedNote = '';
        try {
          final snap = await studentDocRef.get();
          if (snap.exists) {
            final curNote = (snap.data()?['note'] as String?) ?? '';
            updatedNote = appendNote(curNote, inactiveLog);
          }
        } catch (_) {}

        batch.update(studentDocRef, {
          'status': 'INACTIVE',
          'seat_number': null,
          if (updatedNote.isNotEmpty) 'note': updatedNote,
        });
        if (seatNumber != null) {
          final otherStudents = _mockStudents.where(
            (s) => s.seatNumber == seatNumber && s.id != studentId && s.status != 'INACTIVE',
          ).toList();
          final seatDocRef = _tenantCol('seats').doc('seat_$seatNumber');
          if (otherStudents.isNotEmpty) {
            final rem = otherStudents.first;
            batch.update(seatDocRef, {
              'is_occupied': true,
              'student_id': rem.id,
              'student_name': rem.name,
              'shift': rem.shift,
            });
          } else {
            batch.update(seatDocRef, {
              'is_occupied': false,
              'student_id': null,
              'student_name': null,
              'shift': null,
            });
          }
        }
        await batch.commit();
      } catch (_) {}
    }

    final idx = _mockStudents.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final s = _mockStudents[idx];
      final updatedNote = appendNote(s.note, inactiveLog);
      _mockStudents[idx] = s.copyWith(
        status: 'INACTIVE',
        seatNumber: null,
        clearSeatNumber: true,
        note: updatedNote,
      );
    }
    _syncSeatsWithStudents();
    _mockStudentsController.add(List.unmodifiable(_mockStudents));
    await _saveLocalState();
  }

  // Delete Student alias to markStudentInactive (moves student to INACTIVE tab)
  Future<void> deleteStudent(String studentId, int? seatNumber) async {
    await markStudentInactive(studentId, seatNumber);
  }

  // Permanently purge student from records and delete associated payments
  Future<void> permanentlyDeleteStudent(String studentId, int? seatNumber) async {
    ensureInitialized();
    if (isFirebaseConnected) {
      try {
        final batch = _db.batch();
        final studentDocRef = _tenantCol('students').doc(studentId);
        batch.delete(studentDocRef);

        // Delete all payment records linked to this student from Firestore
        try {
          final paySnap = await _tenantCol('payments').where('student_id', isEqualTo: studentId).get();
          for (final pDoc in paySnap.docs) {
            batch.delete(pDoc.reference);
          }
        } catch (_) {}

        if (seatNumber != null) {
          final otherStudents = _mockStudents.where(
            (s) => s.seatNumber == seatNumber && s.id != studentId && s.status != 'INACTIVE',
          ).toList();
          final seatDocRef = _tenantCol('seats').doc('seat_$seatNumber');
          if (otherStudents.isNotEmpty) {
            final rem = otherStudents.first;
            batch.update(seatDocRef, {
              'is_occupied': true,
              'student_id': rem.id,
              'student_name': rem.name,
              'shift': rem.shift,
            });
          } else {
            batch.update(seatDocRef, {
              'is_occupied': false,
              'student_id': null,
              'student_name': null,
              'shift': null,
            });
          }
        }
        await batch.commit();
      } catch (_) {}
    }

    _mockStudents.removeWhere((s) => s.id == studentId);
    _mockPayments.removeWhere((p) => p.studentId == studentId);
    _syncSeatsWithStudents();
    _mockStudentsController.add(List.unmodifiable(_mockStudents));
    _mockPaymentsController.add(List.unmodifiable(_mockPayments));
    await _saveLocalState();
  }

  // Mark Student as Trial
  Future<void> markStudentTrial(String studentId) async {
    ensureInitialized();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final trialLog = 'Status changed to TRIAL on $dateStr.';

    if (isFirebaseConnected) {
      String updatedNote = '';
      try {
        final snap = await _tenantCol('students').doc(studentId).get();
        if (snap.exists) {
          final curNote = (snap.data()?['note'] as String?) ?? '';
          updatedNote = appendNote(curNote, trialLog);
        }
      } catch (_) {}
      await _tenantCol('students').doc(studentId).update({
        'status': 'TRIAL',
        'dues_amount': 0,
        if (updatedNote.isNotEmpty) 'note': updatedNote,
      });
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final updatedNote = appendNote(_mockStudents[idx].note, trialLog);
        _mockStudents[idx] = _mockStudents[idx].copyWith(
          status: 'TRIAL',
          duesAmount: 0,
          note: updatedNote,
        );
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        _saveLocalState();
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
    final newStatus = duesAmount > 0 ? 'DUES' : 'ACTIVE';
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final dueDateStr = DateFormat('dd-MMM-yyyy').format(dDate);
    final duesLog = duesAmount > 0
        ? 'Pending dues of ₹$duesAmount marked on $dateStr (Due date: $dueDateStr).'
        : 'Pending dues cleared on $dateStr.';

    if (isFirebaseConnected) {
      String updatedNote = '';
      try {
        final snap = await _tenantCol('students').doc(studentId).get();
        if (snap.exists) {
          final curNote = (snap.data()?['note'] as String?) ?? '';
          updatedNote = appendNote(curNote, duesLog);
        }
      } catch (_) {}
      await _tenantCol('students').doc(studentId).update({
        'status': newStatus,
        'dues_amount': duesAmount,
        'fee_due_date': Timestamp.fromDate(dDate),
        if (updatedNote.isNotEmpty) 'note': updatedNote,
      });
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final updatedNote = appendNote(_mockStudents[idx].note, duesLog);
        _mockStudents[idx] = _mockStudents[idx].copyWith(
          status: newStatus,
          duesAmount: duesAmount,
          feeDueDate: dDate,
          note: updatedNote,
        );
        _syncSeatsWithStudents();
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        _saveLocalState();
      }
    }
  }

  // Reactivate / Restore Inactive Student
  Future<void> reactivateStudent(
    String studentId, [
    int? seatNumber,
  ]) async {
    ensureInitialized();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final reactivateLog = seatNumber != null
        ? 'Member reactivated to Active on $dateStr (Assigned Seat S-$seatNumber).'
        : 'Member reactivated to Active on $dateStr.';

    if (isFirebaseConnected) {
      final batch = _db.batch();
      final studentDocRef = _tenantCol('students').doc(studentId);

      String updatedNote = '';
      try {
        final snap = await studentDocRef.get();
        if (snap.exists) {
          final curNote = (snap.data()?['note'] as String?) ?? '';
          updatedNote = appendNote(curNote, reactivateLog);
        }
      } catch (_) {}

      final updates = <String, dynamic>{
        'status': 'ACTIVE',
        'dues_amount': 0,
        if (updatedNote.isNotEmpty) 'note': updatedNote,
      };
      if (seatNumber != null) {
        updates['seat_number'] = seatNumber;
        final seatDocRef = _tenantCol('seats').doc('seat_$seatNumber');
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
        final updatedNote = appendNote(s.note, reactivateLog);
        _mockStudents[idx] = s.copyWith(
          status: 'ACTIVE',
          seatNumber: seatNumber ?? s.seatNumber,
          duesAmount: 0,
          note: updatedNote,
        );
        _syncSeatsWithStudents();
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        _saveLocalState();
      }
    }
  }

  // Update Student details via StudentInfo object directly
  Future<bool> updateStudentInfo(StudentInfo s) {
    return updateStudent(
      studentId: s.id,
      name: s.name,
      phone: s.phone,
      shift: s.shift,
      seatNumber: s.seatNumber,
      note: s.note,
      monthlyFee: s.monthlyFee,
      duesAmount: s.duesAmount,
      advanceAmount: s.advanceAmount,
      status: s.status,
      feeDueDate: s.feeDueDate,
      fatherName: s.fatherName,
      address: s.address,
      aadhaarNumber: s.aadhaarNumber,
      preparationFor: s.preparationFor,
      gender: s.gender,
      sectionName: s.sectionName,
      photoBase64: s.photoBase64,
    );
  }

  // Update Student details (Name, Phone, Shift, Seat, Note, Status, Due Date, etc.)
  Future<bool> updateStudent({
    required String studentId,
    required String name,
    required String phone,
    required String shift,
    int? seatNumber,
    String? note,
    int? monthlyFee,
    int? duesAmount,
    int? advanceAmount,
    String? status,
    DateTime? feeDueDate,
    String? fatherName,
    String? address,
    String? aadhaarNumber,
    String? preparationFor,
    String? gender,
    String? sectionName,
    String? photoBase64,
    DateTime? incomingUpdatedAt,
  }) async {
    ensureInitialized();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);

    if (isFirebaseConnected) {
      final studentDocRef = _tenantCol('students').doc(studentId);
      String curNote = '';
      String oldShift = '';
      int? oldSeat;
      String oldStatus = '';
      String oldPhoto = '';
      Map<String, dynamic> d = {};
      try {
        final snap = await studentDocRef.get();
        if (snap.exists) {
          d = snap.data() ?? {};
          curNote = (d['note'] as String?) ?? '';
          oldShift = (d['shift'] as String?) ?? '';
          oldSeat = (d['seat_number'] as num?)?.toInt();
          oldStatus = (d['status'] as String?) ?? '';
          oldPhoto = (d['photo_base64'] as String?) ?? '';
        }
      } catch (_) {}

      String mergedNote = curNote;
      // 1. Audit shift change if modified
      if (oldShift.isNotEmpty && oldShift.toLowerCase() != shift.toLowerCase()) {
        final curAdv = (d['advance_amount'] as num?)?.toInt() ?? 0;
        final curMonthly = (d['monthly_fee'] as num?)?.toInt() ?? 0;
        final newMonthly = monthlyFee ?? curMonthly;
        if (advanceAmount != null && advanceAmount > curAdv) {
          final advanceCredited = advanceAmount - curAdv;
          await adjustLastPaymentForShiftChange(
            studentId: studentId,
            phone: phone,
            studentName: name,
            newShift: shift,
            targetTenureCost: newMonthly,
            advanceCredited: advanceCredited,
          );
        } else if (advanceAmount != null && advanceAmount == 0 && curAdv > 0) {
          await adjustLastPaymentForShiftChange(
            studentId: studentId,
            phone: phone,
            studentName: name,
            newShift: shift,
            targetTenureCost: newMonthly,
            advanceConsumed: curAdv,
          );
        }

        final hasShiftLog = note != null && (note.toLowerCase().contains('shift upgraded') || note.toLowerCase().contains('shift downgraded') || note.toLowerCase().contains('shift changed') || note.toLowerCase().contains('shift updated'));
        if (!hasShiftLog) {
          mergedNote = appendNote(mergedNote, 'Shift changed: $oldShift → $shift on $dateStr.');
        }
      }
      // 2. Audit seat change if modified
      if (seatNumber != null && oldSeat != null && seatNumber != oldSeat) {
        final hasSeatLog = note != null && note.toLowerCase().contains('seat changed');
        if (!hasSeatLog) {
          mergedNote = appendNote(mergedNote, 'Seat changed: S-$oldSeat → S-$seatNumber ($shift) on $dateStr.');
        }
      } else if (seatNumber != null && oldSeat == null) {
        final hasSeatLog = note != null && (note.toLowerCase().contains('seat assigned') || note.toLowerCase().contains('seat changed'));
        if (!hasSeatLog) {
          mergedNote = appendNote(mergedNote, 'Seat assigned: S-$seatNumber ($shift) on $dateStr.');
        }
      }
      // 3. Audit status change if modified
      if (status != null && oldStatus.isNotEmpty && status != oldStatus) {
        if (oldStatus == 'INACTIVE' && status != 'INACTIVE') {
          mergedNote = appendNote(mergedNote, 'Member reactivated ($status) on $dateStr.');
        } else {
          mergedNote = appendNote(mergedNote, 'Status changed: $oldStatus → $status on $dateStr.');
        }
      }
      // 4. Audit photo update or removal
      if (photoBase64 != null) {
        if (photoBase64.isNotEmpty && photoBase64 != oldPhoto) {
          mergedNote = appendNote(mergedNote, 'Profile photo updated on $dateStr.');
        } else if (photoBase64.isEmpty && oldPhoto.isNotEmpty) {
          mergedNote = appendNote(mergedNote, 'Profile photo removed on $dateStr.');
        }
      }
      // 5. Merge incoming remarks if provided (never wipe existing notes)
      if (note != null && note.trim().isNotEmpty) {
        mergedNote = appendNote(mergedNote, note.trim());
      }

      final updates = <String, dynamic>{
        'name': name,
        'phone': phone,
        'shift': shift,
        'note': mergedNote,
        'updated_at': Timestamp.fromDate(now),
      };
      if (seatNumber != null) updates['seat_number'] = seatNumber;
      if (monthlyFee != null) updates['monthly_fee'] = monthlyFee;
      if (duesAmount != null) updates['dues_amount'] = duesAmount;
      if (advanceAmount != null) updates['advance_amount'] = advanceAmount;
      if (status != null) updates['status'] = status;
      if (feeDueDate != null) updates['fee_due_date'] = Timestamp.fromDate(feeDueDate);
      if (fatherName != null) updates['father_name'] = fatherName;
      if (address != null) updates['address'] = address;
      if (aadhaarNumber != null) updates['aadhaar_number'] = aadhaarNumber;
      if (preparationFor != null) updates['preparation_for'] = preparationFor;
      if (gender != null) updates['gender'] = gender;
      if (sectionName != null) updates['section_name'] = sectionName;
      if (photoBase64 != null) updates['photo_base64'] = photoBase64;
      await studentDocRef.update(updates);

      // CRITICAL: Synchronize Seats collection in Firestore so Seats Tab & Live Seat Map reflect the new shift & occupants immediately
      final targetSeat = seatNumber ?? oldSeat;
      if (targetSeat != null) {
        final seatDocRef = _tenantCol('seats').doc('seat_$targetSeat');
        if (status == 'INACTIVE') {
          final remaining = _mockStudents.where(
            (s) => s.seatNumber == targetSeat && s.id != studentId && s.status != 'INACTIVE',
          ).toList();
          if (remaining.isNotEmpty) {
            final rem = remaining.first;
            await seatDocRef.set({
              'seat_number': targetSeat,
              'is_occupied': true,
              'student_id': rem.id,
              'student_name': remaining.map((r) => r.name).join(', '),
              'shift': remaining.map((r) => r.shift).toSet().join(', '),
              'last_updated_by': 'Admin',
            }, SetOptions(merge: true));
          } else {
            await seatDocRef.set({
              'seat_number': targetSeat,
              'is_occupied': false,
              'student_id': null,
              'student_name': null,
              'shift': null,
              'last_updated_by': 'Admin',
            }, SetOptions(merge: true));
          }
        } else {
          final otherOccupants = _mockStudents.where(
            (s) => s.seatNumber == targetSeat && s.id != studentId && s.status != 'INACTIVE',
          ).toList();
          final allNames = [name, ...otherOccupants.map((o) => o.name)].join(', ');
          final allShifts = [shift, ...otherOccupants.map((o) => o.shift)].toSet().join(', ');

          await seatDocRef.set({
            'seat_number': targetSeat,
            'is_occupied': true,
            'student_id': studentId,
            'student_name': allNames,
            'shift': allShifts,
            'last_updated_by': 'Admin',
          }, SetOptions(merge: true));
        }
      }

      // If seat changed from oldSeat to targetSeat, vacate oldSeat
      if (oldSeat != null && targetSeat != null && oldSeat != targetSeat) {
        final oldSeatDocRef = _tenantCol('seats').doc('seat_$oldSeat');
        final remainingOnOld = _mockStudents.where(
          (s) => s.seatNumber == oldSeat && s.id != studentId && s.status != 'INACTIVE',
        ).toList();
        if (remainingOnOld.isNotEmpty) {
          final rem = remainingOnOld.first;
          await oldSeatDocRef.set({
            'seat_number': oldSeat,
            'is_occupied': true,
            'student_id': rem.id,
            'student_name': remainingOnOld.map((r) => r.name).join(', '),
            'shift': remainingOnOld.map((r) => r.shift).toSet().join(', '),
            'last_updated_by': 'Admin',
          }, SetOptions(merge: true));
        } else {
          await oldSeatDocRef.set({
            'seat_number': oldSeat,
            'is_occupied': false,
            'student_id': null,
            'student_name': null,
            'shift': null,
            'last_updated_by': 'Admin',
          }, SetOptions(merge: true));
        }
      }

      // Also update in-memory cache and controller so all local screens update immediately
      final mIdx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (mIdx != -1) {
        _mockStudents[mIdx] = _mockStudents[mIdx].copyWith(
          name: name,
          phone: phone,
          shift: shift,
          seatNumber: targetSeat,
          note: mergedNote,
          monthlyFee: monthlyFee ?? _mockStudents[mIdx].monthlyFee,
          duesAmount: duesAmount ?? _mockStudents[mIdx].duesAmount,
          advanceAmount: advanceAmount ?? _mockStudents[mIdx].advanceAmount,
          status: status ?? _mockStudents[mIdx].status,
          feeDueDate: feeDueDate ?? _mockStudents[mIdx].feeDueDate,
          updatedAt: now,
        );
        _syncSeatsWithStudents();
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        await _saveLocalState();
      }
      return true;
    } else {
      final idx = _mockStudents.indexWhere((s) => s.id == studentId);
      if (idx != -1) {
        final s = _mockStudents[idx];
        if (incomingUpdatedAt != null && s.updatedAt != null && incomingUpdatedAt.isBefore(s.updatedAt!)) {
          // Optimistic locking conflict detected: older version cannot overwrite newer version
          return false;
        }

        final oldSeat = s.seatNumber;
        final newSeat = seatNumber ?? oldSeat;
        final oldShift = s.shift;
        final oldStatus = s.status;

        String mergedNote = s.note;
        // 1. Audit shift change if modified
        if (oldShift.isNotEmpty && oldShift.toLowerCase() != shift.toLowerCase()) {
          final newMonthly = monthlyFee ?? s.monthlyFee;
          if (advanceAmount != null && advanceAmount > s.advanceAmount) {
            final advanceCredited = advanceAmount - s.advanceAmount;
            await adjustLastPaymentForShiftChange(
              studentId: studentId,
              phone: phone,
              studentName: name,
              newShift: shift,
              targetTenureCost: newMonthly,
              advanceCredited: advanceCredited,
            );
          } else if (advanceAmount != null && advanceAmount == 0 && s.advanceAmount > 0) {
            await adjustLastPaymentForShiftChange(
              studentId: studentId,
              phone: phone,
              studentName: name,
              newShift: shift,
              targetTenureCost: newMonthly,
              advanceConsumed: s.advanceAmount,
            );
          }

          final hasShiftLog = note != null && (note.toLowerCase().contains('shift upgraded') || note.toLowerCase().contains('shift downgraded') || note.toLowerCase().contains('shift changed') || note.toLowerCase().contains('shift updated'));
          if (!hasShiftLog) {
            mergedNote = appendNote(mergedNote, 'Shift changed: $oldShift → $shift on $dateStr.');
          }
        }
        // 2. Audit seat change if modified
        if (newSeat != null && oldSeat != null && newSeat != oldSeat) {
          final hasSeatLog = note != null && note.toLowerCase().contains('seat changed');
          if (!hasSeatLog) {
            mergedNote = appendNote(mergedNote, 'Seat changed: S-$oldSeat → S-$newSeat ($shift) on $dateStr.');
          }
        } else if (newSeat != null && oldSeat == null) {
          final hasSeatLog = note != null && (note.toLowerCase().contains('seat assigned') || note.toLowerCase().contains('seat changed'));
          if (!hasSeatLog) {
            mergedNote = appendNote(mergedNote, 'Seat assigned: S-$newSeat ($shift) on $dateStr.');
          }
        }
        // 3. Audit status change if modified
        if (status != null && oldStatus.isNotEmpty && status != oldStatus) {
          if (oldStatus == 'INACTIVE' && status != 'INACTIVE') {
            mergedNote = appendNote(mergedNote, 'Member reactivated ($status) on $dateStr.');
          } else {
            mergedNote = appendNote(mergedNote, 'Status changed: $oldStatus → $status on $dateStr.');
          }
        }
        // 4. Audit photo update or removal
        if (photoBase64 != null) {
          final oldPhoto = s.photoBase64 ?? '';
          if (photoBase64.isNotEmpty && photoBase64 != oldPhoto) {
            mergedNote = appendNote(mergedNote, 'Profile photo updated on $dateStr.');
          } else if (photoBase64.isEmpty && oldPhoto.isNotEmpty) {
            mergedNote = appendNote(mergedNote, 'Profile photo removed on $dateStr.');
          }
        }
        // 5. Merge incoming remarks if provided (never wipe existing notes)
        if (note != null && note.trim().isNotEmpty) {
          mergedNote = appendNote(mergedNote, note.trim());
        }

        // If changing to a new seat or shift, ensure it is not already occupied for that shift
        if (newSeat != null && (newSeat != oldSeat || shift != s.shift) && isSeatOccupied(newSeat, shift: shift, excludeStudentId: studentId)) {
          final occ = getStudentForSeat(newSeat, shift: shift);
          if (occ != null && occ.id != studentId) {
            throw Exception('Seat S-$newSeat is already occupied for shift "$shift" by ${occ.name}.');
          }
        }

        _mockStudents[idx] = s.copyWith(
          name: name,
          phone: phone,
          shift: shift,
          seatNumber: newSeat,
          note: mergedNote,
          monthlyFee: monthlyFee ?? s.monthlyFee,
          duesAmount: duesAmount ?? s.duesAmount,
          advanceAmount: advanceAmount ?? s.advanceAmount,
          status: status ?? s.status,
          feeDueDate: feeDueDate ?? s.feeDueDate,
          fatherName: fatherName ?? s.fatherName,
          address: address ?? s.address,
          aadhaarNumber: aadhaarNumber ?? s.aadhaarNumber,
          preparationFor: preparationFor ?? s.preparationFor,
          gender: gender ?? s.gender,
          sectionName: sectionName ?? s.sectionName,
          photoBase64: photoBase64 ?? s.photoBase64,
          updatedAt: now,
        );

        // Resync all seats to correctly reflect shift-wise occupants after student update
        _syncSeatsWithStudents();
        _mockStudentsController.add(List.unmodifiable(_mockStudents));
        await _saveLocalState();
        return true;
      }
      return false;
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
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final payLog = 'Payment of ₹$amount collected via $paymentMode on $dateStr${notes.isNotEmpty ? " • $notes" : ""}.';

    if (isFirebaseConnected) {
      final studentDocRef = _tenantCol('students').doc(studentId);
      final paymentDocRef = _tenantCol('payments').doc();
      final batch = _db.batch();

      String studentName = '';
      String studentPhone = '';
      int? seatNumber;
      String shift = 'Full Day';
      int currentDues = 0;
      String curNote = '';

      try {
        final snap = await studentDocRef.get();
        if (snap.exists) {
          final data = snap.data() ?? {};
          studentName = (data['name'] as String?) ?? '';
          studentPhone = (data['phone'] as String?) ?? '';
          seatNumber = (data['seat_number'] as num?)?.toInt();
          shift = (data['shift'] as String?) ?? 'Full Day';
          currentDues = (data['dues_amount'] as num?)?.toInt() ?? 0;
          curNote = (data['note'] as String?) ?? '';
        }
      } catch (_) {}

      final newDues = (currentDues - amount).clamp(0, 999999);
      final newStatus = newDues == 0 ? 'ACTIVE' : 'DUES';
      final updatedNote = appendNote(curNote, payLog);

      final updateData = <String, dynamic>{
        'status': newStatus,
        'dues_amount': newDues,
        'payment_mode': paymentMode,
        'note': updatedNote,
      };
      if (newDues == 0) {
        updateData['fee_due_date'] = Timestamp.fromDate(validUntil);
      }
      batch.update(studentDocRef, updateData);

      batch.set(paymentDocRef, {
        'payment_id': paymentDocRef.id,
        'student_id': studentId,
        'student_name': studentName,
        'student_phone': studentPhone,
        'seat_number': seatNumber,
        'shift': shift,
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
        final currentDues = s.effectiveDues;
        final newDues = (currentDues - amount).clamp(0, 999999);
        final newStatus = newDues == 0 ? 'ACTIVE' : 'DUES';
        final newDueDate = newDues == 0 ? validUntil : s.feeDueDate;
        final updatedNote = appendNote(s.note, payLog);

        _mockStudents[idx] = s.copyWith(
          status: newStatus,
          duesAmount: newDues,
          feeDueDate: newDueDate,
          paymentMode: paymentMode,
          note: updatedNote,
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
        await _saveLocalState();
      }
    }
  }

  // --- Tools & More Helpers ---

  List<StudentInfo> getStudentsWithDues() {
    ensureInitialized();
    return _mockStudents.where((s) =>
        s.status != 'INACTIVE' &&
        (s.hasDues || s.effectiveDues > 0 || s.duesAmount > 0 || s.status == 'DUES')
    ).toList();
  }

  void saveBranding({
    String? logoEmblem,
    String? tagline,
    String? libraryName,
    String? city,
    String? logoBase64,
    String? logoUrl,
    bool clearCustomLogo = false,
    String? accentColorHex,
    String? cardThemeStyle,
    String? noticeAnnouncement,
    String? receiptFooterNote,
    bool? showBrandingWatermark,
  }) {
    if (logoEmblem != null) profile.logoEmblem = logoEmblem;
    if (tagline != null) profile.tagline = tagline;
    if (accentColorHex != null) profile.accentColorHex = accentColorHex;
    if (cardThemeStyle != null) profile.cardThemeStyle = cardThemeStyle;
    if (noticeAnnouncement != null) profile.noticeAnnouncement = noticeAnnouncement;
    if (receiptFooterNote != null) profile.receiptFooterNote = receiptFooterNote;
    if (showBrandingWatermark != null) profile.showBrandingWatermark = showBrandingWatermark;
    if (clearCustomLogo) {
      profile.logoBase64 = null;
      profile.logoUrl = null;
    } else {
      if (logoBase64 != null) profile.logoBase64 = logoBase64;
      if (logoUrl != null) profile.logoUrl = logoUrl;
    }
    if (libraryName != null && libraryName.trim().isNotEmpty) {
      profile.libraryName = libraryName.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      profile.city = city.trim();
    }
    _saveLocalState();
    notifyStreamControllers();
    if (isFirebaseConnected) {
      _tenantCol('settings').doc('branding').set(profile.toMap(), SetOptions(merge: true)).catchError((_) {});
    }
  }

  void saveWhatsAppSettings({
    bool? notifications,
    bool? autoReminders,
    bool? autoWelcome,
    bool? autoReceipt,
    bool? remind3DaysBefore,
    bool? remindOnExpiry,
    bool? remindAfterExpiry,
    String? welcomeTpl,
    String? reminderTpl,
    String? receiptTpl,
    String? followupTpl,
    String? seatChangeTpl,
    String? shiftChangeTpl,
    String? seatAllotmentTpl,
  }) {
    if (notifications != null) profile.whatsappNotifications = notifications;
    if (autoReminders != null) profile.autoFeeReminders = autoReminders;
    if (autoWelcome != null) profile.autoWelcomeMessage = autoWelcome;
    if (autoReceipt != null) profile.autoPaymentReceipt = autoReceipt;
    if (remind3DaysBefore != null) profile.remind3DaysBefore = remind3DaysBefore;
    if (remindOnExpiry != null) profile.remindOnExpiry = remindOnExpiry;
    if (remindAfterExpiry != null) profile.remindAfterExpiry = remindAfterExpiry;
    if (welcomeTpl != null) profile.welcomeTemplate = welcomeTpl;
    if (reminderTpl != null) profile.reminderTemplate = reminderTpl;
    if (receiptTpl != null) profile.receiptTemplate = receiptTpl;
    if (followupTpl != null) profile.followupTemplate = followupTpl;
    if (seatChangeTpl != null) profile.seatChangeTemplate = seatChangeTpl;
    if (shiftChangeTpl != null) profile.shiftChangeTemplate = shiftChangeTpl;
    if (seatAllotmentTpl != null) profile.seatAllotmentTemplate = seatAllotmentTpl;
    _saveLocalState();

    if (isFirebaseConnected) {
      _tenantCol('settings').doc('whatsapp').set(profile.toMap(), SetOptions(merge: true)).catchError((_) {});
    }
  }

  void addWhatsAppCredits(int amount) {
    profile.whatsappCredits += amount;
    _saveLocalState();
    if (isFirebaseConnected) {
      _tenantCol('settings').doc('whatsapp').set({'whatsapp_credits': profile.whatsappCredits}, SetOptions(merge: true)).catchError((_) {});
    }
  }

  bool useWhatsAppCredit([int count = 1]) {
    if (profile.whatsappCredits >= count) {
      profile.whatsappCredits -= count;
      profile.messagesSentCount += count;
      _saveLocalState();
      return true;
    }
    return false;
  }

  String formatTemplate(
    String tpl, {
    required StudentInfo student,
    int? amount,
    DateTime? dueDate,
    String? customNote,
  }) {
    final dueStr = dueDate != null
        ? DateFormat('dd MMM yyyy').format(dueDate)
        : (student.feeDueDate != null ? DateFormat('dd MMM yyyy').format(student.feeDueDate!) : 'Due Soon');
    final dueAmt = amount ?? (student.effectiveDues > 0 ? student.effectiveDues : student.monthlyFee);

    var result = tpl
        .replaceAll('{student_name}', student.name)
        .replaceAll('{seat_number}', student.seatNumber != null ? '${student.seatNumber}' : 'Unallocated')
        .replaceAll('{shift}', student.shift)
        .replaceAll('{due_amount}', '$dueAmt')
        .replaceAll('{due_date}', dueStr)
        .replaceAll('{amount}', '$dueAmt')
        .replaceAll('{mode}', student.paymentMode)
        .replaceAll('{valid_until}', dueStr)
        .replaceAll('{library_name}', profile.libraryName)
        .replaceAll('{phone}', student.phone)
        .replaceAll('{status}', student.status);

    if (customNote != null && customNote.trim().isNotEmpty) {
      result = result.replaceAll('{note}', customNote.trim());
    } else {
      // Do not include or dump historical notes. Cleanly strip any {note} tag
      result = result.replaceAll(RegExp(r'\n*📌\s*Note:\s*\{note\}'), '').replaceAll('{note}', '').trim();
    }
    return result;
  }

  String formatActionDraft({
    required String actionType, // 'seat_change', 'shift_change', 'seat_allotment', 'fee_due', 'followup', 'welcome', 'receipt'
    required StudentInfo student,
    String? customNote,
    int? amount,
    DateTime? dueDate,
  }) {
    String tpl;
    switch (actionType) {
      case 'seat_change':
        tpl = profile.seatChangeTemplate;
        break;
      case 'shift_change':
        tpl = profile.shiftChangeTemplate;
        break;
      case 'seat_allotment':
        tpl = profile.seatAllotmentTemplate;
        break;
      case 'fee_due':
        tpl = profile.reminderTemplate;
        break;
      case 'welcome':
        tpl = profile.welcomeTemplate;
        break;
      case 'receipt':
        tpl = profile.receiptTemplate;
        break;
      case 'followup':
      default:
        tpl = profile.followupTemplate;
        break;
    }

    String formatted = formatTemplate(
      tpl,
      student: student,
      amount: amount,
      dueDate: dueDate,
      customNote: customNote,
    );

    // If an optional custom note was provided and template didn't contain {note}, cleanly append note line
    if (customNote != null && customNote.trim().isNotEmpty && !tpl.contains('{note}')) {
      formatted += '\n\n📌 Note: ${customNote.trim()}';
    }

    return formatted;
  }

  static Future<bool> sendWhatsAppDirect({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = normalizePhone(phone);
    final phoneClean = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final encoded = Uri.encodeComponent(message);

    // 1. WhatsApp Universal URL
    final waUri = Uri.parse('https://wa.me/$phoneClean?text=$encoded');
    try {
      if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    // 2. WhatsApp native scheme fallback
    final nativeUri = Uri.parse('whatsapp://send?phone=$phoneClean&text=$encoded');
    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    try {
      if (await launchUrl(waUri)) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  static Future<bool> sendSmsDirect({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = normalizePhone(phone);
    final encoded = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$cleanPhone?body=$encoded');
    try {
      if (await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    try {
      if (await launchUrl(smsUri)) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}