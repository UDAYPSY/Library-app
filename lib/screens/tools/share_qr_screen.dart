import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../public/student_self_registration_screen.dart';
import 'student_live_portal_screen.dart';

class ShareQrScreen extends StatefulWidget {
  const ShareQrScreen({super.key});

  @override
  State<ShareQrScreen> createState() => _ShareQrScreenState();
}

class _ShareQrScreenState extends State<ShareQrScreen> {
  final LibraryService _service = LibraryService();
  int _qrSeed = 42;
  int _selectedQrMode = 0; // 0 = Desk Self-Admission QR, 1 = Live Seat Availability

  String get _effectiveBaseUrl {
    return _service.profile.effectivePortalBaseUrl;
  }

  String get _registrationUrl {
    final tenant = _service.tenantId;
    final libName = Uri.encodeComponent(_service.profile.libraryName);
    final city = Uri.encodeComponent(_service.profile.city);
    return '$_effectiveBaseUrl/#/join?lib=$tenant&libname=$libName&city=$city';
  }

  String get _portalUrl {
    final tenant = _service.tenantId;
    final libName = Uri.encodeComponent(_service.profile.libraryName);
    final city = Uri.encodeComponent(_service.profile.city);
    return '$_effectiveBaseUrl/#/portal?lib=$tenant&libname=$libName&city=$city';
  }

  String get _publicUrl => _selectedQrMode == 0 ? _registrationUrl : _portalUrl;

  void _editPortalBaseUrl() {
    final ctrl = TextEditingController(text: _effectiveBaseUrl);
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.language_rounded, color: Color(0xFF0D6E66), size: 24),
            SizedBox(width: 8),
            Text('Web Portal Host URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your production web domain or hosting URL for QR code generation:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://udaypsy.github.io/Library-app',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('GitHub Pages', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'https://udaypsy.github.io/Library-app',
                ),
                ActionChip(
                  label: const Text('app.manageyourlib.com', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'https://app.manageyourlib.com',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6E66),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = ctrl.text.trim();
              if (newUrl.isNotEmpty) {
                _service.profile.portalBaseUrl = newUrl;
                await _service.saveProfile(_service.profile);
                if (mounted) setState(() {});
              }
              Navigator.pop(dCtx);
            },
            child: const Text('Save & Update QR'),
          ),
        ],
      ),
    );
  }

  void _regenerateQR() {
    setState(() {
      _qrSeed = DateTime.now().millisecondsSinceEpoch % 1000;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code re-synchronized with live portal!'),
        backgroundColor: Color(0xFF0D6E66),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    final libName = _service.profile.libraryName;
    final text = _selectedQrMode == 0
        ? 'Welcome to $libName! Scan or click this link to submit your student admission application & choose your shift:\n$_publicUrl'
        : 'Check live seat availability at $libName before visiting:\n$_publicUrl';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _openPublicPreview() {
    if (_selectedQrMode == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentSelfRegistrationScreen(libraryId: _service.tenantId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentLivePortalScreen()),
      );
    }
  }

  void _shareOrDownload() {
    final isAdmission = _selectedQrMode == 0;
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
                  isAdmission ? 'Share Admission Desk QR' : 'Share Live Seat QR Code',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),

            // Option 1: Copy Link
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.link_rounded, color: Color(0xFF16A34A)),
              ),
              title: Text(isAdmission ? 'Copy Admission Portal Link' : 'Copy Live Web Link', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(_publicUrl, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: _publicUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAdmission ? 'Admission link copied to clipboard!' : 'Live student seat link copied to clipboard!'),
                    backgroundColor: const Color(0xFF0D6E66),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Option 2: Share via WhatsApp
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('Share to WhatsApp Status / Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(isAdmission ? 'Post QR admission link for aspirants to register' : 'Post live seat link for all aspirants to view', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _shareOnWhatsApp();
              },
            ),

            // Option 3: Print Poster View
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.print_outlined, color: Color(0xFF0284C7)),
              ),
              title: const Text('Reception Print Poster Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('View and copy formatted notice for printing at reception gate', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                final posterText = isAdmission
                    ? '===================================\n'
                      '        ${_service.profile.libraryName.toUpperCase()}\n'
                      '     ${_service.profile.city}\n'
                      '===================================\n'
                      'SCAN TO JOIN / STUDENT SELF-ADMISSION\n'
                      'Scan this QR code with your phone camera\n'
                      'to apply for admission & choose your shift!\n\n'
                      'Portal: $_publicUrl\n'
                      'Helpline: ${_service.profile.adminPhone}\n'
                      '==================================='
                    : '===================================\n'
                      '        ${_service.profile.libraryName.toUpperCase()}\n'
                      '     ${_service.profile.city}\n'
                      '===================================\n'
                      'SCAN TO CHECK LIVE SEAT AVAILABILITY\n'
                      'URL: $_publicUrl\n'
                      'Helpline: ${_service.profile.adminPhone}\n'
                      '===================================';
                Clipboard.setData(ClipboardData(text: posterText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print poster notice copied to clipboard!'),
                    backgroundColor: Color(0xFF0D6E66),
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
    final isAdmission = _selectedQrMode == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Library QR Codes',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector Toggle (Self-Admission vs Live Seat Availability)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedQrMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedQrMode == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedQrMode == 0
                              ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 16,
                              color: _selectedQrMode == 0 ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Desk Self-Admission',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedQrMode == 0 ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedQrMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedQrMode == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedQrMode == 1
                              ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_seat_rounded,
                              size: 16,
                              color: _selectedQrMode == 1 ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live Seat Availability',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedQrMode == 1 ? const Color(0xFF0D9488) : const Color(0xFF64748B),
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
            const SizedBox(height: 20),

            // DIGITAL ACCESS Pill
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
                  Icon(isAdmission ? Icons.how_to_reg_rounded : Icons.qr_code_rounded, size: 14, color: const Color(0xFF0D9488)),
                  const SizedBox(width: 5),
                  Text(
                    isAdmission ? 'STUDENT SELF-REGISTRATION' : 'DIGITAL ACCESS',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title & Subtitle
            Text(
              isAdmission ? 'Student Admission Desk QR' : 'Seat Availability QR Code',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmission
                  ? 'Print and place this QR poster at your reception desk. New students scan with their phone camera to submit admission details & request a seat.'
                  : 'Generate a unique QR code for your library. Students can scan this to check real-time seat availability without logging in.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Big QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Real Scannable ISO QR Code Image
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: QrImageView(
                        data: _publicUrl,
                        version: QrVersions.auto,
                        size: 186.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Public URL bar with Copy icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _publicUrl,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _publicUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard!'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PREVIEW PAGE [↗] & CONFIGURE DOMAIN [⚙]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _openPublicPreview,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAdmission ? 'TEST PORTAL' : 'PREVIEW LIVE SEATS',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Color(0xFF0D6E66),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF0D6E66)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Container(width: 1, height: 14, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: _editPortalBaseUrl,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SET DOMAIN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Color(0xFF0D6E66),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.tune_rounded, size: 14, color: Color(0xFF0D6E66)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SHARE & DOWNLOAD BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6E66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _shareOrDownload,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  isAdmission ? 'Share / Print Admission QR' : 'Share or Download QR',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // RE-GENERATE QR CODE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6E66),
                  side: const BorderSide(color: Color(0xFFCCFBF1), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.white,
                ),
                onPressed: _regenerateQR,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Re-generate QR Code',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // How It Works Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0D6E66)),
                      const SizedBox(width: 8),
                      Text(
                        isAdmission ? 'How Self-Admission Works:' : 'How Live Portal Works:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAdmission
                        ? '1. Print this QR poster and place it on your reception desk.\n'
                          '2. Visiting students scan with phone camera (no app install needed).\n'
                          '3. Student fills name, phone, photo, and desired shift.\n'
                          '4. Request appears instantly in your "QR REQUESTS" tab in Student Directory.\n'
                          '5. You allot an empty seat and collect payment with 1 tap!'
                        : '1. Print this QR code and paste it on library entrance.\n'
                          '2. Aspirants can scan with phone camera to see occupied vs vacant seats.\n'
                          '3. Prevents crowded front desks and saves time for library admin.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
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
}
