import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';
import 'package:library_manager/services/disaster_recovery_service.dart';
import 'package:library_manager/services/biometric_auth_service.dart';
import 'package:library_manager/services/excel_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryService service;

  setUp(() async {
    service = LibraryService();
    service.ensureInitialized();
    await service.clearAllData();
  });

  group('Multi-Branch & Staff Role Boundaries Tests', () {
    test('Adding and switching active library branch updates profile', () {
      final initialCount = service.branches.length;
      final newBranch = const LibraryBranch(
        id: 'branch_ac_hall_2',
        name: 'Floor 2 AC Hall',
        address: 'Boring Road Patna',
        totalSeats: 45,
      );

      service.addBranch(newBranch);
      expect(service.branches.length, equals(initialCount + 1));

      // Switch branch
      service.switchBranch('branch_ac_hall_2');
      expect(service.activeBranchId, equals('branch_ac_hall_2'));
      expect(service.currentBranch.name, equals('Floor 2 AC Hall'));
      expect(service.profile.libraryName, equals('Floor 2 AC Hall'));
      expect(service.profile.city, equals('Boring Road Patna'));
    });

    test('Staff member management: Add, toggle active, and remove', () {
      final initialStaff = service.staffList.length;
      final staff = StaffMember(
        id: 'staff_test_99',
        name: 'Karan Manager',
        phone: '9870099887',
        role: 'Shift Manager',
        addedAt: DateTime.now(),
        isActive: true,
      );

      service.addStaffMember(staff);
      expect(service.staffList.length, equals(initialStaff + 1));
      expect(service.staffList.any((s) => s.id == 'staff_test_99'), isTrue);

      // Toggle active status
      service.toggleStaffActive('staff_test_99');
      final toggled = service.staffList.firstWhere((s) => s.id == 'staff_test_99');
      expect(toggled.isActive, isFalse);

      // Toggle back to active
      service.toggleStaffActive('staff_test_99');
      final reToggled = service.staffList.firstWhere((s) => s.id == 'staff_test_99');
      expect(reToggled.isActive, isTrue);

      // Remove staff member
      service.removeStaffMember('staff_test_99');
      expect(service.staffList.any((s) => s.id == 'staff_test_99'), isFalse);
    });

    test('Owner adds student, creates Branch Assistant, staff logs in and sees student in directory and stream', () async {
      // 1. Owner signs in as admin
      final adminRes = await service.login(identifier: 'admin', password: 'password123');
      expect(adminRes.success, isTrue);
      expect(service.isAdmin, isTrue);

      // 2. Owner adds a student
      await service.assignSeatAndRegisterStudent(
        seatNumber: 12,
        studentName: 'Priya Sharma',
        phone: '9876543210',
        shift: 'Morning Shift',
        feeAmount: 600,
        monthlyFee: 600,
        branchId: 'branch_1',
      );

      expect(service.allStudents.length, equals(1));
      expect(service.allStudents.first.name, equals('Priya Sharma'));

      // 3. Owner creates a staff member with role 'Branch Assistant'
      final staff = StaffMember(
        id: 'staff_ba_01',
        name: 'Rahul Assistant',
        phone: '9112233445',
        role: 'Branch Assistant',
        email: 'rahul@library.com',
        pinHash: LibraryService.hashPin('12345678'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      // 4. Owner signs out
      await service.signOut();
      expect(service.isAuthenticated, isFalse);

      // 5. Staff member logs in using phone & password/PIN
      final staffRes = await service.login(identifier: '9112233445', password: '12345678');
      expect(staffRes.success, isTrue);
      expect(service.currentUserRole, equals('Branch Assistant'));
      expect(service.isAdmin, isFalse);
      expect(service.isStaff, isTrue);
      expect(service.isBranchAssistant, isTrue);
      expect(service.canViewStudents, isTrue);
      expect(service.canManageSeats, isTrue);

      // 6. Branch Assistant MUST be able to see the student in allStudents, activeBranchStudents, and streamStudents
      expect(service.allStudents.length, equals(1));
      expect(service.allStudents.first.name, equals('Priya Sharma'));
      expect(service.activeBranchStudents.length, equals(1));
      expect(service.activeBranchStudents.first.name, equals('Priya Sharma'));

      final streamStudents = await service.streamStudents().first;
      expect(streamStudents.length, equals(1));
      expect(streamStudents.first.name, equals('Priya Sharma'));
      expect(streamStudents.first.seatNumber, equals(12));

      // 7. Verify seat occupancy is visible to Branch Assistant
      expect(service.isSeatOccupied(12), isTrue);
      final occupant = service.getStudentForSeat(12);
      expect(occupant, isNotNull);
      expect(occupant!.name, equals('Priya Sharma'));
    });

    test('Staff member can log in using email address and password', () async {
      final staff = StaffMember(
        id: 'staff_email_02',
        name: 'Sunita Desk',
        phone: '9988771122',
        role: 'Receptionist & Desk',
        email: 'sunita@apexlibrary.in',
        pinHash: LibraryService.hashPin('deskPass88'),
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      final loginRes = await service.login(
        identifier: 'sunita@apexlibrary.in',
        password: 'deskPass88',
      );
      expect(loginRes.success, isTrue);
      expect(service.currentUserRole, equals('Receptionist'));
      expect(service.currentUserName, equals('Sunita Desk'));
      expect(service.isReceptionist, isTrue);
      expect(service.canViewStudents, isTrue);
      expect(service.canManageSeats, isTrue);
    });

    test('Comprehensive role boundaries matrix audit across all 6 roles', () async {
      // Setup student
      await service.assignSeatAndRegisterStudent(
        seatNumber: 3,
        studentName: 'Vikram Joshi',
        phone: '9123400001',
        shift: 'Full Day',
        feeAmount: 1000,
        branchId: 'branch_1',
      );

      final rolesToTest = [
        {
          'role': 'Receptionist & Desk',
          'expectedRole': 'Receptionist',
          'canViewRevenue': false,
          'canManageSeats': true,
          'canManageStaff': false,
          'canSwitchBranch': false,
        },
        {
          'role': 'Branch Assistant',
          'expectedRole': 'Branch Assistant',
          'canViewRevenue': false,
          'canManageSeats': true,
          'canManageStaff': false,
          'canSwitchBranch': false,
        },
        {
          'role': 'Shift Manager',
          'expectedRole': 'Shift Manager',
          'canViewRevenue': false,
          'canManageSeats': true,
          'canManageStaff': false,
          'canSwitchBranch': false,
        },
        {
          'role': 'Night Supervisor',
          'expectedRole': 'Night Supervisor',
          'canViewRevenue': false,
          'canManageSeats': true,
          'canManageStaff': false,
          'canSwitchBranch': false,
        },
        {
          'role': 'Accountant & Fees',
          'expectedRole': 'Accountant & Fees',
          'canViewRevenue': false,
          'canManageSeats': false,
          'canManageStaff': false,
          'canSwitchBranch': false,
        },
      ];

      for (int i = 0; i < rolesToTest.length; i++) {
        final r = rolesToTest[i];
        final phone = '900000000$i';
        final staff = StaffMember(
          id: 'staff_role_$i',
          name: 'Staff Test $i',
          phone: phone,
          role: r['role'] as String,
          pinHash: LibraryService.hashPin('pin12345'),
          isActive: true,
          addedAt: DateTime.now(),
        );
        service.currentUserRole = 'Admin';
        service.addStaffMember(staff);

        await service.signOut();
        final res = await service.login(identifier: phone, password: 'pin12345');
        expect(res.success, isTrue);
        expect(service.currentUserRole, equals(r['expectedRole']));
        expect(service.isAdmin, isFalse);
        expect(service.isStaff, isTrue);

        // All roles MUST be able to view students
        expect(service.canViewStudents, isTrue);
        final students = await service.streamStudents().first;
        expect(students.any((s) => s.name == 'Vikram Joshi'), isTrue);

        // Check specific permissions
        expect(service.canViewRevenue, equals(r['canViewRevenue']));
        expect(service.canManageSeats, equals(r['canManageSeats']));
        expect(service.canManageStaff, equals(r['canManageStaff']));
        expect(service.canSwitchBranch, equals(r['canSwitchBranch']));
      }
    });

    test('Staff login never changes Google Drive backup email and staff cannot alter backup settings', () async {
      final recovery = DisasterRecoveryService(service: service);

      // 1. Owner sets up library with owner email and Google Drive backup email
      service.profile = LibraryProfile(
        libraryId: 'lib_test_01',
        libraryName: 'Apex Central',
        adminName: 'Owner Sir',
        adminEmail: 'owner@apexlibrary.in',
        adminPhone: '9888888888',
        city: 'Patna',
      );
      await recovery.setBackupEmail('owner.backup@gmail.com');
      expect(await recovery.getBackupEmail(), equals('owner.backup@gmail.com'));

      // 2. Owner adds Branch Assistant with staff email
      final staff = StaffMember(
        id: 'staff_ba_safe_01',
        name: 'Suresh Assistant',
        phone: '9555544444',
        email: 'suresh.staff@gmail.com',
        role: 'Branch Assistant',
        pinHash: LibraryService.hashPin('pass8899'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      // 3. Staff logs in
      await service.signOut();
      final loginRes = await service.login(identifier: '9555544444', password: 'pass8899');
      expect(loginRes.success, isTrue);
      expect(service.isStaff, isTrue);
      expect(service.isAdmin, isFalse);

      // 4. VERIFY: Google Drive backup email MUST still be the Owner's email, NOT the staff's email!
      final currentBackupEmail = await recovery.getBackupEmail();
      expect(currentBackupEmail, equals('owner.backup@gmail.com'));
      expect(currentBackupEmail, isNot(equals('suresh.staff@gmail.com')));

      // 5. Staff attempts to change backup email -> MUST be rejected by ownership guard
      await recovery.setBackupEmail('hacked_drive@gmail.com');
      expect(await recovery.getBackupEmail(), equals('owner.backup@gmail.com'));

      // 6. Staff attempts to disable auto-backup -> MUST be rejected by ownership guard
      final beforeEnabled = await recovery.isAutoBackupEnabled();
      await recovery.setAutoBackupEnabled(!beforeEnabled);
      expect(await recovery.isAutoBackupEnabled(), equals(beforeEnabled));
    });

    test('Staff member cannot switch branch, add branch, or add staff', () async {
      // 1. Setup multi-branch as Admin
      final newBranch = const LibraryBranch(
        id: 'branch_floor_2',
        name: 'Floor 2 AC Hall',
        address: 'Boring Road',
        totalSeats: 40,
      );
      service.addBranch(newBranch);
      expect(service.branches.any((b) => b.id == 'branch_floor_2'), isTrue);

      // 2. Add Branch Assistant pinned to branch_1
      final staff = StaffMember(
        id: 'staff_ba_branch_lock',
        name: 'Rohan Assistant',
        phone: '9444433333',
        role: 'Branch Assistant',
        pinHash: LibraryService.hashPin('pass1234'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      // 3. Staff logs in
      await service.signOut();
      final loginRes = await service.login(identifier: '9444433333', password: 'pass1234');
      expect(loginRes.success, isTrue);
      expect(service.activeBranchId, equals('branch_1'));
      expect(service.canSwitchBranch, isFalse);

      // 4. Staff attempts to switch to branch_floor_2 -> MUST be blocked
      service.switchBranch('branch_floor_2');
      expect(service.activeBranchId, equals('branch_1')); // Blocked!

      // 5. Staff attempts to switch to 'all' -> MUST be blocked
      service.switchBranch('all');
      expect(service.activeBranchId, equals('branch_1')); // Blocked!

      // 6. Staff attempts to add another branch -> MUST be blocked
      final unauthorizedBranch = const LibraryBranch(
        id: 'branch_unauth',
        name: 'Rogue Branch',
        address: 'Nowhere',
      );
      service.addBranch(unauthorizedBranch);
      expect(service.branches.any((b) => b.id == 'branch_unauth'), isFalse); // Blocked!

      // 7. Staff attempts to add another staff member -> MUST be blocked
      final rogueStaff = StaffMember(
        id: 'staff_rogue',
        name: 'Rogue Member',
        phone: '9111111111',
        role: 'Administrator',
        addedAt: DateTime.now(),
      );
      service.addStaffMember(rogueStaff);
      expect(service.staffList.any((s) => s.id == 'staff_rogue'), isFalse); // Blocked!
    });

    test('Staff operational workflow: Staff adds student, collects fee, tags collector info, and handles advance renewal', () async {
      // 1. Setup library and add Receptionist staff
      service.profile = service.profile.copyWith(libraryId: 'lib_owner_100');
      final receptionist = StaffMember(
        id: 'staff_rec_01',
        name: 'Aarti Desk',
        phone: '9888877777',
        role: 'Receptionist & Desk',
        pinHash: LibraryService.hashPin('desk1234'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.currentUserRole = 'Admin';
      service.addStaffMember(receptionist);

      // 2. Staff logs in
      await service.signOut();
      final loginRes = await service.login(identifier: '9888877777', password: 'desk1234');
      expect(loginRes.success, isTrue);
      expect(service.currentUserRole, equals('Receptionist'));
      expect(service.currentUserName, equals('Aarti Desk'));
      expect(service.canCollectFees, isTrue);
      expect(service.canManageSeats, isTrue);

      // 3. Staff adds a student with initial 1 month fee
      final now = DateTime.now();
      final expiry1 = DateTime(now.year, now.month + 1, now.day);
      await service.assignSeatAndRegisterStudent(
        seatNumber: 15,
        studentName: 'Amit Kumar',
        phone: '9777766666',
        shift: 'Morning Shift',
        feeAmount: 600,
        monthlyFee: 600,
        branchId: 'branch_1',
        joiningDate: now,
        validUntil: expiry1,
      );

      expect(service.allStudents.length, equals(1));
      final student = service.allStudents.first;
      expect(student.name, equals('Amit Kumar'));
      expect(student.duesAmount, equals(0));
      expect(student.status, equals('ACTIVE'));
      expect(service.isSeatOccupied(15), isTrue);

      // Verify payment was recorded and tagged with Aarti Desk (Receptionist)
      expect(service.currentPayments.length, equals(1));
      final firstPayment = service.currentPayments.first;
      expect(firstPayment.amount, equals(600));
      expect(firstPayment.collectedBy, equals('Aarti Desk'));
      expect(firstPayment.staffRole, equals('Receptionist'));

      // 4. DUPLICATE TENURE CHECK: Staff attempts to record a second payment for the SAME tenure
      // Since Amit Kumar is active with 0 dues and paid until expiry1, a payment for the same tenure MUST be rejected!
      expect(
        () async => await service.recordPayment(
          studentId: student.id,
          studentName: student.name,
          phone: student.phone,
          amount: 600,
          validFrom: now,
          validUntil: expiry1, // Same tenure, already paid!
          paymentMode: 'Cash',
        ),
        throwsA(isA<Exception>()),
      );

      // 5. ADVANCE RENEWAL: Staff collects an advance renewal extending beyond expiry1
      final expiry2 = DateTime(expiry1.year, expiry1.month + 1, expiry1.day);
      await service.recordPayment(
        studentId: student.id,
        studentName: student.name,
        phone: student.phone,
        amount: 600,
        validFrom: expiry1,
        validUntil: expiry2, // Advance renewal!
        paymentMode: 'UPI',
        notes: '1 Month Advance Renewal Fee',
      );

      // Verify advance renewal succeeded
      expect(service.currentPayments.length, equals(2));
      final updatedStudent = service.findStudentByPhone('9777766666');
      expect(updatedStudent, isNotNull);
      expect(updatedStudent!.feeDueDate, equals(expiry2));
      expect(updatedStudent.duesAmount, equals(0));
    });

    test('Staff session restore preserves owner libraryId and does not overwrite with anonymous UID', () async {
      service.profile = service.profile.copyWith(libraryId: 'owner_firebase_uid_99');
      final staff = StaffMember(
        id: 'staff_sm_01',
        name: 'Sunil Shift Manager',
        phone: '9333322222',
        role: 'Shift Manager',
        pinHash: LibraryService.hashPin('shiftPass'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.currentUserRole = 'Admin';
      service.addStaffMember(staff);

      await service.signOut();
      await service.login(identifier: '9333322222', password: 'shiftPass');
      expect(service.currentUserRole, equals('Shift Manager'));
      expect(service.profile.libraryId, equals('owner_firebase_uid_99'));

      // Simulate session restore
      await service.restoreSession();
      expect(service.currentUserRole, equals('Shift Manager'));
      expect(service.profile.libraryId, equals('owner_firebase_uid_99'));
    });

    test('Biometric identity binding tags 1 ID at a time and preserves exact staff role without Admin elevation', () async {
      // 1. Owner registers / logs in
      service.profile.adminEmail = 'owner@library.com';
      service.profile.adminName = 'Library Owner';
      service.profile.libraryId = 'lib_owner_100';
      await service.login(identifier: 'admin', password: 'password123');
      expect(service.isAdmin, isTrue);

      // Verify biometric binding tags owner as Admin
      var binding = await service.getBiometricBinding();
      expect(binding, isNotNull);
      expect(binding!['user_role'], equals('Admin'));
      expect(binding['is_owner'], isTrue);
      expect(binding['user_email'], equals('owner@library.com'));

      // 2. Staff member logs in
      final staff = StaffMember(
        id: 'staff_bio_01',
        name: 'Vikas Assistant',
        phone: '9888877777',
        role: 'Branch Assistant',
        pinHash: LibraryService.hashPin('staffPass'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      await service.signOut();
      expect(service.currentUserRole, equals('Guest'));

      await service.login(identifier: '9888877777', password: 'staffPass');
      expect(service.currentUserRole, equals('Branch Assistant'));
      expect(service.isAdmin, isFalse);

      // Verify biometric binding has now re-tagged to Vikas (Branch Assistant)
      binding = await service.getBiometricBinding();
      expect(binding, isNotNull);
      expect(binding!['user_id'], equals('staff_bio_01'));
      expect(binding['user_name'], equals('Vikas Assistant'));
      expect(binding['user_role'], equals('Branch Assistant'));
      expect(binding['is_owner'], isFalse);

      // Verify owner's email was NEVER replaced by staff phone!
      expect(service.profile.adminEmail, equals('owner@library.com'));
    });

    test('Strict staff RBAC enforcement blocks unauthorized deletions and settings edits', () async {
      final staff = StaffMember(
        id: 'staff_rbac_01',
        name: 'Rohan Desk',
        phone: '9555544444',
        role: 'Receptionist',
        pinHash: LibraryService.hashPin('deskPass'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      // Login as staff
      await service.login(identifier: '9555544444', password: 'deskPass');
      expect(service.currentUserRole, equals('Receptionist'));
      expect(service.canDeleteRecords, isFalse);
      expect(service.canEditSettings, isFalse);

      // Attempt permanentlyDeleteStudent -> must throw UnsupportedError
      expect(
        () async => await service.permanentlyDeleteStudent('student_123', 5),
        throwsA(isA<UnsupportedError>()),
      );

      // Attempt deleteExpense -> must throw UnsupportedError
      expect(
        () async => await service.deleteExpense('exp_123'),
        throwsA(isA<UnsupportedError>()),
      );

      // Attempt saveBranding -> must throw UnsupportedError
      expect(
        () => service.saveBranding(tagline: 'Unauthorized Branding Edit'),
        throwsA(isA<UnsupportedError>()),
      );

      // Attempt saveWhatsAppSettings -> must throw UnsupportedError
      expect(
        () => service.saveWhatsAppSettings(autoReminders: false),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('Permanent account deletion clears biometric binding and resets role to Guest', () async {
      await service.login(identifier: 'admin', password: 'password123');
      expect(await service.getBiometricBinding(), isNotNull);

      await service.deleteAccountPermanently();

      expect(service.isAuthenticated, isFalse);
      expect(service.currentUserRole, equals('Guest'));
      expect(await service.getBiometricBinding(), isNull);
    });

    test('Owner-configured seat capacity synchronizes to branches and totalSeatsCount', () async {
      service.updateSectionsAndRebuildSeats([
        SectionConfig(id: 'sec_1', name: 'Main Hall', startSeat: 1, endSeat: 10),
      ]);

      expect(service.totalSeatsCount, equals(10));
      expect(service.currentBranch.totalSeats, equals(10));
      expect(service.effectiveBranches.first.totalSeats, equals(10));
      expect(service.allSeats.length, equals(10));
    });

    test('Biometric login checks intended role and rejects cross-role access (Owner vs Staff)', () async {
      BiometricAuthService.testMode = true;
      BiometricAuthService.testAuthResult = true;
      await service.login(identifier: 'admin', password: 'password123');
      expect(await service.getBiometricBinding(), isNotNull);
      await service.signOut();

      // Attempt biometric login on Staff tab when device is bound to Owner
      final staffTabRes = await service.loginWithBiometrics(intendedRole: 'Staff');
      expect(staffTabRes.success, isFalse);
      expect(staffTabRes.message, contains('registered to Library Owner'));
      expect(staffTabRes.message, contains('Staff tab'));

      // Attempt biometric login with mismatched identifier
      final mismatchRes = await service.loginWithBiometrics(
        intendedRole: 'Admin',
        enteredIdentifier: '9999988888',
      );
      expect(mismatchRes.success, isFalse);
      expect(mismatchRes.message, contains('does not match the entered identifier'));

      // Valid Owner login on Admin tab
      final adminTabRes = await service.loginWithBiometrics(intendedRole: 'Admin');
      expect(adminTabRes.success, isTrue);
      expect(service.isAdmin, isTrue);
    });

    test('Least-privilege RBAC strictly blocks staff from viewing revenue, editing admin profile, and exporting data', () async {
      final staff = StaffMember(
        id: 'staff_strict_01',
        name: 'Kavita Desk',
        phone: '9888877777',
        role: 'Receptionist',
        pinHash: LibraryService.hashPin('1234'),
        branchId: 'branch_1',
        isActive: true,
        addedAt: DateTime.now(),
      );
      service.addStaffMember(staff);

      await service.login(identifier: '9888877777', password: '1234');
      expect(service.isStaff, isTrue);
      expect(service.isAdmin, isFalse);
      expect(service.canViewRevenue, isFalse);
      expect(service.canExportReports, isFalse);
      expect(service.canEditAdminProfile, isFalse);

      expect(
        () async => await service.saveProfile(service.profile.copyWith(adminName: 'Hacked Name')),
        throwsA(isA<UnsupportedError>()),
      );

      expect(
        () => service.exportFullBackupJson(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('Strict 10-digit mobile number and RFC email validation utilities', () {
      // 1. Phone validation: exactly 10 digits
      expect(LibraryService.isValid10DigitPhone('9876543210'), isTrue);
      expect(LibraryService.isValid10DigitPhone('+91 98765 43210'), isTrue);
      expect(LibraryService.isValid10DigitPhone('987654321012345678'), isFalse); // 18 digits blocked!
      expect(LibraryService.isValid10DigitPhone('98765'), isFalse); // < 10 digits blocked
      expect(LibraryService.isValid10DigitPhone(''), isFalse);
      expect(LibraryService.isValid10DigitPhone('abcdefghij'), isFalse);

      // 2. Email validation: standard RFC format
      expect(LibraryService.isValidEmail('owner@library.com'), isTrue);
      expect(LibraryService.isValidEmail('admin.desk@branch.co.in'), isTrue);
      expect(LibraryService.isValidEmail('invalid'), isFalse);
      expect(LibraryService.isValidEmail('user@'), isFalse);
      expect(LibraryService.isValidEmail('user@domain'), isFalse);
      expect(LibraryService.isValidEmail('user@.com'), isFalse);
      expect(LibraryService.isValidEmail(''), isFalse);
    });

    test('Library setup and registration strictly rejects 18-digit phone numbers and invalid emails', () async {
      // 1. Reject invalid email
      final invalidEmailRes = await service.registerAdminAccount(
        email: 'not-an-email',
        password: 'password123',
        adminName: 'Owner',
        libraryName: 'Test Lib',
        phone: '9876543210',
      );
      expect(invalidEmailRes.success, isFalse);
      expect(invalidEmailRes.message, contains('valid email'));

      // 2. Reject 18-digit phone number
      final invalidPhoneRes = await service.registerAdminAccount(
        email: 'owner@library.com',
        password: 'password123',
        adminName: 'Owner',
        libraryName: 'Test Lib',
        phone: '987654321012345678', // 18 digits
      );
      expect(invalidPhoneRes.success, isFalse);
      expect(invalidPhoneRes.message, contains('10-digit mobile'));

      // 3. Valid setup succeeds
      final validRes = await service.registerAdminAccount(
        email: 'owner@library.com',
        password: 'password123',
        adminName: 'Owner',
        libraryName: 'Test Lib',
        phone: '9876543210',
      );
      expect(validRes.success, isTrue);
      expect(service.profile.adminPhone, equals('9876543210'));
      expect(service.profile.adminEmail, equals('owner@library.com'));
    });

    test('saveProfile strictly blocks invalid phone and email formats', () async {
      await service.login(identifier: 'admin', password: 'password123');
      expect(service.isAdmin, isTrue);

      // 18-digit phone in profile update throws ArgumentError
      expect(
        () async => await service.saveProfile(service.profile.copyWith(adminPhone: '123456789012345678')),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid email in profile update throws ArgumentError
      expect(
        () async => await service.saveProfile(service.profile.copyWith(adminEmail: 'bad-email')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Disaster Recovery service enforces setup Google Drive binding and static lock', () async {
      await service.login(identifier: 'admin', password: 'password123');
      service.profile.adminEmail = 'owner_setup@library.com';
      service.profile.upiId = 'owner_settlement@upi';

      final drService = DisasterRecoveryService(service: service);

      // Default backup email binds strictly to setup owner email
      final initialEmail = await drService.getBackupEmail();
      expect(initialEmail, equals('owner_setup@library.com'));

      // Setting invalid email throws ArgumentError
      expect(
        () async => await drService.setBackupEmail('not-an-email'),
        throwsA(isA<ArgumentError>()),
      );

      // Valid email updates successfully
      await drService.setBackupEmail('backup_drive@gmail.com');
      expect(await drService.getBackupEmail(), equals('backup_drive@gmail.com'));

      // Generated Excel contains locked Google Drive destination and STATIC_SETUP_LOCKED status
      final xml = drService.generateMasterExcelWorkbookXml(targetDriveEmail: 'backup_drive@gmail.com');
      expect(xml, contains('Designated Google Drive Destination'));
      expect(xml, contains('backup_drive@gmail.com'));
      expect(xml, contains('STATIC_SETUP_LOCKED'));
      expect(xml, contains('Payment UPI VPA'));
      expect(xml, contains('owner_settlement@upi'));
    });

    test('backupToGoogleDriveNow strictly binds to onboarding email and executes Google Drive sync', () async {
      final service = LibraryService();
      service.ensureInitialized();
      await service.login(identifier: 'admin', password: 'password123');
      service.profile.adminEmail = 'onboarding_owner@library.com';

      final drService = DisasterRecoveryService(service: service);
      await drService.setBackupEmail('onboarding_owner@library.com');
      expect(await drService.getBackupEmail(), equals('onboarding_owner@library.com'));

      final ok = await drService.backupToGoogleDriveNow();
      expect(ok, isTrue);
      expect(await drService.getLastBackupStatus(), equals('Success (Google Drive Sync)'));
      expect(await drService.getLastBackupTime(), isNotNull);
    });
  });

  group('Ongoing Library Paper Register Onboarding & Non-Breaking Compatibility Tests', () {
    test('ExcelImportService backward compatibility: legacy 7-column CSV imports cleanly', () {
      const legacyCsv = '''Full Name,Phone Number,Shift,Seat Number,Monthly Fee,Father Name,Address
Aarav Sharma,9876543210,Full Day,1,800,Ramesh Sharma,Patna Bihar
Priya Singh,9812345678,Morning,2,500,Vijay Singh,Boring Road Patna''';

      final result = ExcelImportService.parseAndImport(legacyCsv, service);
      expect(result.successfullyImported, equals(2));
      expect(result.errorMessages, isEmpty);

      final aarav = service.findStudentByPhone('9876543210');
      expect(aarav, isNotNull);
      expect(aarav!.name, equals('Aarav Sharma'));
      expect(aarav.status, equals('Active'));
      expect(aarav.duesAmount, equals(0));

      final priya = service.findStudentByPhone('9812345678');
      expect(priya, isNotNull);
      expect(priya!.name, equals('Priya Singh'));
      expect(priya.status, equals('Active'));
    });

    test('ExcelImportService 10-column CSV imports historical join date, custom next due date and past dues', () {
      const registerCsv = '''Full Name,Phone Number,Shift,Seat Number,Monthly Fee,Father Name,Address,Joining Date,Next Fee Due Date,Past Dues
Amit Kumar,9876543211,Full Day,5,800,Rajesh Kumar,Patna,15-08-2026,18-11-2026,0
Suman Roy,9812345679,Morning,6,600,B Roy,Boring Road,01-09-2026,10-11-2026,300''';

      final result = ExcelImportService.parseAndImport(registerCsv, service);
      expect(result.successfullyImported, equals(2));
      expect(result.errorMessages, isEmpty);

      // Amit Kumar: fee paid up to 18-Nov-2026, no past dues -> Active
      final amit = service.findStudentByPhone('9876543211');
      expect(amit, isNotNull);
      expect(amit!.name, equals('Amit Kumar'));
      expect(amit.joinedAt?.year, equals(2026));
      expect(amit.joinedAt?.month, equals(8));
      expect(amit.joinedAt?.day, equals(15));
      expect(amit.feeDueDate?.year, equals(2026));
      expect(amit.feeDueDate?.month, equals(11));
      expect(amit.feeDueDate?.day, equals(18));
      expect(amit.duesAmount, equals(0));
      expect(amit.status, equals('Active'));

      // Suman Roy: has 300 past register dues -> DUES
      final suman = service.findStudentByPhone('9812345679');
      expect(suman, isNotNull);
      expect(suman!.name, equals('Suman Roy'));
      expect(suman.duesAmount, equals(300));
      expect(suman.status, equals('DUES'));
      expect(suman.note, contains('Past Dues: ₹300'));
    });

    test('assignSeatAndRegisterStudent with feeAmount: 0 onboard register student without skewing today cash ledger', () async {
      final initialPaymentCount = service.currentPayments.length;

      final historicalJoiningDate = DateTime(2026, 7, 10);
      final nextDueDate = DateTime(2026, 11, 25);

      // Onboard student from physical register who already paid fee in register
      await service.assignSeatAndRegisterStudent(
        seatNumber: 15,
        studentName: 'Register Student Rahul',
        phone: '9876543299',
        shift: 'Full Day',
        feeAmount: 0,
        monthlyFee: 800,
        duesAmount: 0,
        durationMonths: 1,
        paymentMode: 'Cash',
        status: 'ACTIVE',
        joiningDate: historicalJoiningDate,
        validUntil: nextDueDate,
        paymentDate: DateTime.now(),
        note: 'Migrated from paper register.',
      );

      // Verify student is active and seat is occupied
      final student = service.findStudentByPhone('9876543299');
      expect(student, isNotNull);
      expect(student!.status, equals('ACTIVE'));
      expect(student.seatNumber, equals(15));
      expect(student.joinedAt, equals(historicalJoiningDate));
      expect(student.feeDueDate, equals(nextDueDate));
      expect(student.duesAmount, equals(0));

      // Verify ZERO new payment transactions were recorded in today's cash book
      expect(service.currentPayments.length, equals(initialPaymentCount));
    });

    test('Regular walk-in admission records payment in ledger normally without disruption', () async {
      final initialPaymentCount = service.currentPayments.length;

      await service.assignSeatAndRegisterStudent(
        seatNumber: 16,
        studentName: 'Walk-In Student Sneha',
        phone: '9876543288',
        shift: 'Morning',
        feeAmount: 600,
        monthlyFee: 600,
        duesAmount: 0,
        durationMonths: 1,
        paymentMode: 'Cash',
        status: 'ACTIVE',
        joiningDate: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
        paymentDate: DateTime.now(),
      );

      // Verify student is active and seat is assigned
      final student = service.findStudentByPhone('9876543288');
      expect(student, isNotNull);
      expect(student!.status, equals('ACTIVE'));
      expect(student.seatNumber, equals(16));

      // Verify normal payment transaction was created
      expect(service.currentPayments.length, equals(initialPaymentCount + 1));
      final payment = service.currentPayments.first;
      expect(payment.studentName, equals('Walk-In Student Sneha'));
      expect(payment.amount, equals(600));
    });
  });
}


