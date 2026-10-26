import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/library_service.dart';
import '../../services/local_storage_service.dart';
import 'seat_setup_screen.dart';
import '../login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _service = LibraryService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _service.profile.adminName != 'Nivi' ? _service.profile.adminName : '');
    _emailCtrl = TextEditingController(text: '');
    _phoneCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _isNameValid => _nameCtrl.text.trim().isNotEmpty;
  bool get _isEmailValid =>
      _emailCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().contains('@') &&
      _emailCtrl.text.trim().contains('.');
  bool get _isPhoneValid =>
      _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10;
  bool get _isPassValid => _passCtrl.text.length >= 6;

  void _onCreateAccount() async {
    setState(() => _showErrors = true);

    if (!_isNameValid || !_isEmailValid || !_isPhoneValid || !_isPassValid) {
      return;
    }

    _service.profile.adminName = _nameCtrl.text.trim();
    _service.profile.adminEmail = _emailCtrl.text.trim();
    _service.profile.adminPhone = _phoneCtrl.text.trim();
    await LocalStorageService.saveString('app_admin_password', _passCtrl.text.trim());

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeatSetupScreen()),
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
            // Top Section (Images 3 & 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryTeal, size: 30),
                  ),
                  const SizedBox(height: 12),
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
                    'Administrator Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Almost there! Who will be managing this space?',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar: Step 2 of 2 (Full)
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 5,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Step 2 of 2',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // White Rounded Bottom Card (Images 3 & 4)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with back arrow (Image 3 & 4)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textNavy),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Text(
                            'Your Profile',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input 1: Full Name
                      _buildField(
                        label: 'FULL NAME',
                        controller: _nameCtrl,
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        isError: _showErrors && !_isNameValid,
                        errorMessage: 'Name is required',
                      ),
                      const SizedBox(height: 14),

                      // Input 2: Email Address
                      _buildField(
                        label: 'EMAIL ADDRESS',
                        controller: _emailCtrl,
                        hintText: 'manageyourlib@gmail.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        isError: _showErrors && !_isEmailValid,
                        errorMessage: 'Enter a valid email address',
                      ),
                      const SizedBox(height: 14),

                      // Input 3: Phone Number
                      _buildField(
                        label: 'PHONE NUMBER',
                        controller: _phoneCtrl,
                        hintText: '9457464850',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isError: _showErrors && !_isPhoneValid,
                        errorMessage: 'Phone number is required',
                      ),
                      const SizedBox(height: 14),

                      // Input 4: Password
                      _buildField(
                        label: 'PASSWORD',
                        controller: _passCtrl,
                        hintText: 'Min. 6 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePass,
                        isError: _showErrors && !_isPassValid,
                        errorMessage: 'Password must be at least 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Create Account Button (Images 3 & 4)
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
                          onPressed: _onCreateAccount,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Sign in link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
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
                      const SizedBox(height: 20),

                      // Footnote
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Secure 256-bit Encryption',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool isError = false,
    required String errorMessage,
    Widget? suffixIcon,
  }) {
    const errorColor = Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (_showErrors) setState(() {});
          },
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, color: isError ? errorColor : AppColors.textMuted, size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFFBFDFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isError ? errorColor : AppColors.inputBorder, width: isError ? 1.5 : 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isError ? errorColor : AppColors.inputBorder, width: isError ? 1.5 : 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isError ? errorColor : AppColors.primaryTeal, width: 1.5),
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: errorColor,
            ),
          ),
        ],
      ],
    );
  }
}
