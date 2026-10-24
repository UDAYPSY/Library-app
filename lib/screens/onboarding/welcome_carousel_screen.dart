import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../login_screen.dart';
import 'workspace_setup_screen.dart';

class WelcomeCarouselScreen extends StatefulWidget {
  const WelcomeCarouselScreen({super.key});

  @override
  State<WelcomeCarouselScreen> createState() => _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends State<WelcomeCarouselScreen> {
  final PageController _pageCtrl = PageController(initialPage: 2); // Start at slide 2 as in 1.jpeg
  int _currentPage = 2;
  Timer? _timer;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Space Grid\nManagement',
      'description': 'Interactive visual live occupancy and real-time seat assignment for your halls.',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF0D766E),
    },
    {
      'title': 'Zero Revenue\nLeakage',
      'description': 'Automated fee due dates, advance tenures, and instant payment receipt tracking.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF0D766E),
    },
    {
      'title': 'Complete\nStudent Insights',
      'description': 'Track attendance, payments, and shift renewals from a single dashboard.',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFFF59E0B), // Golden amber as in 1.jpeg
    },
    {
      'title': 'Multi-Shift\nFlexibility',
      'description': 'Seamlessly allocate Morning, Evening, Night, and 24-Hour memberships without conflict.',
      'icon': Icons.schedule_rounded,
      'color': Color(0xFF0D766E),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Subtle auto-scroll every 5 seconds if idle
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageCtrl.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageCtrl.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          // Subtle soft warm gradient shapes matching 1.jpeg
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7).withOpacity(0.35),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Carousel PageView Area (Center Illustration & Text)
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                    },
                    itemBuilder: (ctx, idx) {
                      final slide = _slides[idx];
                      final iconColor = slide['color'] as Color;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Big circular badge with gold/amber border (matching 1.jpeg)
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFEAA023),
                                  width: 3.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  slide['icon'] as IconData,
                                  size: 78,
                                  color: iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Headline (matching 1.jpeg)
                            Text(
                              slide['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description (matching 1.jpeg)
                            Text(
                              slide['description'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Carousel Dots Indicator (matching 1.jpeg)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (idx) {
                    final isActive = _currentPage == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF0D766E) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),

                // Action Buttons Section (matching 1.jpeg)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Create New Library Button (Pill)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D766E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WorkspaceSetupScreen()),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create New Library',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Already a member? Log in
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(text: 'Already a member? '),
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: Color(0xFF0D766E),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Footer Terms & Privacy Policy
                      const Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
