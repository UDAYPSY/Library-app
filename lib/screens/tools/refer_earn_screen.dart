import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  Future<void> _openWhatsAppClaim(BuildContext context, String adminName) async {
    const phone = '919457464850';
    final msg = 'Hello TrackMyLibrary team! I referred a fellow library owner and would like to claim my ₹149 referral bonus. Admin: $adminName (Code: LIB_${adminName.toUpperCase()})';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: msg));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim message copied! Reach out to 94574 64850.')),
      );
    }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://trackmylibrary.in');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _shareReferralLink(BuildContext context, String adminName) {
    final code = 'LIB_${adminName.toUpperCase().replaceAll(' ', '_')}';
    final link = 'https://trackmylibrary.in/ref?code=$code';
    final shareMessage = 'Hey! I use TrackMyLibrary to manage my library seats, student dues, and automated WhatsApp reminders. Use my referral code "$code" to get ₹149 off on registration: $link';

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
                const Text('Share Referral Link', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            // Share via WhatsApp
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('Share to WhatsApp Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Send invite message with your referral link', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareMessage)}');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  await launchUrl(uri);
                }
              },
            ),

            // Copy Link
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.copy_rounded, color: Color(0xFF6366F1)),
              ),
              title: const Text('Copy Referral Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Text(link, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Referral link copied to clipboard!'),
                    backgroundColor: Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

            // Copy Code Only
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF16A34A)),
              ),
              title: Text('Copy Code: $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Share code directly to apply during onboarding', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Referral code "$code" copied to clipboard!'),
                    backgroundColor: const Color(0xFF16A34A),
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
    final service = LibraryService();
    final adminName = service.profile.adminName.isNotEmpty ? service.profile.adminName : 'Owner';
    final referralCode = 'LIB_${adminName.toUpperCase().replaceAll(' ', '_')}';

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
          'Refer & Earn',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Purple Gradient Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4DFF), Color(0xFF8655F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x306366F1), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'Earn ₹149',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Per Successful Referral',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Referral Stats Card
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR REFERRAL CODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(referralCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF5B4DFF))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF5B4DFF)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Code $referralCode copied!'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statCol('Earned', '₹298', const Color(0xFF16A34A)),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _statCol('Referrals', '2 Libraries', AppColors.textNavy),
                      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                      _statCol('Pending', '1 (₹149)', const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Our Mission
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                children: [
                  TextSpan(text: 'At '),
                  TextSpan(
                    text: 'Track My Library',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0D9488)),
                  ),
                  TextSpan(
                    text: ', we are dedicated to providing the best tools for library owners like you.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'We really need your support to keep improving and reaching more people. If you\'ve found our app helpful, please consider referring it to your fellow library owners.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                children: [
                  const TextSpan(text: 'You can also visit our official website at '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: InkWell(
                      onTap: _openWebsite,
                      child: const Text(
                        'TrackmyLibrary.in',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D9488),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' to learn more about our future vision.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: Color(0xFF0D9488), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After you refer someone and they subscribe, please let us know so we can credit your bonus!',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Button 1: Share with Friends
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x307C3AED), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'Share with Friends',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                onPressed: () => _shareReferralLink(context, adminName),
              ),
            ),
            const SizedBox(height: 14),

            // Button 2: DM to Claim Bonus
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openWhatsAppClaim(context, adminName),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DM to Claim Bonus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
