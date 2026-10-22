import 'package:flutter_test/flutter_test.dart';
import 'package:library_manager/main.dart';
import 'package:library_manager/screens/main_hub_screen.dart';
import 'package:library_manager/screens/login_screen.dart';
import 'package:library_manager/screens/seats/seats_screen.dart';
import 'package:library_manager/screens/students/member_profile_screen.dart';
import 'package:library_manager/screens/students/student_directory_screen.dart';
import 'package:library_manager/screens/students/add_student_wizard_screen.dart';
import 'package:library_manager/screens/tools/reports_exports_screen.dart';
import 'package:library_manager/screens/payments/revenue_screen.dart';
import 'package:library_manager/screens/shifts/shift_system_screen.dart';
import 'package:library_manager/screens/analytics/financial_analytics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All core application screens and services compile cleanly', () {
    expect(MainHubScreen, isNotNull);
    expect(LoginScreen, isNotNull);
    expect(SeatsScreen, isNotNull);
    expect(MemberProfileScreen, isNotNull);
    expect(ReportsExportsScreen, isNotNull);
    expect(StudentDirectoryScreen, isNotNull);
    expect(AddStudentWizardScreen, isNotNull);
    expect(RevenueScreen, isNotNull);
    expect(ShiftSystemScreen, isNotNull);
    expect(FinancialAnalyticsScreen, isNotNull);
  });
}
