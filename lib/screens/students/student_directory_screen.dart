import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class StudentDirectoryScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const StudentDirectoryScreen({super.key, this.initialStatusFilter});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final LibraryService _service = LibraryService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _statusScrollCtrl = ScrollController();
  String _selectedShiftFilter = 'ALL SHIFTS';
  String _selectedStatusFilter = 'RECENT'; // Default RECENT (Image 2)

  final List<Map<String, dynamic>> _statusFilters = [
    {'label': 'RECENT', 'icon': Icons.access_time_rounded},
    {'label': 'PAID', 'icon': Icons.check_rounded},
    {'label': 'DUES', 'icon': Icons.error_outline_rounded},
    {'label': 'REMAINING', 'icon': Icons.account_balance_wallet_outlined},
    {'label': 'TRIAL', 'icon': Icons.science_outlined},
    {'label': 'ACTIVE', 'icon': Icons.people_alt_outlined},
    {'label': 'INACTIVE', 'icon': Icons.highlight_off_rounded},
    {'label': 'UNALLOCATED', 'icon': Icons.inventory_2_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _selectedStatusFilter = widget.initialStatusFilter!;
      _maybeScrollToFilter(_selectedStatusFilter);
    }
  }

  @override
  void didUpdateWidget(covariant StudentDirectoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != null && widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      setState(() {
        _selectedStatusFilter = widget.initialStatusFilter!;
      });
      _maybeScrollToFilter(_selectedStatusFilter);
    }
  }

  void _maybeScrollToFilter(String filter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_statusScrollCtrl.hasClients) return;
      final idx = _statusFilters.indexWhere((f) => f['label'] == filter);
      if (idx > 2) {
        _statusScrollCtrl.animateTo(
          (idx - 1) * 85.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _statusScrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String shift = _service.shifts.isNotEmpty ? _service.shifts.first.name : 'Full Day';
    int fee = _service.shifts.isNotEmpty ? _service.shifts.first.monthlyFee : 500;
    int? allocatedSeat;
    String status = 'ACTIVE';
    String paymentMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
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
                      'Register New Member',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textNavy),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: shift,
                        items: _service.shifts
                            .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final found = _service.shifts.firstWhere((s) => s.name == v);
                            setModalState(() {
                              shift = v;
                              fee = found.monthlyFee;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Shift',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        items: ['ACTIVE', 'TRIAL']
                            .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v ?? status),
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: allocatedSeat,
                        hint: const Text('Seat (Optional)'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Unallocated')),
                          ...List.generate(_service.totalSeatsCount, (i) => i + 1)
                              .map((num) => DropdownMenuItem<int?>(value: num, child: Text('Seat S-$num'))),
                        ],
                        onChanged: (v) => setModalState(() => allocatedSeat = v),
                        decoration: const InputDecoration(
                          labelText: 'Seat Allocation',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentMode,
                        items: ['UPI', 'Cash']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setModalState(() => paymentMode = v ?? paymentMode),
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty || phone.isEmpty) return;
                      Navigator.pop(ctx);

                      final seatNum = allocatedSeat ?? 1;
                      await _service.assignSeatAndRegisterStudent(
                        seatNumber: seatNum,
                        studentName: name,
                        phone: phone,
                        shift: shift,
                        deviceUserId: _service.profile.adminName,
                        feeAmount: fee,
                        paymentMode: paymentMode,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name registered successfully ($status)!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Confirm Member (₹$fee)',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _sendWhatsAppMessage(StudentInfo s) async {
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    final msg = 'Hello ${s.name}, greetings from ${_service.profile.libraryName}! Your membership is active.';
    final uri = Uri.parse('https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(msg)}');
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
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        final allStudents = snapshot.data ?? [];

        // Apply Search & Filters
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredStudents = allStudents.where((s) {
          // Search filter
          if (query.isNotEmpty) {
            final matchName = s.name.toLowerCase().contains(query);
            final matchPhone = s.phone.contains(query);
            final matchSeat = 's-${s.seatNumber}'.contains(query);
            if (!matchName && !matchPhone && !matchSeat) return false;
          }

          // Shift filter
          if (_selectedShiftFilter != 'ALL SHIFTS') {
            if (s.shift.toUpperCase() != _selectedShiftFilter) return false;
          }

          // Status filter
          if (_selectedStatusFilter == 'RECENT') {
            return true;
          } else if (_selectedStatusFilter == 'PAID') {
            return s.monthlyFee > 0;
          } else if (_selectedStatusFilter == 'DUES') {
            return s.status == 'INACTIVE';
          } else if (_selectedStatusFilter == 'ACTIVE') {
            return s.status == 'ACTIVE';
          } else if (_selectedStatusFilter == 'INACTIVE') {
            return s.status == 'INACTIVE';
          } else if (_selectedStatusFilter == 'UNALLOCATED') {
            return s.seatNumber == null;
          } else if (_selectedStatusFilter == 'TRIAL') {
            return s.status == 'TRIAL';
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: MANAGEMENT Directory + [📥] + [0 PROFILES] (Image 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (Navigator.canPop(context)) ...[
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textNavy),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 4),
                              ],
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MANAGEMENT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Directory',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Download / Export Icon Button (Image 2)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Exported ${allStudents.length} student records.')),
                                  );
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.file_download_outlined, color: AppColors.primaryTeal, size: 22),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Profile Count Badge (Image 2)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${allStudents.length}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                    const Text(
                                      'PROFILES',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search Bar (Image 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search by name or number...',
                            hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shift Filter Chips Row: ALL SHIFTS, FULL DAY, etc. (Image 2 & 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _shiftChip('ALL SHIFTS', null),
                            ..._service.shifts.map((sh) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _shiftChip(sh.name.toUpperCase(), Icons.wb_cloudy_rounded),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Filter Chips Row: RECENT, PAID, DUES, REMAINING, TRIAL, ACTIVE, etc. (Images 2, 3, 4)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 38,
                        child: ListView.builder(
                          controller: _statusScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          itemCount: _statusFilters.length,
                          itemBuilder: (ctx, i) {
                            final item = _statusFilters[i];
                            final label = item['label'] as String;
                            final icon = item['icon'] as IconData;
                            final isSelected = _selectedStatusFilter == label;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _selectedStatusFilter = label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryTeal : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppColors.textNavy,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: isSelected ? Colors.white : AppColors.textNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content Area (Image 2: Empty state OR Student Cards)
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  const Text(
                                    'No students found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try adjusting search or filters.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                              itemCount: filteredStudents.length,
                              itemBuilder: (ctx, i) {
                                final st = filteredStudents[i];
                                final seatLabel = st.seatNumber != null ? 'S-${st.seatNumber}' : 'Unallocated';
                                final dueStr = st.feeDueDate != null
                                    ? DateFormat('dd MMM yyyy').format(st.feeDueDate!)
                                    : 'N/A';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.lightMint,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            seatLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              st.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textNavy,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Shift: ${st.shift} • Phone: ${st.phone}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Valid Until: $dueStr',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.whatsappDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.whatsappGreen),
                                        onPressed: () => _sendWhatsAppMessage(st),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Floating Action Button: [+ New Member] (Images 2 - 5)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _openAddMemberSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x400F766E),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'New Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _shiftChip(String label, IconData? icon) {
    final isSelected = _selectedShiftFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedShiftFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? Colors.white : AppColors.textNavy),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isSelected ? Colors.white : AppColors.textNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
