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
  late String _selectedAccentColor;
  late String _selectedCardStyle;
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _noticeCtrl;
  late TextEditingController _receiptFooterCtrl;
  late bool _showWatermark;

  final List<Map<String, dynamic>> _colorThemes = [
    {'name': 'Royal Emerald', 'hex': '#0D9488', 'color': const Color(0xFF0D9488)},
    {'name': 'Ocean Sapphire', 'hex': '#0284C7', 'color': const Color(0xFF0284C7)},
    {'name': 'Mystic Violet', 'hex': '#8B5CF6', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Imperial Amber', 'hex': '#F59E0B', 'color': const Color(0xFFF59E0B)},
    {'name': 'Cyber Indigo', 'hex': '#6366F1', 'color': const Color(0xFF6366F1)},
    {'name': 'Crimson Rose', 'hex': '#F43F5E', 'color': const Color(0xFFF43F5E)},
  ];

  final List<Map<String, dynamic>> _cardStyles = [
    {
      'title': 'Modern Glassmorphism',
      'subtitle': 'Frosted glass sheen with smooth gradients',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'title': 'Executive Gold Foil',
      'subtitle': 'Prestige dark background with luxury gold trim',
      'icon': Icons.workspace_premium_rounded,
    },
    {
      'title': 'Royal Emerald',
      'subtitle': 'Botanical deep green and vivid teal glow',
      'icon': Icons.eco_rounded,
    },
    {
      'title': 'Minimalist Slate',
      'subtitle': 'Crisp monochrome structure with clean lines',
      'icon': Icons.crop_square_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    final p = _service.profile;
    _selectedLogoName = p.logoEmblem;
    _selectedAccentColor = p.accentColorHex;
    _selectedCardStyle = p.cardThemeStyle;
    _showWatermark = p.showBrandingWatermark;
    _nameCtrl = TextEditingController(text: p.libraryName);
    _cityCtrl = TextEditingController(text: p.city);
    _taglineCtrl = TextEditingController(text: p.tagline);
    _noticeCtrl = TextEditingController(text: p.noticeAnnouncement);
    _receiptFooterCtrl = TextEditingController(text: p.receiptFooterNote);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _taglineCtrl.dispose();
    _noticeCtrl.dispose();
    _receiptFooterCtrl.dispose();
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
      case 'Golden Shield':
        return Icons.shield_rounded;
      case 'Achievement Trophy':
        return Icons.emoji_events_rounded;
      case 'Knowledge Globe':
        return Icons.public_rounded;
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
      case 'Golden Shield':
        return const Color(0xFFEAB308);
      case 'Achievement Trophy':
        return const Color(0xFFEC4899);
      case 'Knowledge Globe':
        return const Color(0xFF06B6D4);
      case 'Book & Torch':
      default:
        return const Color(0xFF0D9488);
    }
  }

  Color _getActiveThemeColor() {
    final found = _colorThemes.firstWhere(
      (t) => t['hex'] == _selectedAccentColor,
      orElse: () => _colorThemes.first,
    );
    return found['color'] as Color;
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
          accentColorHex: _selectedAccentColor,
          cardThemeStyle: _selectedCardStyle,
          noticeAnnouncement: _noticeCtrl.text.trim(),
          receiptFooterNote: _receiptFooterCtrl.text.trim(),
          showBrandingWatermark: _showWatermark,
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
      accentColorHex: _selectedAccentColor,
      cardThemeStyle: _selectedCardStyle,
      noticeAnnouncement: _noticeCtrl.text.trim(),
      receiptFooterNote: _receiptFooterCtrl.text.trim(),
      showBrandingWatermark: _showWatermark,
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
    final emblems = [
      {'name': 'Book & Torch', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF0D9488)},
      {'name': 'Academic Pillar', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF0284C7)},
      {'name': 'Modern Campus', 'icon': Icons.location_city_rounded, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Scholar Cap', 'icon': Icons.school_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'Golden Shield', 'icon': Icons.shield_rounded, 'color': const Color(0xFFEAB308)},
      {'name': 'Achievement Trophy', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFEC4899)},
      {'name': 'Knowledge Globe', 'icon': Icons.public_rounded, 'color': const Color(0xFF06B6D4)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Library Emblem / Crest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a distinctive symbol for your student ID cards and receipts:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.start,
              children: emblems.map((e) {
                final isSelected = _selectedLogoName == e['name'];
                final col = e['color'] as Color;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedLogoName = e['name'] as String);
                    _saveBranding();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: col.withOpacity(isSelected ? 0.18 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? col : Colors.black12, width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(e['icon'] as IconData, color: col, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          e['name'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  void _saveBranding() {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final tagline = _taglineCtrl.text.trim();
    final notice = _noticeCtrl.text.trim();
    final receiptFooter = _receiptFooterCtrl.text.trim();

    _service.saveBranding(
      logoEmblem: _selectedLogoName,
      tagline: tagline.isNotEmpty ? tagline : 'Silence • Focus • Success',
      libraryName: name.isNotEmpty ? name : null,
      city: city.isNotEmpty ? city : null,
      logoBase64: _service.profile.logoBase64,
      accentColorHex: _selectedAccentColor,
      cardThemeStyle: _selectedCardStyle,
      noticeAnnouncement: notice.isNotEmpty ? notice : null,
      receiptFooterNote: receiptFooter.isNotEmpty ? receiptFooter : null,
      showBrandingWatermark: _showWatermark,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Library aesthetic branding & card theme saved!'),
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
    final activeColor = _getActiveThemeColor();

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
          'Library Branding & Aesthetics',
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
              'Aesthetic Studio',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Personalize emblems, color palettes, student badges & digital receipt styling.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: LIVE BRANDED MEMBER CARD PREVIEW
            _buildLiveCardPreview(libraryName, city, tagline, activeColor),
            const SizedBox(height: 20),

            // Card 2: COLOR THEME ACCENT PALETTE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ACCENT PALETTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
                      Text('Dynamic Theme Color', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorThemes.map((theme) {
                      final isSelected = _selectedAccentColor == theme['hex'];
                      final col = theme['color'] as Color;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedAccentColor = theme['hex'] as String);
                          _saveBranding();
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: col.withOpacity(isSelected ? 0.45 : 0.2),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: CARD & RECEIPT THEME STYLE SELECTOR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STUDENT BADGE & RECEIPT THEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  ..._cardStyles.map((style) {
                    final title = style['title'] as String;
                    final isSelected = _selectedCardStyle == title;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor.withOpacity(0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() => _selectedCardStyle = title);
                          _saveBranding();
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(style['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
                        ),
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isSelected ? activeColor : AppColors.textNavy)),
                        subtitle: Text(style['subtitle'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: activeColor, size: 22) : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 4: OFFICIAL EMBLEM / LOGO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'OFFICIAL EMBLEM / LOGO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
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
                            color: _service.profile.hasCustomLogo ? activeColor : const Color(0xFF64748B),
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
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: activeColor, width: 2.5),
                            boxShadow: [BoxShadow(color: activeColor.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Image.memory(
                              base64Decode(_service.profile.logoBase64!),
                              width: 130,
                              height: 130,
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
                            decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _getEmblemColor(_selectedLogoName).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _getEmblemColor(_selectedLogoName), width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getEmblemIcon(_selectedLogoName), color: _getEmblemColor(_selectedLogoName), size: 44),
                            const SizedBox(height: 8),
                            Text(
                              _selectedLogoName,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _getEmblemColor(_selectedLogoName)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Upload Custom Logo Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isUploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded, size: 20),
                      label: Text(
                        _isUploading ? 'Uploading Logo...' : (_service.profile.hasCustomLogo ? 'Change Custom Logo' : 'Upload Custom Logo'),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      onPressed: _isUploading ? null : _pickAndUploadLogo,
                    ),
                  ),
                  const SizedBox(height: 10),

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

            // Card 5: INSTITUTIONAL DETAILS & NOTICE BOARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LIBRARY DETAILS & MOTTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B))),
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noticeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Notice Board / Welcome Announcement',
                      hintText: 'e.g. Silence is Golden • High-Speed 5G Wi-Fi • Fully AC',
                      prefixIcon: const Icon(Icons.campaign_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _receiptFooterCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Receipt Footer Notes & Rules',
                      hintText: 'e.g. Fees once paid are non-refundable. Please keep ID card during entry.',
                      prefixIcon: const Icon(Icons.article_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Watermark Crest on ID Cards', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Embeds subtle background library watermark on ID cards & receipts', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: _showWatermark,
                    activeColor: activeColor,
                    onChanged: (val) {
                      setState(() => _showWatermark = val);
                      _saveBranding();
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text('Save All Branding Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _saveBranding,
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

  Widget _buildLiveCardPreview(String libraryName, String city, String tagline, Color activeColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedCardStyle == 'Executive Gold Foil'
                ? const Color(0xFF1E293B)
                : _selectedCardStyle == 'Royal Emerald'
                    ? const Color(0xFF064E3B)
                    : _selectedCardStyle == 'Minimalist Slate'
                        ? const Color(0xFF334155)
                        : activeColor.withOpacity(0.92),
            _selectedCardStyle == 'Executive Gold Foil'
                ? const Color(0xFF0F172A)
                : _selectedCardStyle == 'Royal Emerald'
                    ? const Color(0xFF042F2E)
                    : _selectedCardStyle == 'Minimalist Slate'
                        ? const Color(0xFF1E293B)
                        : activeColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _selectedCardStyle == 'Executive Gold Foil' ? const Color(0xFFF59E0B) : Colors.white24,
          width: _selectedCardStyle == 'Executive Gold Foil' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: _service.profile.hasCustomLogo
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_service.profile.logoBase64!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(_getEmblemIcon(_selectedLogoName), color: Colors.white, size: 20),
                            ),
                          )
                        : Icon(_getEmblemIcon(_selectedLogoName), color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libraryName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        city,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedCardStyle == 'Executive Gold Foil' ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STUDENT PASS',
                  style: TextStyle(
                    color: _selectedCardStyle == 'Executive Gold Foil' ? Colors.black : Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rahul Sharma',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seat: S-14 • Full Day Shift',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 28, color: AppColors.textNavy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
              if (_showWatermark)
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED MEMBER',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
