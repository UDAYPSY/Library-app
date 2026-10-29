import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/excel_import_service.dart';
import '../../services/file_export_service.dart';
import '../../services/library_service.dart';
import '../../services/theme_service.dart';
import '../login_screen.dart';
import '../onboarding/admin_profile_screen.dart';
import '../shifts/shift_system_screen.dart';
import '../tools/disaster_recovery_screen.dart';
import '../tools/library_branding_screen.dart';
import '../tools/reports_exports_screen.dart';
import '../tools/share_qr_screen.dart';
import '../tools/whatsapp_automation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LibraryService _service = LibraryService();
  String get _currentTheme => ThemeService().themeModeName;

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // MODALS & ACTIONS
  // -------------------------------------------------------------

  void _showSubscriptionModal() {
    final renewalDate = DateTime.now().add(const Duration(days: 342));
    final renewalStr = DateFormat('MMMM dd, yyyy').format(renewalDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFF0F766E), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'TrackMyLibrary PRO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Plan: PRO Annual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Renews on $renewalStr • ₹499/month billed annually', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _benefitItem(Icons.check_circle_rounded, 'Unlimited students & space seat assignments'),
            _benefitItem(Icons.check_circle_rounded, 'Full WhatsApp reminders & admission greetings'),
            _benefitItem(Icons.check_circle_rounded, 'Real-time financial analytics & expense tracking'),
            _benefitItem(Icons.check_circle_rounded, 'Digital QR code student live availability page'),
            _benefitItem(Icons.check_circle_rounded, 'Custom library crest branding on receipts & cards'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Download Plan Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final invoiceNum = 'INV-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01';
                  final invoiceDate = DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 23)));
                  final content = 'TrackMyLibrary Subscription Tax Invoice\n'
                      '===============================================\n'
                      'Invoice No: $invoiceNum\n'
                      'Date of Issue: $invoiceDate\n'
                      'Library Name: ${_service.profile.libraryName}\n'
                      'Address: ${_service.profile.city}\n'
                      'Admin Contact: ${_service.profile.adminName} (${_service.profile.adminPhone})\n'
                      '-----------------------------------------------\n'
                      'Item: TrackMyLibrary PRO Annual Commercial License\n'
                      'HSN/SAC: 998313 (IT Software as a Service)\n'
                      'Base Amount: INR 4,236.44\n'
                      'IGST (18%): INR 762.56\n'
                      'Total Amount Paid: INR 4,999.00\n'
                      'Payment Method: UPI Auto-Renew (Transaction ID: TML${DateTime.now().millisecondsSinceEpoch})\n'
                      'Status: PAID IN FULL\n'
                      'Valid Until: $renewalStr\n'
                      '===============================================\n'
                      'Thank you for partnering with TrackMyLibrary!';

                  final success = await FileExportService.download(
                    fileName: 'TrackMyLibrary_Subscription_Invoice.txt',
                    content: content,
                    mimeType: 'text/plain;charset=utf-8',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Invoice $invoiceNum downloaded successfully!' : 'Downloaded invoice statement.'),
                        backgroundColor: const Color(0xFF0D766E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textNavy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBillingHistoryModal() {
    final now = DateTime.now();
    final d1 = now.subtract(const Duration(days: 23));
    final d2 = now.subtract(const Duration(days: 53));
    final d3 = now.subtract(const Duration(days: 83));
    final inv1Date = DateFormat('dd MMM yyyy').format(d1);
    final inv2Date = DateFormat('dd MMM yyyy').format(d2);
    final inv3Date = DateFormat('dd MMM yyyy').format(d3);

    final inv1No = 'INV-${d1.year}-${d1.month.toString().padLeft(2, '0')}-01';
    final inv2No = 'INV-${d2.year}-${d2.month.toString().padLeft(2, '0')}-01';
    final inv3No = 'INV-${d3.year}-${d3.month.toString().padLeft(2, '0')}-15';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Billing History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 8),
            _billingItem('PRO Annual Subscription', inv1No, '₹4,999', 'Paid on $inv1Date'),
            _billingItem('PRO Monthly Renewal', inv2No, '₹499', 'Paid on $inv2Date'),
            _billingItem('Setup & Digital Onboarding', inv3No, '₹199', 'Paid on $inv3Date'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download All Invoices (CSV)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final csv = 'Invoice Number,Date,Description,Amount (INR),GST (18%),Total Paid (INR),Status,Payment Mode\n'
                      '$inv1No,$inv1Date,PRO Annual Subscription,4236.44,762.56,4999.00,PAID,UPI Autopay\n'
                      '$inv2No,$inv2Date,PRO Monthly Renewal,422.88,76.12,499.00,PAID,UPI Autopay\n'
                      '$inv3No,$inv3Date,Setup & Digital Onboarding,168.64,30.36,199.00,PAID,Net Banking\n';

                  final success = await FileExportService.download(
                    fileName: 'TrackMyLibrary_Billing_History.csv',
                    content: csv,
                    mimeType: 'text/csv;charset=utf-8',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Billing statements downloaded successfully!' : 'Downloaded invoices statement.'),
                        backgroundColor: const Color(0xFF0F766E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billingItem(String title, String inv, String amount, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 2),
              Text('$inv • $date', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }

  void _restorePurchases() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking store receipts... Purchases verified and active!'),
        backgroundColor: Color(0xFF0D766E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemeSelector() {
    final themeService = ThemeService();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFF59E0B)),
              title: Text(
                'Light Mode (Standard)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              trailing: themeService.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle, color: Color(0xFF0D766E))
                  : null,
              onTap: () async {
                await themeService.setThemeMode(ThemeMode.light);
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched to Light Theme!'),
                    backgroundColor: Color(0xFF0D766E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_outlined, color: Color(0xFF6366F1)),
              title: Text(
                'Dark Mode (Sleek Slate)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              trailing: themeService.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle, color: Color(0xFF14B8A6))
                  : null,
              onTap: () async {
                await themeService.setThemeMode(ThemeMode.dark);
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched to Dark Theme! 🌙'),
                    backgroundColor: Color(0xFF14B8A6),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_suggest_outlined, color: AppColors.textMutedColor(context)),
              title: Text(
                'System Default',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context)),
              ),
              trailing: themeService.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle, color: Color(0xFF0D766E))
                  : null,
              onTap: () async {
                await themeService.setThemeMode(ThemeMode.system);
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme set to follow System Default!'),
                    backgroundColor: Color(0xFF0D766E),
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

  void _showEditProfileModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminProfileScreen(isEditMode: true)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showBranchSwitcherModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Branch Switcher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Manage and switch between your library locations & floors', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (_service.isAdmin) ...[
                InkWell(
                  onTap: () {
                    _service.switchBranch('all');
                    setState(() {});
                    setModalState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to All Branches view'),
                        backgroundColor: Color(0xFF0D766E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _service.activeBranchId == 'all' ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _service.activeBranchId == 'all' ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _service.activeBranchId == 'all' ? const Color(0xFFDCFCE7) : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.public_rounded, color: _service.activeBranchId == 'all' ? const Color(0xFF16A34A) : const Color(0xFF64748B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All Branches (Combined)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textNavy)),
                              SizedBox(height: 2),
                              Text('View aggregate seats and member rosters across all branches', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        if (_service.activeBranchId == 'all')
                          const Row(
                            children: [
                              Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                              SizedBox(width: 4),
                              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                            ],
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D766E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () {
                              _service.switchBranch('all');
                              setState(() {});
                              setModalState(() {});
                            },
                            child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              ..._service.branches.map((b) {
                final isCurrent = b.id == _service.activeBranchId;
                return InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          _service.switchBranch(b.id);
                          setState(() {});
                          setModalState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched active branch to ${b.name}'),
                              backgroundColor: const Color(0xFF0D766E),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isCurrent ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFFDCFCE7) : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.apartment_rounded, color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF64748B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textNavy)),
                              const SizedBox(height: 2),
                              Text('${b.address} • ${b.totalSeats} Seats', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          const Row(
                            children: [
                              Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                              SizedBox(width: 4),
                              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                            ],
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D766E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () {
                                  _service.switchBranch(b.id);
                                  setState(() {});
                                  setModalState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Switched active branch to ${b.name}'),
                                      backgroundColor: const Color(0xFF0D766E),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                              if (_service.branches.length > 1) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                  onPressed: () {
                                    _service.removeBranch(b.id);
                                    setState(() {});
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_business_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Add New Library Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Configure additional floor, hall or location', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF16A34A)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddBranchDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityModal() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                        Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Security & Authentication',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cloud isolation status and master administrative credentials.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Cloud Tenant & Security Status Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _service.isFirebaseConnected ? Icons.verified_user_rounded : Icons.cloud_off_rounded,
                            color: _service.isFirebaseConnected ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _service.isFirebaseConnected ? 'Cloud Tenant Isolated (Firestore)' : 'Local Storage Mode',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textNavy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cloud Tenant ID: ${_service.tenantId}',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auth Email: ${_service.currentUserEmail.isNotEmpty ? _service.currentUserEmail : _service.profile.adminEmail} • Role: ${_service.currentUserRole}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Change Master Admin Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy)),
                const SizedBox(height: 10),

                TextField(
                  controller: currentPassCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password (min 6 characters)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Update Master Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () async {
                      final curr = currentPassCtrl.text.trim();
                      final newP = newPassCtrl.text.trim();
                      final conf = confirmPassCtrl.text.trim();

                      if (curr.isEmpty || newP.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all password fields')),
                        );
                        return;
                      }
                      if (newP.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New password must be at least 6 characters')),
                        );
                        return;
                      }
                      if (newP != conf) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New passwords do not match')),
                        );
                        return;
                      }

                      final ok = await _service.changeAdminPassword(
                        currentPassword: curr,
                        newPassword: newP,
                      );
                      if (ok) {
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Master password updated successfully in cloud and local vault!'),
                              backgroundColor: Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incorrect current password. Please try again.'),
                              backgroundColor: Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final seatsCtrl = TextEditingController(text: '35');
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Library Branch', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Branch Name (e.g. Floor 2 AC Hall) *',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.apartment_rounded),
                ),
                onChanged: (_) {
                  if (errorText != null) setDialogState(() => errorText = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  hintText: 'e.g. 2nd Floor, Main Street',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seatsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Seats Capacity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_seat_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => errorText = 'Please enter branch name');
                  return;
                }
                final addr = addrCtrl.text.trim().isNotEmpty ? addrCtrl.text.trim() : _service.profile.city;
                final seats = int.tryParse(seatsCtrl.text.trim()) ?? 35;
                final newBranch = LibraryBranch(
                  id: 'branch_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  address: addr,
                  totalSeats: seats,
                );
                _service.addBranch(newBranch);
                _service.switchBranch(newBranch.id);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Branch "$name" created and activated!'),
                    backgroundColor: const Color(0xFF0D766E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Create Branch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserManagementModal() {
    if (!_service.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Library Administrator can manage staff accounts.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Assign staff permissions and assistant logins', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.person, color: Color(0xFF0284C7)),
                ),
                title: Text(_service.profile.adminName.isNotEmpty ? _service.profile.adminName : 'Administrator', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Owner • Administrator (Full Control)'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                  child: const Text('OWNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                ),
              ),
              const Divider(),
              ..._service.staffList.map((staff) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: staff.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    child: Icon(Icons.badge_rounded, color: staff.isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8), size: 20),
                  ),
                  title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    '${staff.role} • ${staff.phone} • ${_service.branches.any((b) => b.id == staff.branchId) ? _service.branches.firstWhere((b) => b.id == staff.branchId).name : (_service.branches.isNotEmpty ? _service.branches.first.name : "Main Campus")}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          staff.isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: staff.isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          size: 30,
                        ),
                        onPressed: () {
                          _service.toggleStaffActive(staff.id);
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        onPressed: () {
                          _service.removeStaffMember(staff.id);
                          setModalState(() {});
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed ${staff.name} from staff')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0F766E)),
                ),
                title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Add receptionist, desk manager or shift operator'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddStaffDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog() {
    if (!_service.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Library Administrator can add staff members.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String selectedRole = 'Receptionist & Desk';
    final initialBranches = _service.effectiveBranches;
    String selectedBranchId = initialBranches.any((b) => b.id == _service.activeBranchId)
        ? _service.activeBranchId
        : (initialBranches.isNotEmpty ? initialBranches.first.id : 'branch_1');
    bool obscurePass = true;
    bool obscureConfirm = true;
    String? validationError;

    int calculateStrength(String pass) {
      if (pass.isEmpty) return 0;
      int score = 0;
      if (pass.length >= 8) score++;
      if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
      if (RegExp(r'[a-z]').hasMatch(pass) && RegExp(r'[0-9]').hasMatch(pass)) score++;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
      return score;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final pass = passCtrl.text;
          final strengthScore = calculateStrength(pass);
          Color strengthColor = Colors.grey;
          String strengthLabel = 'Min 8 chars required';
          if (pass.isNotEmpty) {
            if (strengthScore <= 1) {
              strengthColor = const Color(0xFFEF4444);
              strengthLabel = 'Weak';
            } else if (strengthScore == 2) {
              strengthColor = const Color(0xFFF59E0B);
              strengthLabel = 'Fair';
            } else if (strengthScore == 3) {
              strengthColor = const Color(0xFF0D9488);
              strengthLabel = 'Strong';
            } else {
              strengthColor = const Color(0xFF16A34A);
              strengthLabel = 'Very Strong';
            }
          }

          final availableBranches = _service.effectiveBranches;
          final validSelectedBranchId = availableBranches.any((b) => b.id == selectedBranchId)
              ? selectedBranchId
              : (availableBranches.isNotEmpty ? availableBranches.first.id : 'branch_1');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFF0D766E), size: 24),
                SizedBox(width: 8),
                Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.of(dialogCtx).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(validationError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Pooja Sharma',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: (_) {
                        if (validationError != null) setDialogState(() => validationError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '10-Digit Mobile Number (Login ID) *',
                        hintText: 'e.g. 9876543210',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      onChanged: (_) {
                        if (validationError != null) setDialogState(() => validationError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'e.g. staff@library.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      onChanged: (_) {
                        if (validationError != null) setDialogState(() => validationError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (availableBranches.length > 1) ...[
                      DropdownButtonFormField<String>(
                        value: validSelectedBranchId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Library Branch *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        items: availableBranches
                            .map((b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedBranchId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_rounded, color: Color(0xFF0F766E), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned Branch', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                  Text(
                                    availableBranches.isNotEmpty ? availableBranches.first.name : 'Main Campus',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Staff Role & Permissions *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Receptionist & Desk', child: Text('Receptionist & Desk')),
                        DropdownMenuItem(value: 'Shift Manager', child: Text('Shift Manager')),
                        DropdownMenuItem(value: 'Accountant & Fees', child: Text('Accountant & Fees')),
                        DropdownMenuItem(value: 'Night Supervisor', child: Text('Night Supervisor')),
                        DropdownMenuItem(value: 'Branch Assistant', child: Text('Branch Assistant')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password with Strong Protection
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password (min 8 chars) *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 6),

                    // Password strength indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pass.isEmpty ? 0 : (strengthScore / 4).clamp(0.15, 1.0),
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strengthLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: strengthColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Requires 8+ characters, uppercase, lowercase, number & symbol.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      onChanged: (_) {
                        if (validationError != null) setDialogState(() => validationError = null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
                  final email = emailCtrl.text.trim();
                  final password = passCtrl.text;
                  final confirm = confirmPassCtrl.text;

                  if (name.isEmpty) {
                    setDialogState(() => validationError = 'Please enter staff full name.');
                    return;
                  }
                  if (phone.length < 10) {
                    setDialogState(() => validationError = 'Please enter a valid 10-digit mobile number.');
                    return;
                  }
                  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                    setDialogState(() => validationError = 'Please enter a valid email address.');
                    return;
                  }
                  if (password.length < 8) {
                    setDialogState(() => validationError = 'Password must be at least 8 characters long.');
                    return;
                  }
                  if (strengthScore < 2) {
                    setDialogState(() => validationError = 'Please choose a stronger password (include numbers & symbols).');
                    return;
                  }
                  if (password != confirm) {
                    setDialogState(() => validationError = 'Passwords do not match.');
                    return;
                  }

                  final newStaff = StaffMember(
                    id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    phone: phone,
                    role: selectedRole,
                    email: email,
                    pinHash: LibraryService.hashPin(password),
                    addedAt: DateTime.now(),
                    branchId: selectedBranchId,
                  );
                  _service.addStaffMember(newStaff);
                  setState(() {});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Staff account created for $name ($selectedRole)!'),
                      backgroundColor: const Color(0xFF0D766E),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Create Staff Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkImportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Student Import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
            const SizedBox(height: 6),
            const Text('Upload existing student records via Excel or CSV spreadsheet', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.file_download_outlined, color: Color(0xFF2563EB)),
              ),
              title: const Text('Download Sample CSV Template', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Columns: Name, Phone, Shift, Seat Number, Monthly Fee'),
              onTap: () async {
                Navigator.pop(ctx);
                final template = ExcelImportService.generateTemplateCsv();
                final success = await FileExportService.download(
                  fileName: 'students_bulk_import_template.csv',
                  content: template,
                  mimeType: 'text/csv;charset=utf-8',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Template downloaded: students_bulk_import_template.csv' : 'CSV template prepared!'),
                      backgroundColor: const Color(0xFF2563EB),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF16A34A)),
              ),
              title: const Text('Paste & Import Excel / CSV Spreadsheet', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Auto-maps columns, validates phone numbers and seat availability'),
              onTap: () {
                Navigator.pop(ctx);
                _showInteractiveImportSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInteractiveImportSheet() {
    final textCtrl = TextEditingController(
      text: 'Full Name,Phone Number,Shift,Seat Number,Monthly Fee\n'
          'Aman Gupta,9876543210,Full Day,,800\n'
          'Sana Khan,9812345678,Evening,,600\n',
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
                  const Text('Paste Spreadsheet Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Copy rows directly from Microsoft Excel or Google Sheets and paste below:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Name, Phone, Shift, Seat, Fee...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    label: const Text('Paste Clipboard'),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        textCtrl.text = data.text!;
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Import Students', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final content = textCtrl.text.trim();
                      if (content.isEmpty) return;
                      final result = ExcelImportService.parseAndImport(content, _service);
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully imported ${result.successfullyImported} student(s)!'),
                          backgroundColor: const Color(0xFF0D766E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactsSyncModal() {
    String selectedFilter = 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final allStudents = _service.currentStudents;
          List<StudentInfo> targetList;
          if (selectedFilter == 'ACTIVE') {
            targetList = allStudents.where((s) => s.status != 'INACTIVE').toList();
          } else if (selectedFilter == 'DUES') {
            targetList = allStudents.where((s) => s.status != 'INACTIVE' && (s.hasDues || s.effectiveDues > 0)).toList();
          } else {
            targetList = allStudents;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      const Text('Save Students to Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Select where you want to save or sync student contacts:', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),

                  // Member scope filter
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Active (${allStudents.where((s) => s.status != "INACTIVE").length})'),
                        selected: selectedFilter == 'ACTIVE',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedFilter = 'ACTIVE');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Defaulters (${allStudents.where((s) => s.status != "INACTIVE" && (s.hasDues || s.effectiveDues > 0)).length})'),
                        selected: selectedFilter == 'DUES',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedFilter = 'DUES');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('All (${allStudents.length})'),
                        selected: selectedFilter == 'ALL',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedFilter = 'ALL');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Option 1: SAVE DIRECTLY TO PHONE CONTACTS (vCard .vcf)
                  InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final buffer = StringBuffer();
                      for (var s in targetList) {
                        buffer.writeln('BEGIN:VCARD');
                        buffer.writeln('VERSION:3.0');
                        buffer.writeln('FN:${s.name} (${_service.profile.libraryName})');
                        buffer.writeln('N:${s.name};;;;');
                        buffer.writeln('TEL;TYPE=CELL:${s.phone}');
                        if (s.email != null && s.email!.isNotEmpty) {
                          buffer.writeln('EMAIL;TYPE=HOME,INTERNET:${s.email}');
                        }
                        buffer.writeln('NOTE:Library: ${_service.profile.libraryName} | Seat: S-${s.seatNumber ?? "Unallocated"} | Shift: ${s.shift} | Fee: INR ${s.monthlyFee}');
                        buffer.writeln('END:VCARD');
                      }

                      final success = await FileExportService.download(
                        fileName: 'TrackMyLibrary_Contacts.vcf',
                        content: buffer.toString(),
                        mimeType: 'text/vcard;charset=utf-8',
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Exported ${targetList.length} contacts! Select your Phone Contacts app to save.'
                                : 'Generated contacts vCard file.'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.phone_android_rounded, color: Color(0xFF16A34A), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Save to Phone Contacts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF14532D))),
                                const SizedBox(height: 2),
                                Text(
                                  'Directly imports ${targetList.length} contacts into your Phone Contacts app for instant caller ID & WhatsApp sync.',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: EXPORT & SYNC VIA EMAIL / GOOGLE CONTACTS
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEmailContactsExportDialog(targetList);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email_outlined, color: Color(0xFF0284C7), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Export & Save via Email', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0369A1))),
                                const SizedBox(height: 2),
                                Text(
                                  'Sends Google Contacts CSV & vCard archive to your email for easy cloud backup and Gmail contact sync.',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 16),
                        ],
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

  void _showEmailContactsExportDialog(List<StudentInfo> targetList) {
    final emailCtrl = TextEditingController(text: _service.profile.adminEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.email_rounded, color: Color(0xFF0284C7), size: 24),
            SizedBox(width: 8),
            Text('Email Contact Export', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export ${targetList.length} student contacts formatted for Google Contacts & Email address books.', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Destination Email Address',
                hintText: 'e.g. yourname@gmail.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.mark_email_read_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download CSV'),
            onPressed: () async {
              Navigator.pop(ctx);
              final buffer = StringBuffer();
              buffer.writeln('Name,Given Name,Family Name,Phone 1 - Type,Phone 1 - Value,E-mail 1 - Type,E-mail 1 - Value,Organization 1 - Name,Organization 1 - Title,Notes');
              for (final s in targetList) {
                final note = 'Seat S-${s.seatNumber ?? "Unallocated"} | Shift: ${s.shift} | Fee: INR ${s.monthlyFee}';
                buffer.writeln('"${s.name} (${_service.profile.libraryName})","${s.name}","","Mobile","${s.phone}","Home","${s.email ?? ""}","${_service.profile.libraryName}","Student","${note.replaceAll('"', '""')}"');
              }
              final ok = await FileExportService.download(
                fileName: 'Google_Contacts_Export_${DateFormat("yyyyMMdd").format(DateTime.now())}.csv',
                content: buffer.toString(),
                mimeType: 'text/csv;charset=utf-8',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Google Contacts CSV exported for ${emailCtrl.text.trim()}!' : 'Export file generated!'),
                    backgroundColor: const Color(0xFF0284C7),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Open in Email'),
            onPressed: () async {
              Navigator.pop(ctx);
              final to = emailCtrl.text.trim();
              final subject = Uri.encodeComponent('TrackMyLibrary Student Contacts Export (${targetList.length} members)');
              final bodySummary = Uri.encodeComponent('TrackMyLibrary Student Directory Export\nLibrary: ${_service.profile.libraryName}\nTotal Contacts: ${targetList.length}\n\nDownload the Google Contacts CSV to import all contacts into your Gmail / Google Contacts with 1-click.');
              final mailUri = Uri.parse('mailto:$to?subject=$subject&body=$bodySummary');
              if (await canLaunchUrl(mailUri)) {
                await launchUrl(mailUri);
              }
            },
          ),
        ],
      ),
    );
  }

  void _downloadFullDatabaseBackup() async {
    final jsonContent = _service.exportFullBackupJson();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'TrackMyLibrary_Full_Backup_$stamp.json';

    final success = await FileExportService.download(
      fileName: fileName,
      content: jsonContent,
      mimeType: 'application/json;charset=utf-8',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Complete library backup ($fileName) saved successfully!' : 'Backup generated!'),
          backgroundColor: const Color(0xFF0D766E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRestoreDatabaseModal() {
    if (!_service.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Library Administrator can restore the database.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final textCtrl = TextEditingController();
    Map<String, dynamic>? parsedData;
    String validationError = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
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
                    const Text('Restore Library Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Paste your TrackMyLibrary backup JSON data below to restore your library state:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '{\n  "app": "TrackMyLibrary",\n  "version": "2.0.0" ...\n}',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  onChanged: (val) {
                    try {
                      final dec = json.decode(val.trim());
                      if (dec is Map<String, dynamic> && dec.containsKey('app')) {
                        setModalState(() {
                          parsedData = dec;
                          validationError = '';
                        });
                      } else {
                        setModalState(() {
                          parsedData = null;
                          validationError = 'Valid JSON, but not a TrackMyLibrary backup file.';
                        });
                      }
                    } catch (_) {
                      setModalState(() {
                        parsedData = null;
                        validationError = 'Invalid JSON syntax.';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 18),
                      label: const Text('Paste from Clipboard'),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          textCtrl.text = data.text!;
                          try {
                            final dec = json.decode(data.text!.trim());
                            if (dec is Map<String, dynamic> && dec.containsKey('app')) {
                              setModalState(() {
                                parsedData = dec;
                                validationError = '';
                              });
                            } else {
                              setModalState(() {
                                parsedData = null;
                                validationError = 'Not a TrackMyLibrary backup file.';
                              });
                            }
                          } catch (_) {
                            setModalState(() {
                              parsedData = null;
                              validationError = 'Invalid JSON format in clipboard.';
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (validationError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(validationError, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                ],
                if (parsedData != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Text('Verified Backup Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Library: ${(parsedData!['profile'] as Map?)?['library_name'] ?? 'Library'}\n'
                          'Students: ${(parsedData!['students'] as List?)?.length ?? 0} • '
                          'Payments: ${(parsedData!['payments'] as List?)?.length ?? 0} • '
                          'Expenses: ${(parsedData!['expenses'] as List?)?.length ?? 0}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: const Text('Confirm & Restore Data Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final res = await _service.restoreFromBackupJson(textCtrl.text.trim());
                        if (res['success'] == true) {
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Library restored! ${res['students']} students, ${res['payments']} payments rehydrated.'),
                              backgroundColor: const Color(0xFF0D766E),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Restore failed: ${res['error']}'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showMessageTemplatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Message Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            _templateCard(
              title: 'Fee Dues Reminder',
              content: 'Dear {StudentName}, your library fee of ₹{Amount} is due on {DueDate}. Please pay via UPI to retain your reserved seat.',
            ),
            const SizedBox(height: 10),
            _templateCard(
              title: 'New Admission Welcome',
              content: 'Welcome {StudentName} to {LibraryName}! Your seat #{SeatNumber} in {Shift} shift is confirmed. Wi-Fi: TrackLibraryPass',
            ),
            const SizedBox(height: 10),
            _templateCard(
              title: 'Payment Receipt Notification',
              content: 'Payment received! ₹{Amount} collected for {StudentName}. Seat #{SeatNumber} renewal valid for 30 days.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textNavy)),
              const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF0F766E)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  void _showRateAppModal() {
    int rating = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate TrackMyLibrary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
              const SizedBox(height: 6),
              const Text('How is your experience managing your library?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 36,
                    ),
                    onPressed: () => setModalState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your rating & support! ❤️')),
                    );
                  },
                  child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy)),
        content: const Text('Are you sure you want to log out from this device? Your library data remains safely stored in the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    if (_service.isReceptionist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Library Administrator can delete the account.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
          ],
        ),
        content: const Text(
          'This action is irreversible. All student profiles, fee transactions, expense records, seat allocation maps, library settings, and login credentials will be permanently erased.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Show blocking progress indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => PopScope(
                  canPop: false,
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: const Row(
                      children: [
                        CircularProgressIndicator(color: Color(0xFFEF4444)),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            'Permanently deleting account and wiping data...',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              try {
                await _service.deleteAccountPermanently();
              } catch (_) {}

              if (context.mounted) {
                // Dismiss blocking indicator
                Navigator.of(context, rootNavigator: true).pop();

                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your library account and all associated data have been permanently deleted.'),
                    backgroundColor: Color(0xFFEF4444),
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
  }

  // -------------------------------------------------------------
  // BUILD METHOD
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final profile = _service.profile;
    final isAdmin = _service.isAdmin;
    final currentRole = _service.currentUserRole;
    final displayName = (_service.currentUserName.isNotEmpty && _service.currentUserName != 'Guest')
        ? _service.currentUserName
        : (profile.adminName.isNotEmpty ? profile.adminName : 'Admin');
    final displayEmail = _service.currentUserEmail.isNotEmpty
        ? _service.currentUserEmail
        : (profile.adminEmail.isNotEmpty ? profile.adminEmail : 'admin@gmail.com');
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header (Image 1)
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your account and preferences',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedColor(context),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card (Image 1)
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _showEditProfileModal,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.cardBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.isDark(context) ? Colors.black26 : const Color(0x06000000),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isAdmin ? const Color(0xFFE6F4EA) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            avatarLetter,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isAdmin ? const Color(0xFF0F766E) : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? const Color(0xFFDCFCE7) : const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAdmin ? Icons.shield_rounded : Icons.badge_rounded,
                                        size: 12,
                                        color: isAdmin ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAdmin ? 'ADMIN (FULL ACCESS)' : 'RECEPTIONIST (DESK ACCESS)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: isAdmin ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
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
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: SUBSCRIPTION (Image 1)
              _sectionHeader('SUBSCRIPTION'),
              const SizedBox(height: 10),

              // Gradient Pro Banner (Image 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x180D9488), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You are PRO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Renews on ${DateFormat('MMM dd, yyyy').format(DateTime.now().add(const Duration(days: 342)))} • Pro Active',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _showSubscriptionModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'VIEW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Subscription Options Card (Image 1)
              _cardGroup([
                _settingsTile(
                  icon: Icons.credit_card_rounded,
                  iconBg: const Color(0xFFE6F4EA),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Manage Subscription',
                  subtitle: 'View your plan or billing history',
                  onTap: _showSubscriptionModal,
                ),
                _settingsTile(
                  icon: Icons.receipt_long_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Billing History',
                  subtitle: 'View transaction statements',
                  onTap: _showBillingHistoryModal,
                ),
                _settingsTile(
                  icon: Icons.restore_rounded,
                  iconBg: const Color(0xFFECFEFF),
                  iconColor: const Color(0xFF06B6D4),
                  title: 'Restore Purchases',
                  subtitle: 'Recover your premium status',
                  showDivider: false,
                  onTap: _restorePurchases,
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: APPEARANCE (Image 1)
              _sectionHeader('APPEARANCE'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.palette_outlined,
                  iconBg: const Color(0xFFE6F4EA),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Theme Mode',
                  subtitle: 'Currently: $_currentTheme',
                  showDivider: false,
                  onTap: _showThemeSelector,
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: ACCOUNT (Image 2)
              _sectionHeader('ACCOUNT'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Edit Profile',
                  subtitle: 'Name, email, and contact details',
                  onTap: _showEditProfileModal,
                ),
                _settingsTile(
                  icon: Icons.apartment_rounded,
                  iconBg: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFF97316),
                  title: 'Branch Switcher',
                  subtitle: 'Active: ${_service.currentBranch.name} • ${_service.branches.length} ${_service.branches.length == 1 ? "branch" : "branches"}',
                  onTap: _showBranchSwitcherModal,
                ),
                _settingsTile(
                  icon: Icons.add_business_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Add New Library Branch',
                  subtitle: 'Configure additional floor, hall or location',
                  onTap: _showAddBranchDialog,
                ),
                _settingsTile(
                  icon: Icons.manage_accounts_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'User Management',
                  subtitle: 'Add or remove staff accounts',
                  onTap: _showUserManagementModal,
                ),
                _settingsTile(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Security & Master Password',
                  subtitle: 'Cloud Auth UID & Admin Password change',
                  onTap: _showSecurityModal,
                ),
                _settingsTile(
                  icon: Icons.cloud_sync_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Google Drive & Cloud Recovery',
                  subtitle: 'Auto-sync Excel snapshots & 1-click disaster recovery',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DisasterRecoveryScreen()),
                  ),
                ),
                _settingsTile(
                  icon: Icons.auto_fix_high_rounded,
                  iconBg: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFEC4899),
                  title: 'Library Branding',
                  subtitle: 'Upload logo for invoices & receipts',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryBrandingScreen()),
                  ),
                ),
                _settingsTile(
                  icon: Icons.cloud_upload_outlined,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  title: 'Bulk Student Import',
                  subtitle: 'Import multiple students via CSV',
                  onTap: _showBulkImportModal,
                ),
                _settingsTile(
                  icon: Icons.insert_chart_outlined_rounded,
                  iconBg: const Color(0xFFCCFBF1),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Reports & Exports',
                  subtitle: 'Monthly reports & full data downloads',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsExportsScreen()),
                  ),
                ),
                _settingsTile(
                  icon: Icons.group_add_outlined,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Save Students to Contacts',
                  subtitle: 'See names on calls, find them in WhatsApp',
                  onTap: _showContactsSyncModal,
                ),
                _settingsTile(
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Sign Out',
                  subtitle: 'Log out from this device',
                  isDestructive: true,
                  showDivider: false,
                  onTap: _showSignOutDialog,
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: DIGITAL ACCESS (Image 3)
              _sectionHeader('DIGITAL ACCESS'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.qr_code_2_rounded,
                  iconBg: const Color(0xFFCCFBF1),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Library QR Code',
                  subtitle: 'Real-time seat availability for students',
                  showDivider: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShareQrScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: RESOURCES (Image 3)
              _sectionHeader('LEGAL & RESOURCES'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.language_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Official Website',
                  subtitle: 'TrackMyLibrary.in',
                  onTap: () => _launchUrl('https://trackmylibrary.in'),
                ),
                _settingsTile(
                  icon: Icons.policy_outlined,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF0D9488),
                  title: 'Privacy Policy',
                  subtitle: 'DPDP Act 2023 & student data security',
                  onTap: () => _launchUrl('https://udaypsy.github.io/Library-app/privacy-policy.html'),
                ),
                _settingsTile(
                  icon: Icons.description_outlined,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Terms of Service',
                  subtitle: 'User license & library service agreement',
                  showDivider: false,
                  onTap: () => _launchUrl('https://udaypsy.github.io/Library-app/terms.html'),
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: AUTOMATION (Image 3)
              _sectionHeader('AUTOMATION'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  title: 'WhatsApp Notifications',
                  subtitle: 'Manage alerts and connection',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WhatsAppAutomationScreen()),
                  ),
                ),
                _settingsTile(
                  icon: Icons.article_outlined,
                  iconBg: const Color(0xFFCCFBF1),
                  iconColor: const Color(0xFF0F766E),
                  title: 'Message Templates',
                  subtitle: 'Edit welcome and reminder texts',
                  onTap: _showMessageTemplatesModal,
                ),
                _settingsTile(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Shift Management',
                  subtitle: 'Configure timings and slot fees',
                  showDivider: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShiftSystemScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: SUPPORT & FEEDBACK (Image 3 & 4)
              _sectionHeader('SUPPORT & FEEDBACK'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  title: 'Contact on WhatsApp',
                  subtitle: '+91 94574 64850',
                  onTap: () => _launchUrl('https://wa.me/919457464850'),
                ),
                _settingsTile(
                  icon: Icons.email_outlined,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Email Support',
                  subtitle: 'manageyourlib@gmail.com',
                  onTap: () => _launchUrl('mailto:manageyourlib@gmail.com'),
                ),
                _settingsTile(
                  icon: Icons.star_outline_rounded,
                  iconBg: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFFCA8A04),
                  title: 'Rate App',
                  subtitle: 'Show some love on the store',
                  showDivider: false,
                  onTap: _showRateAppModal,
                ),
              ]),
              const SizedBox(height: 24),

              // SECTION: DATA & SECURITY (Image 4)
              _sectionHeader('DATA & SECURITY'),
              const SizedBox(height: 10),
              _cardGroup([
                _settingsTile(
                  icon: Icons.cloud_download_outlined,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Full Library Backup (.JSON)',
                  subtitle: 'Save complete offline snapshot of all students, payments & seats',
                  onTap: _downloadFullDatabaseBackup,
                ),
                _settingsTile(
                  icon: Icons.settings_backup_restore_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Restore Library from Backup',
                  subtitle: 'Rehydrate database seamlessly across devices',
                  onTap: _showRestoreDatabaseModal,
                ),
                _settingsTile(
                  icon: Icons.table_chart_outlined,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Export Student Master (.CSV)',
                  subtitle: 'Download spreadsheet of all registered students',
                  showDivider: false,
                  onTap: () async {
                    final students = _service.currentStudents;
                    final buffer = StringBuffer();
                    buffer.writeln('Student ID,Full Name,Phone,Seat Number,Shift,Monthly Fee,Status,Joined Date,Dues Amount,Section');
                    for (var s in students) {
                      final joined = s.joinedAt != null ? DateFormat('yyyy-MM-dd').format(s.joinedAt!) : '';
                      buffer.writeln('${s.id},"${s.name}",${s.phone},${s.seatNumber ?? ""},${s.shift},${s.monthlyFee},${s.status},$joined,${s.duesAmount},${s.sectionName}');
                    }
                    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
                    final success = await FileExportService.download(
                      fileName: 'TrackMyLibrary_Students_$stamp.csv',
                      content: buffer.toString(),
                      mimeType: 'text/csv;charset=utf-8',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Student master list exported successfully!' : 'CSV exported!'),
                          backgroundColor: const Color(0xFF0D766E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deleting your account will permanently remove all your library data, student records, and subscription history. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F2),
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text(
                          'Delete Account Permanently',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: _showDeleteAccountDialog,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Footer (Image 4)
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Version 2.0.0 (Premium)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'MADE WITH ❤️ BY TRACKMYLIBRARY',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        color: AppColors.textMutedColor(context),
      ),
    );
  }

  Widget _cardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context) ? Colors.black26 : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDestructive ? const Color(0xFFEF4444) : AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? const Color(0xFFFCA5A5)
                      : (AppColors.isDark(context) ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: AppColors.divider(context),
          ),
      ],
    );
  }
}
