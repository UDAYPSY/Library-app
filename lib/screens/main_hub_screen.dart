import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import 'analytics/financial_analytics_screen.dart';
import 'analytics/add_expense_sheet.dart';
import 'payments/revenue_screen.dart';
import 'seats/seats_screen.dart';
import 'shifts/shift_system_screen.dart';
import 'students/add_student_wizard_screen.dart';
import 'students/student_directory_screen.dart';
import 'students/member_profile_screen.dart';
import 'tools/whatsapp_automation_screen.dart';
import 'tools/reports_exports_screen.dart';
import 'tools/share_qr_screen.dart';
import 'tools/library_branding_screen.dart';
import 'tools/refer_earn_screen.dart';
import 'tools/library_community_screen.dart';
import 'settings/settings_screen.dart';
import 'login_screen.dart';

class MainHubScreen extends StatefulWidget {
  const MainHubScreen({super.key});

  @override
  State<MainHubScreen> createState() => _MainHubScreenState();
}

class _MainHubScreenState extends State<MainHubScreen> {
  final LibraryService _service = LibraryService();
  int _currentTabIndex = 0;
  bool _isModernMode = false;
  String _studentFilter = 'RECENT';
  String _paymentTimeFilter = 'MONTHLY';

  void _openFinancialAnalytics() {
    setState(() => _currentTabIndex = 4); // Jump to Analytics tab
  }

  void _openStudentsWithFilter(String filter) {
    setState(() {
      _studentFilter = filter;
      _currentTabIndex = 1; // Jump to Students Directory tab
    });
  }

  void _openRevenueScreen(String filter) {
    setState(() {
      _paymentTimeFilter = filter;
      _currentTabIndex = 3; // Jump to Payments / Revenue tab (Image 2)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildHomeTab(),
            StudentDirectoryScreen(
              key: ValueKey(_studentFilter),
              initialStatusFilter: _studentFilter,
            ),
            _buildSeatsTab(),
            RevenueScreen(
              key: ValueKey(_paymentTimeFilter),
              initialTimeFilter: _paymentTimeFilter,
            ),
            const FinancialAnalyticsScreen(isStandalone: false),
            _buildSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: HOME (Image 1)
  // -------------------------------------------------------------
  Widget _buildHomeTab() {
    final profile = _service.profile;
    final adminName = _service.currentUserName.isNotEmpty
        ? _service.currentUserName
        : (profile.adminName.isNotEmpty ? profile.adminName : 'Administrator');
    final avatarLetter = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'N';

    final hour = DateTime.now().hour;
    final greeting = (hour < 12)
        ? 'Good Morning'
        : (hour < 17)
            ? 'Good Afternoon'
            : 'Good Evening';

    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, studentSnapshot) {
        final students = studentSnapshot.data ?? [];
        final activeStudents = students.where((s) => s.status != 'INACTIVE').length;
        final totalEarnings = students.fold<int>(0, (sum, s) => sum + s.monthlyFee);
        final dueStudents = students.where((s) => s.hasDues).toList();
        final dueStudentsCount = dueStudents.length;
        final pendingDuesTotal = dueStudents.fold<int>(0, (sum, s) => sum + s.effectiveDues);

        return StreamBuilder<List<PaymentTransaction>>(
          stream: _service.streamPayments(),
          builder: (context, paymentSnapshot) {
            final payments = paymentSnapshot.data ?? [];
            final today = DateTime.now();
            final todayPayments = payments.where((p) =>
                p.date.year == today.year &&
                p.date.month == today.month &&
                p.date.day == today.day).toList();
            final todayEarnings = todayPayments.fold<int>(0, (sum, p) => sum + p.amount);

            final monthPayments = payments.where((p) =>
                p.date.year == today.year &&
                p.date.month == today.month).toList();
            final monthEarnings = monthPayments.fold<int>(0, (sum, p) => sum + p.amount);

            return StreamBuilder<List<SeatInfo>>(
              stream: _service.streamSeats(),
              builder: (context, seatSnapshot) {
                final seats = seatSnapshot.data ?? [];
                final occupiedSeats = seats.where((s) => s.isOccupied).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Greeting & Avatar Row (Image 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMutedColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adminName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text(context),
                            ),
                          ),
                        ],
                      ),
                      // Avatar Card with Star (Image 1)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorderColor(context)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.isDark(context) ? Colors.black26 : Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                avatarLetter,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.isDark(context) ? AppColors.mintAccent : AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF59E0B),
                              ),
                              child: const Icon(Icons.star, color: Colors.white, size: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Pill Switcher: Classic vs Modern (Image 1)
                  Container(
                    width: 200,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.subSurface(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () => setState(() => _isModernMode = false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: !_isModernMode
                                    ? (AppColors.isDark(context) ? AppColors.mintAccent : AppColors.primaryTeal)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 14,
                                    color: !_isModernMode
                                        ? (AppColors.isDark(context) ? const Color(0xFF0F172A) : Colors.white)
                                        : AppColors.textMutedColor(context),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Classic',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !_isModernMode
                                          ? (AppColors.isDark(context) ? const Color(0xFF0F172A) : Colors.white)
                                          : AppColors.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () => setState(() => _isModernMode = true),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isModernMode
                                    ? (AppColors.isDark(context) ? AppColors.mintAccent : AppColors.primaryTeal)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: _isModernMode
                                        ? (AppColors.isDark(context) ? const Color(0xFF0F172A) : Colors.white)
                                        : AppColors.textMutedColor(context),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Modern',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isModernMode
                                          ? (AppColors.isDark(context) ? const Color(0xFF0F172A) : Colors.white)
                                          : AppColors.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hero Card: Library Today -> Navigates to Financial Analytics (Image 1)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openFinancialAnalytics,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330D9488),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.show_chart_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'LIVE STATUS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Library Today',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$activeStudents active • ₹$todayEarnings earned today',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0F766E),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Library Overview (Image 1)
                  Text(
                    'Library Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2x2 Metric Grid (Image 1)
                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.people_alt_rounded,
                          iconBg: AppColors.activeGreenBg,
                          iconColor: AppColors.activeGreenIcon,
                          value: '$activeStudents',
                          label: 'ACTIVE',
                          onTap: () => _openStudentsWithFilter('ACTIVE'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.calendar_today_rounded,
                          iconBg: AppColors.todayPurpleBg,
                          iconColor: AppColors.todayPurpleIcon,
                          value: '₹$todayEarnings',
                          label: 'TODAY',
                          onTap: () => _openRevenueScreen('TODAY'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.account_balance_wallet_rounded,
                          iconBg: AppColors.monthlyAmberBg,
                          iconColor: AppColors.monthlyAmberIcon,
                          value: '₹$monthEarnings',
                          label: 'MONTHLY',
                          onTap: () => _openRevenueScreen('MONTHLY'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _overviewCard(
                          icon: Icons.bar_chart_rounded,
                          iconBg: AppColors.totalBlueBg,
                          iconColor: AppColors.totalBlueIcon,
                          value: '${_service.totalSeatsCount}',
                          label: 'TOTAL',
                          onTap: () => _openStudentsWithFilter('RECENT'), // Opens Student Directory, same page as Active tab
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Quick Actions (Image 1)
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Action Cards (Batch 5 Image 1 & Batch 6 Image 1)
                  SizedBox(
                    height: 128,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          ),
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'Add Student',
                          subtitle: 'New admission',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddStudentWizardScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Send Reminders',
                          subtitle: '$dueStudentsCount students due',
                          onTap: () => _openStudentsWithFilter('DUES'),
                        ),
                        const SizedBox(width: 12),
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          icon: Icons.receipt_long_rounded,
                          title: 'Log Expense',
                          subtitle: 'Track costs',
                          onTap: () => showAddExpenseModal(context),
                        ),
                        const SizedBox(width: 12),
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                          ),
                          icon: Icons.bar_chart_rounded,
                          title: 'View Reports',
                          subtitle: 'Deep insights',
                          onTap: _openFinancialAnalytics,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Recommended for You (Batch 6 Image 2)
                  Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Recommended Carousel Row (Batch 6 Image 2)
                  SizedBox(
                    height: 84,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _recommendedCard(
                          width: 290,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          icon: Icons.card_giftcard_rounded,
                          title: 'Refer & Earn ₹149',
                          subtitle: 'Get bonus on every referral',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReferEarnScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        _recommendedCard(
                          width: 320,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          icon: Icons.chat_bubble_rounded,
                          title: 'Join Community',
                          subtitle: 'Connect with 500+ library owners',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LibraryCommunityScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pending Dues Banner (Batch 6 Image 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.isDark(context)
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFFFFE4E6),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? const Color(0xFF450A0A)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: Color(0xFFEF4444),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Dues',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dueStudentsCount > 0
                                    ? '₹$pendingDuesTotal from $dueStudentsCount student${dueStudentsCount == 1 ? '' : 's'}'
                                    : 'All dues cleared • ₹0 pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMutedColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dueStudentsCount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => _openStudentsWithFilter(dueStudentsCount > 0 ? 'DUES' : 'ACTIVE'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dueStudentsCount > 0 ? 'Collect' : 'View All',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Manage (Batch 6 Image 2 & 3)
                  Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3x2 Manage Grid Card (Batch 6 Image 2 & 3)
                  _buildMenuGridCard(
                    items: [
                      _gridMenuItem(
                        icon: Icons.people_alt_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Students',
                        onTap: () => _openStudentsWithFilter('ALL'),
                      ),
                      _gridMenuItem(
                        icon: Icons.grid_view_rounded,
                        iconBg: const Color(0xFFECFEFF),
                        iconColor: const Color(0xFF06B6D4),
                        label: 'Seats',
                        onTap: () => setState(() => _currentTabIndex = 2), // Routes to Image 2 (Seats tab)
                      ),
                      _gridMenuItem(
                        icon: Icons.credit_card_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFFA855F7),
                        label: 'Payments',
                        onTap: () => setState(() => _currentTabIndex = 3), // Routes to Image 3 (Revenue tab)
                      ),
                      _gridMenuItem(
                        icon: Icons.access_time_filled_rounded,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFF97316),
                        label: 'Shifts',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShiftSystemScreen()),
                        ), // Routes to Image 4 & 5 (Shift System)
                      ),
                      _gridMenuItem(
                        icon: Icons.bar_chart_rounded,
                        iconBg: const Color(0xFFFDF2F8),
                        iconColor: const Color(0xFFEC4899),
                        label: 'Analytics',
                        onTap: _openFinancialAnalytics, // Routes to Image 6 (Financial Analytics tab)
                      ),
                      _gridMenuItem(
                        icon: Icons.assignment_ind_rounded,
                        iconBg: const Color(0xFFCCFBF1),
                        iconColor: const Color(0xFF0D9488),
                        label: 'Student ID',
                        onTap: () => setState(() => _currentTabIndex = 1), // Routes to Image 7 (Students tab with Member ID)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PRO TIP • TODAY Card (Batch 6 Image 3)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShareQrScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorderColor(context)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Color(0xFF0D9488),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PRO TIP • TODAY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Use QR codes to let students check-in automatically.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Tools & More (Batch 6 Image 3)
                  Text(
                    'Tools & More',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3x2 Tools & More Grid Card (Batch 6 Image 3)
                  _buildMenuGridCard(
                    items: [
                      _gridMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF10B981),
                        label: 'WhatsApp',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WhatsAppAutomationScreen(),
                          ),
                        ),
                      ),
                      _gridMenuItem(
                        icon: Icons.insert_chart_rounded,
                        iconBg: const Color(0xFFCCFBF1),
                        iconColor: const Color(0xFF0D9488),
                        label: 'Reports',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsExportsScreen(),
                          ),
                        ),
                      ),
                      _gridMenuItem(
                        icon: Icons.qr_code_2_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'QR Code',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ShareQrScreen(),
                          ),
                        ),
                      ),
                      _gridMenuItem(
                        icon: Icons.auto_fix_high_rounded,
                        iconBg: const Color(0xFFFFE4E6),
                        iconColor: const Color(0xFFF43F5E),
                        label: 'Branding',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryBrandingScreen(),
                          ),
                        ),
                      ),
                      _gridMenuItem(
                        icon: Icons.card_giftcard_rounded,
                        iconBg: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF6366F1),
                        label: 'Refer & Earn',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReferEarnScreen(),
                          ),
                        ),
                      ),
                      _gridMenuItem(
                        icon: Icons.forum_rounded,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        label: 'Community',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LibraryCommunityScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TrackMyLibrary Branding Card (Batch 6 Image 4)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.cardBorderColor(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.local_library_rounded,
                                  color: Color(0xFF0D9488),
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TrackMyLibrary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "INDIA'S #1 LIBRARY MANAGEMENT APP",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: AppColors.textMutedColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.divider(context), height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '500+ Libraries',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '4.8 Rating',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _platformPill(icon: Icons.apple, label: 'iOS'),
                            const SizedBox(width: 10),
                            _platformPill(icon: Icons.android_rounded, label: 'Android', iconColor: const Color(0xFF22C55E)),
                            const SizedBox(width: 10),
                            _platformPill(icon: Icons.language_rounded, label: 'Web', iconColor: const Color(0xFF3B82F6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Need Help? Support Card (Batch 6 Image 4)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.cardBorderColor(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.isDark(context) ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.support_agent_rounded,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Our support team is just a message away',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: const Text(
                                  'Chat on WhatsApp',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                onPressed: () => _showSupportDialog('WhatsApp'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 4,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.text(context),
                                  side: BorderSide(color: AppColors.cardBorderColor(context)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF64748B)),
                                label: const Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                onPressed: () => _showSupportDialog('Email'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Invite a Friend! Banner (Batch 6 Image 4)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _showReferralDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context) ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.isDark(context) ? const Color(0xFF3730A3) : const Color(0xFFE0E7FF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.share_rounded,
                                color: Color(0xFF4F46E5),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite a Friend!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.isDark(context) ? const Color(0xFFE0E7FF) : const Color(0xFF312E81),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Help other library owners simplify their work.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.isDark(context) ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enjoying the App? Rating Card (Batch 6 Image 4)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.isDark(context)
                            ? const [Color(0xFF451A03), Color(0xFF78350F)]
                            : const [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.isDark(context) ? const Color(0xFF9A3412) : const Color(0xFFFED7AA),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x22FDBA74),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Enjoying the App?',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.isDark(context) ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your 5-star rating helps us grow!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.isDark(context) ? const Color(0xFFFED7AA) : const Color(0xFF9A3412),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF962D1C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              onPressed: _showRatingDialog,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rate on Play Store',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
      },
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark(context) ? Colors.black26 : Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required LinearGradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReferralDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Refer & Earn ₹149', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share your library referral link with other admins or libraries. When they subscribe, you both receive ₹149 credited to your ledger!'),
            const SizedBox(height: 14),
            SelectableText(
              'Code: LIB-${_service.tenantId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').padRight(4, 'X').substring(0, 4)}-149',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryTeal),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referral link copied to clipboard!')),
              );
            },
            child: const Text('Copy Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _recommendedCard({
    required double width,
    required LinearGradient gradient,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x25000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _platformPill({
    required IconData icon,
    required String label,
    Color iconColor = Colors.black87,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.subSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor == Colors.black87
                ? (AppColors.isDark(context) ? Colors.white70 : Colors.black87)
                : iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGridCard({
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: items[0]),
                VerticalDivider(color: AppColors.divider(context), width: 1, thickness: 1),
                Expanded(child: items[1]),
                VerticalDivider(color: AppColors.divider(context), width: 1, thickness: 1),
                Expanded(child: items[2]),
              ],
            ),
          ),
          Divider(color: AppColors.divider(context), height: 1, thickness: 1),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: items[3]),
                VerticalDivider(color: AppColors.divider(context), width: 1, thickness: 1),
                Expanded(child: items[4]),
                VerticalDivider(color: AppColors.divider(context), width: 1, thickness: 1),
                Expanded(child: items[5]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final shifts = _service.shifts;
        final students = _service.currentStudents;
        final colors = [
          const Color(0xFF3B82F6),
          const Color(0xFF10B981),
          const Color(0xFF8B5CF6),
          const Color(0xFFF97316),
          const Color(0xFF06B6D4),
        ];

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: Color(0xFFF97316)),
                  const SizedBox(width: 8),
                  Text(
                    'Library Shifts & Timings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Live configured shifts with monthly pricing and active seat counts.',
                style: TextStyle(color: AppColors.textMutedColor(context), fontSize: 13),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final shift = shifts[idx];
                    final activeCount = students.where((s) => s.shift == shift.name && s.status != 'INACTIVE').length;
                    final color = colors[idx % colors.length];

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShiftSystemScreen()),
                        );
                      },
                      child: _shiftConfigItem(
                        name: shift.name,
                        timings: '${shift.startsAt} - ${shift.endsAt}',
                        fee: '₹${shift.monthlyFee} / month',
                        activeCount: '$activeCount active students',
                        color: color,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Manage & Add Custom Shifts', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShiftSystemScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shiftConfigItem({
    required String name,
    required String timings,
    required String fee,
    required String activeCount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timings • $fee',
                  style: TextStyle(fontSize: 12, color: AppColors.textMutedColor(context), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  activeCount,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  void _showStudentIDModal() {
    final profile = _service.profile;
    final students = _service.currentStudents;
    final student = students.isNotEmpty
        ? students.firstWhere((s) => s.status != 'INACTIVE', orElse: () => students.first)
        : null;

    final baseUrl = profile.portalBaseUrl.trim().isNotEmpty
        ? profile.portalBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://udaypsy.github.io/Library-app';
    final qrVerifyUrl = student != null
        ? '$baseUrl/#/portal?lib=${_service.tenantId}&verify=${student.id}&seat=${student.seatNumber ?? 0}&student=${Uri.encodeComponent(student.name)}'
        : '$baseUrl/#/portal?lib=${_service.tenantId}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Digital Student ID Card',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Official digital library membership card with verified QR verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              if (student == null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.badge_outlined, size: 54, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Members Registered Yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textNavy),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enroll your first student to generate their official scannable digital ID pass.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Enroll First Member'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openAddStudentSheet();
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x330F766E), blurRadius: 14, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(base64Decode(profile.logoBase64!), width: 22, height: 22, fit: BoxFit.cover),
                              )
                            else
                              const Icon(Icons.local_library_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                profile.libraryName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'STUDENT PASS',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: student.hasPhoto
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.memory(
                                        base64Decode(student.photoBase64!),
                                        width: 62,
                                        height: 62,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF0F766E)),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Seat #${student.seatNumber ?? 'Unassigned'} • Phone: ${student.phone}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Shift: ${student.shift}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    student.feeDueDate != null
                                        ? 'Valid till: ${DateFormat('dd MMM yyyy').format(student.feeDueDate!)}'
                                        : 'Active Member',
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: QrImageView(
                                data: qrVerifyUrl,
                                size: 52,
                                version: QrVersions.auto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF10B981)),
                        label: const Text('Share on WhatsApp', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final cleanPhone = student.phone.replaceAll(RegExp(r'\D'), '');
                          final target = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
                          final passMsg = '''
📇 *OFFICIAL DIGITAL ID CARD*
🏛️ *${profile.libraryName.toUpperCase()}*
----------------------------------------
👤 *Member Name:* ${student.name}
🪑 *Seat:* #${student.seatNumber ?? 'Unassigned'}
⏰ *Shift:* ${student.shift}
📅 *Validity:* ${student.feeDueDate != null ? DateFormat('dd-MMM-yyyy').format(student.feeDueDate!) : 'Active'}
✅ *Status:* ${student.status}
----------------------------------------
📲 *Scan Digital Verification Pass:*
$qrVerifyUrl
'''.trim();
                          final uri = Uri.parse('https://wa.me/$target?text=${Uri.encodeComponent(passMsg)}');
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              await launchUrl(uri);
                            }
                          } catch (_) {}
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: const Text('Member Profile'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MemberProfileScreen(student: student, memberId: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showQRCodeModal() {
    final profile = _service.profile;
    final baseUrl = profile.portalBaseUrl.trim().isNotEmpty
        ? profile.portalBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://udaypsy.github.io/Library-app';
    final portalUrl = '$baseUrl/#/portal?lib=${_service.tenantId}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text(
                    'Student Check-in QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Place this QR code at your entrance for real-time seat check-in & public verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 22),
              // Live QR Display Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      ),
                      child: QrImageView(
                        data: portalUrl,
                        version: QrVersions.auto,
                        size: 160,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.libraryName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textNavy),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      portalUrl,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Open QR Studio'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShareQrScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Share Link'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final text = 'Check live seat availability at ${profile.libraryName} before visiting:\n$portalUrl';
                        final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(uri);
                          }
                        } catch (_) {}
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWhatsAppToolsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'WhatsApp Automation Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Send instant fee reminders, welcome greetings, and announcements.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              _whatsappActionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Fee Dues Reminder',
                subtitle: 'Send 1-tap reminders with UPI payment link to pending students',
                buttonText: 'Send to Dues',
                onPressed: () {
                  Navigator.pop(ctx);
                  _openStudentsWithFilter('DUES');
                },
              ),
              const SizedBox(height: 12),
              _whatsappActionTile(
                icon: Icons.waving_hand_outlined,
                title: 'Welcome New Admissions',
                subtitle: 'Send WiFi pass, seat number and library rules',
                buttonText: 'Send Welcome',
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAdmissionWelcomeDialog();
                },
              ),
              const SizedBox(height: 12),
              _whatsappActionTile(
                icon: Icons.campaign_outlined,
                title: 'Broadcast Announcement',
                subtitle: 'Notify all active members about timings, holidays or AC notice',
                buttonText: 'Draft Notice',
                onPressed: () {
                  Navigator.pop(ctx);
                  _showBroadcastNoticeDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdmissionWelcomeDialog() {
    final welcomeMsg = '''
🎉 *WELCOME TO ${_service.profile.libraryName.toUpperCase()}!*
----------------------------------------
Dear Member,
Your study seat admission is confirmed!

🔑 *Library Amenities & Guidelines:*
📶 High-Speed Study WiFi: Available at reception
🤫 Strict Silence inside reading halls
🔌 Clean power socket at your assigned desk
☕ RO Drinking water on-site

For questions, feel free to contact the front desk.
Have a productive study session!
'''.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            const Text('Welcome Greeting Template', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: SelectableText(welcomeMsg, style: const TextStyle(fontSize: 12, height: 1.4)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Share Greeting via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(welcomeMsg)}');
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      await launchUrl(uri);
                    }
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastNoticeDialog() {
    final noticeCtrl = TextEditingController(
      text: '📢 *IMPORTANT NOTICE FROM ${_service.profile.libraryName.toUpperCase()}*\n\nPlease note that tomorrow the study hall will operate with revised hours. Thank you for your cooperation.',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              const Text('Broadcast Notice to Members', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              const Text('Draft an announcement to share with your active library members.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              TextField(
                controller: noticeCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Broadcast via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final text = noticeCtrl.text.trim();
                    Navigator.pop(ctx);
                    if (text.isNotEmpty) {
                      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(uri);
                        }
                      } catch (_) {}
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whatsappActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onPressed,
            child: Text(buttonText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBrandingModal() {
    final profile = _service.profile;
    final nameCtrl = TextEditingController(text: profile.libraryName);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: Color(0xFFF43F5E)),
                    SizedBox(width: 8),
                    Text(
                      'Library Branding & Identity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Customize your library brand name, receipt logos, and theme styling.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Library Display Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.storefront_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isNotEmpty) {
                        _service.saveBranding(
                          libraryName: newName,
                          logoEmblem: profile.logoEmblem,
                          tagline: profile.tagline,
                          logoBase64: profile.logoBase64,
                        );
                        if (mounted) setState(() {});
                      }
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Library branding saved successfully!'),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      }
                    },
                    child: const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF43F5E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFF43F5E)),
                    ),
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    label: const Text('Open Full Branding Studio (Logo & Colors)'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LibraryBrandingScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommunityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.forum_rounded, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'TrackMyLibrary Community',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Connect with 500+ Indian library owners sharing tips & occupancy growth strategies.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Text('Daily seat filling strategies & price benchmarks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Text('Electricity & AC cost optimization tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 8),
                        Text('Direct feedback and feature requests to developers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Join WhatsApp Community', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('https://wa.me/919457464850?text=${Uri.encodeComponent("Hello TrackMyLibrary team, I'd like to join the Official Library Owners Community group.")}');
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        await launchUrl(uri);
                      }
                    } catch (_) {}
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupportDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              type == 'WhatsApp' ? Icons.chat_bubble_outline_rounded : Icons.mail_outline_rounded,
              color: type == 'WhatsApp' ? const Color(0xFF22C55E) : AppColors.primaryTeal,
            ),
            const SizedBox(width: 8),
            Text('$type Support', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connect directly with our 24/7 dedicated support team via $type.'),
            const SizedBox(height: 14),
            SelectableText(
              type == 'WhatsApp' ? '+91 94574 64850' : 'manageyourlib@gmail.com',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryTeal),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'WhatsApp' ? const Color(0xFF22C55E) : AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = type == 'WhatsApp'
                  ? Uri.parse('https://wa.me/919457464850?text=${Uri.encodeComponent("Hi TrackMyLibrary Support Team, I need assistance with my library management app.")}')
                  : Uri.parse('mailto:manageyourlib@gmail.com?subject=${Uri.encodeComponent("TrackMyLibrary Support Request")}');
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(uri);
                }
              } catch (_) {}
            },
            child: Text('Contact on $type'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enjoying TrackMyLibrary?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your feedback helps us continuously improve library management.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () => setModalState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF962D1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you for rating TrackMyLibrary 5 Stars! ⭐⭐⭐⭐⭐')),
                        );
                      },
                      child: const Text('Submit Review on Play Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: STUDENTS
  // -------------------------------------------------------------
  Widget _buildStudentsTab() {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Student Directory',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded, color: AppColors.primaryTeal),
                    onPressed: _openAddStudentSheet,
                  ),
                ],
              ),
            ),
            if (students.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No registered students yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: students.length,
                  itemBuilder: (context, idx) {
                    final s = students[idx];
                    final seatLabel = s.seatNumber != null ? 'S-${s.seatNumber}' : 'None';
                    final dateStr = s.feeDueDate != null
                        ? DateFormat('dd MMM yyyy').format(s.feeDueDate!)
                        : 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.lightMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                seatLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryTeal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textNavy),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Shift: ${s.shift} • Phone: ${s.phone}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Renewal Due: $dateStr',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.whatsappDark),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.whatsappGreen),
                            onPressed: () => _sendWhatsAppReminder(s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: SEATS MAP
  // -------------------------------------------------------------
  Widget _buildSeatsTab() {
    return const SeatsScreen();
  }

  void _openAddStudentSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStudentWizardScreen()),
    );
  }

  Future<void> _sendWhatsAppReminder(StudentInfo s) async {
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    final msg =
        'Hello ${s.name}, your monthly library seat renewal fee of Rs.${s.monthlyFee} is scheduled. Please confirm at the desk.';
    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // TAB 6: SETTINGS
  // -------------------------------------------------------------
  Widget _buildSettingsTab() {
    return const SettingsScreen();
  }

  // -------------------------------------------------------------
  // 6-ITEM BOTTOM NAVIGATION BAR (Image 1 & 2)
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.divider(context))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (idx) => setState(() => _currentTabIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card(context),
        selectedItemColor: isDark ? AppColors.mintAccent : AppColors.primaryTeal,
        unselectedItemColor: isDark ? AppColors.darkTextSubtle : const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chair_alt_rounded),
            label: 'Seats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
