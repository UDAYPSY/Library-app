import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/models/library_models.dart';
import 'package:library_manager/services/library_service.dart';

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
  });
}
