import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class ShiftSystemScreen extends StatefulWidget {
  const ShiftSystemScreen({super.key});

  @override
  State<ShiftSystemScreen> createState() => _ShiftSystemScreenState();
}

class _ShiftSystemScreenState extends State<ShiftSystemScreen> {
  final LibraryService _service = LibraryService();

  void _toggleShift(ShiftConfig shift) {
    setState(() {
      _service.toggleShiftActive(shift.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shift.isActive
              ? '${shift.name} moved to Active Shifts'
              : '${shift.name} moved to Inactive Shifts',
        ),
        backgroundColor: shift.isActive ? const Color(0xFF0D766E) : Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openEditShiftModal(ShiftConfig shift) {
    final nameCtrl = TextEditingController(text: shift.name);
    final feeCtrl = TextEditingController(text: '${shift.monthlyFee}');
    String startsAt = shift.startsAt;
    String endsAt = shift.endsAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Shift Slot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textNavy),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shift Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: startsAt),
                      decoration: const InputDecoration(
                        labelText: 'Starts At',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                      ),
                      onChanged: (val) => startsAt = val,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: endsAt),
                      decoration: const InputDecoration(
                        labelText: 'Ends At',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time_rounded, size: 18),
                      ),
                      onChanged: (val) => endsAt = val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Fee (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final fee = int.tryParse(feeCtrl.text.trim()) ?? shift.monthlyFee;
                    setState(() {
                      _service.updateShift(
                        ShiftConfig(
                          id: shift.id,
                          name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : shift.name,
                          startsAt: startsAt,
                          endsAt: endsAt,
                          monthlyFee: fee,
                          isActive: shift.isActive,
                          isSystemSlot: shift.isSystemSlot,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameCtrl.text.trim()} updated successfully!'),
                        backgroundColor: const Color(0xFF0D766E),
                      ),
                    );
                  },
                  child: const Text(
                    'Save Slot Settings',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddNewSlotModal() {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '500');
    final startCtrl = TextEditingController(text: '08:00 AM');
    final endCtrl = TextEditingController(text: '02:00 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Shift Slot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textNavy),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slot Name (e.g. Afternoon Special)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Starts At',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ends At',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Fee (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final fee = int.tryParse(feeCtrl.text.trim()) ?? 500;
                    setState(() {
                      _service.addShift(
                        ShiftConfig(
                          id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          startsAt: startCtrl.text.trim(),
                          endsAt: endCtrl.text.trim(),
                          monthlyFee: fee,
                          isActive: true,
                          isSystemSlot: false,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Shift slot "$name" created!'),
                        backgroundColor: const Color(0xFF0D766E),
                      ),
                    );
                  },
                  child: const Text(
                    'Create Slot',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyPreset(String name, String start, String end, int fee) {
    setState(() {
      _service.addShift(
        ShiftConfig(
          id: 'shift_preset_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          startsAt: start,
          endsAt: end,
          monthlyFee: fee,
          isActive: true,
          isSystemSlot: false,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "$name" added to Active Shifts!'),
        backgroundColor: const Color(0xFF0D766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeShifts = _service.shifts.where((s) => s.isActive).toList();
    final inactiveShifts = _service.shifts.where((s) => !s.isActive).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with back button (Image 4 & 5)
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: AppColors.textNavy, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift System',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textNavy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure timings and slot fees',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Smart Scheduling Banner (Image 4)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x286366F1),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Scheduling',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Shifts help in auto-calculating fees and managing seat occupancy efficiently.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ACTIVE SHIFTS Header + [+ New Slot] Button (Image 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIVE SHIFTS (${activeShifts.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  InkWell(
                    onTap: _openAddNewSlotModal,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D766E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'New Slot',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Shifts List (Image 4)
              if (activeShifts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No active shifts. Activate a shift below.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else
                ...activeShifts.map((s) => _buildShiftCard(s, isActive: true)),

              const SizedBox(height: 24),

              // INACTIVE SHIFTS Header (Image 4 & 5)
              Text(
                'INACTIVE SHIFTS (${inactiveShifts.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // Inactive Shifts List (Image 4 & 5)
              if (inactiveShifts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'All shifts are active.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else
                ...inactiveShifts.map((s) => _buildShiftCard(s, isActive: false)),

              const SizedBox(height: 24),

              // SUGGESTED PRESETS Section (Image 5)
              const Text(
                'SUGGESTED PRESETS (4)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              _presetCard(
                title: 'Half Day Morning (6 hrs)',
                time: '08:00 AM — 02:00 PM',
                fee: 400,
                onAdd: () => _applyPreset('Half Day Morning', '08:00 AM', '02:00 PM', 400),
              ),
              const SizedBox(height: 10),
              _presetCard(
                title: 'Half Day Evening (6 hrs)',
                time: '02:00 PM — 08:00 PM',
                fee: 400,
                onAdd: () => _applyPreset('Half Day Evening', '02:00 PM', '08:00 PM', 400),
              ),
              const SizedBox(height: 10),
              _presetCard(
                title: 'Weekend Pass',
                time: '07:00 AM — 09:00 PM',
                fee: 300,
                onAdd: () => _applyPreset('Weekend Pass', '07:00 AM', '09:00 PM', 300),
              ),
              const SizedBox(height: 10),
              _presetCard(
                title: 'Exam Marathon (16 hrs)',
                time: '06:00 AM — 10:00 PM',
                fee: 800,
                onAdd: () => _applyPreset('Exam Marathon', '06:00 AM', '10:00 PM', 800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftCard(ShiftConfig shift, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE6FFFA) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: isActive ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'MONTHLY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${shift.monthlyFee}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            shift.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 3),

          // Time range
          Text(
            '${shift.startsAt} — ${shift.endsAt}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Bottom action row (Image 4 & 5)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tag: SYSTEM SLOT or INACTIVE
              if (shift.isSystemSlot)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SYSTEM SLOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF137333),
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'INACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CUSTOM SLOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0369A1),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

              // Action buttons: Eye Toggle and Edit Pencil
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isActive ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
                      size: 20,
                    ),
                    onPressed: () => _toggleShift(shift),
                    tooltip: isActive ? 'Deactivate' : 'Activate',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                    onPressed: () => _openEditShiftModal(shift),
                    tooltip: 'Edit Slot',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetCard({
    required String title,
    required String time,
    required int fee,
    required VoidCallback onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$time • ₹$fee/mo',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Text(
                '+ Add',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
