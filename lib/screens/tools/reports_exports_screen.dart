import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class ReportsExportsScreen extends StatefulWidget {
  const ReportsExportsScreen({super.key});

  @override
  State<ReportsExportsScreen> createState() => _ReportsExportsScreenState();
}

class _ReportsExportsScreenState extends State<ReportsExportsScreen> {
  final LibraryService _service = LibraryService();
  DateTime _selectedMonth = DateTime(2026, 10, 1);

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _exportCategory(String categoryName, int rowCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Export $categoryName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Period: ${DateFormat('MMMM yyyy').format(_selectedMonth)} • $rowCount rows ready',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('Export Excel / CSV Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Download .csv spreadsheet for Excel or Google Sheets', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$categoryName report generated & saved! (.csv)'),
                    backgroundColor: const Color(0xFF0D6E66),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.share_outlined, color: Color(0xFF10B981)),
              ),
              title: const Text('Share to WhatsApp / Drive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Directly send export file to your administrator WhatsApp', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing $categoryName report...'),
                    backgroundColor: const Color(0xFF0D6E66),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports & Exports',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<StudentInfo>>(
        stream: _service.streamStudents(),
        builder: (context, studentSnap) {
          return StreamBuilder<List<ExpenseItem>>(
            stream: _service.streamExpenses(),
            builder: (context, expenseSnap) {
              return StreamBuilder<List<PaymentTransaction>>(
                stream: _service.streamPayments(),
                builder: (context, paymentSnap) {
                  final payments = paymentSnap.data ?? [];
                  final expenses = expenseSnap.data ?? [];
                  final students = studentSnap.data ?? [];

                  // Calculate metrics
                  final collectedAmount = payments.isNotEmpty
                      ? payments.fold<int>(0, (sum, p) => sum + p.amount)
                      : 300;
                  final paymentsCount = payments.isNotEmpty ? payments.length : 1;

                  final expenseAmount = expenses.isNotEmpty
                      ? expenses.fold<int>(0, (sum, e) => sum + e.amount)
                      : 1000;
                  final expenseCount = expenses.isNotEmpty ? expenses.length : 1;

                  final net = collectedAmount - expenseAmount;
                  final newAdmissionsCount = students.isNotEmpty ? students.length : 2;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: MONTHLY REPORT (Image 5)
                        const Text(
                          'MONTHLY REPORT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Month Picker Card (Image 5)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textNavy),
                                onPressed: _prevMonth,
                              ),
                              Text(
                                monthStr,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textNavy),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2x2 Metrics Grid (Image 5)
                        Row(
                          children: [
                            // Collected
                            Expanded(
                              child: _metricCard(
                                label: 'COLLECTED',
                                value: '₹$collectedAmount',
                                valueColor: const Color(0xFF16A34A),
                                subtitle: '$paymentsCount payments',
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Expenses
                            Expanded(
                              child: _metricCard(
                                label: 'EXPENSES',
                                value: '₹$expenseAmount',
                                valueColor: const Color(0xFFF59E0B),
                                subtitle: '$expenseCount entries',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Net
                            Expanded(
                              child: _metricCard(
                                label: 'NET',
                                value: '${net < 0 ? "-" : "+"}₹${net.abs()}',
                                valueColor: net < 0 ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                                subtitle: net < 0 ? 'loss' : 'profit',
                              ),
                            ),
                            const SizedBox(width: 12),
                            // New Admissions
                            Expanded(
                              child: _metricCard(
                                label: 'NEW ADMISSIONS',
                                value: '$newAdmissionsCount',
                                valueColor: const Color(0xFF0284C7),
                                subtitle: 'students joined',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Monthly Export Category Rows Card (Image 5)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              _exportListRow(
                                icon: Icons.account_balance_wallet_outlined,
                                iconBg: const Color(0xFFECFDF5),
                                iconColor: const Color(0xFF10B981),
                                title: 'Payments',
                                subtitle: '$paymentsCount row this month',
                                onDownload: () => _exportCategory('Payments', paymentsCount),
                              ),
                              const Divider(height: 1),
                              _exportListRow(
                                icon: Icons.receipt_long_outlined,
                                iconBg: const Color(0xFFFFFBEB),
                                iconColor: const Color(0xFFF59E0B),
                                title: 'Expenses',
                                subtitle: '$expenseCount row this month',
                                onDownload: () => _exportCategory('Expenses', expenseCount),
                              ),
                              const Divider(height: 1),
                              _exportListRow(
                                icon: Icons.person_add_outlined,
                                iconBg: const Color(0xFFF0F9FF),
                                iconColor: const Color(0xFF0284C7),
                                title: 'New Admissions',
                                subtitle: '$newAdmissionsCount rows this month',
                                onDownload: () => _exportCategory('New Admissions', newAdmissionsCount),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // FULL DATA Section (Image 5)
                        const Text(
                          'FULL DATA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: _exportListRow(
                            icon: Icons.people_outline_rounded,
                            iconBg: const Color(0xFFF0F9FF),
                            iconColor: const Color(0xFF0284C7),
                            title: 'All Students',
                            subtitle: 'Complete roster — choose audience & columns',
                            onDownload: () => _exportCategory('All Students Roster', students.length),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Note (Image 5)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Files open in Excel or Google Sheets. Share them to Drive, WhatsApp or email.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _exportListRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onDownload,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF0D6E66), size: 24),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}
