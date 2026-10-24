import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';
import '../../services/local_storage_service.dart';
import 'setup_success_screen.dart';

class ReviewSetupScreen extends StatelessWidget {
  const ReviewSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LibraryService();
    final sections = service.sections;
    final shifts = service.shifts;
    final totalSeats = service.totalSeatsCount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Image 9)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textNavy),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'STEP 3 OF 3',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Full Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 4,
                      backgroundColor: Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Ready to go',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Check everything looks right. You can change all of this later.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35),
                  ),
                ],
              ),
            ),

            // Content Cards (Image 9)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Big Mint Summary Card (Image 9)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.mintTipBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.mintAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$totalSeats',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SEATS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'across ${sections.length} ${sections.length == 1 ? 'section' : 'sections'} • ${shifts.length} ${shifts.length == 1 ? 'shift' : 'shifts'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTIONS
                    const Text(
                      'SECTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sections.map((sec) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sec.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Seats ${sec.startSeat}–${sec.endSeat}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                '${sec.totalSeats}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 18),

                    // SHIFTS
                    const Text(
                      'SHIFTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...shifts.map((sh) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sh.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${sh.startsAt} – ${sh.endsAt}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${sh.monthlyFee}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),

                    // Reassurance footnote
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_open_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nothing here is permanent — edit sections, seats and fees anytime.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Bottom CTA: Create My Library (Image 9)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final savedPass = await LocalStorageService.getString('app_admin_password') ?? 'password123';
                    await service.registerAdminAccount(
                      email: service.profile.adminEmail.isNotEmpty ? service.profile.adminEmail : 'manageyourlib@gmail.com',
                      password: savedPass,
                      adminName: service.profile.adminName.isNotEmpty ? service.profile.adminName : 'Administrator',
                      libraryName: service.profile.libraryName.isNotEmpty ? service.profile.libraryName : 'My Library',
                      phone: service.profile.adminPhone.isNotEmpty ? service.profile.adminPhone : '9457464850',
                    );
                    service.updateSectionsAndRebuildSeats(service.sections);
                    await service.persistAll();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SetupSuccessScreen()),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Create my library',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
