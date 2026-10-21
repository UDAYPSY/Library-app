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
    final cleanPhone = LibraryService.normalizePhone(studentPhone);
    final phoneToUse = cleanPhone.isNotEmpty ? '91$cleanPhone' : '919457464850';
    final uri = Uri.parse('https://wa.me/$phoneToUse?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp for $phoneToUse')),
        );
      }
    }
  }

  Future<void> _openWhatsAppSupport(String message) async {
    final cleanPhone = _service.profile.adminPhone.replaceAll(RegExp(r'\D'), '');
    final phoneToUse = cleanPhone.isNotEmpty ? '91$cleanPhone' : '919457464850';
    final uri = Uri.parse('https://wa.me/$phoneToUse?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  String _formatTemplate(String tpl, {required StudentInfo student, int? amount, DateTime? dueDate}) {
    final dueStr = dueDate != null
        ? DateFormat('dd MMM yyyy').format(dueDate)
        : (student.feeDueDate != null ? DateFormat('dd MMM yyyy').format(student.feeDueDate!) : 'Due Soon');
    final dueAmt = amount ?? (student.effectiveDues > 0 ? student.effectiveDues : student.monthlyFee);

    return tpl
        .replaceAll('{student_name}', student.name)
        .replaceAll('{seat_number}', student.seatNumber != null ? '${student.seatNumber}' : 'Unallocated')
        .replaceAll('{shift}', student.shift)
        .replaceAll('{due_amount}', '$dueAmt')
        .replaceAll('{due_date}', dueStr)
        .replaceAll('{amount}', '$dueAmt')
        .replaceAll('{mode}', student.paymentMode)
        .replaceAll('{valid_until}', dueStr)
        .replaceAll('{library_name}', _service.profile.libraryName);
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
                        children: ['Reminder', 'Welcome', 'Receipt'].map((t) {
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
                        height: 260,
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
                              subtitle: Text('Seat #${s.seatNumber ?? "—"} • ${s.phone} • Status: ${s.status}', style: const TextStyle(fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
                                tooltip: 'Send WhatsApp',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _service.useWhatsAppCredit(1);
                                  setState(() {
                                    _credits = _service.profile.whatsappCredits;
                                    _messagesSent = _service.profile.messagesSentCount;
                                  });
                                  String rawTpl = _service.profile.reminderTemplate;
                                  if (templateType == 'Welcome') rawTpl = _service.profile.welcomeTemplate;
                                  if (templateType == 'Receipt') rawTpl = _service.profile.receiptTemplate;

                                  final msg = _formatTemplate(rawTpl, student: s);
                                  _openWhatsAppToStudent(s.phone, msg);
                                },
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
                  const Text('Customize Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Available dynamic tags: {student_name}, {seat_number}, {due_amount}, {due_date}, {library_name}, {shift}, {mode}',
                style: TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const Text('Welcome Note Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: welcomeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Fee Reminder Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: reminderCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Payment Receipt Template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: receiptCtrl,
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
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Templates updated and saved successfully!'), behavior: SnackBarBehavior.floating),
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
