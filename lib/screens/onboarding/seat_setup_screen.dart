import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import 'shift_setup_screen.dart';

class SeatSetupScreen extends StatefulWidget {
  const SeatSetupScreen({super.key});

  @override
  State<SeatSetupScreen> createState() => _SeatSetupScreenState();
}

class _SeatSetupScreenState extends State<SeatSetupScreen> {
  final _service = LibraryService();
  late List<SectionConfig> _sections;

  @override
  void initState() {
    super.initState();
    _sections = List.from(_service.sections);
    if (_sections.isEmpty) {
      _sections.add(SectionConfig(id: 'sec_1', name: 'Main Hall', startSeat: 1, endSeat: 35));
    }
  }

  int get _totalSeats {
    int count = 0;
    for (var s in _sections) {
      count += s.totalSeats;
    }
    return count;
  }

  void _addSection() {
    setState(() {
      final nextIndex = _sections.length + 1;
      final start = _sections.isEmpty ? 1 : (_sections.last.endSeat + 1);
      final end = start + 24;
      _sections.add(
        SectionConfig(
          id: 'sec_$nextIndex',
          name: 'Section $nextIndex',
          startSeat: start,
          endSeat: end,
        ),
      );
    });
  }

  void _editSectionName(int index) {
    final ctrl = TextEditingController(text: _sections[index].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Section'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Section Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _sections[index].name = ctrl.text.trim());
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
    if (_totalSeats <= 0) return;
    _service.updateSectionsAndRebuildSeats(_sections);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShiftSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _totalSeats > 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Indicator (Images 5 & 6)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'STEP 1 OF 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress line (1 of 3)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: 1 / 3,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Set up your seats',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Most libraries have one hall. Add more only if you have separate rooms.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
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
                            'Tap any name or seat number to change it',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Hall Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: _sections.length + 1,
                itemBuilder: (context, index) {
                  if (index == _sections.length) {
                    // Add another section dashed card
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                          width: 1.2,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _addSection,
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: AppColors.primaryTeal, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Add another section',
                                style: TextStyle(
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final sec = _sections[index];
                  final quickOptions = [10, 20, 30, 50, 100];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _editSectionName(index),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sec.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                            if (_sections.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed, size: 20),
                                onPressed: () => setState(() => _sections.removeAt(index)),
                              ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),

                        // Start & End Seat Inputs
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'START SEAT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: TextFormField(
                                      initialValue: '${sec.startSeat}',
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      decoration: const InputDecoration(border: InputBorder.none),
                                      onChanged: (val) {
                                        setState(() {
                                          sec.startSeat = int.tryParse(val) ?? 1;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Text('—', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'END SEAT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: TextFormField(
                                      key: ValueKey('end_${sec.endSeat}'),
                                      initialValue: '${sec.endSeat}',
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      decoration: const InputDecoration(border: InputBorder.none),
                                      onChanged: (val) {
                                        setState(() {
                                          sec.endSeat = int.tryParse(val) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Chips: 10, 20, 30, 50, 100 (Image 5 & 6)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: quickOptions.map((opt) {
                            final isSelected = sec.endSeat == (sec.startSeat + opt - 1);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    setState(() {
                                      sec.endSeat = sec.startSeat + opt - 1;
                                    });
                                  },
                                  child: Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryTeal : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$opt',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : AppColors.textNavy,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Seat count badge (Image 6)
                        if (sec.totalSeats > 0)
                          Row(
                            children: [
                              const Icon(Icons.grid_view_rounded, size: 14, color: AppColors.primaryTeal),
                              const SizedBox(width: 5),
                              Text(
                                '${sec.totalSeats} seats',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Sticky Bar (Image 5 & 6)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_sections.length} ${_sections.length == 1 ? 'section' : 'sections'}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalSeats seats',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                      ),
                    ],
                  ),
                  if (!isValid) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Enter a start and end seat for every section',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warningOrange),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid ? AppColors.primaryTeal : const Color(0xFF64748B).withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isValid ? _onContinue : null,
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
