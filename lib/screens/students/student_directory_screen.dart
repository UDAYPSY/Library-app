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
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    final duesText = s.duesAmount > 0 ? 'Pending dues: ₹${s.duesAmount}. ' : '';
    final msg =
        'Hello ${s.name}, greetings from ${_service.profile.libraryName}! Your library seat (${s.seatNumber != null ? "Seat #${s.seatNumber}" : "Unallocated"}) renewal is due. ${duesText}Monthly fee is ₹${s.monthlyFee}. Please visit the reception.';
    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _sendSmsReminder(StudentInfo s) async {
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    final duesText = s.duesAmount > 0 ? 'Due: Rs.${s.duesAmount}. ' : '';
    final msg =
        'Dear ${s.name}, reminder for library fee Rs.${s.monthlyFee}. ${duesText}Please pay at reception. - ${_service.profile.libraryName}';
    final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS reminder sent to ${s.name} (${s.phone})'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteStudent(StudentInfo s) {
    final isInactive = s.status == 'INACTIVE';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isInactive ? 'Permanently Delete Student' : 'Move to Inactive Tab',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy),
        ),
        content: Text(
          isInactive
              ? 'Are you sure you want to permanently delete ${s.name}? This student record will be completely removed.'
              : 'Are you sure you want to remove ${s.name}? They will be moved to the INACTIVE tab and their seat (${s.seatNumber != null ? "Seat #${s.seatNumber}" : "unallocated"}) will be vacated. You can restore them anytime from the INACTIVE tab.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isInactive) {
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
              } else {
                await _service.markStudentInactive(s.id, s.seatNumber);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.name} moved to Inactive tab and seat vacated.'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(isInactive ? 'Delete Permanently' : 'Move to Inactive', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 16),

                    // Content Area (Image 2: Empty state OR Student Cards)
                    Expanded(
                      child: filteredStudents.isEmpty
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
                                                   backgroundColor: AppColors.primaryTeal,
                                                   foregroundColor: Colors.white,
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   elevation: 0,
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.white),
                                                 label: const Text(
                                                   'View Profile',
                                                   style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                                 ),
                                                 onPressed: () => _openViewStudentSheet(st, memberId),
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

}
