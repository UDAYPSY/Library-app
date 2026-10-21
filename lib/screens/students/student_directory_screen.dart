import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import 'add_student_wizard_screen.dart';

class StudentDirectoryScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const StudentDirectoryScreen({super.key, this.initialStatusFilter});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final LibraryService _service = LibraryService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _statusScrollCtrl = ScrollController();
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
      _maybeScrollToFilter(_selectedStatusFilter);
    }
  }

  @override
  void didUpdateWidget(covariant StudentDirectoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != null && widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      setState(() {
        _selectedStatusFilter = widget.initialStatusFilter!;
      });
      _maybeScrollToFilter(_selectedStatusFilter);
    }
  }

  void _maybeScrollToFilter(String filter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_statusScrollCtrl.hasClients) return;
      final idx = _statusFilters.indexWhere((f) => f['label'] == filter);
      if (idx > 2) {
        _statusScrollCtrl.animateTo(
          (idx - 1) * 85.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _statusScrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final activeShifts = _service.shifts.where((s) => s.isActive).toList();
    String shift = activeShifts.isNotEmpty ? activeShifts.first.name : (_service.shifts.isNotEmpty ? _service.shifts.first.name : 'Full Day');
    int fee = activeShifts.isNotEmpty ? activeShifts.first.monthlyFee : (_service.shifts.isNotEmpty ? _service.shifts.first.monthlyFee : 500);
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
        builder: (sheetContext, setModalState) => Padding(
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
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone Number',
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
                        items: (activeShifts.isNotEmpty ? activeShifts : _service.shifts)
                            .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final found = _service.shifts.firstWhere((s) => s.name == v);
                            setModalState(() {
                              shift = v;
                              fee = found.monthlyFee;
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
                      Navigator.pop(ctx);

                      await _service.assignSeatAndRegisterStudent(
                        seatNumber: allocatedSeat,
                        studentName: name,
                        phone: phone,
                        shift: shift,
                        deviceUserId: _service.profile.adminName,
                        feeAmount: fee,
                        paymentMode: paymentMode,
                        status: status,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name registered successfully ($status)!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Confirm Member (₹$fee)',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _toggleTrialStatus(StudentInfo st) {
    final isTrial = st.status == 'TRIAL';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTrial ? 'Convert to Regular Active Member' : 'Mark as Trial Student',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy),
        ),
        content: Text(
          isTrial
              ? 'Do you want to convert ${st.name} from a Trial student to a regular Active Member?'
              : 'Do you want to mark ${st.name} as a Trial Student? Trial students are tagged under the TRIAL tab.',
          style: const TextStyle(fontSize: 14, color: AppColors.textNavy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isTrial ? AppColors.primaryTeal : const Color(0xFFD97706),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isTrial) {
                await _service.reactivateStudent(st.id, st.seatNumber);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${st.name} is now a regular Active Member!'), backgroundColor: AppColors.primaryTeal),
                  );
                }
              } else {
                await _service.markStudentTrial(st.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${st.name} marked as Trial Student!'), backgroundColor: const Color(0xFFD97706)),
                  );
                }
              }
            },
            child: Text(isTrial ? 'Convert to Active' : 'Mark as Trial', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openMarkDuesSheet(StudentInfo st) {
    final defaultDues = st.effectiveDues > 0 ? st.effectiveDues : st.monthlyFee;
    final duesCtrl = TextEditingController(text: defaultDues.toString());
    DateTime selectedDate = st.feeDueDate ?? DateTime.now().add(const Duration(days: 7));
    final noteCtrl = TextEditingController(
      text: 'Fee due for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mark Fee Due - ${st.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                      const SizedBox(height: 2),
                      Text('Seat: ${st.seatNumber != null ? "S-${st.seatNumber}" : "Unallocated"} • Shift: ${st.shift}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: duesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Due Amount (₹)',
                  hintText: 'Enter pending fee amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee, color: Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF0284C7), size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Due Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason / Note',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setModalState(() => duesCtrl.text = '${st.monthlyFee}'),
                      child: Text('Full Fee (₹${st.monthlyFee})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setModalState(() => duesCtrl.text = '0'),
                      child: const Text('Clear Dues (₹0)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
                    backgroundColor: const Color(0xFFE11D48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final dues = int.tryParse(duesCtrl.text.trim()) ?? 0;
                    Navigator.pop(ctx);
                    if (dues <= 0) {
                      await _service.updateStudent(
                        studentId: st.id,
                        name: st.name,
                        phone: st.phone,
                        shift: st.shift,
                        seatNumber: st.seatNumber,
                        duesAmount: 0,
                        status: st.status == 'DUES' ? 'ACTIVE' : st.status,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cleared all dues for ${st.name}!'), backgroundColor: const Color(0xFF10B981)),
                        );
                      }
                    } else {
                      await _service.markStudentDues(st.id, dues, selectedDate);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Marked ₹$dues due for ${st.name}!'), backgroundColor: const Color(0xFFE11D48)),
                        );
                      }
                    }
                  },
                  child: const Text('Save Due Fee', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNoteSheet(StudentInfo st) {
    final noteCtrl = TextEditingController(text: st.note);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
                    const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text('Notes for ${st.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter student notes or remarks...',
                filled: true,
                fillColor: const Color(0xFFFFFBEB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFEF3C7))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFEF3C7))),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }

  void _openViewStudentSheet(StudentInfo st, int memberId) {
    final initials = st.name.trim().isNotEmpty
        ? (st.name.trim().split(' ').length > 1
            ? '${st.name.trim().split(' ')[0][0]}${st.name.trim().split(' ')[1][0]}'.toUpperCase()
            : (st.name.trim().length >= 2 ? st.name.trim().substring(0, 2).toUpperCase() : st.name.trim().toUpperCase()))
        : 'ST';
    final joinDateStr = st.joinedAt != null ? DateFormat('dd-MMM-yyyy').format(st.joinedAt!) : '20-Oct-2026';
    final seatLabel = st.seatNumber != null ? '${st.sectionName} • #${st.seatNumber}' : 'Main Hall • #$memberId';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MEMBER ID: #$memberId',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      st.status,
                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _viewRow(Icons.phone_outlined, 'Phone', st.phone),
                    const Divider(height: 20),
                    _viewRow(Icons.chair_outlined, 'Seat', seatLabel),
                    const Divider(height: 20),
                    _viewRow(Icons.wb_sunny_outlined, 'Shift', '${st.shift} (06:00 AM - 10:00 PM)'),
                    const Divider(height: 20),
                    _viewRow(Icons.calendar_today_outlined, 'Joined', joinDateStr),
                    const Divider(height: 20),
                    _viewRow(Icons.payments_outlined, 'Monthly Fee', '₹${st.monthlyFee} (${st.paymentMode})'),
                    if (st.duesAmount > 0) ...[
                      const Divider(height: 20),
                      _viewRow(Icons.warning_amber_rounded, 'Pending Dues', '₹${st.duesAmount}', valueColor: const Color(0xFFEF4444)),
                    ],
                    if (st.note.isNotEmpty) ...[
                      const Divider(height: 20),
                      _viewRow(Icons.note_outlined, 'Note', st.note),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textNavy),
                      label: const Text('Edit Details', style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditStudentSheet(st);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6E66),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                      label: const Text('Collect Fee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openPaySheet(st);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.textNavy, fontWeight: FontWeight.w800)),
      ],
    );
  }

  void _openEditStudentSheet(StudentInfo st) {
    final nameCtrl = TextEditingController(text: st.name);
    final phoneCtrl = TextEditingController(text: st.phone);
    final feeCtrl = TextEditingController(text: st.monthlyFee.toString());
    final duesCtrl = TextEditingController(text: st.duesAmount.toString());
    final noteCtrl = TextEditingController(text: st.note);
    final activeShifts = _service.shifts.where((s) => s.isActive).toList();
    String shift = activeShifts.any((s) => s.name == st.shift)
        ? st.shift
        : (activeShifts.isNotEmpty ? activeShifts.first.name : st.shift);
    int? seatNumber = st.seatNumber;
    String status = ['ACTIVE', 'TRIAL', 'INACTIVE'].contains(st.status) ? st.status : 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
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
                    const Text('Edit Student Profile', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: (activeShifts.any((s) => s.name == shift))
                            ? shift
                            : (activeShifts.isNotEmpty ? activeShifts.first.name : null),
                        items: (activeShifts.isNotEmpty ? activeShifts : _service.shifts)
                            .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setModalState(() => shift = v ?? shift),
                        decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        items: ['ACTIVE', 'TRIAL', 'INACTIVE']
                            .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v ?? status),
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
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
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Monthly Fee (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: duesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pending Dues (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.warning_amber_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note / Remarks', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sticky_note_2_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      final dues = int.tryParse(duesCtrl.text.trim()) ?? 0;
                      await _service.updateStudent(
                        studentId: st.id,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        shift: shift,
                        seatNumber: status == 'INACTIVE' ? null : seatNumber,
                        monthlyFee: int.tryParse(feeCtrl.text.trim()) ?? st.monthlyFee,
                        duesAmount: dues,
                        status: status,
                        note: noteCtrl.text.trim(),
                      );
                      if (status == 'INACTIVE' && st.status != 'INACTIVE') {
                        await _service.markStudentInactive(st.id, st.seatNumber);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated profile for ${nameCtrl.text.trim()}!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPaySheet(StudentInfo st) {
    final defaultAmount = st.duesAmount > 0 ? st.duesAmount : st.monthlyFee;
    final amountCtrl = TextEditingController(text: defaultAmount.toString());
    final noteCtrl = TextEditingController(text: 'Monthly fee renewal');
    String paymentMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Collect Payment - ${st.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                      const SizedBox(height: 2),
                      Text('Seat #${st.seatNumber ?? 1} • ${st.shift}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount to Collect (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMode,
                items: ['UPI', 'Cash', 'Card', 'Net Banking'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setModalState(() => paymentMode = v ?? paymentMode),
                decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Payment Note', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes_rounded)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6E66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final amt = int.tryParse(amountCtrl.text.trim()) ?? defaultAmount;
                    Navigator.pop(ctx);
                    await _service.collectStudentFee(
                      studentId: st.id,
                      amount: amt,
                      paymentMode: paymentMode,
                      notes: noteCtrl.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment of ₹$amt collected from ${st.name} via $paymentMode!'),
                          backgroundColor: const Color(0xFF0D6E66),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text('Confirm & Collect ₹${amountCtrl.text}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            return !s.hasDues && s.status != 'TRIAL';
          } else if (_selectedStatusFilter == 'DUES' || _selectedStatusFilter == 'REMAINING') {
            return s.hasDues;
          } else if (_selectedStatusFilter == 'ACTIVE') {
            return s.status == 'ACTIVE' || s.status == 'PAID';
          } else if (_selectedStatusFilter == 'UNALLOCATED') {
            return s.seatNumber == null;
          } else if (_selectedStatusFilter == 'TRIAL') {
            return s.status == 'TRIAL';
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
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
                                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textNavy),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 4),
                              ],
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MANAGEMENT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Directory',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Download / Export Icon Button (Image 2)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Exported ${allStudents.length} student records.')),
                                  );
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4F1),
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
                                  color: const Color(0xFFE6F4F1),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or number...',
                            hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shift Filter Chips Row: ALL SHIFTS, FULL DAY, etc. (only active shifts)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _shiftChip('ALL SHIFTS', null),
                            ..._service.shifts.where((sh) => sh.isActive).map((sh) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _shiftChip(sh.name.toUpperCase(), Icons.wb_cloudy_rounded),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Filter Chips Row: RECENT, PAID, DUES, REMAINING, TRIAL, ACTIVE, etc. (Images 2, 3, 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 38,
                        child: ListView.builder(
                          controller: _statusScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          itemCount: _statusFilters.length,
                          itemBuilder: (ctx, i) {
                            final item = _statusFilters[i];
                            final label = item['label'] as String;
                            final icon = item['icon'] as IconData;
                            final isSelected = _selectedStatusFilter == label;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _selectedStatusFilter = label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryTeal : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppColors.textNavy,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: isSelected ? Colors.white : AppColors.textNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x06000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
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
                                                    border: Border.all(color: Colors.white, width: 2),
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
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.textNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'MEMBER ID: #$memberId',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (st.effectiveDues > 0)
                                                InkWell(
                                                  onTap: () => _openMarkDuesSheet(st),
                                                  child: Container(
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
                                                ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.sticky_note_2_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 20,
                                                ),
                                                onPressed: () => _openNoteSheet(st),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                                                onSelected: (val) {
                                                  if (val == 'dues') _openMarkDuesSheet(st);
                                                  if (val == 'trial') _toggleTrialStatus(st);
                                                  if (val == 'edit') _openEditStudentSheet(st);
                                                  if (val == 'delete') _confirmDeleteStudent(st);
                                                  if (val == 'restore') _restoreStudent(st);
                                                },
                                                itemBuilder: (ctx) => [
                                                  const PopupMenuItem(
                                                    value: 'dues',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.currency_rupee, size: 18, color: Color(0xFFE11D48)),
                                                        SizedBox(width: 8),
                                                        Text('Mark Due Fees'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'trial',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.science_outlined, size: 18, color: Color(0xFFD97706)),
                                                        SizedBox(width: 8),
                                                        Text(st.status == 'TRIAL' ? 'Convert to Active' : 'Mark as Trial'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textNavy),
                                                        SizedBox(width: 8),
                                                        Text('Edit Student'),
                                                      ],
                                                    ),
                                                  ),
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

                                      // Note Card Banner (Image 1)
                                      InkWell(
                                        onTap: () => _openNoteSheet(st),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFEF3C7)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.description_outlined, color: Color(0xFFD97706), size: 16),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'NOTE',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                        color: Color(0xFFD97706),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      st.note.isNotEmpty
                                                          ? st.note
                                                          : 'Enrolled for ${st.shift}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.textNavy,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD97706), size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // 2x2 Details Grid (Image 7)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'PHONE',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    st.phone.isNotEmpty ? st.phone : 'Not provided',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textNavy,
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
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF64748B)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'STATUS',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF64748B),
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
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'JOINED',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    joinDateStr,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textNavy,
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
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF64748B)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'SEAT',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    seatLabel,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textNavy,
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
                                               color: Colors.white,
                                               borderRadius: BorderRadius.circular(8),
                                               border: Border.all(color: const Color(0xFFE2E8F0)),
                                             ),
                                             child: Row(
                                               mainAxisSize: MainAxisSize.min,
                                               children: [
                                                 const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   shiftTimingStr,
                                                   style: const TextStyle(
                                                     fontSize: 10,
                                                     fontWeight: FontWeight.w600,
                                                     color: Color(0xFF64748B),
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
                                         // Row 1: View | Edit | Pay (Image 1)
                                         Row(
                                           children: [
                                             Expanded(
                                               child: OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   foregroundColor: AppColors.textNavy,
                                                   side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: const Icon(Icons.visibility_outlined, size: 18),
                                                 label: const Text(
                                                   'View',
                                                   style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                                 ),
                                                 onPressed: () => _openViewStudentSheet(st, memberId),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               child: OutlinedButton.icon(
                                                 style: OutlinedButton.styleFrom(
                                                   foregroundColor: AppColors.textNavy,
                                                   side: const BorderSide(color: Color(0xFFE2E8F0)),
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: const Icon(Icons.edit_outlined, size: 18),
                                                 label: const Text(
                                                   'Edit',
                                                   style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                                 ),
                                                 onPressed: () => _openEditStudentSheet(st),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               child: ElevatedButton.icon(
                                                 style: ElevatedButton.styleFrom(
                                                   backgroundColor: const Color(0xFF0D6E66),
                                                   foregroundColor: Colors.white,
                                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                                   elevation: 0,
                                                   shape: RoundedRectangleBorder(
                                                     borderRadius: BorderRadius.circular(14),
                                                   ),
                                                 ),
                                                 icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.white),
                                                 label: const Text(
                                                   'Pay',
                                                   style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                                 ),
                                                 onPressed: () => _openPaySheet(st),
                                               ),
                                             ),
                                           ],
                                         ),
                                         const SizedBox(height: 10),

                                         // Row 2: WhatsApp | SMS Reminder | Delete
                                         Row(
                                           children: [
                                             Expanded(
                                               flex: 5,
                                               child: InkWell(
                                                 borderRadius: BorderRadius.circular(14),
                                                 onTap: () => _sendWhatsApp(st),
                                                 child: Container(
                                                   padding: const EdgeInsets.symmetric(vertical: 11),
                                                   decoration: BoxDecoration(
                                                     color: const Color(0xFFECFDF5),
                                                     borderRadius: BorderRadius.circular(14),
                                                     border: Border.all(color: const Color(0xFFA7F3D0)),
                                                   ),
                                                   child: const Row(
                                                     mainAxisAlignment: MainAxisAlignment.center,
                                                     children: [
                                                       Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 16),
                                                       SizedBox(width: 6),
                                                       Text(
                                                         'WhatsApp',
                                                         style: TextStyle(
                                                           color: Color(0xFF059669),
                                                           fontSize: 13,
                                                           fontWeight: FontWeight.w800,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               flex: 6,
                                               child: InkWell(
                                                 borderRadius: BorderRadius.circular(14),
                                                 onTap: () => _sendSmsReminder(st),
                                                 child: Container(
                                                   padding: const EdgeInsets.symmetric(vertical: 11),
                                                   decoration: BoxDecoration(
                                                     color: const Color(0xFFF0F9FF),
                                                     borderRadius: BorderRadius.circular(14),
                                                     border: Border.all(color: const Color(0xFFBAE6FD)),
                                                   ),
                                                   child: const Row(
                                                     mainAxisAlignment: MainAxisAlignment.center,
                                                     children: [
                                                       Icon(Icons.message_outlined, color: Color(0xFF0284C7), size: 16),
                                                       SizedBox(width: 6),
                                                       Text(
                                                         'SMS Reminder',
                                                         style: TextStyle(
                                                           color: Color(0xFF0284C7),
                                                           fontSize: 13,
                                                           fontWeight: FontWeight.w800,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
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
                                                   Icons.delete_outline_rounded,
                                                   color: Color(0xFFEF4444),
                                                   size: 20,
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                         const SizedBox(height: 10),

                                         // Row 3: Quick Action Chips: Mark Due & Trial
                                         Row(
                                           children: [
                                             Expanded(
                                               child: InkWell(
                                                 borderRadius: BorderRadius.circular(12),
                                                 onTap: () => _openMarkDuesSheet(st),
                                                 child: Container(
                                                   padding: const EdgeInsets.symmetric(vertical: 8),
                                                   decoration: BoxDecoration(
                                                     color: const Color(0xFFFFF1F2),
                                                     borderRadius: BorderRadius.circular(12),
                                                     border: Border.all(color: const Color(0xFFFECDD3)),
                                                   ),
                                                   child: const Row(
                                                     mainAxisAlignment: MainAxisAlignment.center,
                                                     children: [
                                                       Icon(Icons.currency_rupee, size: 14, color: Color(0xFFE11D48)),
                                                       SizedBox(width: 4),
                                                       Text(
                                                         'Mark Due',
                                                         style: TextStyle(
                                                           color: Color(0xFFE11D48),
                                                           fontSize: 12,
                                                           fontWeight: FontWeight.w800,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ),
                                             ),
                                             const SizedBox(width: 8),
                                             Expanded(
                                               child: InkWell(
                                                 borderRadius: BorderRadius.circular(12),
                                                 onTap: () => _toggleTrialStatus(st),
                                                 child: Container(
                                                   padding: const EdgeInsets.symmetric(vertical: 8),
                                                   decoration: BoxDecoration(
                                                     color: st.status == 'TRIAL'
                                                         ? const Color(0xFFECFDF5)
                                                         : const Color(0xFFFFFBEB),
                                                     borderRadius: BorderRadius.circular(12),
                                                     border: Border.all(
                                                       color: st.status == 'TRIAL'
                                                           ? const Color(0xFFA7F3D0)
                                                           : const Color(0xFFFDE68A),
                                                     ),
                                                   ),
                                                   child: Row(
                                                     mainAxisAlignment: MainAxisAlignment.center,
                                                     children: [
                                                       Icon(
                                                         st.status == 'TRIAL' ? Icons.check_circle_outline : Icons.science_outlined,
                                                         size: 14,
                                                         color: st.status == 'TRIAL' ? const Color(0xFF059669) : const Color(0xFFD97706),
                                                       ),
                                                       const SizedBox(width: 4),
                                                       Text(
                                                         st.status == 'TRIAL' ? 'Active Member' : 'Mark Trial',
                                                         style: TextStyle(
                                                           color: st.status == 'TRIAL' ? const Color(0xFF059669) : const Color(0xFFD97706),
                                                           fontSize: 12,
                                                           fontWeight: FontWeight.w800,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
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
                    ),
                  ],
                ),

                // Floating Action Button: [+ New Member] (Images 2 - 5)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddStudentWizardScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                          SizedBox(width: 8),
                          Text(
                            'New Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Widget _shiftChip(String label, IconData? icon) {
    final isSelected = _selectedShiftFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedShiftFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? Colors.white : AppColors.textNavy),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isSelected ? Colors.white : AppColors.textNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
