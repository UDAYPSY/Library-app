import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import 'student_live_portal_screen.dart';

class ShareQrScreen extends StatefulWidget {
  const ShareQrScreen({super.key});

  @override
  State<ShareQrScreen> createState() => _ShareQrScreenState();
}

class _ShareQrScreenState extends State<ShareQrScreen> {
  final LibraryService _service = LibraryService();
  int _qrSeed = 42;

  String get _publicUrl {
    final slug = _service.profile.libraryName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return 'https://trackmylibrary.in/live/$slug';
  }

  void _regenerateQR() {
    setState(() {
      _qrSeed = DateTime.now().millisecondsSinceEpoch % 1000;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New QR Code synchronized with live student portal!'),
        backgroundColor: Color(0xFF0D6E66),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareOnWhatsApp() async {
    final text = 'Check live seat availability at ${_service.profile.libraryName} before visiting:\n$_publicUrl';
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentLivePortalScreen()),
    );
  }

  void _shareOrDownload() {
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
                const Text('Share Live Seat QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
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
              title: const Text('Copy Live Web Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(_publicUrl, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: _publicUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live student seat link copied to clipboard!'),
                    backgroundColor: Color(0xFF0D6E66),
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
              subtitle: const Text('Post live seat link for all aspirants to view', style: TextStyle(fontSize: 11)),
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
                final posterText = '===================================\n'
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
          'Share QR Code',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DIGITAL ACCESS Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_rounded, size: 14, color: Color(0xFF0D9488)),
                  SizedBox(width: 5),
                  Text(
                    'DIGITAL ACCESS',
                    style: TextStyle(
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
            const Text(
              'Seat Availability QR Code',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a unique QR code for your library. Students can scan this to check real-time seat availability without logging in.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Big QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
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
                    width: 220,
                    height: 220,
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
                        size: 196.0,
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
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
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

                  // PREVIEW PAGE [↗]
                  InkWell(
                    onTap: _openPublicPreview,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PREVIEW PAGE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF0D6E66),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF0D6E66)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Feature Checkmarks
            _featureRow('Public access for students (no login required)'),
            const SizedBox(height: 12),
            _featureRow('High-resolution for high-quality printing'),
            const SizedBox(height: 12),
            _featureRow('Real-time data synchronization every 30s'),
            const SizedBox(height: 28),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6E66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _regenerateQR,
                child: const Text(
                  'REGENERATE QR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textNavy,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                label: const Text(
                  'SHARE OR DOWNLOAD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: _shareOrDownload,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 13, color: Color(0xFF16A34A)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textNavy,
            ),
          ),
        ),
      ],
    );
  }
}

