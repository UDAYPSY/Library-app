import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _shareViaWhatsApp(String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  String _cleanCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _generatePaymentsCsv(List<PaymentTransaction> list) {
    final headers = ['Receipt ID', 'Date', 'Student Name', 'Phone', 'Seat #', 'Shift', 'Amount (INR)', 'Payment Mode', 'Notes'];
    final rows = list.map((p) => [
      p.id,
      DateFormat('dd-MM-yyyy').format(p.date),
      p.studentName,
      p.studentPhone,
      p.seatNumber != null ? 'S-${p.seatNumber}' : 'Unallocated',
      p.shift,
      '${p.amount}',
      p.paymentMode,
      p.notes,
    ].map(_cleanCsvField).join(',')).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generateExpensesCsv(List<ExpenseItem> list) {
    final headers = ['Expense ID', 'Date', 'Title', 'Category', 'Amount (INR)', 'Payment Mode', 'Notes'];
    final rows = list.map((e) => [
      e.id,
      DateFormat('dd-MM-yyyy').format(e.date),
      e.title,
      e.category,
      '${e.amount}',
      e.paymentMode,
      e.note,
    ].map(_cleanCsvField).join(',')).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generateAdmissionsCsv(List<StudentInfo> list) {
    final headers = ['Date Joined', 'Student Name', 'Phone', 'Seat #', 'Shift', 'Monthly Fee (INR)', 'Status'];
    final rows = list.map((s) => [
      s.joinedAt != null ? DateFormat('dd-MM-yyyy').format(s.joinedAt!) : 'N/A',
      s.name,
      s.phone,
      s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated',
      s.shift,
      '${s.monthlyFee}',
      s.status,
    ].map(_cleanCsvField).join(',')).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generateAllStudentsCsv(List<StudentInfo> list) {
    final headers = ['Student ID', 'Full Name', 'Phone', 'Seat Number', 'Shift', 'Status', 'Monthly Fee (INR)', 'Pending Dues (INR)', 'Joining Date', 'Father Name', 'Address', 'Aadhaar'];
    final rows = list.map((s) => [
      s.id,
      s.name,
      s.phone,
      s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated',
      s.shift,
      s.status,
      '${s.monthlyFee}',
      '${s.effectiveDues}',
      s.joinedAt != null ? DateFormat('dd-MM-yyyy').format(s.joinedAt!) : 'N/A',
      s.fatherName,
      s.address,
      s.aadhaarNumber,
    ].map(_cleanCsvField).join(',')).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  void _showPreviewTable(String title, List<String> headers, List<List<String>> rows) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$title Preview (${rows.length} rows)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textNavy)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No rows in this period.', style: TextStyle(color: Color(0xFF64748B)))),
              )
            else
              SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)))).toList(),
                      rows: rows.map((r) => DataRow(
                        cells: r.map((c) => DataCell(Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                      )).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _exportCategory({
    required String categoryName,
    required int rowCount,
    required String csvData,
    required List<String> headers,
    required List<List<String>> previewRows,
    required String summaryText,
  }) {
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
            const SizedBox(height: 4),
            Text(
              'Period: ${DateFormat('MMMM yyyy').format(_selectedMonth)} • $rowCount rows ready',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Option 1: Copy CSV Data
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.table_view_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('Copy CSV / Excel Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Copies complete comma-separated data to clipboard to paste into Excel or Sheets', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: csvData));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$categoryName CSV ($rowCount rows) copied to clipboard! Ready to paste into Excel.'),
                    backgroundColor: const Color(0xFF0D6E66),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Option 2: View In-App Table
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.visibility_outlined, color: Color(0xFF0284C7)),
              ),
              title: const Text('Preview Data Table', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Browse formatted rows and columns directly inside the app', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _showPreviewTable(categoryName, headers, previewRows);
              },
            ),

            // Option 3: Share via WhatsApp
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.share_outlined, color: Color(0xFF10B981)),
              ),
              title: const Text('Share Summary to WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Directly send export summary report to administration', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _shareViaWhatsApp(summaryText);
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
                  final payments = paymentSnap.data ?? _service.currentPayments;
                  final expenses = expenseSnap.data ?? [];
                  final students = studentSnap.data ?? _service.currentStudents;

                  // Filter by month
                  final monthPayments = payments.where((p) =>
                      p.date.year == _selectedMonth.year &&
                      p.date.month == _selectedMonth.month).toList();
                  final monthExpenses = expenses.where((e) =>
                      e.date.year == _selectedMonth.year &&
                      e.date.month == _selectedMonth.month).toList();
                  final monthStudents = students.where((s) =>
                      s.joinedAt != null &&
                      s.joinedAt!.year == _selectedMonth.year &&
                      s.joinedAt!.month == _selectedMonth.month).toList();

                  final collectedAmount = monthPayments.fold<int>(0, (sum, p) => sum + p.amount);
                  final paymentsCount = monthPayments.length;

                  final expenseAmount = monthExpenses.fold<int>(0, (sum, e) => sum + e.amount);
                  final expenseCount = monthExpenses.length;

                  final net = collectedAmount - expenseAmount;
                  final newAdmissionsCount = monthStudents.length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: MONTHLY REPORT
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

                        // Month Picker Card
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

                        // 2x2 Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                label: 'COLLECTED',
                                value: '₹$collectedAmount',
                                valueColor: const Color(0xFF16A34A),
                                subtitle: '$paymentsCount payments',
                              ),
                            ),
                            const SizedBox(width: 12),
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
                            Expanded(
                              child: _metricCard(
                                label: 'NET',
                                value: '${net < 0 ? "-" : "+"}₹${net.abs()}',
                                valueColor: net < 0 ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                                subtitle: net < 0 ? 'loss' : 'profit',
                              ),
                            ),
                            const SizedBox(width: 12),
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

                        // Monthly Export Category Rows Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            children: [
                              // Payments
                              _exportListRow(
                                icon: Icons.account_balance_wallet_outlined,
                                iconBg: const Color(0xFFECFDF5),
                                iconColor: const Color(0xFF10B981),
                                title: 'Payments Report',
                                subtitle: '$paymentsCount payments in $monthStr (₹$collectedAmount)',
                                onDownload: () {
                                  final csv = _generatePaymentsCsv(monthPayments);
                                  final headers = ['Receipt', 'Date', 'Student', 'Phone', 'Seat', 'Shift', 'Amount', 'Mode', 'Notes'];
                                  final previewRows = monthPayments.map((p) => [
                                    p.id,
                                    DateFormat('dd-MM-yy').format(p.date),
                                    p.studentName,
                                    p.studentPhone,
                                    p.seatNumber != null ? 'S-${p.seatNumber}' : 'Unallocated',
                                    p.shift,
                                    '₹${p.amount}',
                                    p.paymentMode,
                                    p.notes,
                                  ]).toList();
                                  final summary = '${_service.profile.libraryName} - Payments Report ($monthStr)\nTotal Collected: ₹$collectedAmount across $paymentsCount transactions.';
                                  _exportCategory(
                                    categoryName: 'Payments ($monthStr)',
                                    rowCount: paymentsCount,
                                    csvData: csv,
                                    headers: headers,
                                    previewRows: previewRows,
                                    summaryText: summary,
                                  );
                                },
                              ),
                              const Divider(height: 1),

                              // Expenses
                              _exportListRow(
                                icon: Icons.receipt_long_outlined,
                                iconBg: const Color(0xFFFFFBEB),
                                iconColor: const Color(0xFFF59E0B),
                                title: 'Expenses Report',
                                subtitle: '$expenseCount entries in $monthStr (₹$expenseAmount)',
                                onDownload: () {
                                  final csv = _generateExpensesCsv(monthExpenses);
                                  final headers = ['ID', 'Date', 'Title', 'Category', 'Amount', 'Mode', 'Note'];
                                  final previewRows = monthExpenses.map((e) => [
                                    e.id,
                                    DateFormat('dd-MM-yy').format(e.date),
                                    e.title,
                                    e.category,
                                    '₹${e.amount}',
                                    e.paymentMode,
                                    e.note,
                                  ]).toList();
                                  final summary = '${_service.profile.libraryName} - Expenses Report ($monthStr)\nTotal Expenses: ₹$expenseAmount across $expenseCount entries.';
                                  _exportCategory(
                                    categoryName: 'Expenses ($monthStr)',
                                    rowCount: expenseCount,
                                    csvData: csv,
                                    headers: headers,
                                    previewRows: previewRows,
                                    summaryText: summary,
                                  );
                                },
                              ),
                              const Divider(height: 1),

                              // New Admissions
                              _exportListRow(
                                icon: Icons.person_add_outlined,
                                iconBg: const Color(0xFFF0F9FF),
                                iconColor: const Color(0xFF0284C7),
                                title: 'New Admissions',
                                subtitle: '$newAdmissionsCount students joined in $monthStr',
                                onDownload: () {
                                  final csv = _generateAdmissionsCsv(monthStudents);
                                  final headers = ['Joined', 'Name', 'Phone', 'Seat', 'Shift', 'Monthly', 'Status'];
                                  final previewRows = monthStudents.map((s) => [
                                    s.joinedAt != null ? DateFormat('dd-MM-yy').format(s.joinedAt!) : 'N/A',
                                    s.name,
                                    s.phone,
                                    s.seatNumber != null ? 'S-${s.seatNumber}' : 'None',
                                    s.shift,
                                    '₹${s.monthlyFee}',
                                    s.status,
                                  ]).toList();
                                  final summary = '${_service.profile.libraryName} - New Admissions ($monthStr)\nTotal Admissions: $newAdmissionsCount students.';
                                  _exportCategory(
                                    categoryName: 'New Admissions ($monthStr)',
                                    rowCount: newAdmissionsCount,
                                    csvData: csv,
                                    headers: headers,
                                    previewRows: previewRows,
                                    summaryText: summary,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // FULL DATA Section
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
                            title: 'All Students Roster',
                            subtitle: 'Complete library roster (${students.length} students enrolled)',
                            onDownload: () {
                              final csv = _generateAllStudentsCsv(students);
                              final headers = ['ID', 'Name', 'Phone', 'Seat', 'Shift', 'Status', 'Monthly', 'Dues', 'Joined'];
                              final previewRows = students.map((s) => [
                                s.id,
                                s.name,
                                s.phone,
                                s.seatNumber != null ? 'S-${s.seatNumber}' : 'None',
                                s.shift,
                                s.status,
                                '₹${s.monthlyFee}',
                                '₹${s.effectiveDues}',
                                s.joinedAt != null ? DateFormat('dd-MM-yy').format(s.joinedAt!) : 'N/A',
                              ]).toList();
                              final summary = '${_service.profile.libraryName} - Full Student Roster\nTotal Students: ${students.length}';
                              _exportCategory(
                                categoryName: 'Complete Student Roster',
                                rowCount: students.length,
                                csvData: csv,
                                headers: headers,
                                previewRows: previewRows,
                                summaryText: summary,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer Note
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Files open in Excel or Google Sheets. Copy to clipboard or share directly to WhatsApp or Drive.',
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
