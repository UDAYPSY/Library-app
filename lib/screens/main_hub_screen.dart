import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import 'analytics/financial_analytics_screen.dart';
import 'students/student_directory_screen.dart';
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

  void _openFinancialAnalytics() {
    setState(() => _currentTabIndex = 4); // Jump to Analytics tab
  }

  void _openStudentsWithFilter(String filter) {
    setState(() {
      _studentFilter = filter;
      _currentTabIndex = 1; // Jump to Students Directory tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
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
            _buildPaymentsTab(),
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
    final adminName = profile.adminName.isNotEmpty ? profile.adminName : 'Nivi';
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
        final activeStudents = students.where((s) => s.status == 'ACTIVE').length;
        final totalEarnings = students.fold<int>(0, (sum, s) => sum + s.monthlyFee);

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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textNavy,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                avatarLetter,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryTeal,
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
                      color: const Color(0xFFEDF2F7),
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
                                color: !_isModernMode ? AppColors.primaryTeal : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 14,
                                    color: !_isModernMode ? Colors.white : AppColors.textNavy,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Classic',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !_isModernMode ? Colors.white : AppColors.textNavy,
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
                                color: _isModernMode ? AppColors.primaryTeal : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: _isModernMode ? Colors.white : AppColors.textNavy,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Modern',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isModernMode ? Colors.white : AppColors.textNavy,
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
                                  '$occupiedSeats active • ₹$totalEarnings earned today',
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
                  const Text(
                    'Library Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
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
                          value: '₹$totalEarnings',
                          label: 'TODAY',
                          onTap: _openFinancialAnalytics,
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
                          value: '₹$totalEarnings',
                          label: 'MONTHLY',
                          onTap: _openFinancialAnalytics,
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
                          onTap: () => setState(() => _currentTabIndex = 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Section Header: Quick Actions (Image 1)
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Action Cards (Image 1)
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          ),
                          icon: Icons.person_add_rounded,
                          title: 'Add Student',
                          onTap: () => _openAddStudentSheet(),
                        ),
                        const SizedBox(width: 12),
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                          icon: Icons.chat_rounded,
                          title: 'WhatsApp Reminder',
                          onTap: () => setState(() => _currentTabIndex = 1),
                        ),
                        const SizedBox(width: 12),
                        _quickActionCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          icon: Icons.receipt_long_rounded,
                          title: 'Fee Ledger',
                          onTap: () => setState(() => _currentTabIndex = 3),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
    return StreamBuilder<List<SeatInfo>>(
      stream: _service.streamSeats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final seats = snapshot.data!;
        final occupiedCount = seats.where((s) => s.isOccupied).length;
        final vacantCount = seats.length - occupiedCount;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seats Map',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  Row(
                    children: [
                      _badgeChip('$occupiedCount Occupied', AppColors.errorRed, const Color(0xFFFEE2E2)),
                      const SizedBox(width: 6),
                      _badgeChip('$vacantCount Vacant', AppColors.whatsappDark, const Color(0xFFDCFCE7)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemCount: seats.length,
                itemBuilder: (context, idx) {
                  final seat = seats[idx];
                  final isOccupied = seat.isOccupied;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _handleSeatClick(seat),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOccupied ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOccupied ? AppColors.errorRed : AppColors.successGreen,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chair_alt_rounded,
                            size: 22,
                            color: isOccupied ? AppColors.errorRed : AppColors.successGreen,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S-${seat.seatNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          if (isOccupied)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Text(
                                seat.studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
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

  Widget _badgeChip(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  void _handleSeatClick(SeatInfo seat) {
    if (seat.isOccupied) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Seat S-${seat.seatNumber} Occupied'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${seat.studentName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Shift: ${seat.shift}'),
              const SizedBox(height: 6),
              const Text('Status: Active Renewal', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
              onPressed: () async {
                Navigator.pop(ctx);
                await _service.vacateSeat(seat.seatNumber, seat.studentId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seat S-${seat.seatNumber} is now vacant.')),
                  );
                }
              },
              child: const Text('Vacate Seat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _openAssignSeatSheet(seat.seatNumber);
    }
  }

  void _openAssignSeatSheet(int seatNum) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String shift = _service.shifts.isNotEmpty ? _service.shifts.first.name : 'Full Day';
    int fee = _service.shifts.isNotEmpty ? _service.shifts.first.monthlyFee : 500;
    String paymentMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Seat S-$seatNum (Fee: ₹$fee/mo)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Student Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: shift,
                      items: _service.shifts.map((s) => DropdownMenuItem(value: s.name, child: Text('${s.name} (₹${s.monthlyFee})'))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final found = _service.shifts.firstWhere((s) => s.name == v);
                          setModalState(() {
                            shift = v;
                            fee = found.monthlyFee;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Select Shift', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: paymentMode,
                      items: ['UPI', 'Cash']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setModalState(() => paymentMode = v ?? paymentMode),
                      decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    await _service.assignSeatAndRegisterStudent(
                      seatNumber: seatNum,
                      studentName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      shift: shift,
                      deviceUserId: _service.profile.adminName,
                      feeAmount: fee,
                      paymentMode: paymentMode,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Student assigned to S-$seatNum & ₹$fee fee collected via $paymentMode!')),
                      );
                    }
                  },
                  child: Text('Confirm & Collect ₹$fee ($paymentMode)', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddStudentSheet() {
    _openAssignSeatSheet(1);
  }

  Future<void> _sendWhatsAppReminder(StudentInfo s) async {
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    final msg = 'Hello ${s.name}, your monthly library seat renewal fee of Rs.${s.monthlyFee} is scheduled. Please confirm at the desk.';
    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open WhatsApp: $e')));
      }
    }
  }

  // -------------------------------------------------------------
  // TAB 4: PAYMENTS
  // -------------------------------------------------------------
  Widget _buildPaymentsTab() {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final totalCollected = students.fold<int>(0, (sum, s) => sum + s.monthlyFee);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fee Ledger & Receipts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL COLLECTED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('₹$totalCollected', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${students.length} recorded payments', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Recent Collections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final st = students[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Seat S-${st.seatNumber ?? "None"} • ${st.shift} (${st.paymentMode})', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          Text('₹${st.monthlyFee}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.successGreen)),
                        ],
                      ),
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

  // -------------------------------------------------------------
  // TAB 6: SETTINGS
  // -------------------------------------------------------------
  Widget _buildSettingsTab() {
    final p = _service.profile;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Text('Settings & Workspace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.libraryName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(p.city, style: const TextStyle(color: AppColors.textMuted)),
                const Divider(height: 24),
                Text('Admin: ${p.adminName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Email: ${p.adminEmail}', style: const TextStyle(color: AppColors.textMuted)),
                Text('Phone: ${p.adminPhone}', style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6-ITEM BOTTOM NAVIGATION BAR (Image 1 & 2)
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (idx) => setState(() => _currentTabIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: const Color(0xFF94A3B8),
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
