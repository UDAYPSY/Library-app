import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../../services/excel_import_service.dart';
import '../../services/file_export_service.dart';
import '../../widgets/collect_payment_modal.dart';
import '../tools/share_qr_screen.dart';
import 'add_student_wizard_screen.dart';
import 'member_profile_screen.dart';

class StudentDirectoryScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const StudentDirectoryScreen({super.key, this.initialStatusFilter});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final LibraryService _service = LibraryService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedShiftFilter = 'ALL SHIFTS';
  String _selectedStatusFilter = 'RECENT'; // Default RECENT (Image 2)

  final List<Map<String, dynamic>> _statusFilters = [
    {'label': 'RECENT', 'icon': Icons.access_time_rounded},
    {'label': 'QR REQUESTS', 'icon': Icons.qr_code_scanner_rounded},
    {'label': 'PAID', 'icon': Icons.check_rounded},
    {'label': 'DUES', 'icon': Icons.error_outline_rounded},
    {'label': 'REMAINING', 'icon': Icons.account_balance_wallet_outlined},
    {'label': 'TRIAL', 'icon': Icons.science_outlined},
    {'label': 'ACTIVE', 'icon': Icons.people_alt_outlined},
    {'label': 'INACTIVE', 'icon': Icons.highlight_off_rounded},
    {'label': 'UNALLOCATED', 'icon': Icons.inventory_2_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _selectedStatusFilter = widget.initialStatusFilter!;
    }
  }

  @override
  void didUpdateWidget(covariant StudentDirectoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != null && widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      setState(() {
        _selectedStatusFilter = widget.initialStatusFilter!;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                        'Bulk Import Students from Excel',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textNavy),
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

  void _openAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String shift = _service.shifts.isNotEmpty ? _service.shifts.first.name : 'Full Day';
    final initialFee = _service.shifts.isNotEmpty ? _service.shifts.first.monthlyFee : 500;
    final feeCtrl = TextEditingController(text: '$initialFee');
    final paidCtrl = TextEditingController(text: '$initialFee');
    int? allocatedSeat;
    String status = 'ACTIVE';
    String paymentMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final mFee = int.tryParse(feeCtrl.text.trim()) ?? initialFee;
          final pAmt = int.tryParse(paidCtrl.text.trim()) ?? 0;
          final remDue = (mFee - pAmt).clamp(0, 999999);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register New Member',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textNavy),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Student Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Phone Number (10 Digits)',
                      hintText: '10-digit number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: shift,
                          items: _service.shifts
                              .map((s) => DropdownMenuItem(
                                    value: s.name,
                                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              final found = _service.shifts.firstWhere((s) => s.name == v);
                              setModalState(() {
                                shift = v;
                                found.isActive = true;
                                feeCtrl.text = '${found.monthlyFee}';
                                paidCtrl.text = '${found.monthlyFee}';
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select Shift',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          items: ['ACTIVE', 'TRIAL']
                              .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                              .toList(),
                          onChanged: (v) => setModalState(() => status = v ?? status),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          readOnly: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Fee (₹) [Fixed]',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 16),
                            suffixIcon: Icon(Icons.lock_rounded, size: 16, color: Color(0xFF64748B)),
                            helperText: 'Fixed from shift',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: paidCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount Paid (₹)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payment, size: 16),
                          ),
                          onChanged: (val) {
                            final raw = int.tryParse(val.trim()) ?? 0;
                            if (raw > mFee) {
                              paidCtrl.text = '$mFee';
                              paidCtrl.selection = TextSelection.fromPosition(TextPosition(offset: paidCtrl.text.length));
                            }
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  if (remDue > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        '⚠️ Remaining Due: ₹$remDue • Will be tagged in DUES & REMAINING tabs',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: allocatedSeat,
                          hint: const Text('Seat (Optional)'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Unallocated')),
                            ...List.generate(_service.totalSeatsCount, (i) => i + 1)
                                .map((num) => DropdownMenuItem<int?>(value: num, child: Text('Seat S-$num'))),
                          ],
                          onChanged: (v) => setModalState(() => allocatedSeat = v),
                          decoration: const InputDecoration(
                            labelText: 'Seat Allocation',
                            border: OutlineInputBorder(),
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) return;
                        if (phone.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mobile number must be exactly 10 digits.'),
                              backgroundColor: Color(0xFFE11D48),
                            ),
                          );
                          return;
                        }
                        if (_service.isDuplicateStudentPhone(phone)) {
                          final existing = _service.findStudentByPhone(phone);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Duplicate: Student "${existing?.name ?? "Enrolled"}" already registered with phone $phone. No duplicates allowed!'),
                              backgroundColor: const Color(0xFFE11D48),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);

                        final parsedFee = int.tryParse(feeCtrl.text.trim()) ?? initialFee;
                        final rawPaid = int.tryParse(paidCtrl.text.trim()) ?? 0;
                        final parsedPaid = rawPaid.clamp(0, parsedFee);
                        final dues = (parsedFee - parsedPaid).clamp(0, parsedFee);
                        final finalStatus = status == 'TRIAL'
                            ? 'TRIAL'
                            : (dues > 0 || parsedPaid == 0 ? 'DUES' : 'ACTIVE');

                        await _service.assignSeatAndRegisterStudent(
                          seatNumber: allocatedSeat,
                          studentName: name,
                          phone: phone,
                          shift: shift,
                          deviceUserId: _service.profile.adminName,
                          feeAmount: parsedPaid,
                          duesAmount: dues,
                          paymentMode: paymentMode,
                          status: finalStatus,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                dues > 0
                                    ? '$name registered with ₹$dues pending due!'
                                    : '$name registered successfully ($finalStatus)!',
                              ),
                              backgroundColor: dues > 0 ? const Color(0xFFE11D48) : Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(
                        remDue > 0 ? 'Register with ₹$remDue Due' : 'Confirm Member (₹$mFee)',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendWhatsApp(StudentInfo s) async {
    final msg = s.note.isNotEmpty
        ? _service.formatTemplate(_service.profile.followupTemplate, student: s)
        : _service.formatTemplate(_service.profile.reminderTemplate, student: s);
    final ok = await LibraryService.sendWhatsAppDirect(phone: s.phone, message: msg);
    if (!ok) {
      Clipboard.setData(ClipboardData(text: msg));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Message copied to clipboard!'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _sendSmsReminder(StudentInfo s) async {
    final msg = s.note.isNotEmpty
        ? _service.formatTemplate(_service.profile.followupTemplate, student: s)
        : _service.formatTemplate(_service.profile.reminderTemplate, student: s);
    final ok = await LibraryService.sendSmsDirect(phone: s.phone, message: msg);
    if (!ok) {
      Clipboard.setData(ClipboardData(text: msg));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app. Message copied to clipboard!'), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS dispatched to ${s.name} (${s.phone})'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteStudent(StudentInfo s) {
    final isInactive = s.status == 'INACTIVE';

    if (isInactive) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Text('Permanently Delete?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete ${s.name}? This will completely remove all student records from the database.',
            style: const TextStyle(fontSize: 14, color: AppColors.textNavy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _service.permanentlyDeleteStudent(s.id, s.seatNumber);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.name} permanently deleted.'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Student', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to remove ${s.name}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textNavy, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 20),
                    ),
                    title: const Text('Move to Inactive Tab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Frees Seat #${s.seatNumber ?? "—"} while preserving past payment and membership history for future renewal.', style: const TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _service.markStudentInactive(s.id, s.seatNumber);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${s.name} moved to Inactive and seat freed.'), backgroundColor: const Color(0xFFD97706)),
                        );
                      }
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Permanently Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFEF4444))),
                    subtitle: const Text('Completely purges this student record from the database. Cannot be undone.', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _service.permanentlyDeleteStudent(s.id, s.seatNumber);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${s.name} permanently deleted.'), backgroundColor: Colors.black87),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreStudent(StudentInfo s) async {
    await _service.reactivateStudent(s.id, null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.name} restored to Active members!'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  void _openNoteSheet(StudentInfo st) {
    final noteCtrl = TextEditingController(text: st.note);
    final hasExistingNote = st.note.trim().isNotEmpty;
    bool isEditing = !hasExistingNote;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Note',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text(ctx),
                              ),
                            ),
                            Text(
                              st.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMutedColor(ctx),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textMutedColor(ctx)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // If student has an existing note and not in edit mode, show detailed note view
                if (hasExistingNote && !isEditing) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.isDark(ctx) ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.isDark(ctx) ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description_outlined, color: Color(0xFFD97706), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'DETAILED NOTE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          st.note,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.isDark(ctx) ? Colors.amber.shade200 : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD97706),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit / Update Note', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setSheetState(() {
                              isEditing = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: noteCtrl,
                    maxLines: 4,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: AppColors.text(ctx)),
                    decoration: InputDecoration(
                      hintText: 'Enter student notes, special remarks or follow-up details...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textMutedColor(ctx)),
                      filled: true,
                      fillColor: AppColors.isDark(ctx) ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFEF3C7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.isDark(ctx) ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (hasExistingNote) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _service.updateStudent(
                              studentId: st.id,
                              name: st.name,
                              phone: st.phone,
                              shift: st.shift,
                              seatNumber: st.seatNumber,
                              note: '',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Note removed'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _service.updateStudent(
                                studentId: st.id,
                                name: st.name,
                                phone: st.phone,
                                shift: st.shift,
                                seatNumber: st.seatNumber,
                                note: noteCtrl.text.trim(),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Note updated!'), behavior: SnackBarBehavior.floating),
                                );
                              }
                            },
                            child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openViewStudentSheet(StudentInfo st, int memberId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemberProfileScreen(
          student: st,
          memberId: memberId,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }


    @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        final allStudents = snapshot.data ?? [];

        // Apply Search & Filters
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredStudents = allStudents.where((s) {
          // Search filter
          if (query.isNotEmpty) {
            final matchName = s.name.toLowerCase().contains(query);
            final matchPhone = s.phone.contains(query);
            final matchSeat = s.seatNumber != null ? 's-${s.seatNumber}'.contains(query) : 'unallocated'.contains(query);
            if (!matchName && !matchPhone && !matchSeat) return false;
          }

          // Shift filter
          if (_selectedShiftFilter != 'ALL SHIFTS') {
            if (s.shift.trim().toUpperCase() != _selectedShiftFilter.trim().toUpperCase()) return false;
          }

          // INACTIVE tab strictly shows inactive students
          if (_selectedStatusFilter == 'INACTIVE') {
            return s.status == 'INACTIVE';
          }
          // For all other status filters, inactive students must not appear
          if (s.status == 'INACTIVE') return false;

          // Status filter
          if (_selectedStatusFilter == 'RECENT' || _selectedStatusFilter == 'ALL') {
            return true;
          } else if (_selectedStatusFilter == 'PAID') {
            return !s.hasDues && s.duesAmount == 0 && s.status != 'DUES' && s.status != 'TRIAL';
          } else if (_selectedStatusFilter == 'DUES' || _selectedStatusFilter == 'REMAINING') {
            return s.hasDues || s.effectiveDues > 0 || s.duesAmount > 0 || s.status == 'DUES';
          } else if (_selectedStatusFilter == 'ACTIVE') {
            return (s.status == 'ACTIVE' || s.status == 'PAID') && !s.hasDues && s.duesAmount == 0;
          } else if (_selectedStatusFilter == 'UNALLOCATED') {
            return s.seatNumber == null;
          } else if (_selectedStatusFilter == 'TRIAL') {
            return s.status == 'TRIAL';
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: MANAGEMENT Directory + [📥] + [0 PROFILES] (Image 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (Navigator.canPop(context)) ...[
                                IconButton(
                                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MANAGEMENT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: AppColors.textMutedColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Directory',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Download / Export Icon Button (Real CSV File Download)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final buffer = StringBuffer();
                                  buffer.writeln('Student ID,Full Name,Phone,Seat Number,Shift,Status,Monthly Fee (INR),Pending Dues (INR),Joining Date,Father Name,Address,Aadhaar');
                                  for (final s in allStudents) {
                                    final seatStr = s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated';
                                    final joinStr = s.joinedAt != null ? DateFormat('dd-MM-yyyy').format(s.joinedAt!) : 'N/A';
                                    final row = [
                                      s.id,
                                      '"${s.name.replaceAll('"', '""')}"',
                                      s.phone,
                                      seatStr,
                                      '"${s.shift.replaceAll('"', '""')}"',
                                      s.status,
                                      '${s.monthlyFee}',
                                      '${s.effectiveDues}',
                                      joinStr,
                                      '"${s.fatherName.replaceAll('"', '""')}"',
                                      '"${s.address.replaceAll('"', '""')}"',
                                      s.aadhaarNumber,
                                    ].join(',');
                                    buffer.writeln(row);
                                  }
                                  final fileName = 'student_directory_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
                                  final ok = await FileExportService.download(fileName: fileName, content: buffer.toString());
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok ? 'Exported ${allStudents.length} student records to $fileName!' : 'Export file saved!'),
                                        backgroundColor: const Color(0xFF0D9488),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFE6F4F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.file_download_outlined, color: AppColors.primaryTeal, size: 22),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Profile Count Badge (Image 2)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFE6F4F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${allStudents.length}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                    const Text(
                                      'PROFILES',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search Bar (Image 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorderColor(context)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by name or number...',
                            hintStyle: TextStyle(color: AppColors.textSubtleColor(context), fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMutedColor(context), size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shift & Status Dropdown Filters Row (Requirement 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Shift Dropdown
                          Expanded(
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorderColor(context)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: (['ALL SHIFTS', ..._service.shifts.where((sh) => sh.isActive).map((sh) => sh.name.toUpperCase())].contains(_selectedShiftFilter))
                                      ? _selectedShiftFilter
                                      : 'ALL SHIFTS',
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMutedColor(context), size: 20),
                                  dropdownColor: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(16),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text(context),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'ALL SHIFTS',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primaryTeal),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'All Shifts',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.text(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ..._service.shifts.where((sh) => sh.isActive).map((sh) {
                                      return DropdownMenuItem<String>(
                                        value: sh.name.toUpperCase(),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.wb_cloudy_rounded, size: 14, color: AppColors.primaryTeal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sh.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.text(context),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedShiftFilter = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Status Dropdown
                          Expanded(
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorderColor(context)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _statusFilters.any((f) => f['label'] == _selectedStatusFilter)
                                      ? _selectedStatusFilter
                                      : 'RECENT',
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMutedColor(context), size: 20),
                                  dropdownColor: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(16),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text(context),
                                  ),
                                  items: _statusFilters.map((item) {
                                    final label = item['label'] as String;
                                    final icon = item['icon'] as IconData;
                                    return DropdownMenuItem<String>(
                                      value: label,
                                      child: Row(
                                        children: [
                                          Icon(icon, size: 14, color: AppColors.primaryTeal),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              label,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: AppColors.text(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedStatusFilter = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top banner for pending QR admission requests (visible across all student directory tabs)
                    if (_selectedStatusFilter != 'QR REQUESTS')
                      StreamBuilder<List<RegistrationRequest>>(
                        stream: _service.streamRegistrationRequests(),
                        initialData: _service.currentRegistrationRequests,
                        builder: (ctx, reqSnap) {
                          final pending = (reqSnap.data ?? _service.currentRegistrationRequests)
                              .where((r) => r.status == 'PENDING')
                              .toList();
                          if (pending.isEmpty) return const SizedBox.shrink();

                          final first = pending.first;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (pending.length == 1) {
                                  _showSeatAllotmentSheet(first);
                                } else {
                                  setState(() => _selectedStatusFilter = 'QR REQUESTS');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x260F766E),
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${pending.length} New QR Admission Request${pending.length > 1 ? "s" : ""}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF08A),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'PENDING',
                                                  style: TextStyle(
                                                    color: Color(0xFF854D0E),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${first.studentName} (${first.shift}) • Tap to allot seat',
                                            style: const TextStyle(
                                              color: Color(0xFFCCFBF1),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF0F766E),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => _showSeatAllotmentSheet(first),
                                      child: const Text('Allot Seat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Content Area (Image 2: Empty state OR Student Cards OR QR Requests)
                    Expanded(
                      child: _selectedStatusFilter == 'QR REQUESTS'
                          ? _buildQrRequestsView()
                          : filteredStudents.isEmpty
                              ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  const Text(
                                    'No students found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try adjusting search or filters.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                              itemCount: filteredStudents.length,
                              itemBuilder: (ctx, i) {
                                final st = filteredStudents[i];
                                final memberId = i + 1;
                                final seatLabel = st.seatNumber != null ? '${st.sectionName} • #${st.seatNumber}' : 'Unallocated';
                                final joinDateStr = st.joinedAt != null
                                    ? DateFormat('dd-MMM-yyyy').format(st.joinedAt!)
                                    : DateFormat('dd-MMM-yyyy').format(DateTime.now());
                                
                                final initials = st.name.trim().isNotEmpty
                                    ? (st.name.trim().split(' ').length > 1
                                        ? '${st.name.trim().split(' ')[0][0]}${st.name.trim().split(' ')[1][0]}'.toUpperCase()
                                        : (st.name.trim().length >= 2 ? st.name.trim().substring(0, 2).toUpperCase() : st.name.trim().toUpperCase()))
                                    : 'ST';

                                final matchedShift = _service.shifts.firstWhere(
                                  (sh) => sh.name.toLowerCase() == st.shift.toLowerCase(),
                                  orElse: () => ShiftConfig(
                                    id: 'custom',
                                    name: st.shift,
                                    startsAt: '06:00 AM',
                                    endsAt: '10:00 PM',
                                    monthlyFee: st.monthlyFee,
                                    isActive: true,
                                  ),
                                );
                                final shiftTimingStr = '${matchedShift.startsAt} - ${matchedShift.endsAt}';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.cardBorderColor(context)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.isDark(context) ? Colors.black26 : const Color(0x06000000),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Avatar with status dot, Name, Member ID, and Note icon (Image 7)
                                      Row(
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0284C7),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: st.status == 'INACTIVE'
                                                        ? const Color(0xFF94A3B8)
                                                        : (st.status == 'TRIAL'
                                                            ? const Color(0xFFF59E0B)
                                                            : (st.hasDues
                                                                ? const Color(0xFFEF4444)
                                                                : const Color(0xFF22C55E))),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: AppColors.card(context), width: 2),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  st.name.isNotEmpty ? st.name : 'Member',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.text(context),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'MEMBER ID: #$memberId',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: AppColors.textMutedColor(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (st.effectiveDues > 0)
                                                Container(
                                                  margin: const EdgeInsets.only(right: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF2F2),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFFFECACA)),
                                                  ),
                                                  child: Text(
                                                    '₹${st.effectiveDues}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFEF4444),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              Builder(
                                                builder: (context) {
                                                  final hasNote = st.note.trim().isNotEmpty;
                                                  return Tooltip(
                                                    message: hasNote ? 'View Note' : 'Add Note',
                                                    child: InkWell(
                                                      onTap: () => _openNoteSheet(st),
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: hasNote
                                                              ? (AppColors.isDark(context)
                                                                  ? const Color(0xFF78350F).withOpacity(0.3)
                                                                  : const Color(0xFFFEF3C7))
                                                              : Colors.transparent,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: hasNote
                                                              ? Border.all(
                                                                  color: AppColors.isDark(context)
                                                                      ? const Color(0xFFD97706).withOpacity(0.5)
                                                                      : const Color(0xFFFDE68A),
                                                                  width: 1,
                                                                )
                                                              : null,
                                                        ),
                                                        child: Stack(
                                                          clipBehavior: Clip.none,
                                                          children: [
                                                            Icon(
                                                              hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
                                                              color: hasNote ? const Color(0xFFD97706) : AppColors.textMutedColor(context),
                                                              size: 20,
                                                            ),
                                                            if (hasNote)
                                                              Positioned(
                                                                top: -1,
                                                                right: -1,
                                                                child: Container(
                                                                  width: 6,
                                                                  height: 6,
                                                                  decoration: const BoxDecoration(
                                                                    color: Color(0xFFD97706),
                                                                    shape: BoxShape.circle,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                                                onSelected: (val) {
                                                  if (val == 'delete') _confirmDeleteStudent(st);
                                                  if (val == 'restore') _restoreStudent(st);
                                                },
                                                itemBuilder: (ctx) => [
                                                  if (st.status == 'INACTIVE')
                                                    const PopupMenuItem(
                                                      value: 'restore',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.restore_rounded, size: 18, color: Color(0xFF0D9488)),
                                                          SizedBox(width: 8),
                                                          Text('Restore Student'),
                                                        ],
                                                      ),
                                                    ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          st.status == 'INACTIVE' ? 'Delete Permanently' : 'Move to Inactive',
                                                          style: const TextStyle(color: Color(0xFFEF4444)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // 2x2 Details Grid (Image 7)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.subSurface(context),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.cardBorderColor(context)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'PHONE',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.textMutedColor(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    st.phone.isNotEmpty ? st.phone : 'Not provided',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.text(context),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.subSurface(context),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.cardBorderColor(context)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textSubtleColor(context)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'STATUS',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.textSubtleColor(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    st.status == 'INACTIVE'
                                                        ? 'Inactive'
                                                        : (st.status == 'TRIAL'
                                                            ? 'Trial'
                                                            : (st.hasDues ? 'Due: ₹${st.effectiveDues}' : 'Active')),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: st.status == 'INACTIVE'
                                                          ? const Color(0xFFEF4444)
                                                          : (st.status == 'TRIAL'
                                                              ? const Color(0xFFD97706)
                                                              : (st.hasDues
                                                                  ? const Color(0xFFE11D48)
                                                                  : const Color(0xFF16A34A))),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.subSurface(context),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.cardBorderColor(context)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSubtleColor(context)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'JOINED',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.textSubtleColor(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    joinDateStr,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.text(context),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.subSurface(context),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppColors.cardBorderColor(context)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSubtleColor(context)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'SEAT',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.textSubtleColor(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    seatLabel,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.text(context),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Bottom Tags Row (Image 7)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDFA),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF99F6E4)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.wb_sunny_outlined, size: 12, color: Color(0xFF0D9488)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  st.shift.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0D9488),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                             decoration: BoxDecoration(
                                               color: AppColors.isDark(context) ? AppColors.darkSubSurface : Colors.white,
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(color: AppColors.cardBorderColor(context)),
                                             ),
                                             child: Row(
                                               mainAxisSize: MainAxisSize.min,
                                               children: [
                                                 Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSubtleColor(context)),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   shiftTimingStr,
                                                   style: TextStyle(
                                                     fontSize: 10,
                                                     fontWeight: FontWeight.w600,
                                                     color: AppColors.textSubtleColor(context),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                           if (st.status == 'INACTIVE')
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                               decoration: BoxDecoration(
                                                 color: const Color(0xFFFEF2F2),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(color: const Color(0xFFFECACA)),
                                               ),
                                               child: const Text(
                                                 'INACTIVE MEMBER',
                                                 style: TextStyle(
                                                   fontSize: 10,
                                                   fontWeight: FontWeight.w800,
                                                   color: Color(0xFFEF4444),
                                                 ),
                                               ),
                                             )
                                           else if (st.status == 'TRIAL')
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                               decoration: BoxDecoration(
                                                 color: const Color(0xFFFFFBEB),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(color: const Color(0xFFFDE68A)),
                                               ),
                                               child: Text(
                                                 st.joinedAt != null
                                                     ? 'TRIAL • ${(DateTime.now().difference(st.joinedAt!).inDays + 1)} DAYS IN'
                                                     : 'TRIAL MEMBER',
                                                 style: const TextStyle(
                                                   fontSize: 10,
                                                   fontWeight: FontWeight.w800,
                                                   color: Color(0xFFD97706),
                                                 ),
                                               ),
                                             )
                                           else if (st.hasDues)
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                               decoration: BoxDecoration(
                                                 color: const Color(0xFFFFF1F2),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(color: const Color(0xFFFECDD3)),
                                               ),
                                               child: Text(
                                                 'DUE: ₹${st.effectiveDues}',
                                                 style: const TextStyle(
                                                   fontSize: 10,
                                                   fontWeight: FontWeight.w800,
                                                   color: Color(0xFFE11D48),
                                                 ),
                                               ),
                                             )
                                           else
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                               decoration: BoxDecoration(
                                                 color: const Color(0xFFECFDF5),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(color: const Color(0xFFA7F3D0)),
                                               ),
                                               child: const Text(
                                                 'PAID • ACTIVE',
                                                 style: TextStyle(
                                                   fontSize: 10,
                                                   fontWeight: FontWeight.w800,
                                                   color: Color(0xFF059669),
                                                 ),
                                               ),
                                             ),
                                         ],
                                       ),
                                       const SizedBox(height: 16),

                                       // Actions
                                       if (st.status == 'INACTIVE') ...[
                                         Row(
                                           children: [
                                             Expanded(
                                               child: ElevatedButton.icon(
                                                 style: ElevatedButton.styleFrom(
                                                   backgroundColor: AppColors.primaryTeal,
                                                   foregroundColor: Colors.white,
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: const Icon(Icons.restore_rounded, size: 18),
                                                 label: const Text(
                                                   'Restore Member',
                                                   style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                                 ),
                                                 onPressed: () => _restoreStudent(st),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             InkWell(
                                               borderRadius: BorderRadius.circular(14),
                                               onTap: () => _confirmDeleteStudent(st),
                                               child: Container(
                                                 padding: const EdgeInsets.all(11),
                                                 decoration: BoxDecoration(
                                                   color: const Color(0xFFFEF2F2),
                                                   borderRadius: BorderRadius.circular(14),
                                                   border: Border.all(color: const Color(0xFFFECACA)),
                                                 ),
                                                 child: const Icon(
                                                   Icons.delete_forever_rounded,
                                                   color: Color(0xFFEF4444),
                                                   size: 20,
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                       ] else ...[
                                         Row(
                                           children: [
                                             Expanded(
                                               child: ElevatedButton.icon(
                                                 style: ElevatedButton.styleFrom(
                                                   backgroundColor: st.seatNumber == null ? const Color(0xFF0F766E) : AppColors.primaryTeal,
                                                   foregroundColor: Colors.white,
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   elevation: 0,
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: Icon(st.seatNumber == null ? Icons.chair_alt_rounded : Icons.visibility_outlined, size: 18, color: Colors.white),
                                                 label: Text(
                                                   st.seatNumber == null ? "Allot Seat" : "View Profile",
                                                   style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                                 ),
                                                 onPressed: () {
                                                   if (st.seatNumber == null) {
                                                     final req = _service.currentRegistrationRequests.firstWhere(
                                                       (r) => (r.id.isNotEmpty && st.id.contains(r.id)) || (r.phone.isNotEmpty && LibraryService.normalizePhone(r.phone) == LibraryService.normalizePhone(st.phone)),
                                                       orElse: () => RegistrationRequest(
                                                         id: "req_${st.id}",
                                                         studentName: st.name,
                                                         phone: st.phone,
                                                         shift: st.shift,
                                                         status: "PENDING",
                                                         createdAt: st.joinedAt ?? DateTime.now(),
                                                         libraryId: _service.tenantId,
                                                         fatherName: st.fatherName,
                                                         address: st.address,
                                                         aadhaarNumber: st.aadhaarNumber,
                                                         preparationFor: st.preparationFor,
                                                         gender: st.gender,
                                                         photoBase64: st.photoBase64,
                                                         preferredMonthlyFee: st.monthlyFee,
                                                       ),
                                                     );
                                                     _showSeatAllotmentSheet(req);
                                                   } else {
                                                     _openViewStudentSheet(st, memberId);
                                                   }
                                                 },
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             InkWell(
                                               borderRadius: BorderRadius.circular(14),
                                               onTap: () => _sendWhatsApp(st),
                                               child: Container(
                                                 padding: const EdgeInsets.all(12),
                                                 decoration: BoxDecoration(
                                                   color: const Color(0xFFECFDF5),
                                                   borderRadius: BorderRadius.circular(14),
                                                   border: Border.all(color: const Color(0xFFA7F3D0)),
                                                 ),
                                                 child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 18),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             InkWell(
                                               borderRadius: BorderRadius.circular(14),
                                               onTap: () => _sendSmsReminder(st),
                                               child: Container(
                                                 padding: const EdgeInsets.all(12),
                                                 decoration: BoxDecoration(
                                                   color: const Color(0xFFF0F9FF),
                                                   borderRadius: BorderRadius.circular(14),
                                                   border: Border.all(color: const Color(0xFFBAE6FD)),
                                                 ),
                                                 child: const Icon(Icons.message_outlined, color: Color(0xFF0284C7), size: 18),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             InkWell(
                                               borderRadius: BorderRadius.circular(14),
                                               onTap: () => _confirmDeleteStudent(st),
                                               child: Container(
                                                 padding: const EdgeInsets.all(12),
                                                 decoration: BoxDecoration(
                                                   color: const Color(0xFFFEF2F2),
                                                   borderRadius: BorderRadius.circular(14),
                                                   border: Border.all(color: const Color(0xFFFECACA)),
                                                 ),
                                                 child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                               ),
                                             ),
                                           ],
                                         ),
                                       ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Floating Action Buttons: [Excel Import] and [+ New Member]
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _openBulkImportSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x30000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_view_rounded, color: Color(0xFF38BDF8), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Excel Import',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddStudentWizardScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x400F766E),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'New Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // QR STUDENT ADMISSION REQUESTS & APPROVAL WORKFLOW
  // -------------------------------------------------------------

  Widget _buildQrRequestsView() {
    return StreamBuilder<List<RegistrationRequest>>(
      stream: _service.streamRegistrationRequests(),
      builder: (context, snapshot) {
        final allReqs = snapshot.data ?? _service.currentRegistrationRequests;
        final query = _searchCtrl.text.trim().toLowerCase();
        final reqs = allReqs.where((r) {
          if (query.isNotEmpty) {
            final matchesName = r.studentName.toLowerCase().contains(query);
            final matchesPhone = r.phone.contains(query);
            if (!matchesName && !matchesPhone) return false;
          }
          if (_selectedShiftFilter != 'ALL SHIFTS') {
            if (r.shift.toUpperCase() != _selectedShiftFilter) return false;
          }
          return true;
        }).toList();

        if (reqs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCCFBF1), width: 2),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No QR Admission Requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When students scan your reception desk QR code with their mobile camera, their admission requests appear here for instant seat allotment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6E66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShareQrScreen()),
                      );
                    },
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('View Desk QR Poster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
          itemCount: reqs.length,
          itemBuilder: (ctx, i) {
            final req = reqs[i];
            return _buildRegistrationRequestCard(req);
          },
        );
      },
    );
  }

  Widget _buildRegistrationRequestCard(RegistrationRequest req) {
    final isPending = req.status == 'PENDING';
    final isAccepted = req.status == 'ACCEPTED';

    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFFD97706);
    String statusText = 'PENDING ALLOTMENT';
    if (isAccepted) {
      statusBg = const Color(0xFFECFDF5);
      statusColor = const Color(0xFF059669);
      statusText = 'SEAT ALLOTTED';
    } else if (req.status == 'REJECTED') {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFEF4444);
      statusText = 'DECLINED';
    }

    final dateStr = DateFormat('dd MMM, hh:mm a').format(req.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context) ? Colors.black26 : const Color(0x06000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Photo + Name + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: req.photoBase64 != null && req.photoBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(req.photoBase64!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFF0D9488).withOpacity(0.12),
                        child: Center(
                          child: Text(
                            req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            req.studentName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied $dateStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSubtleColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details grid: Phone, Shift, Goal
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0D9488)),
                        const SizedBox(width: 6),
                        Text(
                          '+91 ${req.phone}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        final text = 'Hello ${req.studentName}, thank you for your admission request at ${_service.profile.libraryName}.';
                        LibraryService.sendWhatsAppDirect(phone: req.phone, message: text);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              req.shift,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              req.preparationFor,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (req.fatherName.isNotEmpty || req.address.isNotEmpty) ...[
                  const Divider(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${req.fatherName.isNotEmpty ? "C/o ${req.fatherName} • " : ""}${req.address}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSubtleColor(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions Row (for PENDING requests)
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6E66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showSeatAllotmentSheet(req),
                    icon: const Icon(Icons.chair_alt_rounded, size: 18),
                    label: const Text('Allot Seat & Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Decline Request?', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to decline admission request for ${req.studentName}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Decline'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _service.rejectRegistrationRequest(req.id);
                    }
                  },
                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showSeatAllotmentSheet(RegistrationRequest req) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentWizardScreen(
          registrationRequest: req,
          initialStep: 1, // Lands directly on "Schedule & Fees" step
        ),
      ),
    );
  }
}
