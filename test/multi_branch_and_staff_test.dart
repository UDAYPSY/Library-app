import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';
import 'package:library_manager/services/disaster_recovery_service.dart';

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
          'canViewRevenue': true,
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
      );
      service.addStaffMember(rogueStaff);
      expect(service.staffList.any((s) => s.id == 'staff_rogue'), isFalse); // Blocked!
    });
  });
}
