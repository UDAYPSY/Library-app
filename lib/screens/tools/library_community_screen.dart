import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

class LibraryCommunityScreen extends StatelessWidget {
  const LibraryCommunityScreen({super.key});

  Future<void> _joinWhatsAppGroup(BuildContext context) async {
    const groupLink = 'https://chat.whatsapp.com/TrackMyLibraryCommunity';
    final uri = Uri.parse(groupLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening TrackMyLibrary Official Community on WhatsApp...'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            // Green Gradient Official Group Banner (Image 10)
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
                  // WhatsApp Logo Watermark
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

                  // Pill badges: News | Support | Updates (Image 10)
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

            // Why Join? (Image 10)
            const Text(
              'Why Join?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Direct Help (Image 10)
            _benefitCard(
              icon: Icons.language_rounded,
              title: 'Direct Help',
              description: 'Get quick answers to your technical or billing issues.',
            ),
            const SizedBox(height: 12),

            // Card 2: New Updates (Image 10)
            _benefitCard(
              icon: Icons.notifications_none_rounded,
              title: 'New Updates',
              description: 'Be the first to know about new features and bug fixes.',
            ),
            const SizedBox(height: 12),

            // Card 3: Networking (Image 10)
            _benefitCard(
              icon: Icons.groups_outlined,
              title: 'Networking',
              description: 'Connect with other library owners across India.',
            ),
            const SizedBox(height: 32),

            // Bottom Action: Join the Group Now (Image 10)
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
            const Center(
              child: Text(
                'Safe & Secure. Only for library owners.',
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
