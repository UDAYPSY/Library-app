import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import 'review_setup_screen.dart';

class ShiftSetupScreen extends StatefulWidget {
  const ShiftSetupScreen({super.key});

  @override
  State<ShiftSetupScreen> createState() => _ShiftSetupScreenState();
}

class _ShiftSetupScreenState extends State<ShiftSetupScreen> {
  final _service = LibraryService();
  late List<ShiftConfig> _shifts;

  @override
  void initState() {
    super.initState();
    _shifts = List.from(_service.shifts);
    if (_shifts.isEmpty) {
      _shifts.add(
        ShiftConfig(
          id: 'shift_1',
          name: 'Full Day',
          startsAt: '06:00 AM',
          endsAt: '10:00 PM',
          monthlyFee: 500,
        ),
      );
    }
  }

  void _showAddShiftBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Image 8)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add a shift',
                  style: TextStyle(
                    fontSize: 20,
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
            const SizedBox(height: 4),
            const Text(
              'Pick a starting point — you can rename it and change the times after.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Custom Shift Card (Image 8)
            Container(
              decoration: BoxDecoration(
                color: AppColors.mintTipBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.mintAccent.withOpacity(0.5)),
              ),
              child: ListTile(
                title: const Text(
                  'Custom shift',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text(
                  'Set your own name and timings',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
                onTap: () {
                  Navigator.pop(ctx);
                  _createCustomShift();
                },
              ),
            ),
            const SizedBox(height: 18),

            // OR START FROM divider
            const Center(
              child: Text(
                'OR START FROM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Presets (Image 8)
            _presetOption(ctx, 'Morning', '06:00 AM – 12:00 PM', '06:00 AM', '12:00 PM', 400),
            _presetOption(ctx, 'Afternoon', '12:00 PM – 06:00 PM', '12:00 PM', '06:00 PM', 400),
            _presetOption(ctx, 'Evening', '02:00 PM – 10:00 PM', '02:00 PM', '10:00 PM', 450),
            _presetOption(ctx, 'Night', '08:00 PM – 06:00 AM', '08:00 PM', '06:00 AM', 450),
            _presetOption(ctx, 'Full Day', '06:00 AM – 10:00 PM', '06:00 AM', '10:00 PM', 500),
            _presetOption(ctx, '24 Hours', '12:00 AM – 11:59 PM', '12:00 AM', '11:59 PM', 700),
          ],
        ),
      ),
    );
  }

  Widget _presetOption(
    BuildContext ctx,
    String name,
    String displayTime,
    String starts,
    String ends,
    int fee,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textNavy),
        ),
        subtitle: Text(
          displayTime,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryTeal, size: 22),
        onTap: () {
          setState(() {
            _shifts.add(
              ShiftConfig(
                id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                startsAt: starts,
                endsAt: ends,
                monthlyFee: fee,
              ),
            );
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _createCustomShift() {
    final nameCtrl = TextEditingController(text: 'Custom Shift');
    final feeCtrl = TextEditingController(text: '500');
    String starts = '08:00 AM';
    String ends = '08:00 PM';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Custom Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shift Name')),
            const SizedBox(height: 10),
            TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Fee (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              setState(() {
                _shifts.add(
                  ShiftConfig(
                    id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isEmpty ? 'Custom Shift' : nameCtrl.text.trim(),
                    startsAt: starts,
                    endsAt: ends,
                    monthlyFee: int.tryParse(feeCtrl.text) ?? 500,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Shift', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editShiftName(int idx) {
    final ctrl = TextEditingController(text: _shifts[idx].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Shift'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Shift Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _shifts[idx].name = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (_shifts.isEmpty) return;
    _service.shifts = _shifts;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Image 7)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textNavy),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'STEP 2 OF 3',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress bar (2 of 3)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: 2 / 3,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'When do students sit?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add the shifts you run. Rename, retime and price each one.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Tip Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.mintTipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryTeal),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap any name, time or fee to change it',
                            style: TextStyle(color: AppColors.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Shifts List (Image 7)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: _shifts.length + 1,
                itemBuilder: (context, index) {
                  if (index == _shifts.length) {
                    // + Add shift dashed card
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _showAddShiftBottomSheet,
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: AppColors.primaryTeal, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Add shift ⌄',
                                style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final sh = _shifts[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shift Header
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryTeal, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _editShiftName(index),
                                child: Row(
                                  children: [
                                    Text(
                                      sh.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                            if (_shifts.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                                onPressed: () => setState(() => _shifts.removeAt(index)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Starts / Ends
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('STARTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(sh.startsAt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ENDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(sh.endsAt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Monthly Fee
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MONTHLY FEE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5),
                            ),
                            Row(
                              children: [
                                const Text('₹ ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textNavy)),
                                Text(
                                  '${sh.monthlyFee}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Sticky Bar (Image 7)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_shifts.length} ${_shifts.length == 1 ? 'shift' : 'shifts'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textNavy, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _onContinue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
