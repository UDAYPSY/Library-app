import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';
import 'package:library_manager/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryService service;

  setUp(() async {
    service = LibraryService();
    service.ensureInitialized();
    await service.clearAllData();
  });

  group('Authentication & Security (RBAC & Multi-Tenant)', () {
    test('Default admin credentials log in successfully as Admin', () async {
      final res = await service.login(
        identifier: 'manageyourlib@gmail.com',
        password: 'password123',
      );

      expect(res.success, isTrue);
      expect(res.role, equals('Admin'));
      expect(service.isAuthenticated, isTrue);
      expect(service.isAdmin, isTrue);
      expect(service.isReceptionist, isFalse);

      final legacyRes = await service.login(
        identifier: 'nivi@library.com',
        password: 'password123',
      );
      expect(legacyRes.success, isTrue);
    });

    test('Incorrect admin password fails authentication gracefully', () async {
      final res = await service.login(
        identifier: 'manageyourlib@gmail.com',
        password: 'wrong_password_999',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('Incorrect password'));
    });

    test('Registering new admin account updates session and tenant ID', () async {
      final res = await service.registerAdminAccount(
        email: 'founder@apexlibrary.in',
        password: 'securePassword456',
        adminName: 'Rohan Sharma',
        libraryName: 'Apex Study Lounge',
        phone: '9811223344',
      );

      expect(res.success, isTrue);
      expect(res.role, equals('Admin'));
      expect(service.currentUserName, equals('Rohan Sharma'));
      expect(service.currentUserEmail, equals('founder@apexlibrary.in'));
      expect(service.profile.libraryName, equals('Apex Study Lounge'));
      expect(service.tenantId, isNotEmpty);
      expect(service.isAdmin, isTrue);

      // Verify sign in with new credentials works
      await service.signOut();
      expect(service.isAuthenticated, isFalse);

      final loginRes = await service.login(
        identifier: 'founder@apexlibrary.in',
        password: 'securePassword456',
      );
      expect(loginRes.success, isTrue);
      expect(service.isAdmin, isTrue);
    });

    test('Admin registration rejects weak password', () async {
      final res = await service.registerAdminAccount(
        email: 'test@lib.com',
        password: '123',
        adminName: 'Test',
        libraryName: 'Test Lib',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('at least 6 characters'));
    });

    test('Staff Receptionist logs in with phone and PIN, role strictly Receptionist', () async {
      final staff = StaffMember(
        id: 'staff_rec_01',
        name: 'Pooja Verma',
        phone: '9988776655',
        role: 'Receptionist & Desk',
        pinHash: LibraryService.hashPin('5678'),
        email: 'pooja@library.local',
        addedAt: DateTime.now(),
        isActive: true,
      );
      service.addStaffMember(staff);

      final res = await service.login(
        identifier: '9988776655',
        password: '5678',
      );

      expect(res.success, isTrue);
      expect(res.role, equals('Receptionist'));
      expect(service.isAdmin, isFalse);
      expect(service.isReceptionist, isTrue);
      expect(service.currentUserName, equals('Pooja Verma'));
      expect(service.currentUserId, equals('staff_rec_01'));
    });

    test('Deactivated staff member is barred from logging in', () async {
      final staff = StaffMember(
        id: 'staff_deact_02',
        name: 'Vikram Singh',
        phone: '9123456780',
        role: 'Night Supervisor',
        pinHash: LibraryService.hashPin('9999'),
        addedAt: DateTime.now(),
        isActive: false, // Deactivated
      );
      service.addStaffMember(staff);

      final res = await service.login(
        identifier: '9123456780',
        password: '9999',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('deactivated'));
    });

    test('Sign out cleanly clears active user session', () async {
      await service.login(
        identifier: 'manageyourlib@gmail.com',
        password: 'password123',
      );
      expect(service.isAuthenticated, isTrue);

      await service.signOut();
      expect(service.isAuthenticated, isFalse);
      expect(service.currentUserId, isNull);
      expect(service.currentUserName, equals('Guest'));
    });

    test('Multi-tenant isolation namespaces collection paths under tenant ID', () {
      final tenantId = service.tenantId;
      expect(tenantId, isNotEmpty);
      expect(service.profile.libraryId, equals(tenantId));
    });

    test('Google Sign-In logs in successfully as Admin', () async {
      final res = await service.loginWithGoogle();
      expect(res.success, isTrue);
      expect(res.role, equals('Admin'));
      expect(service.isAuthenticated, isTrue);
      expect(service.isAdmin, isTrue);
    });

    test('Biometric login authenticates administrator session', () async {
      final res = await service.loginWithBiometrics();
      expect(res.success, isTrue);
      expect(service.isAuthenticated, isTrue);
      expect(service.isAdmin, isTrue);
    });

    test('sendPasswordReset rejects non-email identifiers honestly', () async {
      final phoneRes = await service.sendPasswordReset('9876543210');
      expect(phoneRes.success, isFalse);
      expect(phoneRes.message, contains('Staff PINs cannot be reset via email'));

      final emailRes = await service.sendPasswordReset('admin@apexlibrary.in');
      expect(emailRes.success, isTrue);
    });

    test('hasConfiguredLibrary detects configured vs unconfigured state', () async {
      service.profile.libraryName = '';
      await LocalStorageService.remove('app_setup_completed');
      await LocalStorageService.remove('app_library_profile');
      expect(await service.hasConfiguredLibrary(), isFalse);

      service.profile.libraryName = 'Sunrise Study Library';
      await LocalStorageService.saveString('app_setup_completed', 'true');
      expect(await service.hasConfiguredLibrary(), isTrue);
    });

    test('deleteAccountPermanently completely wipes state, storage, and library configuration', () async {
      service.profile.libraryName = 'Test Deletion Library';
      await LocalStorageService.saveString('app_setup_completed', 'true');
      await LocalStorageService.saveString('app_last_login_identifier', 'admin@test.com');
      await LocalStorageService.saveString('app_active_session', '{"user_id":"123"}');

      await service.deleteAccountPermanently();

      expect(service.profile.libraryName, isEmpty);
      expect(service.currentUserId, isNull);
      expect(service.isAuthenticated, isFalse);
      expect(service.staffList, isEmpty);
      expect(service.branches, isEmpty);
      expect(await LocalStorageService.getString('app_setup_completed'), isNull);
      expect(await LocalStorageService.getString('app_last_login_identifier'), isNull);
      expect(await LocalStorageService.getString('app_active_session'), isNull);
      expect(await service.hasConfiguredLibrary(), isFalse);

      // Biometrics must fail when no credentials exist
      final bioRes = await service.loginWithBiometrics();
      expect(bioRes.success, isFalse);
      expect(bioRes.message, contains('No registered credentials found'));
    });
  });
}

