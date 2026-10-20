import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import 'add_expense_sheet.dart';

class FinancialAnalyticsScreen extends StatefulWidget {
  final bool isStandalone;

  const FinancialAnalyticsScreen({super.key, this.isStandalone = false});

  @override
  State<FinancialAnalyticsScreen> createState() => _FinancialAnalyticsScreenState();
}

class _FinancialAnalyticsScreenState extends State<FinancialAnalyticsScreen> {
  final LibraryService _service = LibraryService();

  int _selectedYear = 2026;
  int _selectedMonthIndex = 9; // October (0-indexed: 9)
  bool _isIncomeSelected = true; // Income vs Expenses toggle

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  void _showAddExpenseSheet() {
    showAddExpenseModal(context, onExpenseAdded: () {
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, studentSnapshot) {
        final students = studentSnapshot.data ?? [];

        return StreamBuilder<List<ExpenseItem>>(
          stream: _service.streamExpenses(),
          builder: (context, expenseSnapshot) {
            final expenses = expenseSnapshot.data ?? [];

            // Metrics Calculations
            final today = DateTime.now();
            final todayStudents = students.where((s) =>
                s.joinedAt != null &&
                s.joinedAt!.year == today.year &&
                s.joinedAt!.month == today.month &&
                s.joinedAt!.day == today.day).toList();

            final todayRevenue = todayStudents.fold<int>(0, (sum, s) => sum + s.monthlyFee);
            final todayCash = todayStudents.where((s) => s.paymentMode == 'Cash').fold<int>(0, (sum, s) => sum + s.monthlyFee);
            final todayUPI = todayStudents.where((s) => s.paymentMode == 'UPI').fold<int>(0, (sum, s) => sum + s.monthlyFee);

            final monthlyRevenue = students.fold<int>(0, (sum, s) => sum + s.monthlyFee);
            final monthlyPaidCount = students.length;

            final monthlyExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amount);
            final netProfit = monthlyRevenue - monthlyExpenses;

            // Inactive / Pending dues
            final totalDues = 0; // Or calculated pending students
            final annualRevenue = monthlyRevenue;
            final annualExpenses = monthlyExpenses;
            final annualNetProfit = netProfit;

            return Scaffold(
              backgroundColor: AppColors.scaffoldBg,
              appBar: widget.isStandalone
                  ? AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0.5,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textNavy),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: const Text(
                        'Financial Analytics',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textNavy, fontSize: 18),
                      ),
                    )
                  : null,
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: FINANCIAL Analytics + [+ Expense] (Image 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FINANCIAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.textMuted,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Analytics',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textNavy,
                              ),
                            ),
                          ],
                        ),
                        // [+ Expense] Button (Image 2)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showAddExpenseSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle, color: Color(0xFFEF4444), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.textNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SELECT YEAR (Image 2)
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'SELECT YEAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _yearPill(2025),
                        const SizedBox(width: 8),
                        _yearPill(2026),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SELECT MONTH (Image 2)
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'SELECT MONTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _months.length,
                        itemBuilder: (ctx, i) {
                          final isSelected = _selectedMonthIndex == i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() => _selectedMonthIndex = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFCBD5E1) : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _months[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppColors.textNavy : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // PENDING & PAID Badges Row (Image 2)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'PENDING: Target for all active members.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'PAID: Collections reached so far.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2x2 CARDS ROW 1 & 2 (Image 2)
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.calendar_today_outlined,
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0284C7),
                            title: 'Today Revenue',
                            amount: '₹$todayRevenue',
                            accentText: 'Cash: ₹$todayCash • UPI: ₹$todayUPI',
                            accentColor: const Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.calendar_month_outlined,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            title: 'Monthly Revenue',
                            amount: '₹$monthlyRevenue',
                            accentText: '$monthlyPaidCount Students Paid',
                            accentColor: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.trending_down_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            title: 'Monthly Expenses',
                            amount: '₹$monthlyExpenses',
                            accentText: 'Total Spending',
                            accentColor: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.account_balance_wallet_outlined,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            title: 'Net Profit',
                            amount: '₹$netProfit',
                            accentText: 'Monthly Gain',
                            accentColor: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2x2 CARDS ROW 3 & 4: Total Dues, Annual Revenue, Annual Expenses, Annual Profit (Image 3)
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.access_time_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            title: 'Total Dues',
                            amount: '₹$totalDues',
                            accentText: '0 Pending',
                            accentColor: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.bar_chart_rounded,
                            iconBg: const Color(0xFFFEF9C3),
                            iconColor: const Color(0xFFCA8A04),
                            title: 'Annual Revenue',
                            amount: '₹$annualRevenue',
                            accentText: 'Gross Income',
                            accentColor: const Color(0xFFCA8A04),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.receipt_long_outlined,
                            iconBg: const Color(0xFFFCE7F3),
                            iconColor: const Color(0xFFDB2777),
                            title: 'Annual Expenses',
                            amount: '₹$annualExpenses',
                            accentText: 'Annual Spending',
                            accentColor: const Color(0xFFDB2777),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _kpiCard(
                            icon: Icons.payments_outlined,
                            iconBg: const Color(0xFFD1FAE5),
                            iconColor: const Color(0xFF059669),
                            title: 'Annual Net Profit',
                            amount: '₹$annualNetProfit',
                            accentText: 'Yearly Gain',
                            accentColor: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Financial Trend Card (Images 3 & 4)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Financial Trend',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Revenue & Expenses for $_selectedYear',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.mintTipBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryTeal, size: 20),
                                  onPressed: () => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Visual Bar Chart Mockup (Images 3 & 4)
                          SizedBox(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _trendBar('Jun', 30, 20, false),
                                _trendBar('Jul', 45, 15, false),
                                _trendBar('Aug', 60, 25, false),
                                _trendBar('Sep', 50, 30, false),
                                _trendBar('Oct', monthlyRevenue > 0 ? 80 : 10, monthlyExpenses > 0 ? 40 : 10, true),
                                _trendBar('Nov', 20, 10, false),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Chart Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 5),
                              const Text('Revenue', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 18),
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 5),
                              const Text('Expenses', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Income vs Expenses Switcher (Image 4)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => setState(() => _isIncomeSelected = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isIncomeSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                  border: _isIncomeSelected ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                                  boxShadow: _isIncomeSelected
                                      ? const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _isIncomeSelected ? AppColors.primaryTeal : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => setState(() => _isIncomeSelected = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isIncomeSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                  border: !_isIncomeSelected ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                                  boxShadow: !_isIncomeSelected
                                      ? const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Expenses',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: !_isIncomeSelected ? AppColors.errorRed : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Revenue Breakdown Card (Image 4)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isIncomeSelected ? 'Revenue Breakdown' : 'Expense Breakdown',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_months[_selectedMonthIndex]} $_selectedYear',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF94A3B8), size: 28),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isIncomeSelected
                                      ? (students.isEmpty ? 'No transactions recorded' : '${students.length} Student Memberships Active')
                                      : (expenses.isEmpty ? 'No expenses recorded' : '${expenses.length} Logged Expenses'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textNavy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Latest Payments Card (Image 4)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latest Payments',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (students.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                          else
                            ...students.take(5).map((st) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(st.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('Seat S-${st.seatNumber ?? "None"} • ${st.paymentMode}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      Text(
                                        '+₹${st.monthlyFee}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _yearPill(int year) {
    final isSelected = _selectedYear == year;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedYear = year),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          isSelected ? '$year •' : '$year',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.textNavy,
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
    required String accentText,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            accentText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stable this period',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendBar(String month, double revHeight, double expHeight, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: revHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 8,
              height: expHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? AppColors.textNavy : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
