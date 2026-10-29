import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class WhatsAppAutomationScreen extends StatefulWidget {
  const WhatsAppAutomationScreen({super.key});

  @override
  State<WhatsAppAutomationScreen> createState() => _WhatsAppAutomationScreenState();
}

class _WhatsAppAutomationScreenState extends State<WhatsAppAutomationScreen> {
  final LibraryService _service = LibraryService();

  // Settings state persisted from service
  late bool _whatsappNotifications;
  late bool _autoFeeReminders;
  late bool _autoWelcomeMessage;
  late bool _autoPaymentReceipt;

  late bool _remind3DaysBefore;
  late bool _remindOnExpiry;
  late bool _remindAfterExpiry;

  late int _credits;
  late int _messagesSent;

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    _whatsappNotifications = _service.profile.whatsappNotifications;
    _autoFeeReminders = _service.profile.autoFeeReminders;
    _autoWelcomeMessage = _service.profile.autoWelcomeMessage;
    _autoPaymentReceipt = _service.profile.autoPaymentReceipt;
    _remind3DaysBefore = _service.profile.remind3DaysBefore;
    _remindOnExpiry = _service.profile.remindOnExpiry;
    _remindAfterExpiry = _service.profile.remindAfterExpiry;
    _credits = _service.profile.whatsappCredits;
    _messagesSent = _service.profile.messagesSentCount;
  }

  void _persistSettings() {
    _service.saveWhatsAppSettings(
      notifications: _whatsappNotifications,
      autoReminders: _autoFeeReminders,
      autoWelcome: _autoWelcomeMessage,
      autoReceipt: _autoPaymentReceipt,
      remind3DaysBefore: _remind3DaysBefore,
      remindOnExpiry: _remindOnExpiry,
      remindAfterExpiry: _remindAfterExpiry,
    );
  }

  Future<void> _openWhatsAppToStudent(String studentPhone, String message) async {
    final ok = await LibraryService.sendWhatsAppDirect(phone: studentPhone, message: message);
    if (!ok && mounted) {
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open WhatsApp for $studentPhone. Message copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openWhatsAppSupport(String message) async {
    final cleanPhone = _service.profile.adminPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin phone is not configured. Please configure your phone in Settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await LibraryService.sendWhatsAppDirect(phone: cleanPhone, message: message);
    if (!ok && mounted) {
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support text copied to clipboard!'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  String _formatTemplate(String tpl, {required StudentInfo student, int? amount, DateTime? dueDate, String? customNote}) {
    return _service.formatTemplate(
      tpl,
      student: student,
      amount: amount,
      dueDate: dueDate,
      customNote: customNote,
    );
  }

  void _sendAllDueReminders() {
    final dueStudents = _service.getStudentsWithDues();

    if (dueStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
              SizedBox(width: 8),
              Text('All Caught Up!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
            ],
          ),
          content: const Text(
            'No students currently have pending dues! All active memberships are up to date.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Great!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final totalDuesSum = dueStudents.fold<int>(0, (sum, s) => sum + (s.effectiveDues > 0 ? s.effectiveDues : s.duesAmount));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.send_rounded, color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dueStudents.length} Students with Dues',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                        ),
                        Text(
                          'Total Pending: ₹$totalDuesSum',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 280,
              child: ListView.separated(
                itemCount: dueStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = dueStudents[i];
                  final dueAmt = s.effectiveDues > 0 ? s.effectiveDues : s.duesAmount;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFEE2E2),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900),
                      ),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy)),
                    subtitle: Text('Seat #${s.seatNumber ?? "—"} • Due: ₹$dueAmt • ${s.phone}', style: const TextStyle(fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('Send', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      onPressed: () {
                        _service.useWhatsAppCredit(1);
                        setState(() {
                          _credits = _service.profile.whatsappCredits;
                          _messagesSent = _service.profile.messagesSentCount;
                        });
                        final msg = _formatTemplate(_service.profile.reminderTemplate, student: s, amount: dueAmt);
                        _openWhatsAppToStudent(s.phone, msg);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.copy_all_rounded, color: Colors.white, size: 18),
                label: const Text('Copy All Reminder Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                onPressed: () {
                  final allText = dueStudents.map((s) {
                    final dueAmt = s.effectiveDues > 0 ? s.effectiveDues : s.duesAmount;
                    return 'To: ${s.name} (${s.phone})\n' + _formatTemplate(_service.profile.reminderTemplate, student: s, amount: dueAmt);
                  }).join('\n\n------------------------\n\n');
                  Clipboard.setData(ClipboardData(text: allText));
                  _service.useWhatsAppCredit(dueStudents.length);
                  setState(() {
                    _credits = _service.profile.whatsappCredits;
                    _messagesSent = _service.profile.messagesSentCount;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${dueStudents.length} formatted reminders copied to clipboard! Ready to paste into WhatsApp.'),
                      backgroundColor: AppColors.primaryTeal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChooseSpecificStudentsSheet() {
    String search = '';
    String templateType = 'Reminder';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => StreamBuilder<List<StudentInfo>>(
          stream: _service.streamStudents(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? _service.currentStudents;
            final filtered = all.where((s) {
              final q = search.trim().toLowerCase();
              if (q.isEmpty) return true;
              return s.name.toLowerCase().contains(q) ||
                  s.phone.contains(q) ||
                  (s.seatNumber != null && '${s.seatNumber}'.contains(q));
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                          'Send to Specific Student',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Template Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Seat Change',
                          'Shift Change',
                          'Seat Allotment',
                          'Fee Reminder',
                          'Follow-up',
                          'Welcome',
                          'Receipt',
                        ].map((t) {
                          final isSel = templateType == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: isSel ? Colors.white : AppColors.textNavy, fontSize: 12)),
                              selected: isSel,
                              selectedColor: AppColors.primaryTeal,
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (_) => setModalState(() => templateType = t),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by student name, phone, seat...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onChanged: (v) => setModalState(() => search = v),
                    ),
                    const SizedBox(height: 14),

                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No matching students found.', style: TextStyle(color: Color(0xFF94A3B8)))),
                      )
                    else
                      SizedBox(
                        height: 270,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final s = filtered[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0284C7),
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textNavy)),
                              subtitle: Text(
                                'Seat #${s.seatNumber ?? "—"} • ${s.shift} • ${s.phone}',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // SMS Button
                                  IconButton(
                                    icon: const Icon(Icons.sms_outlined, color: Color(0xFF0284C7), size: 20),
                                    tooltip: 'Send SMS',
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      String rawTpl = _service.profile.followupTemplate;
                                      if (templateType == 'Seat Change') rawTpl = _service.profile.seatChangeTemplate;
                                      if (templateType == 'Shift Change') rawTpl = _service.profile.shiftChangeTemplate;
                                      if (templateType == 'Seat Allotment') rawTpl = _service.profile.seatAllotmentTemplate;
                                      if (templateType == 'Fee Reminder' || templateType == 'Reminder') rawTpl = _service.profile.reminderTemplate;
                                      if (templateType == 'Welcome') rawTpl = _service.profile.welcomeTemplate;
                                      if (templateType == 'Receipt') rawTpl = _service.profile.receiptTemplate;

                                      final msg = _formatTemplate(rawTpl, student: s);
                                      final ok = await LibraryService.sendSmsDirect(phone: s.phone, message: msg);
                                      if (!ok && mounted) {
                                        Clipboard.setData(ClipboardData(text: msg));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not open SMS. Message for ${s.name} copied to clipboard!')),
                                        );
                                      }
                                    },
                                  ),
                                  // WhatsApp Button
                                  IconButton(
                                    icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 20),
                                    tooltip: 'Send WhatsApp',
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _service.useWhatsAppCredit(1);
                                      setState(() {
                                        _credits = _service.profile.whatsappCredits;
                                        _messagesSent = _service.profile.messagesSentCount;
                                      });
                                      String rawTpl = _service.profile.followupTemplate;
                                      if (templateType == 'Seat Change') rawTpl = _service.profile.seatChangeTemplate;
                                      if (templateType == 'Shift Change') rawTpl = _service.profile.shiftChangeTemplate;
                                      if (templateType == 'Seat Allotment') rawTpl = _service.profile.seatAllotmentTemplate;
                                      if (templateType == 'Fee Reminder' || templateType == 'Reminder') rawTpl = _service.profile.reminderTemplate;
                                      if (templateType == 'Welcome') rawTpl = _service.profile.welcomeTemplate;
                                      if (templateType == 'Receipt') rawTpl = _service.profile.receiptTemplate;

                                      final msg = _formatTemplate(rawTpl, student: s);
                                      _openWhatsAppToStudent(s.phone, msg);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCustomizeTemplatesSheet() {
    final welcomeCtrl = TextEditingController(text: _service.profile.welcomeTemplate);
    final reminderCtrl = TextEditingController(text: _service.profile.reminderTemplate);
    final receiptCtrl = TextEditingController(text: _service.profile.receiptTemplate);
    final followupCtrl = TextEditingController(text: _service.profile.followupTemplate);
    final seatChangeCtrl = TextEditingController(text: _service.profile.seatChangeTemplate);
    final shiftChangeCtrl = TextEditingController(text: _service.profile.shiftChangeTemplate);
    final seatAllotmentCtrl = TextEditingController(text: _service.profile.seatAllotmentTemplate);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customize Action Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Available tags: {student_name}, {seat_number}, {shift}, {due_amount}, {due_date}, {library_name}, {mode}, {phone}',
                style: TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 14),
              const Text('💺 Seat Change Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: seatChangeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('⏰ Shift Change Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: shiftChangeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('🎫 Seat Allotment Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: seatAllotmentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('🔔 Fee Due Reminder Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: reminderCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('💬 General Follow-up Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: followupCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('🧾 Payment Receipt Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: receiptCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('👋 Welcome Note Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: welcomeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
                  onPressed: () {
                    _service.saveWhatsAppSettings(
                      welcomeTpl: welcomeCtrl.text.trim(),
                      reminderTpl: reminderCtrl.text.trim(),
                      receiptTpl: receiptCtrl.text.trim(),
                      followupTpl: followupCtrl.text.trim(),
                      seatChangeTpl: seatChangeCtrl.text.trim(),
                      shiftChangeTpl: shiftChangeCtrl.text.trim(),
                      seatAllotmentTpl: seatAllotmentCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action templates updated and saved successfully!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Save Templates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFollowupMessengerSheet([StudentInfo? initialStudent]) {
    StudentInfo? selectedStudent = initialStudent;
    String search = '';
    String selectedAction = 'Seat Change';
    final customRemarkCtrl = TextEditingController();
    TextEditingController? messageCtrl;

    String getActionDraft(String action, StudentInfo student, String customRemark) {
      String rawTpl;
      switch (action) {
        case 'Seat Change':
          rawTpl = _service.profile.seatChangeTemplate;
          break;
        case 'Shift Change':
          rawTpl = _service.profile.shiftChangeTemplate;
          break;
        case 'Seat Allotment':
          rawTpl = _service.profile.seatAllotmentTemplate;
          break;
        case 'Fee Reminder':
          rawTpl = _service.profile.reminderTemplate;
          break;
        case 'Custom':
          return 'Hello ${student.name}, this is from ${_service.profile.libraryName}.';
        case 'General Follow-up':
        default:
          rawTpl = _service.profile.followupTemplate;
          break;
      }

      var msg = _service.formatTemplate(
        rawTpl,
        student: student,
        customNote: customRemark.trim().isNotEmpty ? customRemark.trim() : null,
      );

      if (customRemark.trim().isNotEmpty && !rawTpl.contains('{note}')) {
        msg += '\n\n📌 Note: ${customRemark.trim()}';
      }
      return msg;
    }

    void initControllers(StudentInfo s) {
      selectedStudent = s;
      customRemarkCtrl.clear();
      messageCtrl = TextEditingController(text: getActionDraft(selectedAction, s, ''));
    }

    if (initialStudent != null) {
      initControllers(initialStudent);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final all = _service.currentStudents;
          final filtered = all.where((s) {
            final q = search.trim().toLowerCase();
            if (q.isEmpty) return true;
            return s.name.toLowerCase().contains(q) ||
                s.phone.contains(q) ||
                (s.seatNumber != null && '${s.seatNumber}'.contains(q));
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
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
                      const Row(
                        children: [
                          Icon(Icons.assignment_ind_rounded, color: Color(0xFF0D9488), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Follow-up Messenger',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text(
                    'Send action-specific templates (Seat Change, Shift Change, Seat Allotment, Fee Due, Follow-up).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  if (selectedStudent == null) ...[
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search student for follow-up...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onChanged: (v) => setModalState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: filtered.isEmpty
                          ? const Center(child: Text('No students found', style: TextStyle(color: Color(0xFF94A3B8))))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final st = filtered[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFCCFBF1),
                                    child: Text(
                                      st.name.isNotEmpty ? st.name[0].toUpperCase() : 'S',
                                      style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy)),
                                  subtitle: Text(
                                    'Seat #${st.seatNumber ?? "—"} • ${st.shift} • ${st.phone}',
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  onTap: () {
                                    setModalState(() {
                                      initControllers(st);
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF0D9488),
                            child: Text(
                              selectedStudent!.name.isNotEmpty ? selectedStudent!.name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedStudent!.name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textNavy),
                                ),
                                Text(
                                  'Seat #${selectedStudent!.seatNumber ?? "—"} (${selectedStudent!.shift}) • Due: ₹${selectedStudent!.effectiveDues > 0 ? selectedStudent!.effectiveDues : selectedStudent!.monthlyFee}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setModalState(() => selectedStudent = null),
                            child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Draft Selection Chips
                    const Text('Select Action Draft Template:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textNavy)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Seat Change',
                          'Shift Change',
                          'Seat Allotment',
                          'Fee Reminder',
                          'General Follow-up',
                          'Custom',
                        ].map((action) {
                          final isSel = selectedAction == action;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                action,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? Colors.white : AppColors.textNavy,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF0D9488),
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (_) {
                                setModalState(() {
                                  selectedAction = action;
                                  messageCtrl?.text = getActionDraft(action, selectedStudent!, customRemarkCtrl.text);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Custom Remark for THIS message dispatch
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Custom Remark to Message:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textNavy)),
                        Text('(Optional)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: customRemarkCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Granted 2 days extension / Shift effective 1st of next month...',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          messageCtrl?.text = getActionDraft(selectedAction, selectedStudent!, val);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Draft Message to Send:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textNavy)),
                        Text('(Fully Editable)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            onPressed: () async {
                              final textToSend = messageCtrl?.text.trim() ?? '';
                              final remark = customRemarkCtrl.text.trim();
                              if (remark.isNotEmpty) {
                                final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
                                final updatedNote = LibraryService.appendNote(selectedStudent!.note, 'Follow-up ($selectedAction) on $dateStr: $remark');
                                await _service.updateStudentInfo(selectedStudent!.copyWith(note: updatedNote));
                              }
                              _service.useWhatsAppCredit(1);
                              setState(() {
                                _credits = _service.profile.whatsappCredits;
                                _messagesSent = _service.profile.messagesSentCount;
                              });
                              Navigator.pop(ctx);
                              final ok = await LibraryService.sendWhatsAppDirect(
                                phone: selectedStudent!.phone,
                                message: textToSend,
                              );
                              if (!ok && mounted) {
                                Clipboard.setData(ClipboardData(text: textToSend));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open WhatsApp. Message copied to clipboard!')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.sms_outlined, size: 18),
                            label: const Text('SMS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            onPressed: () async {
                              final textToSend = messageCtrl?.text.trim() ?? '';
                              final remark = customRemarkCtrl.text.trim();
                              if (remark.isNotEmpty) {
                                final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
                                final updatedNote = LibraryService.appendNote(selectedStudent!.note, 'Follow-up ($selectedAction) on $dateStr: $remark');
                                await _service.updateStudentInfo(selectedStudent!.copyWith(note: updatedNote));
                              }
                              Navigator.pop(ctx);
                              final ok = await LibraryService.sendSmsDirect(
                                phone: selectedStudent!.phone,
                                message: textToSend,
                              );
                              if (!ok && mounted) {
                                Clipboard.setData(ClipboardData(text: textToSend));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open SMS. Message copied to clipboard!')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Copy Message',
                          icon: const Icon(Icons.copy_rounded, color: AppColors.textNavy),
                          onPressed: () {
                            final textToSend = messageCtrl?.text.trim() ?? '';
                            Clipboard.setData(ClipboardData(text: textToSend));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message copied to clipboard!'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addCreditsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add WhatsApp Credits', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy)),
        content: const Text(
          'Top up WhatsApp credits for demo testing or live notifications.\nChoose top up amount:',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              Navigator.pop(ctx);
              _service.addWhatsAppCredits(100);
              setState(() {
                _credits = _service.profile.whatsappCredits;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('+100 WhatsApp Credits Added!'), backgroundColor: Color(0xFF16A34A)),
              );
            },
            child: const Text('+100 Credits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
          'WhatsApp Automation',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'WhatsApp Automation',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Control how and when fee reminders are sent to your students.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: WhatsApp Credits
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhatsApp Credits',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_messagesSent messages sent lifetime',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _credits > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_credits',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _credits > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              'CREDITS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: _credits > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions: Top-up / Contact Us
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D9488),
                            side: const BorderSide(color: Color(0xFF99F6E4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Add Credits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          onPressed: _addCreditsDialog,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          onPressed: () => _openWhatsAppSupport('Hi, I want to purchase WhatsApp Credits for my library on TrackMyLibrary.'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CONTROLS Section
            const Text(
              'CONTROLS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _switchRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'WhatsApp Notifications',
                    subtitle: 'Enable sending messages via WhatsApp API',
                    value: _whatsappNotifications,
                    onChanged: (v) {
                      setState(() => _whatsappNotifications = v);
                      _persistSettings();
                    },
                  ),
                  const Divider(height: 20),
                  _switchRow(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF0D9488),
                    title: 'Auto Fee Reminders',
                    subtitle: 'Automatically send reminders via Cloud Scheduler daily',
                    value: _autoFeeReminders,
                    onChanged: (v) {
                      setState(() => _autoFeeReminders = v);
                      _persistSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INSTANT NOTIFICATIONS Section
            const Text(
              'INSTANT NOTIFICATIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _switchRow(
                    icon: Icons.person_add_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'Automatic Welcome Message',
                    subtitle: 'Send instant welcome note to newly added students',
                    value: _autoWelcomeMessage,
                    onChanged: (v) {
                      setState(() => _autoWelcomeMessage = v);
                      _persistSettings();
                    },
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.receipt_long_outlined,
                    iconBg: const Color(0xFFF0F9FF),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Automatic Payment Receipt',
                    subtitle: 'Send automated confirmation receipt after payment',
                    value: _autoPaymentReceipt,
                    onChanged: (v) {
                      setState(() => _autoPaymentReceipt = v);
                      _persistSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // REMINDER TIMING Section
            const Text(
              'REMINDER TIMING',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
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
                  const Text(
                    'Choose when students receive reminders relative to their fee expiry date.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  _switchRow(
                    icon: Icons.calendar_month_outlined,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF8B5CF6),
                    title: '3 Days Before Expiry',
                    subtitle: 'Proactive reminder before fee expires',
                    value: _remind3DaysBefore,
                    onChanged: (v) {
                      setState(() => _remind3DaysBefore = v);
                      _persistSettings();
                    },
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.calendar_today_outlined,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'On Expiry Day',
                    subtitle: 'Reminder sent on the exact day fee expires',
                    value: _remindOnExpiry,
                    onChanged: (v) {
                      setState(() => _remindOnExpiry = v);
                      _persistSettings();
                    },
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.error_outline_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFEF4444),
                    title: 'After Expiry (Overdue)',
                    subtitle: 'Students whose fee has already passed',
                    value: _remindAfterExpiry,
                    onChanged: (v) {
                      setState(() => _remindAfterExpiry = v);
                      _persistSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MANUAL TRIGGER Section
            const Text(
              'MANUAL TRIGGER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send Reminders Now',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Instantly send to students with due fees',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.group_rounded, size: 18),
                      label: const Text('Send to All Due Students', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      onPressed: _sendAllDueReminders,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textNavy,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.person_search_rounded, size: 18),
                      label: const Text('Choose Specific Students', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      onPressed: _openChooseSpecificStudentsSheet,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        backgroundColor: const Color(0xFFF0FDFA),
                        side: const BorderSide(color: Color(0xFF99F6E4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                      label: const Text('Follow-up with Student Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      onPressed: () => _openFollowupMessengerSheet(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Customize Templates Card
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openCustomizeTemplatesSheet,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customize Templates',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Edit welcome, payment & reminder messages',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textNavy),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.2),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF0D9488),
          activeTrackColor: const Color(0xFF99F6E4),
        ),
      ],
    );
  }
}
