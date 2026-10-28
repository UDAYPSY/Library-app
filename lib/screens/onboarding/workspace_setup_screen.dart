import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';
import 'admin_profile_screen.dart';
import '../login_screen.dart';

class WorkspaceSetupScreen extends StatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  State<WorkspaceSetupScreen> createState() => _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends State<WorkspaceSetupScreen> {
  final _service = LibraryService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: (_service.profile.libraryName.isNotEmpty &&
              _service.profile.libraryName != 'Patna Central Library')
          ? _service.profile.libraryName
          : '',
    );
    _cityCtrl = TextEditingController(
      text: (_service.profile.city.isNotEmpty &&
              _service.profile.city != 'City Center, Main St')
          ? _service.profile.city
          : '',
    );
  }

  void _onContinue() {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (name.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your library name and location')),
      );
      return;
    }
    _service.profile.libraryName = name;
    _service.profile.city = city;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header (Image 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryTeal, size: 32),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'JOIN THE EXPERTS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Workspace Setup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "First, let's set up your digital library.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Progress Bar: Step 1 of 2
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.5,
                            minHeight: 5,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Step 1 of 2',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // White Rounded Bottom Card (Image 2)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Library Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Input 1: Library Name
                      const Text(
                        'LIBRARY NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Patna Central Library',
                          prefixIcon: const Icon(Icons.business_rounded, color: AppColors.textMuted, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          filled: true,
                          fillColor: const Color(0xFFFBFDFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input 2: City / Location
                      const Text(
                        'CITY / LOCATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. City Center, Main St',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          filled: true,
                          fillColor: const Color(0xFFFBFDFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _onContinue,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Sign In link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13, color: AppColors.textNavy),
                              children: [
                                TextSpan(text: 'Already have an account? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Footnote
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Secure 256-bit Encryption',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }
}
