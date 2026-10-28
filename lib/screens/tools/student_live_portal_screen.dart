import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class StudentLivePortalScreen extends StatefulWidget {
  const StudentLivePortalScreen({super.key});

  @override
  State<StudentLivePortalScreen> createState() => _StudentLivePortalScreenState();
}

class _StudentLivePortalScreenState extends State<StudentLivePortalScreen> {
  final LibraryService _service = LibraryService();
  String _selectedShift = 'All Shifts';
  int? _selectedSeatForInquiry;

  String get _effectiveLibraryId {
    final qLib = Uri.base.queryParameters['lib'];
    if (qLib != null && qLib.trim().isNotEmpty) return qLib.trim();

    final frag = Uri.base.fragment;
    if (frag.isNotEmpty) {
      try {
        final fUri = Uri.parse(frag.startsWith('/') ? frag : '/$frag');
        final fLib = fUri.queryParameters['lib'];
        if (fLib != null && fLib.trim().isNotEmpty) return fLib.trim();
      } catch (_) {}
    }
    return _service.tenantId;
  }

  Map<String, String> get _urlParams {
    final params = Map<String, String>.from(Uri.base.queryParameters);
    final frag = Uri.base.fragment;
    if (frag.isNotEmpty) {
      try {
        final fUri = Uri.parse(frag.startsWith('/') ? frag : '/$frag');
        params.addAll(fUri.queryParameters);
      } catch (_) {}
    }
    return params;
  }

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    final targetLib = _effectiveLibraryId;
    if (targetLib.isNotEmpty && targetLib != _service.tenantId) {
      _service.switchTenant(targetLib);
    }
  }

  Future<void> _sendWhatsAppInquiry({int? seatNum, String? shiftName}) async {
    final cleanPhone = _service.profile.adminPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final shiftText = shiftName ?? _selectedShift;
    final seatText = seatNum != null ? 'Seat #S-$seatNum' : 'a vacant seat';
    final msg = 'Hello ${_service.profile.libraryName}! I scanned your library QR Code and want to inquire about booking $seatText for the $shiftText. Are admissions open?';
    
    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      initialData: _service.currentStudents,
      builder: (context, studentSnapshot) {
        final students = studentSnapshot.data ?? _service.currentStudents;
        final profile = _service.profile;
        final totalSeats = _service.totalSeatsCount;
        final allLibraryShifts = ['All Shifts', ..._service.shifts.map((s) => s.name).toSet()];

        int occupiedCount = 0;
        for (int i = 1; i <= totalSeats; i++) {
          final seatOccupants = students.where((s) => s.seatNumber == i && s.status != 'INACTIVE').toList();
          final bool isOcc;
          if (_selectedShift == 'All Shifts') {
            isOcc = seatOccupants.isNotEmpty;
          } else {
            isOcc = seatOccupants.any((s) => LibraryService.doShiftsConflict(s.shift, _selectedShift, allShifts: _service.shifts));
          }
          if (isOcc) occupiedCount++;
        }
        final vacantCount = (totalSeats - occupiedCount).clamp(0, totalSeats);
        final occupancyPercent = totalSeats > 0 ? ((occupiedCount / totalSeats) * 100).round() : 0;

        final params = _urlParams;
        final verifiedId = params['verify'];
        final verifiedStudent = params['student'];
        final verifiedSeat = params['seat'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: const Text(
          'Live Student Seat Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text('LIVE SYNC', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Verified Digital ID Pass Card if scanned via student QR pass
            if (verifiedId != null && verifiedId.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF042F2E), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x332DD4BF), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2DD4BF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF042F2E), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OFFICIAL MEMBER DIGITAL PASS',
                                style: TextStyle(
                                  color: Color(0xFF99F6E4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                verifiedStudent ?? 'Registered Student',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chair_rounded, color: Color(0xFF2DD4BF), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Seat: #${verifiedSeat ?? 'Unassigned'}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          'Pass ID: $verifiedId',
                          style: const TextStyle(color: Color(0xFF99F6E4), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Hero Library Header Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo / Emblem
                      if (profile.hasCustomLogo)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(profile.logoBase64!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _fallbackLogo(profile),
                          ),
                        )
                      else
                        _fallbackLogo(profile),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.libraryName,
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.city,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.tagline,
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF2DD4BF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Occupancy Counter Strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('VACANT SEATS', '$vacantCount', const Color(0xFF34D399)),
                        Container(width: 1, height: 36, color: Colors.white12),
                        _statItem('OCCUPIED', '$occupiedCount', const Color(0xFF94A3B8)),
                        Container(width: 1, height: 36, color: Colors.white12),
                        _statItem('OCCUPANCY', '$occupancyPercent%', const Color(0xFF38BDF8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Seat Grid Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE SEAT MAP',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap any green seat to reserve on WhatsApp',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _legendPill('Free', const Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          _legendPill('Occ', const Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Shift Filter Chips Row
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allLibraryShifts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final sh = allLibraryShifts[i];
                        final isSel = _selectedShift == sh;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedShift = sh;
                              _selectedSeatForInquiry = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF0D9488) : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel ? const Color(0xFF5EEAD4) : Colors.white12,
                              ),
                            ),
                            child: Text(
                              sh,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                color: isSel ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Visual Grid
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: totalSeats,
                      itemBuilder: (ctx, idx) {
                        final seatNum = idx + 1;
                        final seatOccupants = students.where((s) => s.seatNumber == seatNum && s.status != 'INACTIVE').toList();
                        final bool isOcc;
                        final String occLabel;
                        if (_selectedShift == 'All Shifts') {
                          isOcc = seatOccupants.isNotEmpty;
                          occLabel = seatOccupants.isNotEmpty
                              ? seatOccupants.map((s) => s.shift.split(' ').first).join('/')
                              : 'Free';
                        } else {
                          isOcc = seatOccupants.any((s) => LibraryService.doShiftsConflict(s.shift, _selectedShift, allShifts: _service.shifts));
                          occLabel = isOcc ? 'Booked' : 'Free';
                        }
                        final isSelected = _selectedSeatForInquiry == seatNum;

                        return InkWell(
                          onTap: () {
                            if (!isOcc) {
                              setState(() {
                                _selectedSeatForInquiry = seatNum;
                              });
                            } else {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Seat S-$seatNum is already occupied for ${_selectedShift == "All Shifts" ? seatOccupants.map((s) => s.shift).join(", ") : _selectedShift}.'),
                                  backgroundColor: const Color(0xFFE11D48),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isOcc
                                  ? const Color(0xFF0F172A).withOpacity(0.6)
                                  : (isSelected ? const Color(0xFF0D9488) : const Color(0xFF064E3B)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isOcc
                                    ? Colors.white10
                                    : (isSelected ? const Color(0xFF5EEAD4) : const Color(0xFF059669)),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? const [BoxShadow(color: Color(0x660D9488), blurRadius: 10, offset: Offset(0, 3))]
                                  : null,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'S-$seatNum',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: isOcc ? const Color(0xFF64748B) : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    isOcc ? occLabel : (isSelected ? 'Selected' : 'Free'),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: isOcc ? const Color(0xFF475569) : const Color(0xFF6EE7B7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_selectedSeatForInquiry != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Seat: #S-$_selectedSeatForInquiry',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5EEAD4), fontSize: 13),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                            label: const Text('Book on WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _sendWhatsAppInquiry(seatNum: _selectedSeatForInquiry),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Study Hall Amenities
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FACILITIES & AMENITIES',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _amenityChip(Icons.wifi_rounded, 'High-Speed 5G Wi-Fi'),
                      _amenityChip(Icons.ac_unit_rounded, 'Air Conditioned Hall'),
                      _amenityChip(Icons.power_rounded, 'Personal Charging Socket'),
                      _amenityChip(Icons.water_drop_rounded, 'RO Purified Water'),
                      _amenityChip(Icons.volume_off_rounded, 'Pin-Drop Silence Zone'),
                      _amenityChip(Icons.videocam_rounded, '24/7 CCTV Security'),
                      _amenityChip(Icons.newspaper_rounded, 'Daily Newspaper & Magazines'),
                      _amenityChip(Icons.lock_clock_rounded, 'Individual Locker Facility'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Shifts & Timings Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STUDY SHIFTS & ADMISSION TIMINGS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  _shiftRow('Full Day (24/7 Access)', '06:00 AM - 11:00 PM', '₹800/mo', const Color(0xFF10B981)),
                  const Divider(color: Colors.white10, height: 18),
                  _shiftRow('Morning Shift', '06:00 AM - 02:00 PM', '₹500/mo', const Color(0xFF38BDF8)),
                  const Divider(color: Colors.white10, height: 18),
                  _shiftRow('Evening Shift', '02:00 PM - 10:00 PM', '₹500/mo', const Color(0xFFF59E0B)),
                  const Divider(color: Colors.white10, height: 18),
                  _shiftRow('Night Owl Shift', '10:00 PM - 06:00 AM', '₹600/mo', const Color(0xFFA855F7)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reception Contact & Inquire Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x330D9488), blurRadius: 18, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Want to Visit or Book a Seat?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect directly with reception at ${profile.adminPhone}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                      label: const Text(
                        'Direct WhatsApp Inquiry',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      onPressed: () => _sendWhatsAppInquiry(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _fallbackLogo(LibraryProfile profile) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488)),
      ),
      child: Center(
        child: Icon(_getEmblemIcon(profile.logoEmblem), color: const Color(0xFF2DD4BF), size: 32),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _legendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _amenityChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2DD4BF), size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _shiftRow(String shift, String timings, String fee, Color accent) {
    return Row(
      children: [
        Container(width: 4, height: 32, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shift, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              Text(timings, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Text(fee, style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ],
    );
  }
}
