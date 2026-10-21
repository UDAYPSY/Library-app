import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';

class LibraryCommunityScreen extends StatefulWidget {
  const LibraryCommunityScreen({super.key});

  @override
  State<LibraryCommunityScreen> createState() => _LibraryCommunityScreenState();
}

class _LibraryCommunityScreenState extends State<LibraryCommunityScreen> {
  final LibraryService _service = LibraryService();
  bool _webinarReminderSet = false;

  Future<void> _joinWhatsAppGroup(BuildContext context) async {
    const groupLink = 'https://chat.whatsapp.com/TrackMyLibraryCommunity';
    final uri = Uri.parse(groupLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback Sheet
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
                const Text('Join Official WhatsApp Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.copy_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('Copy Group Invite Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text(groupLink, style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(const ClipboardData(text: groupLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WhatsApp Community link copied to clipboard!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.support_agent_rounded, color: Color(0xFF16A34A)),
              ),
              title: const Text('Message Group Admin Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Send a message to admin (94574 64850) to add you', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final msg = 'Hello, please add my library (${_service.profile.libraryName}) to the official TrackMyLibrary WhatsApp group.';
                final adminUri = Uri.parse('https://wa.me/919457464850?text=${Uri.encodeComponent(msg)}');
                try {
                  await launchUrl(adminUri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestFeatureOrSupport(BuildContext context) async {
    final msg = 'Hello TrackMyLibrary team, I have a feature request/feedback for the app from ${_service.profile.libraryName}: ';
    final uri = Uri.parse('https://wa.me/919457464850?text=${Uri.encodeComponent(msg)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: msg));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback prompt copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: AppColors.textNavy, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Library Community',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green Gradient Official Group Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x3010B981), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'TRACK MY LIBRARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFFD1FAE5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Official Group',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pill badges: News | Support | Updates
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badgePill('News'),
                      const SizedBox(width: 8),
                      _badgePill('Support'),
                      const SizedBox(width: 8),
                      _badgePill('Updates'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Why Join?
            const Text(
              'Why Join?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Direct Help
            _benefitCard(
              icon: Icons.language_rounded,
              title: 'Direct Help',
              description: 'Get quick answers to your technical or billing issues directly from the founding engineers.',
            ),
            const SizedBox(height: 12),

            // Card 2: New Updates
            _benefitCard(
              icon: Icons.notifications_none_rounded,
              title: 'New Updates',
              description: 'Be the first to know about new features, shift management upgrades, and bug fixes.',
            ),
            const SizedBox(height: 12),

            // Card 3: Networking
            _benefitCard(
              icon: Icons.groups_outlined,
              title: 'Networking',
              description: 'Connect with over 500+ library owners across India sharing tips on fee collection and occupancy.',
            ),
            const SizedBox(height: 20),

            // Webinar Card
            Container(
              padding: const EdgeInsets.all(16),
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
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Owner Webinar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textNavy)),
                        SizedBox(height: 2),
                        Text('Sunday 7:00 PM • Increasing Library Occupancy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_webinarReminderSet ? Icons.notifications_active_rounded : Icons.notifications_outlined, color: _webinarReminderSet ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                    onPressed: () {
                      setState(() => _webinarReminderSet = !_webinarReminderSet);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_webinarReminderSet ? 'Webinar reminder set for Sunday!' : 'Reminder cancelled.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Action: Join the Group Now
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 22, color: Colors.white),
                label: const Text(
                  'Join the Group Now',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                onPressed: () => _joinWhatsAppGroup(context),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary: Request a Feature
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textNavy,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFFF59E0B)),
                label: const Text('Suggest a Feature / Give Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                onPressed: () => _requestFeatureOrSupport(context),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Safe & Secure. Only for verified library owners.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _badgePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: const Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
