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

            return StreamBuilder<List<PaymentTransaction>>(
              stream: _service.streamPayments(),
              builder: (context, paymentSnapshot) {
                final payments = paymentSnapshot.data ?? [];

                // Metrics Calculations
                final today = DateTime.now();

                // Today payments
                final todayPayments = payments.where((p) =>
                    p.date.year == today.year &&
                    p.date.month == today.month &&
                    p.date.day == today.day).toList();
                final todayRevenue = todayPayments.fold<int>(0, (sum, p) => sum + p.amount);
                final todayCash = todayPayments
                    .where((p) => p.paymentMode.toLowerCase() == 'cash')
                    .fold<int>(0, (sum, p) => sum + p.amount);
                final todayUPI = todayPayments
                    .where((p) => p.paymentMode.toLowerCase() == 'upi')
                    .fold<int>(0, (sum, p) => sum + p.amount);

                // Selected month metrics
                final selectedMonthNumber = _selectedMonthIndex + 1;
                final selectedMonthPayments = payments.where((p) =>
                    p.date.year == _selectedYear &&
                    p.date.month == selectedMonthNumber).toList();
                final monthlyRevenue = selectedMonthPayments.fold<int>(
                    0, (sum, p) => sum + p.amount);
                final monthlyPaidCount = selectedMonthPayments.length;

                final selectedMonthExpenses = expenses.where((e) =>
                    e.date.year == _selectedYear &&
                    e.date.month == selectedMonthNumber).toList();
                final monthlyExpenses = selectedMonthExpenses.fold<int>(
                    0, (sum, e) => sum + e.amount);
                final netProfit = monthlyRevenue - monthlyExpenses;

                // Pending Dues
                final dueStudents = students.where((s) => s.hasDues).toList();
                final totalDues = dueStudents.fold<int>(
                    0, (sum, s) => sum + s.effectiveDues);
                final totalDuesCount = dueStudents.length;

                // Annual Metrics
                final annualPayments = payments.where((p) =>
                    p.date.year == _selectedYear).toList();
                final annualRevenue = annualPayments.fold<int>(
                    0, (sum, p) => sum + p.amount);
                final annualExpensesList = expenses.where((e) =>
                    e.date.year == _selectedYear).toList();
                final annualExpenses = annualExpensesList.fold<int>(
                    0, (sum, e) => sum + e.amount);
                final annualNetProfit = annualRevenue - annualExpenses;

                // 6-month dynamic trend window ending at current selected month
                int maxTrendVal = 1;
                final List<Map<String, dynamic>> trendData = [];

                for (int i = 5; i >= 0; i--) {
                  final targetDate = DateTime(_selectedYear, _selectedMonthIndex + 1 - i, 1);
                  final mRev = payments.where((p) =>
                      p.date.year == targetDate.year &&
                      p.date.month == targetDate.month).fold<int>(0, (sum, p) => sum + p.amount);
                  final mExp = expenses.where((e) =>
                      e.date.year == targetDate.year &&
                      e.date.month == targetDate.month).fold<int>(0, (sum, e) => sum + e.amount);

                  if (mRev > maxTrendVal) maxTrendVal = mRev;
                  if (mExp > maxTrendVal) maxTrendVal = mExp;

                  trendData.add({
                    'monthIndex': targetDate.month - 1,
                    'name': _months[targetDate.month - 1],
                    'revenue': mRev,
                    'expenses': mExp,
                  });
                }

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
                                accentText: '$monthlyPaidCount Collections (${_months[_selectedMonthIndex]})',
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
                                accentText: '${selectedMonthExpenses.length} Outflows (${_months[_selectedMonthIndex]})',
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
                                amount: '${netProfit >= 0 ? '' : '-'}₹${netProfit.abs()}',
                                accentText: netProfit >= 0 ? 'Monthly Gain' : 'Monthly Deficit',
                                accentColor: netProfit >= 0 ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
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
                                accentText: '$totalDuesCount Pending Student${totalDuesCount == 1 ? '' : 's'}',
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
                                accentText: 'Gross Income $_selectedYear',
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
                                accentText: 'Annual Spending $_selectedYear',
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
                                amount: '${annualNetProfit >= 0 ? '' : '-'}₹${annualNetProfit.abs()}',
                                accentText: annualNetProfit >= 0 ? 'Yearly Gain' : 'Yearly Deficit',
                                accentColor: annualNetProfit >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444),
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
                                        'Revenue vs Expenses for $_selectedYear',
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

                              // Dynamic Bar Chart with Real Data (Images 3 & 4)
                              SizedBox(
                                height: 128,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: trendData.map((item) {
                                    final mIdx = item['monthIndex'] as int;
                                    final mName = item['name'] as String;
                                    final mRev = item['revenue'] as int;
                                    final mExp = item['expenses'] as int;
                                    final isActive = mIdx == _selectedMonthIndex;

                                    final revHeight = maxTrendVal > 0
                                        ? ((mRev / maxTrendVal) * 72.0).clamp(6.0, 78.0)
                                        : 6.0;
                                    final expHeight = maxTrendVal > 0
                                        ? ((mExp / maxTrendVal) * 72.0).clamp(6.0, 78.0)
                                        : 6.0;

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(() => _selectedMonthIndex = mIdx),
                                      child: _trendBar(
                                        mName,
                                        revHeight,
                                        expHeight,
                                        isActive,
                                        revAmount: mRev,
                                        expAmount: mExp,
                                      ),
                                    );
                                  }).toList(),
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

                        // Revenue / Expense Breakdown Card (Image 4)
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
                              const SizedBox(height: 20),

                              if (_isIncomeSelected) ...[
                                // Breakdown by Payment Mode
                                _buildModeProgressRow(
                                  label: 'UPI / Digital Transfer',
                                  amount: selectedMonthPayments
                                      .where((p) => p.paymentMode.toLowerCase() == 'upi')
                                      .fold<int>(0, (s, p) => s + p.amount),
                                  total: monthlyRevenue,
                                  color: const Color(0xFF0F766E),
                                  icon: Icons.qr_code_rounded,
                                ),
                                const SizedBox(height: 12),
                                _buildModeProgressRow(
                                  label: 'Cash Collections',
                                  amount: selectedMonthPayments
                                      .where((p) => p.paymentMode.toLowerCase() == 'cash')
                                      .fold<int>(0, (s, p) => s + p.amount),
                                  total: monthlyRevenue,
                                  color: const Color(0xFF10B981),
                                  icon: Icons.payments_rounded,
                                ),
                              ] else ...[
                                // Breakdown by Expense Categories
                                if (selectedMonthExpenses.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'No expenses recorded for this month',
                                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                      ),
                                    ),
                                  )
                                else ...[
                                  _buildExpenseCategoryRow(
                                    category: 'Utility & Electricity',
                                    amount: selectedMonthExpenses
                                        .where((e) => e.category.toLowerCase().contains('util'))
                                        .fold<int>(0, (s, e) => s + e.amount),
                                    total: monthlyExpenses,
                                    color: const Color(0xFFF59E0B),
                                    icon: Icons.bolt_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildExpenseCategoryRow(
                                    category: 'Internet & Wi-Fi',
                                    amount: selectedMonthExpenses
                                        .where((e) => e.category.toLowerCase().contains('inter'))
                                        .fold<int>(0, (s, e) => s + e.amount),
                                    total: monthlyExpenses,
                                    color: const Color(0xFF3B82F6),
                                    icon: Icons.wifi_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildExpenseCategoryRow(
                                    category: 'Maintenance & Upkeep',
                                    amount: selectedMonthExpenses
                                        .where((e) => !e.category.toLowerCase().contains('util') &&
                                                      !e.category.toLowerCase().contains('inter'))
                                        .fold<int>(0, (s, e) => s + e.amount),
                                    total: monthlyExpenses,
                                    color: const Color(0xFFEC4899),
                                    icon: Icons.build_circle_rounded,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Latest Activity Card (Latest Payments or Latest Expenses)
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
                                    _isIncomeSelected ? 'Latest Payments' : 'Latest Expenses',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                  Icon(
                                    _isIncomeSelected ? Icons.receipt_long_outlined : Icons.account_balance_wallet_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isIncomeSelected) ...[
                                if (payments.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: Text(
                                        'No recent payment transactions',
                                        style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  )
                                else
                                  ...payments.take(5).map((p) => Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 16),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(p.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                    Text(
                                                      'Seat S-${p.seatNumber ?? "None"} • ${p.paymentMode} • ${DateFormat('dd MMM').format(p.date)}',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '+₹${p.amount}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF16A34A)),
                                            ),
                                          ],
                                        ),
                                      )),
                              ] else ...[
                                if (expenses.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: Text(
                                        'No logged expenses yet',
                                        style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  )
                                else
                                  ...expenses.take(5).map((e) => Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFF1F5F9)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 16),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                    Text(
                                                      '${e.category} • ${e.paymentMode} • ${DateFormat('dd MMM').format(e.date)}',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '-₹${e.amount}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFEF4444)),
                                            ),
                                          ],
                                        ),
                                      )),
                              ],
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
      },
    );
  }

  Widget _buildModeProgressRow({
    required String label,
    required int amount,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textNavy)),
              ],
            ),
            Text('₹$amount ($pctStr%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCategoryRow({
    required String category,
    required int amount,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textNavy)),
              ],
            ),
            Text('₹$amount ($pctStr%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
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
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Icon(icon, color: iconColor, size: 20)),
              ),
              const Icon(Icons.arrow_upward_rounded, color: Color(0xFF94A3B8), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
          ),
          const SizedBox(height: 4),
          Text(
            accentText,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _trendBar(
    String month,
    double revHeight,
    double expHeight,
    bool isActive, {
    int revAmount = 0,
    int expAmount = 0,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '₹$revAmount',
              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE6F4F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: isActive ? AppColors.primaryTeal : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
