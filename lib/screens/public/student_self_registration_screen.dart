import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class StudentSelfRegistrationScreen extends StatefulWidget {
  final String? libraryId;

  const StudentSelfRegistrationScreen({super.key, this.libraryId});

  @override
  State<StudentSelfRegistrationScreen> createState() =>
      _StudentSelfRegistrationScreenState();
}

class _StudentSelfRegistrationScreenState
    extends State<StudentSelfRegistrationScreen> {
  final LibraryService _service = LibraryService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedShift = 'Full Day';
  String _selectedPrep = 'UPSC / Civil Services';
  String? _photoBase64;
  bool _agreedToRules = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String _submittedRequestId = '';

  final List<String> _prepOptions = [
    'UPSC / Civil Services',
    'State PSC',
    'SSC / Railway',
    'Banking / Insurance',
    'NEET / Medical',
    'JEE / Engineering',
    'CA / CS / Finance',
    'Judiciary / Law',
    'School / College Studies',
    'Self Study / Reading',
    'Other Competitive Exams',
  ];

  String get _effectiveLibraryId {
    if (widget.libraryId != null && widget.libraryId!.trim().isNotEmpty) {
      return widget.libraryId!.trim();
    }
    final qLib = Uri.base.queryParameters['lib'];
    if (qLib != null && qLib.trim().isNotEmpty) return qLib.trim();

    final frag = Uri.base.fragment;
    if (frag.isNotEmpty) {
      final fUri = Uri.parse(frag.startsWith('/') ? frag : '/$frag');
      final fLib = fUri.queryParameters['lib'];
      if (fLib != null && fLib.trim().isNotEmpty) return fLib.trim();
    }
    return _service.tenantId;
  }

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    final shifts = _service.shifts.where((s) => s.isActive).toList();
    if (shifts.isNotEmpty) {
      _selectedShift = shifts.first.name;
    } else if (_service.shifts.isNotEmpty) {
      _selectedShift = _service.shifts.first.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _fatherNameCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load image: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryTeal),
                title: const Text('Take Selfie (Camera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryTeal),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the library rules & discipline guidelines to proceed.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phone = LibraryService.normalizePhone(_phoneCtrl.text);
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanAadhaar = _aadhaarCtrl.text.replaceAll(' ', '').trim();
    if (cleanAadhaar.isNotEmpty && (cleanAadhaar.length != 12 || int.tryParse(cleanAadhaar) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar must be exactly 12 digits'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveLibId = _effectiveLibraryId;

    final matchedShift = _service.shifts.firstWhere(
      (s) => s.name.toLowerCase() == _selectedShift.toLowerCase(),
      orElse: () => ShiftConfig(id: 'def', name: _selectedShift, startsAt: '', endsAt: '', monthlyFee: 500),
    );

    final request = RegistrationRequest(
      id: reqId,
      studentName: _nameCtrl.text.trim(),
      phone: phone,
      fatherName: _fatherNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      aadhaarNumber: cleanAadhaar,
      preparationFor: _selectedPrep,
      gender: _selectedGender,
      shift: _selectedShift,
      photoBase64: _photoBase64,
      createdAt: DateTime.now(),
      status: 'PENDING',
      libraryId: effectiveLibId,
      preferredMonthlyFee: matchedShift.monthlyFee,
    );

    try {
      await _service.submitRegistrationRequest(request);
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
        _submittedRequestId = reqId;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting registration: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _chatWithDesk() async {
    final phone = _service.profile.adminPhone.replaceAll(RegExp(r'\D'), '');
    final deskPhone = phone.isNotEmpty ? phone : '9457464850';
    final text = 'Hello ${_service.profile.libraryName}, I have submitted my registration request (ID: $_submittedRequestId) for ${_nameCtrl.text.trim()}. Please allot my seat.';
    final uri = Uri.parse('https://wa.me/91$deskPhone?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final profile = _service.profile;
    final libName = profile.libraryName.isNotEmpty ? profile.libraryName : 'Oxford Study Library';
    final city = profile.city.isNotEmpty ? profile.city : 'Central Branch';
    final address = city;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          libName,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F766E),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _isSubmitted
              ? _buildSuccessView(libName)
              : _buildFormView(libName, address),
        ),
      ),
    );
  }

  Widget _buildSuccessView(String libName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Application Submitted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your registration request has been submitted to $libName desk.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow('Applicant Name', _nameCtrl.text.trim()),
                const Divider(height: 18),
                _buildSummaryRow('WhatsApp Number', '+91 ${_phoneCtrl.text.trim()}'),
                const Divider(height: 18),
                _buildSummaryRow('Requested Shift', _selectedShift),
                const Divider(height: 18),
                _buildSummaryRow('Goal / Target', _selectedPrep),
                const Divider(height: 18),
                _buildSummaryRow('Status', 'Pending Seat Allotment', valueColor: const Color(0xFFD97706)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: _chatWithDesk,
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text(
              'Chat with Front Desk on WhatsApp',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isSubmitted = false;
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _fatherNameCtrl.clear();
                _addressCtrl.clear();
                _aadhaarCtrl.clear();
                _photoBase64 = null;
              });
            },
            child: const Text('Submit Another Admission Form'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(String libName, String address) {
    final shifts = _service.shifts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F0F766E), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Self-Admission',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFCCFBF1),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              libName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF99F6E4)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFCCFBF1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Photo Uploader
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFF0F766E), width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: ClipOval(
                        child: _photoBase64 != null
                            ? Image.memory(
                                base64Decode(_photoBase64!),
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 36, color: Colors.grey.shade400),
                                  const SizedBox(height: 4),
                                  const Text('Add Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F766E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            _buildLabel('Full Name *'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('e.g. Rahul Sharma', Icons.person_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 16),

            // WhatsApp Phone
            _buildLabel('WhatsApp Mobile Number *'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _inputDeco('10-digit mobile number', Icons.phone_rounded, prefix: '+91 '),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your mobile number';
                if (v.trim().length != 10) return 'Please enter a valid 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Father's Name
            _buildLabel("Father's / Guardian's Name"),
            TextFormField(
              controller: _fatherNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco("e.g. Ramesh Sharma", Icons.family_restroom_rounded),
            ),
            const SizedBox(height: 16),

            // Gender & Shift Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Gender *'),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _inputDeco('', null),
                        items: ['Male', 'Female', 'Other'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedGender = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Preferred Shift *'),
                      DropdownButtonFormField<String>(
                        value: (shifts.any((s) => s.name == _selectedShift))
                            ? _selectedShift
                            : (shifts.isNotEmpty ? shifts.first.name : 'Full Day'),
                        decoration: _inputDeco('', null),
                        isExpanded: true,
                        items: (shifts.isNotEmpty
                                ? shifts
                                : [
                                    ShiftConfig(id: 's1', name: 'Full Day', startsAt: '06:00 AM', endsAt: '10:00 PM', monthlyFee: 500),
                                    ShiftConfig(id: 's2', name: 'Morning Shift', startsAt: '06:00 AM', endsAt: '02:00 PM', monthlyFee: 600),
                                    ShiftConfig(id: 's3', name: 'Evening Shift', startsAt: '02:00 PM', endsAt: '10:00 PM', monthlyFee: 600),
                                    ShiftConfig(id: 's4', name: 'Night Shift', startsAt: '10:00 PM', endsAt: '06:00 AM', monthlyFee: 500),
                                  ])
                            .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                                  value: s.name,
                                  child: Text(
                                    '${s.name} (₹${s.monthlyFee}/month)',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedShift = v);
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '* Select shift according to your timing. Fee is payable at desk upon seat allotment.',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Exam / Preparation
            _buildLabel('Goal / Preparing For *'),
            DropdownButtonFormField<String>(
              value: _selectedPrep,
              decoration: _inputDeco('', Icons.school_rounded),
              items: _prepOptions.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPrep = v);
              },
            ),
            const SizedBox(height: 16),

            // Address
            _buildLabel('Current Address'),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: _inputDeco('Room / Hostel / Flat Address in city', Icons.home_rounded),
            ),
            const SizedBox(height: 16),

            // Aadhaar / ID (12 Digits)
            _buildLabel('Aadhaar / ID Card Number (12 Digits)'),
            TextFormField(
              controller: _aadhaarCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: _inputDeco('12-digit Aadhaar number', Icons.badge_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final clean = v.replaceAll(' ', '').trim();
                if (clean.length != 12 || int.tryParse(clean) == null) {
                  return 'Aadhaar must be exactly 12 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Rules Agreement Checkbox
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreedToRules,
                    activeColor: const Color(0xFF0F766E),
                    onChanged: (v) => setState(() => _agreedToRules = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to maintain pin-drop silence and adhere to all library discipline rules.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Submit Admission Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'TrackMyLibrary Secure Desk Allotment',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData? icon, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0F766E), size: 20) : null,
      prefixText: prefix,
      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
      ),
    );
  }
}
