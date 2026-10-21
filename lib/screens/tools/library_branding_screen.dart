import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class LibraryBrandingScreen extends StatefulWidget {
  const LibraryBrandingScreen({super.key});

  @override
  State<LibraryBrandingScreen> createState() => _LibraryBrandingScreenState();
}

class _LibraryBrandingScreenState extends State<LibraryBrandingScreen> {
  final LibraryService _service = LibraryService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  late String _selectedLogoName;
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _taglineCtrl;

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    _selectedLogoName = _service.profile.logoEmblem;
    _nameCtrl = TextEditingController(text: _service.profile.libraryName);
    _cityCtrl = TextEditingController(text: _service.profile.city);
    _taglineCtrl = TextEditingController(text: _service.profile.tagline);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  IconData _getEmblemIcon(String emblem) {
    switch (emblem) {
      case 'Academic Pillar':
        return Icons.account_balance_rounded;
      case 'Modern Campus':
        return Icons.location_city_rounded;
      case 'Scholar Cap':
        return Icons.school_rounded;
      case 'Book & Torch':
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color _getEmblemColor(String emblem) {
    switch (emblem) {
      case 'Academic Pillar':
        return const Color(0xFF0284C7);
      case 'Modern Campus':
        return const Color(0xFF8B5CF6);
      case 'Scholar Cap':
        return const Color(0xFFF59E0B);
      case 'Book & Torch':
      default:
        return const Color(0xFF0D9488);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      setState(() => _isUploading = true);
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        _service.saveBranding(
          logoEmblem: _selectedLogoName,
          tagline: _taglineCtrl.text.trim().isNotEmpty ? _taglineCtrl.text.trim() : _service.profile.tagline,
          libraryName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
          city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
          logoBase64: base64String,
        );

        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom Library Logo uploaded and saved successfully!'),
              backgroundColor: Color(0xFF0D6E66),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not upload logo: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeCustomLogo() {
    _service.saveBranding(
      logoEmblem: _selectedLogoName,
      tagline: _taglineCtrl.text.trim().isNotEmpty ? _taglineCtrl.text.trim() : _service.profile.tagline,
      libraryName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      clearCustomLogo: true,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom logo removed. Reverted to official emblem.'),
        backgroundColor: Color(0xFF0D6E66),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _chooseLogo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Library Emblem / Logo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a professional emblem for your library receipts and branding:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _emblemOption('Book & Torch', Icons.menu_book_rounded, const Color(0xFF0D9488)),
                _emblemOption('Academic Pillar', Icons.account_balance_rounded, const Color(0xFF0284C7)),
                _emblemOption('Modern Campus', Icons.location_city_rounded, const Color(0xFF8B5CF6)),
                _emblemOption('Scholar Cap', Icons.school_rounded, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Confirm Emblem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveBranding();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emblemOption(String name, IconData icon, Color color) {
    final isSelected = _selectedLogoName == name;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedLogoName = name;
        });
        _saveBranding();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name emblem set as your official library logo!'),
            backgroundColor: const Color(0xFF0D6E66),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(isSelected ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: isSelected ? 2.5 : 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: AppColors.textNavy)),
        ],
      ),
    );
  }

  void _saveBranding() {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final tagline = _taglineCtrl.text.trim();

    _service.saveBranding(
      logoEmblem: _selectedLogoName,
      tagline: tagline.isNotEmpty ? tagline : 'Silence • Focus • Success',
      libraryName: name.isNotEmpty ? name : null,
      city: city.isNotEmpty ? city : null,
      logoBase64: _service.profile.logoBase64,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Library branding saved & applied to receipts!'),
        backgroundColor: Color(0xFF0D6E66),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryName = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : _service.profile.libraryName;
    final city = _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : _service.profile.city;
    final tagline = _taglineCtrl.text.trim().isNotEmpty ? _taglineCtrl.text.trim() : _service.profile.tagline;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Library Branding',
          style: TextStyle(color: AppColors.textNavy, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const Text(
              'Library Branding',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Build your institutional identity across WhatsApp and invoices.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: CURRENT EMBLEM / LOGO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                      Text(
                        'OFFICIAL EMBLEM / LOGO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B).withOpacity(0.9),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _service.profile.hasCustomLogo ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _service.profile.hasCustomLogo ? 'CUSTOM LOGO ACTIVE' : 'PRESET EMBLEM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: _service.profile.hasCustomLogo ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Emblem / Custom Logo Container
                  if (_service.profile.hasCustomLogo)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF0D9488), width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x120D9488), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Image.memory(
                              base64Decode(_service.profile.logoBase64!),
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Center(
                                child: Icon(_getEmblemIcon(_selectedLogoName), size: 48, color: _getEmblemColor(_selectedLogoName)),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D6E66),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: _getEmblemColor(_selectedLogoName).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _getEmblemColor(_selectedLogoName),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getEmblemIcon(_selectedLogoName),
                              color: _getEmblemColor(_selectedLogoName),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedLogoName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _getEmblemColor(_selectedLogoName),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Upload Custom Logo Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6E66),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isUploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: Text(
                        _isUploading ? 'Uploading Logo...' : (_service.profile.hasCustomLogo ? 'Change Custom Logo' : 'Upload Custom Logo'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      onPressed: _isUploading ? null : _pickAndUploadLogo,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Button: Preset Emblem or Remove Logo
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textNavy,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.style_rounded, size: 18),
                          label: const Text('Preset Emblems', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          onPressed: _chooseLogo,
                        ),
                      ),
                      if (_service.profile.hasCustomLogo) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Remove', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          onPressed: _removeCustomLogo,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: EDIT INSTITUTIONAL DETAILS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LIBRARY DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Library Name',
                      prefixIcon: const Icon(Icons.business_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _cityCtrl,
                    decoration: InputDecoration(
                      labelText: 'City / Address',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _taglineCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tagline / Slogan',
                      prefixIcon: const Icon(Icons.format_quote_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _saveBranding,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: INVOICE HEADER PREVIEW
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECEIPT & INVOICE HEADER PREVIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: const Color(0xFF64748B).withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_service.profile.hasCustomLogo)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(_service.profile.logoBase64!),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _getEmblemColor(_selectedLogoName).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_getEmblemIcon(_selectedLogoName), color: _getEmblemColor(_selectedLogoName), size: 24),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getEmblemColor(_selectedLogoName).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getEmblemIcon(_selectedLogoName),
                                  color: _getEmblemColor(_selectedLogoName),
                                  size: 24,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    libraryName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                                  ),
                                  Text(
                                    '$city • $tagline',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Receipt #: REC-2026-1042', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                              child: const Text('PAID', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
