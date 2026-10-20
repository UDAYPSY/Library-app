import 'package:flutter/material.dart';
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

  // Settings state
  bool _whatsappNotifications = false;
  bool _autoFeeReminders = false;
  bool _autoWelcomeMessage = false;
  bool _autoPaymentReceipt = false;

  bool _remind3DaysBefore = true;
  bool _remindOnExpiry = true;
  bool _remindAfterExpiry = true;

  int _credits = 0;
  int _messagesSent = 0;

  Future<void> _openWhatsAppSupport(String message) async {
    final cleanPhone = _service.profile.adminPhone.replaceAll(RegExp(r'\D'), '');
    final phoneToUse = cleanPhone.isNotEmpty ? cleanPhone : '919457464850';
    final uri = Uri.parse('https://wa.me/$phoneToUse?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _sendAllDueReminders() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.primaryTeal),
            SizedBox(width: 8),
            Text('Send Fee Reminders', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
          ],
        ),
        content: const Text(
          'Send WhatsApp fee reminder to all active students with pending or upcoming dues?',
          style: TextStyle(fontSize: 14, color: AppColors.textNavy),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminders queued! Dispatched to all students with dues.'),
                  backgroundColor: AppColors.primaryTeal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Send Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openChooseSpecificStudentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<List<StudentInfo>>(
        stream: _service.streamStudents(),
        builder: (context, snapshot) {
          final students = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Specific Students',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select students to send an instant fee notification:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No students registered yet.')),
                  )
                else
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final s = students[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0284C7),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Seat #${s.seatNumber ?? 1} • ${s.phone}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openWhatsAppSupport(
                                'Hello ${s.name}, your library fee of Rs.${s.monthlyFee} is scheduled. Please confirm at the desk.',
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCustomizeTemplatesSheet() {
    final welcomeCtrl = TextEditingController(
      text: 'Hello {student_name}, welcome to {_service.profile.libraryName}! Your assigned seat is {seat_number}. Happy studying!',
    );
    final reminderCtrl = TextEditingController(
      text: 'Dear {student_name}, this is a gentle reminder that your library seat fee of Rs.{monthly_fee} is due on {due_date}. Thank you!',
    );
    final receiptCtrl = TextEditingController(
      text: 'Payment Received! Dear {student_name}, we have received Rs.{amount} via {mode} for your seat renewal. Receipt #{receipt_no}.',
    );

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
              const SizedBox(height: 12),
              const Text('Welcome Note', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: welcomeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Fee Reminder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: reminderCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              TextField(
                controller: receiptCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Templates updated successfully!'), behavior: SnackBarBehavior.floating),
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
            // Page Header (Image 2)
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

            // Card 1: WhatsApp Credits (Image 2)
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
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_credits',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                            ),
                            const Text(
                              'CREDITS',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact Us Button (Image 2)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openWhatsAppSupport('Hi, I want to purchase WhatsApp Credits for my library on TrackMyLibrary.'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Contact us for WhatsApp\nCredits',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF16A34A), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Warning Banner (Image 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No credits remaining. Tap above to purchase more.',
                            style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CONTROLS Section (Image 2)
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
                    onChanged: (v) => setState(() => _whatsappNotifications = v),
                  ),
                  const SizedBox(height: 12),
                  // Lock banner (Image 2)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Buy credits to unlock WhatsApp features',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _switchRow(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF0D9488),
                    title: 'Auto Fee Reminders',
                    subtitle: 'Automatically send reminders via Cloud Scheduler daily',
                    value: _autoFeeReminders,
                    onChanged: (v) => setState(() => _autoFeeReminders = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INSTANT NOTIFICATIONS Section (Image 2 & 3)
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
                    onChanged: (v) => setState(() => _autoWelcomeMessage = v),
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.receipt_long_outlined,
                    iconBg: const Color(0xFFF0F9FF),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Automatic Payment Receipt',
                    subtitle: 'Send automated confirmation receipt after payment',
                    value: _autoPaymentReceipt,
                    onChanged: (v) => setState(() => _autoPaymentReceipt = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // REMINDER TIMING Section (Image 3)
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
                    onChanged: (v) => setState(() => _remind3DaysBefore = v),
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.calendar_today_outlined,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFF59E0B),
                    title: 'On Expiry Day',
                    subtitle: 'Reminder sent on the exact day fee expires',
                    value: _remindOnExpiry,
                    onChanged: (v) => setState(() => _remindOnExpiry = v),
                  ),
                  const Divider(height: 24),
                  _switchRow(
                    icon: Icons.error_outline_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFEF4444),
                    title: 'After Expiry (Overdue)',
                    subtitle: 'Students whose fee has already passed',
                    value: _remindAfterExpiry,
                    onChanged: (v) => setState(() => _remindAfterExpiry = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // MANUAL TRIGGER Section (Image 3 & 4)
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
                              'Instantly send to all students with due fees',
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
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textNavy,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _sendAllDueReminders,
                      child: const Text('Send to All Due Students', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
                      icon: const Icon(Icons.people_outline_rounded, size: 18),
                      label: const Text('Choose Specific Students', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      onPressed: _openChooseSpecificStudentsSheet,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Customize Templates Card (Image 4)
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
            const SizedBox(height: 18),

            // Bottom Support Card (Image 4)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Auto reminders run daily at 9 AM via Google Cloud Scheduler. Manual sends happen immediately via the button above.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textNavy,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _openWhatsAppSupport('Hello, I need support with WhatsApp Automation on TrackMyLibrary.'),
                      child: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
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
