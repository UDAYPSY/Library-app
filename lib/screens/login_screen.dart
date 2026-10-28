import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/library_service.dart';
import '../services/local_storage_service.dart';
import '../services/biometric_auth_service.dart';
import 'main_hub_screen.dart';
import 'onboarding/workspace_setup_screen.dart';
import 'onboarding/welcome_carousel_screen.dart';
import 'tools/student_live_portal_screen.dart';
import 'public/student_self_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LibraryService _service = LibraryService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    if (_checkPublicWebRedirect()) return;
    _checkActiveSession();
    _loadSavedIdentifier();
  }

  bool _checkPublicWebRedirect() {
    try {
      final frag = Uri.base.fragment;
      final path = Uri.base.path;
      final query = Uri.base.queryParameters;
      if (frag.contains('portal') || path.endsWith('/portal') || query.containsKey('verify')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentLivePortalScreen()),
            );
          }
        });
        return true;
      }
      if (frag.contains('join') || frag.contains('register') || path.endsWith('/join') || path.endsWith('/register')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentSelfRegistrationScreen()),
            );
          }
        });
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkActiveSession() async {
    await _service.restoreSession();
    if (_service.isAuthenticated && mounted) {
      final hasLibrary = await _service.hasConfiguredLibrary();
      if (!mounted) return;
      if (hasLibrary) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainHubScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkspaceSetupScreen()),
        );
      }
    }
  }

  Future<void> _loadSavedIdentifier() async {
    final hasHardware = await BiometricAuthService.canAuthenticate();
    final saved = await LocalStorageService.getString('app_last_login_identifier');
    final savedSession = await LocalStorageService.getString('app_active_session');
    if (mounted) {
      setState(() {
        if (saved != null && saved.isNotEmpty) {
          _emailCtrl.text = saved;
        } else {
          _emailCtrl.text = '';
        }
        _canUseBiometrics = hasHardware &&
            ((savedSession != null && savedSession.isNotEmpty) ||
             (saved != null && saved.isNotEmpty));
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _fillAdminDemo() {
    setState(() {
      _emailCtrl.text = _service.profile.adminEmail.isNotEmpty
          ? _service.profile.adminEmail
          : 'admin@library.com';
      _passCtrl.text = '1234';
      _errorMessage = null;
    });
  }

  void _fillStaffDemo() {
    final staffPhone = _service.staffList.isNotEmpty
        ? _service.staffList.first.phone
        : '9457464850';
    setState(() {
      _emailCtrl.text = staffPhone;
      _passCtrl.text = '1234';
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    final identifier = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number or email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password or PIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.login(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      if (result.success) {
        await LocalStorageService.saveString('app_last_login_identifier', identifier);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome back, ${result.userName}! Signed in as ${result.role}.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D766E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainHubScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message ?? 'Authentication failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login error: $e';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.loginWithGoogle();
      if (!mounted) return;

      if (result.success) {
        final hasLibrary = await _service.hasConfiguredLibrary();
        if (!mounted) return;

        if (hasLibrary) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google Sign-In successful! Welcome back, ${result.userName}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D766E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainHubScreen()),
          );
        } else {
          // First-time Google user: no library created yet.
          // Reset sample mock data so they start with a clean slate
          _service.mockStudentsList.clear();
          _service.mockPaymentsList.clear();
          _service.mockExpensesList.clear();
          _service.staffList.clear();
          _service.branches.clear();
          _service.profile.libraryName = '';
          _service.profile.city = '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome, ${result.userName}! Let\'s create and set up your library.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D766E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkspaceSetupScreen()),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message ?? 'Google Sign-In was cancelled or failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google Sign-In error: $e';
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.loginWithBiometrics();
      if (!mounted) return;

      if (result.success) {
        final hasLibrary = await _service.hasConfiguredLibrary();
        if (!mounted) return;

        if (hasLibrary) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Biometric verified! Welcome back, ${result.userName}.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D766E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainHubScreen()),
          );
        } else {
          // Library not created yet: route to workspace setup
          _service.mockStudentsList.clear();
          _service.mockPaymentsList.clear();
          _service.mockExpensesList.clear();
          _service.staffList.clear();
          _service.branches.clear();
          _service.profile.libraryName = '';
          _service.profile.city = '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Biometric verified! Let\'s create and set up your library.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D766E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkspaceSetupScreen()),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message ?? 'Biometric verification failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Biometric error: $e';
      });
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(
      text: _emailCtrl.text.contains('@') ? _emailCtrl.text : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primaryTeal, size: 24),
            SizedBox(width: 8),
            Text(
              'Reset Admin Password',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered admin email. A secure password reset link will be sent to your inbox by Google Firebase.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Admin Email Address',
                hintText: 'e.g. yourname@gmail.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Staff members: Please ask your Library Admin to reset your 4-digit PIN in Staff Settings.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final target = resetEmailCtrl.text.trim();
              if (!target.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address containing @.'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final res = await _service.sendPasswordReset(target);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message ?? 'Password reset link sent to $target.'),
                    backgroundColor: res.success ? const Color(0xFF0D766E) : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Send Reset Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateAccountModal() {
    final nameCtrl = TextEditingController();
    final libCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? modalError;
    bool isRegistering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Library Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Register your library as Owner / Administrator',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                if (modalError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modalError!,
                            style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin / Owner Full Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: libCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Library / Study Space Name',
                    prefixIcon: Icon(Icons.local_library_outlined, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Official Email (Login ID)',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (10 Digits)',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Secure Password (Min. 6 chars)',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isRegistering
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final lib = libCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final pass = passCtrl.text.trim();

                            if (name.isEmpty || lib.isEmpty || email.isEmpty) {
                              setModalState(() => modalError = 'Please fill all required fields.');
                              return;
                            }
                            if (pass.length < 6) {
                              setModalState(() => modalError = 'Password must be at least 6 characters long.');
                              return;
                            }

                            setModalState(() {
                              isRegistering = true;
                              modalError = null;
                            });

                            final regRes = await _service.registerAdminAccount(
                              email: email,
                              password: pass,
                              adminName: name,
                              libraryName: lib,
                              phone: phoneCtrl.text.trim(),
                            );

                            if (!ctx.mounted) return;

                            if (regRes.success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Account created for $lib! Welcome, $name.'),
                                  backgroundColor: const Color(0xFF0D766E),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MainHubScreen()),
                              );
                            } else {
                              setModalState(() {
                                isRegistering = false;
                                modalError = regRes.message ?? 'Registration failed.';
                              });
                            }
                          },
                    child: isRegistering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Complete Registration & Launch',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomeCarouselScreen()),
                      );
                    },
                    child: const Text(
                      'Launch Interactive Setup Wizard Instead',
                      style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            // Top Teal Brand Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primaryTeal,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SECURE ACCESS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track My Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enterprise library seating & automated dues portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // White Rounded Bottom Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 12, color: Color(0xFF0D766E)),
                                SizedBox(width: 4),
                                Text(
                                  'RBAC Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D766E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quick Demo Role Switcher
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Quick Fill:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: _fillAdminDemo,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Admin Demo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: InkWell(
                                onTap: _fillStaffDemo,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Staff Reception',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Input 1: Mobile or Email
                      const Text(
                        'MOBILE OR EMAIL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter mobile no. or email',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const SizedBox(height: 16),

                      // Input 2: Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PASSWORD OR PIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textNavy,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password or 4-digit PIN',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const SizedBox(height: 22),

                      // Sign In Button & Biometrics
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
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
                          ),
                          if (_canUseBiometrics) ...[
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: _isLoading ? null : _handleBiometricLogin,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF99F6E4)),
                                ),
                                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF0F766E), size: 28),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // OR Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.inputBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.inputBorder)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF1F5F9),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: AppColors.textNavy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // New here? Create Account
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WelcomeCarouselScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13, color: AppColors.textNavy),
                              children: [
                                TextSpan(text: 'New Library Owner? '),
                                TextSpan(
                                  text: 'Create Account',
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
                      const SizedBox(height: 24),

                      // Encryption Footer
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'AES-256 Bit Encrypted Connection • Isolated Tenant',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Legal & Compliance Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('https://manageyourlib.com/privacy'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Text(' • ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse('https://manageyourlib.com/terms'),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
