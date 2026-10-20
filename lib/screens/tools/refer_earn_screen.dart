import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  Future<void> _openWhatsAppClaim(String adminName) async {
    const phone = '919457464850';
    final msg = 'Hello TrackMyLibrary team! I referred a library owner and would like to claim my ₹149 referral bonus. Admin: $adminName';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral link copied: https://trackmylibrary.in/ref?code=LIB_$adminName'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = LibraryService();
    final adminName = service.profile.adminName.isNotEmpty ? service.profile.adminName : 'Owner';

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
            // Big Purple Gradient Banner (Image 9)
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
            const SizedBox(height: 28),

            // Our Mission (Image 9)
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

            // Info Card (Image 9)
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

            // Button 1: Share with Friends (Image 9)
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

            // Button 2: DM to Claim Bonus (Image 9)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openWhatsAppClaim(adminName),
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
}
