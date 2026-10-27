import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../../services/file_export_service.dart';
import '../../services/excel_import_service.dart';

class ReportsExportsScreen extends StatefulWidget {
  const ReportsExportsScreen({super.key});

  @override
  State<ReportsExportsScreen> createState() => _ReportsExportsScreenState();
}

class _ReportsExportsScreenState extends State<ReportsExportsScreen> {
  final LibraryService _service = LibraryService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _selectedTab = 0; // 0: Monthly Financials, 1: Student Tenure, 2: Payment Analysis, 3: Shift & Capacity, 4: Fee Dues

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

  Future<void> _shareViaWhatsApp(String text, {String? phone}) async {
    final phoneClean = phone != null ? LibraryService.normalizePhone(phone) : '';
    if (phoneClean.isNotEmpty && phoneClean.length >= 10) {
      final ok = await LibraryService.sendWhatsAppDirect(phone: phoneClean, message: text);
      if (!ok) {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report copied to clipboard! Ready to paste into WhatsApp.'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } else {
      final encoded = Uri.encodeComponent(text);
      final uri = Uri.parse('https://wa.me/?text=$encoded');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report copied to clipboard!'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
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

  String _generateTenureCsv(List<StudentInfo> list, List<PaymentTransaction> allPayments) {
    final headers = [
      'Student Name',
      'Phone',
      'Seat Number',
      'Shift',
      'Joined Date',
      'Study Duration (Months)',
      'Tenure Category',
      'Total Fees Paid (INR)',
      'Monthly Fee (INR)',
      'Pending Dues (INR)',
      'Status'
    ];
    final now = DateTime.now();
    final rows = list.map((s) {
      final joined = s.joinedAt;
      final months = joined != null
          ? ((now.year - joined.year) * 12 + now.month - joined.month).clamp(0, 120)
          : 1;
      final String category;
      if (months < 1) {
        category = 'New (< 1 Month)';
      } else if (months <= 3) {
        category = 'Recent (1-3 Months)';
      } else if (months <= 6) {
        category = 'Established (3-6 Months)';
      } else if (months <= 12) {
        category = 'Long-Term (6-12 Months)';
      } else {
        category = 'Veteran (> 1 Year)';
      }
      final sPhoneNorm = LibraryService.normalizePhone(s.phone);
      final totalPaid = allPayments.where((p) {
        if (p.studentId.isNotEmpty) return p.studentId == s.id;
        if (sPhoneNorm.isNotEmpty && p.studentPhone.isNotEmpty && LibraryService.normalizePhone(p.studentPhone) == sPhoneNorm) return true;
        return false;
      }).fold<int>(0, (sum, p) => sum + p.amount);

      return [
        s.name,
        s.phone,
        s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated',
        s.shift,
        joined != null ? DateFormat('dd-MM-yyyy').format(joined) : 'N/A',
        '$months',
        category,
        '$totalPaid',
        '${s.monthlyFee}',
        '${s.effectiveDues}',
        s.status,
      ].map(_cleanCsvField).join(',');
    }).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generateShiftOccupancyCsv(List<StudentInfo> students, int totalSeats) {
    final headers = ['Shift Name', 'Enrolled Students', 'Total Seat Capacity', 'Occupancy Rate (%)'];
    final activeStudents = students.where((s) => s.status != 'INACTIVE').toList();
    final shifts = ['Full Day', 'Morning Shift', 'Evening Shift', 'Night Shift'];

    final rows = shifts.map((sh) {
      final count = activeStudents.where((s) => LibraryService.doShiftsConflict(s.shift, sh)).length;
      final rate = totalSeats > 0 ? ((count / totalSeats) * 100).toStringAsFixed(1) : '0.0';
      return [
        sh,
        '$count',
        '$totalSeats',
        '$rate%',
      ].map(_cleanCsvField).join(',');
    }).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generatePaymentModeCsv(List<PaymentTransaction> payments) {
    final headers = ['Payment Mode', 'Transactions Count', 'Total Amount (INR)', 'Revenue Share (%)'];
    final totalAll = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final modes = ['UPI', 'Cash', 'Card', 'Bank Transfer'];

    final rows = modes.map((m) {
      final modePayments = payments.where((p) => p.paymentMode.toUpperCase().contains(m.toUpperCase())).toList();
      final sum = modePayments.fold<int>(0, (s, p) => s + p.amount);
      final pct = totalAll > 0 ? ((sum / totalAll) * 100).toStringAsFixed(1) : '0.0';
      return [
        m,
        '${modePayments.length}',
        '$sum',
        '$pct%',
      ].map(_cleanCsvField).join(',');
    }).join('\n');
    return '${headers.join(',')}\n$rows';
  }

  String _generateDefaultersCsv(List<StudentInfo> list) {
    final headers = ['Student Name', 'Phone', 'Seat #', 'Shift', 'Pending Dues (INR)', 'Monthly Fee (INR)', 'Joined Date', 'Status'];
    final defaulters = list.where((s) => s.status != 'INACTIVE' && (s.hasDues || s.effectiveDues > 0)).toList();
    final rows = defaulters.map((s) => [
      s.name,
      s.phone,
      s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated',
      s.shift,
      '${s.effectiveDues}',
      '${s.monthlyFee}',
      s.joinedAt != null ? DateFormat('dd-MM-yyyy').format(s.joinedAt!) : 'N/A',
      s.status,
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
                Expanded(
                  child: Text(
                    '$title Preview (${rows.length} rows)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textNavy),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No data found for this report.', style: TextStyle(color: Color(0xFF64748B)))),
              )
            else
              SizedBox(
                height: 340,
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

  String _generateMasterBackupCsv({
    required List<StudentInfo> students,
    required List<PaymentTransaction> payments,
    required List<ExpenseItem> expenses,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# ==========================================');
    buffer.writeln('# ${_service.profile.libraryName.toUpperCase()} - MASTER DATABASE BACKUP');
    buffer.writeln('# Exported: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('# City: ${_service.profile.city} | Helpline: ${_service.profile.adminPhone}');
    buffer.writeln('# Capacity: ${_service.totalSeatsCount} Seats Total');
    buffer.writeln('# ==========================================\n');

    buffer.writeln('### SECTION 1: ALL ENROLLED STUDENTS ###');
    buffer.writeln(_generateAllStudentsCsv(students));
    buffer.writeln('\n### SECTION 2: PAYMENT & FEE COLLECTION LEDGER ###');
    buffer.writeln(_generatePaymentsCsv(payments));
    buffer.writeln('\n### SECTION 3: OPERATING EXPENSES ###');
    buffer.writeln(_generateExpensesCsv(expenses));

    return buffer.toString();
  }

  void _openBulkImportSheet() {
    final inputCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.table_chart_rounded, color: Color(0xFF0D6E66)),
                      SizedBox(width: 8),
                      Text(
                        'Bulk Import Students',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste rows directly from Microsoft Excel or Google Sheets (Name, Phone, Shift, SeatNumber, MonthlyFee):',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6E66),
                  side: const BorderSide(color: Color(0xFF0D6E66)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Download Excel Template (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final template = ExcelImportService.generateTemplateCsv();
                  await FileExportService.download(fileName: 'student_import_template.csv', content: template);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Excel Template downloaded! Open in Microsoft Excel.'),
                        backgroundColor: Color(0xFF0D6E66),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inputCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Aarav Sharma, 9876543210, Full Day, 1, 800\nPriya Singh, 9812345678, Morning, 2, 500\nRohan Verma, 9988776655, Evening, , 500',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6E66),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Parse & Import Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () {
                    final text = inputCtrl.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please paste some rows from your Excel sheet.')),
                      );
                      return;
                    }
                    final result = ExcelImportService.parseAndImport(text, _service);
                    Navigator.pop(ctx);
                    setState(() {});
                    _showImportSummaryDialog(result);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportSummaryDialog(ExcelImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              result.successfullyImported > 0 ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: result.successfullyImported > 0 ? const Color(0xFF10B981) : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Import Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Successfully Imported: ${result.successfullyImported} students', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
            if (result.skippedRows > 0)
              Text('⚠️ Skipped Rows: ${result.skippedRows}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
            const SizedBox(height: 10),
            if (result.warnings.isNotEmpty) ...[
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...result.warnings.take(4).map((w) => Text('• $w', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
            ],
            if (result.errorMessages.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
              ...result.errorMessages.take(4).map((e) => Text('• $e', style: const TextStyle(fontSize: 11, color: Colors.red))),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6E66),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
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
    final cleanCategorySlug = categoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final fileName = '${cleanCategorySlug}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

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
                Expanded(
                  child: Text(
                    'Export $categoryName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$rowCount rows ready for export or preview',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Option 1: Native File Download
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.download_rounded, color: Color(0xFF0D9488)),
              ),
              title: const Text('Download Excel / CSV File (.csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D6E66))),
              subtitle: Text('Directly downloads $fileName to your device for Microsoft Excel', style: const TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final success = await FileExportService.download(fileName: fileName, content: csvData);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '$categoryName (.csv) downloaded successfully!' : 'File exported and saved!'),
                      backgroundColor: const Color(0xFF0D6E66),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),

            // Option 2: Copy Tab-Separated Data for Direct Excel Paste
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.content_paste_go_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('Copy Formatted Data for Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Copies tab-separated data to paste directly into Excel columns without import wizard', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                final tsvData = '${headers.join('\t')}\n${previewRows.map((r) => r.join('\t')).join('\n')}';
                Clipboard.setData(ClipboardData(text: tsvData));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$categoryName TSV ($rowCount rows) copied! Paste directly into Excel.'),
                    backgroundColor: const Color(0xFF0D6E66),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Option 3: View In-App Table
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

            // Option 4: Share via WhatsApp
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

  Widget _buildNavTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [const BoxShadow(color: Color(0x180D9488), blurRadius: 6, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Reports & Analytics Hub',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavTab(0, 'Monthly Report', Icons.calendar_month_rounded),
                  const SizedBox(width: 8),
                  _buildNavTab(1, 'Student Tenure (Months)', Icons.history_edu_rounded),
                  const SizedBox(width: 8),
                  _buildNavTab(2, 'Payment Analysis', Icons.pie_chart_rounded),
                  const SizedBox(width: 8),
                  _buildNavTab(3, 'Shift Occupancy', Icons.group_work_rounded),
                  const SizedBox(width: 8),
                  _buildNavTab(4, 'Fee Dues & Defaulters', Icons.warning_amber_rounded),
                ],
              ),
            ),
          ),
        ),
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

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // EXCEL-FIRST DATA HUB CARD (Always present at top)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.35)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.hub_rounded, color: Color(0xFF2DD4BF), size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'LIBRARY DATA HUB & BACKUP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'EXCEL READY',
                                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Manage complete library database with speed and reliability, and 100% offline Excel portability.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D9488),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.download_for_offline_rounded, size: 17),
                                      label: const Text(
                                        'Master Excel Backup',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () async {
                                        final masterCsv = _generateMasterBackupCsv(
                                          students: students,
                                          payments: payments,
                                          expenses: expenses,
                                        );
                                        final fileName = 'library_master_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
                                        final ok = await FileExportService.download(fileName: fileName, content: masterCsv);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(ok ? 'Master Excel Backup downloaded! Contains students, ledger & seats.' : 'Backup generated!'),
                                              backgroundColor: const Color(0xFF0D6E66),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFF334155)),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.file_upload_outlined, size: 17, color: Color(0xFF38BDF8)),
                                      label: const Text(
                                        'Bulk Excel Import',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: _openBulkImportSheet,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Render Tab Content
                        if (_selectedTab == 0)
                          _buildMonthlyReportTab(students, payments, expenses)
                        else if (_selectedTab == 1)
                          _buildStudentTenureTab(students, payments)
                        else if (_selectedTab == 2)
                          _buildPaymentAnalysisTab(payments)
                        else if (_selectedTab == 3)
                          _buildShiftOccupancyTab(students)
                        else if (_selectedTab == 4)
                          _buildFeeDuesTab(students),

                        const SizedBox(height: 24),
                        // Footer Note
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'All reports can be downloaded in .CSV format or copied directly into Microsoft Excel & Google Sheets. Click on any report to preview data table or share via WhatsApp.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
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

  // TAB 0: MONTHLY REPORT
  Widget _buildMonthlyReportTab(
    List<StudentInfo> students,
    List<PaymentTransaction> payments,
    List<ExpenseItem> expenses,
  ) {
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MONTHLY FINANCIAL OVERVIEW',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        // Month Picker Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textNavy),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
                label: 'NET BALANCE',
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
        const SizedBox(height: 20),

        // Export Categories Card
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
                title: 'Payments Report ($monthStr)',
                subtitle: '$paymentsCount payments recorded • Total ₹$collectedAmount',
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
              _exportListRow(
                icon: Icons.receipt_long_outlined,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
                title: 'Expenses Report ($monthStr)',
                subtitle: '$expenseCount entries recorded • Total ₹$expenseAmount',
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
              _exportListRow(
                icon: Icons.person_add_outlined,
                iconBg: const Color(0xFFF0F9FF),
                iconColor: const Color(0xFF0284C7),
                title: 'New Admissions ($monthStr)',
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
              const Divider(height: 1),
              _exportListRow(
                icon: Icons.people_outline_rounded,
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF8B5CF6),
                title: 'Complete Student Roster',
                subtitle: 'All ${students.length} students enrolled in library',
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
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: STUDENT TENURE & DURATION ANALYSIS (How many months students study)
  Widget _buildStudentTenureTab(List<StudentInfo> students, List<PaymentTransaction> payments) {
    final activeStudents = students.where((s) => s.status != 'INACTIVE').toList();
    final now = DateTime.now();

    final tenureList = activeStudents.map((s) {
      final joined = s.joinedAt ?? now;
      final months = ((now.year - joined.year) * 12 + (now.month - joined.month)).clamp(0, 120);
      final days = now.difference(joined).inDays.clamp(0, 99999);
      final sPhoneNorm = LibraryService.normalizePhone(s.phone);

      final totalPaid = payments.where((p) {
        if (p.studentId.isNotEmpty) return p.studentId == s.id;
        if (sPhoneNorm.isNotEmpty && p.studentPhone.isNotEmpty && LibraryService.normalizePhone(p.studentPhone) == sPhoneNorm) return true;
        return false;
      }).fold<int>(0, (sum, p) => sum + p.amount);

      return (
        student: s,
        months: months,
        days: days,
        totalPaid: totalPaid,
      );
    }).toList();

    tenureList.sort((a, b) => b.months.compareTo(a.months));

    final totalStudents = tenureList.length;
    final avgMonths = totalStudents > 0
        ? (tenureList.fold<int>(0, (sum, t) => sum + t.months) / totalStudents).toStringAsFixed(1)
        : '0.0';

    final longest = tenureList.isNotEmpty ? tenureList.first : null;
    final under1m = tenureList.where((t) => t.months < 1).length;
    final m1to3 = tenureList.where((t) => t.months >= 1 && t.months < 3).length;
    final m3to6 = tenureList.where((t) => t.months >= 3 && t.months < 6).length;
    final m6to12 = tenureList.where((t) => t.months >= 6 && t.months < 12).length;
    final over12m = tenureList.where((t) => t.months >= 12).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STUDENT STUDY DURATION & TENURE ANALYSIS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Detailed analysis of how many months students have been studying in your library and their fee contribution.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'AVERAGE TENURE',
                value: '$avgMonths Mo',
                valueColor: const Color(0xFF0D9488),
                subtitle: 'mean study duration',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'LONGEST ENROLLED',
                value: '${longest?.months ?? 0} Mo',
                valueColor: const Color(0xFF8B5CF6),
                subtitle: longest != null ? longest.student.name.split(' ').first : 'None',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'NEW JOINERS (<1M)',
                value: '$under1m Students',
                valueColor: const Color(0xFF0284C7),
                subtitle: 'last 30 days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'LONG-TERM (6M+)',
                value: '${m6to12 + over12m} Students',
                valueColor: const Color(0xFF16A34A),
                subtitle: 'veteran members',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tenure Distribution Card with Progress Bars
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Color(0xFF0D9488), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Study Duration Buckets',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                label: '< 1 Month (New Admissions)',
                count: under1m,
                total: totalStudents,
                barColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: '1 – 3 Months (Recent)',
                count: m1to3,
                total: totalStudents,
                barColor: const Color(0xFF0D9488),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: '3 – 6 Months (Established)',
                count: m3to6,
                total: totalStudents,
                barColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: '6 – 12 Months (Long-Term)',
                count: m6to12,
                total: totalStudents,
                barColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: '> 1 Year (Veterans & Alumni)',
                count: over12m,
                total: totalStudents,
                barColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Export & Preview Action Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: _exportListRow(
            icon: Icons.history_edu_rounded,
            iconBg: const Color(0xFFF0FDFA),
            iconColor: const Color(0xFF0D9488),
            title: 'Student Tenure & Duration Report',
            subtitle: 'Export individual study duration (in months) and total fees paid for all $totalStudents students',
            onDownload: () {
              final csv = _generateTenureCsv(activeStudents, payments);
              final headers = ['Name', 'Phone', 'Seat', 'Shift', 'Joined', 'Months', 'Category', 'Total Paid', 'Status'];
              final previewRows = tenureList.map((t) => [
                t.student.name,
                t.student.phone,
                t.student.seatNumber != null ? 'S-${t.student.seatNumber}' : 'None',
                t.student.shift,
                t.student.joinedAt != null ? DateFormat('dd-MM-yy').format(t.student.joinedAt!) : 'N/A',
                '${t.months} mo',
                t.months < 1 ? '<1 Mo' : (t.months <= 3 ? '1-3 Mo' : (t.months <= 6 ? '3-6 Mo' : (t.months <= 12 ? '6-12 Mo' : '>1 Yr'))),
                '₹${t.totalPaid}',
                t.student.status,
              ]).toList();
              final summary = '${_service.profile.libraryName} - Student Tenure Report\n'
                  'Total Active Students: $totalStudents\n'
                  'Average Study Duration: $avgMonths Months\n'
                  'Studying >6 Months: ${m6to12 + over12m} students\n'
                  'New (<1 Month): $under1m students';
              _exportCategory(
                categoryName: 'Student Tenure & Study Duration',
                rowCount: totalStudents,
                csvData: csv,
                headers: headers,
                previewRows: previewRows,
                summaryText: summary,
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Top Longest-Standing Students List
        const Text(
          'LONGEST-STUDYING MEMBERS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              ...tenureList.take(5).map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${t.months}m',
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.w900,
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
                              t.student.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy),
                            ),
                            Text(
                              'Seat S-${t.student.seatNumber ?? "None"} • ${t.student.shift} • Joined ${t.student.joinedAt != null ? DateFormat("MMM yyyy").format(t.student.joinedAt!) : "N/A"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          '₹${t.totalPaid}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 2: PAYMENT & REVENUE ANALYSIS (Modes, UPI vs Cash, Averages)
  Widget _buildPaymentAnalysisTab(List<PaymentTransaction> payments) {
    final allTimeCollected = payments.fold<int>(0, (sum, p) => sum + p.amount);

    final upiList = payments.where((p) => p.paymentMode.toUpperCase().contains('UPI')).toList();
    final upiTotal = upiList.fold<int>(0, (sum, p) => sum + p.amount);
    final upiPct = allTimeCollected > 0 ? ((upiTotal / allTimeCollected) * 100).toStringAsFixed(1) : '0.0';

    final cashList = payments.where((p) => p.paymentMode.toUpperCase().contains('CASH')).toList();
    final cashTotal = cashList.fold<int>(0, (sum, p) => sum + p.amount);
    final cashPct = allTimeCollected > 0 ? ((cashTotal / allTimeCollected) * 100).toStringAsFixed(1) : '0.0';

    final otherList = payments.where((p) =>
        !p.paymentMode.toUpperCase().contains('UPI') &&
        !p.paymentMode.toUpperCase().contains('CASH')).toList();
    final otherTotal = otherList.fold<int>(0, (sum, p) => sum + p.amount);
    final otherPct = allTimeCollected > 0 ? ((otherTotal / allTimeCollected) * 100).toStringAsFixed(1) : '0.0';

    final avgTicket = payments.isNotEmpty ? (allTimeCollected / payments.length).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT MODES & REVENUE BREAKDOWN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Analyze collection split across digital UPI, cash, cards, and payment ticket size.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'TOTAL REVENUE',
                value: '₹$allTimeCollected',
                valueColor: const Color(0xFF16A34A),
                subtitle: '${payments.length} payments recorded',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'UPI SHARE',
                value: '$upiPct%',
                valueColor: const Color(0xFF0284C7),
                subtitle: '₹$upiTotal collected',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'CASH SHARE',
                value: '$cashPct%',
                valueColor: const Color(0xFF0D9488),
                subtitle: '₹$cashTotal collected',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'AVERAGE PAYMENT',
                value: '₹$avgTicket',
                valueColor: const Color(0xFFF59E0B),
                subtitle: 'average ticket size',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Payment Mode Share Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF0D9488), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Revenue by Payment Mode',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                label: 'Digital UPI Payments',
                count: upiTotal,
                total: allTimeCollected,
                barColor: const Color(0xFF0284C7),
                suffixText: '₹$upiTotal (${upiList.length} txns)',
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: 'Cash In Hand',
                count: cashTotal,
                total: allTimeCollected,
                barColor: const Color(0xFF10B981),
                suffixText: '₹$cashTotal (${cashList.length} txns)',
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: 'Card & Bank Transfers',
                count: otherTotal,
                total: allTimeCollected,
                barColor: const Color(0xFF8B5CF6),
                suffixText: '₹$otherTotal (${otherList.length} txns)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Export Category
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: _exportListRow(
            icon: Icons.payments_outlined,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: 'Payment Modes Analytics Report',
            subtitle: 'Download revenue summary, transaction counts, and shares across payment modes',
            onDownload: () {
              final csv = _generatePaymentModeCsv(payments);
              final headers = ['Mode', 'Transactions', 'Total (INR)', 'Share (%)'];
              final previewRows = [
                ['UPI', '${upiList.length}', '₹$upiTotal', '$upiPct%'],
                ['Cash', '${cashList.length}', '₹$cashTotal', '$cashPct%'],
                ['Card & Bank', '${otherList.length}', '₹$otherTotal', '$otherPct%'],
              ];
              final summary = '${_service.profile.libraryName} - Payment Mode Analytics\n'
                  'Total Revenue: ₹$allTimeCollected (${payments.length} txns)\n'
                  'UPI Share: $upiPct% (₹$upiTotal)\n'
                  'Cash Share: $cashPct% (₹$cashTotal)\n'
                  'Card/Bank Share: $otherPct% (₹$otherTotal)';
              _exportCategory(
                categoryName: 'Payment Modes Analysis',
                rowCount: previewRows.length,
                csvData: csv,
                headers: headers,
                previewRows: previewRows,
                summaryText: summary,
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 3: SHIFT OCCUPANCY & CAPACITY UTILIZATION
  Widget _buildShiftOccupancyTab(List<StudentInfo> students) {
    final activeStudents = students.where((s) => s.status != 'INACTIVE').toList();
    final totalSeats = _service.totalSeatsCount > 0 ? _service.totalSeatsCount : 30;

    final morningList = activeStudents.where((s) => LibraryService.doShiftsConflict(s.shift, 'Morning Shift')).toList();
    final eveningList = activeStudents.where((s) => LibraryService.doShiftsConflict(s.shift, 'Evening Shift')).toList();
    final nightList = activeStudents.where((s) => LibraryService.doShiftsConflict(s.shift, 'Night Shift')).toList();
    final fullDayList = activeStudents.where((s) => LibraryService.doShiftsConflict(s.shift, 'Full Day')).toList();

    final seatMap = <int, int>{};
    for (final s in activeStudents) {
      if (s.seatNumber != null) {
        seatMap[s.seatNumber!] = (seatMap[s.seatNumber!] ?? 0) + 1;
      }
    }
    final sharedSeats = seatMap.values.where((c) => c > 1).length;
    final singleSeats = seatMap.values.where((c) => c == 1).length;
    final occupiedSeats = seatMap.keys.length;
    final vacantSeats = (totalSeats - occupiedSeats).clamp(0, 9999);
    final overallRate = totalSeats > 0 ? ((occupiedSeats / totalSeats) * 100).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SHIFT OCCUPANCY & SEAT UTILIZATION',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track multi-shift seat sharing, vacant slots, and capacity utilization across shifts.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'OCCUPANCY RATE',
                value: '$overallRate%',
                valueColor: const Color(0xFF0D9488),
                subtitle: '$occupiedSeats of $totalSeats seats filled',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'MULTI-SHIFT SEATS',
                value: '$sharedSeats Seats',
                valueColor: const Color(0xFF8B5CF6),
                subtitle: 'shared across shifts',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'DEDICATED SEATS',
                value: '$singleSeats Seats',
                valueColor: const Color(0xFF0284C7),
                subtitle: 'single shift occupied',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'VACANT SEATS',
                value: '$vacantSeats Seats',
                valueColor: const Color(0xFF16A34A),
                subtitle: 'fully available',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Shift Capacity Progress Bars
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Color(0xFF0D9488), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Shift-Wise Capacity Utilization',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressRow(
                label: 'Morning Shift (06:00 AM - 12:00 PM)',
                count: morningList.length,
                total: totalSeats,
                barColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: 'Evening Shift (12:00 PM - 06:00 PM)',
                count: eveningList.length,
                total: totalSeats,
                barColor: const Color(0xFF0284C7),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: 'Night Shift (06:00 PM - 11:00 PM)',
                count: nightList.length,
                total: totalSeats,
                barColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                label: 'Full Day & 24 Hours',
                count: fullDayList.length,
                total: totalSeats,
                barColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Export Shift Report
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: _exportListRow(
            icon: Icons.group_work_rounded,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF16A34A),
            title: 'Shift Occupancy & Capacity Report',
            subtitle: 'Download capacity metrics, multi-shift sharing numbers, and occupancy rates',
            onDownload: () {
              final csv = _generateShiftOccupancyCsv(activeStudents, totalSeats);
              final headers = ['Shift', 'Students', 'Total Seats', 'Occupancy %'];
              final previewRows = [
                ['Morning Shift', '${morningList.length}', '$totalSeats', '${(morningList.length / totalSeats * 100).toStringAsFixed(1)}%'],
                ['Evening Shift', '${eveningList.length}', '$totalSeats', '${(eveningList.length / totalSeats * 100).toStringAsFixed(1)}%'],
                ['Night Shift', '${nightList.length}', '$totalSeats', '${(nightList.length / totalSeats * 100).toStringAsFixed(1)}%'],
                ['Full Day', '${fullDayList.length}', '$totalSeats', '${(fullDayList.length / totalSeats * 100).toStringAsFixed(1)}%'],
              ];
              final summary = '${_service.profile.libraryName} - Shift Occupancy Report\n'
                  'Total Seats: $totalSeats\n'
                  'Occupied Seats: $occupiedSeats ($overallRate%)\n'
                  'Shared Multi-Shift Seats: $sharedSeats\n'
                  'Morning: ${morningList.length} | Evening: ${eveningList.length} | Night: ${nightList.length} | Full Day: ${fullDayList.length}';
              _exportCategory(
                categoryName: 'Shift Occupancy & Utilization',
                rowCount: previewRows.length,
                csvData: csv,
                headers: headers,
                previewRows: previewRows,
                summaryText: summary,
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 4: FEE DUES & DEFAULTERS ANALYSIS
  Widget _buildFeeDuesTab(List<StudentInfo> students) {
    final activeStudents = students.where((s) => s.status != 'INACTIVE').toList();
    final defaulters = activeStudents.where((s) => s.hasDues || s.effectiveDues > 0).toList();
    final totalDuesAmount = defaulters.fold<int>(0, (sum, s) => sum + s.effectiveDues);
    final paidCount = activeStudents.length - defaulters.length;
    final rate = activeStudents.isNotEmpty ? ((paidCount / activeStudents.length) * 100).toStringAsFixed(1) : '100';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FEE DUES & RECOVERY REPORT',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Monitor outstanding dues balances, overdue members, and send direct WhatsApp payment reminders.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        // 3 KPI Cards
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'TOTAL OVERDUE',
                value: '₹$totalDuesAmount',
                valueColor: const Color(0xFFE11D48),
                subtitle: 'uncollected revenue',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'DEFAULTERS',
                value: '${defaulters.length} Members',
                valueColor: const Color(0xFFF59E0B),
                subtitle: 'out of ${activeStudents.length} active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'COLLECTION EFFICIENCY',
                value: '$rate%',
                valueColor: const Color(0xFF16A34A),
                subtitle: '$paidCount students fully paid',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Export Defaulters Action Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: _exportListRow(
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFFF1F2),
            iconColor: const Color(0xFFE11D48),
            title: 'Defaulters & Pending Dues List',
            subtitle: 'Download contact details, overdue amounts, and seats for all ${defaulters.length} students with dues',
            onDownload: () {
              final csv = _generateDefaultersCsv(activeStudents);
              final headers = ['Name', 'Phone', 'Seat', 'Shift', 'Due Amount', 'Monthly Fee', 'Joined'];
              final previewRows = defaulters.map((s) => [
                s.name,
                s.phone,
                s.seatNumber != null ? 'S-${s.seatNumber}' : 'None',
                s.shift,
                '₹${s.effectiveDues}',
                '₹${s.monthlyFee}',
                s.joinedAt != null ? DateFormat('dd-MM-yy').format(s.joinedAt!) : 'N/A',
              ]).toList();
              final summary = '${_service.profile.libraryName} - Defaulters Report\n'
                  'Total Outstanding Overdue: ₹$totalDuesAmount\n'
                  'Members with Pending Dues: ${defaulters.length} students\n'
                  'Collection Efficiency: $rate%';
              _exportCategory(
                categoryName: 'Defaulters & Pending Dues',
                rowCount: defaulters.length,
                csvData: csv,
                headers: headers,
                previewRows: previewRows,
                summaryText: summary,
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // List of Defaulters with 1-Tap WhatsApp Reminder
        const Text(
          'PENDING DUES FOLLOW-UP',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        if (defaulters.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
                  SizedBox(height: 8),
                  Text('No Outstanding Dues!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF15803D))),
                  SizedBox(height: 4),
                  Text('All active students have cleared their monthly library fees.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                ...defaulters.take(8).map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_outline_rounded, color: Color(0xFFE11D48), size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy),
                              ),
                              Text(
                                'Seat S-${s.seatNumber ?? "None"} • ${s.shift} • Phone: ${s.phone}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${s.effectiveDues}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE11D48)),
                            ),
                            InkWell(
                              onTap: () {
                                final reminderText = '🏛️ *${_service.profile.libraryName}*\n'
                                    'Dear ${s.name},\n'
                                    'This is a friendly reminder regarding your pending library fee of *₹${s.effectiveDues}* for Seat S-${s.seatNumber ?? "Unassigned"} (${s.shift}).\n'
                                    'Kindly clear the dues at your earliest convenience.\n'
                                    'Thank you!';
                                _shareViaWhatsApp(reminderText, phone: s.phone);
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.send_rounded, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 2),
                                    Text('Remind', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int count,
    required int total,
    required Color barColor,
    String? suffixText,
  }) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final pctString = (pct * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
            Text(
              suffixText ?? '$count ($pctString%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
