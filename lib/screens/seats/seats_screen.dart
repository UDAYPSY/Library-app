import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class SeatsScreen extends StatefulWidget {
  const SeatsScreen({super.key});

  @override
  State<SeatsScreen> createState() => _SeatsScreenState();
}

class _SeatsScreenState extends State<SeatsScreen> {
  final LibraryService _service = LibraryService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedShift = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedDues = 'ALL';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAssignSeatModal(SeatInfo seat, List<StudentInfo> students) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '500');
    String shift = 'Full Day';
    String paymentMode = 'UPI';
    StudentInfo? selectedExistingStudent;

    // Filter unallocated students
    final unassignedStudents = students.where((s) => s.seatNumber == null).toList();

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Seat ${seat.seatNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Main Hall • Space Grid',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textNavy),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Option to select unassigned student
                if (unassignedStudents.isNotEmpty) ...[
                  const Text(
                    'Select Existing Student',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<StudentInfo>(
                        hint: const Text('Choose an enrolled student', style: TextStyle(fontSize: 13)),
                        value: selectedExistingStudent,
                        isExpanded: true,
                        items: unassignedStudents.map((s) {
                          return DropdownMenuItem<StudentInfo>(
                            value: s,
                            child: Text('${s.name} (${s.phone})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedExistingStudent = val;
                              nameCtrl.text = val.name;
                              phoneCtrl.text = val.phone;
                              shift = val.shift;
                              feeCtrl.text = '${val.monthlyFee}';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR ENTER DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Student Name
                const Text(
                  'Student Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
                    decoration: const InputDecoration(
                      hintText: 'e.g. GSHSGSG',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone Number
                const Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 6464649199',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Shift & Monthly Fee
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shift',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: shift,
                                isExpanded: true,
                                items: ['Full Day', 'Morning Shift', 'Evening Shift', 'Night Shift', '24 Hours']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => shift = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fee (₹)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: feeCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Assign Seat Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final studentName = nameCtrl.text.trim().isEmpty ? 'GSHSGSG' : nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim().isEmpty ? '9876543210' : phoneCtrl.text.trim();
                      final fee = int.tryParse(feeCtrl.text.trim()) ?? 500;

                      Navigator.pop(ctx);

                      await _service.assignSeatAndRegisterStudent(
                        seatNumber: seat.seatNumber,
                        studentName: studentName,
                        phone: phone,
                        shift: shift,
                        deviceUserId: 'admin_device',
                        feeAmount: fee,
                        paymentMode: paymentMode,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Seat ${seat.seatNumber} successfully assigned to $studentName!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF0D766E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Assign Seat',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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

  void _showSeatOccupiedModal(SeatInfo seat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEAB308), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          seat.studentName.isNotEmpty ? seat.studentName.substring(0, 1).toUpperCase() : 'S',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seat.studentName.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                        ),
                        Text(
                          'Seat ${seat.seatNumber} • ${seat.shift}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textNavy),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const Border.all(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Vacate Seat', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _service.vacateSeat(seat.seatNumber, seat.studentId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Seat ${seat.seatNumber} is now vacant and available.'),
                            backgroundColor: Colors.black87,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sync_alt_rounded, size: 18),
                    label: const Text('Change Seat', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select another available seat to reassign.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoreSeatsDialog() {
    final countCtrl = TextEditingController(text: '5');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Seats to Main Hall', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many seats would you like to add?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Seats',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final count = int.tryParse(countCtrl.text.trim()) ?? 5;
              Navigator.pop(ctx);
              final currentTotal = _service.totalSeatsCount;
              final newSections = [
                SectionConfig(
                  id: 'sec_1',
                  name: 'Main Hall',
                  startSeat: 1,
                  endSeat: currentTotal + count,
                ),
              ];
              setState(() {
                _service.updateSectionsAndRebuildSeats(newSections);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $count more seats! Total seats: ${currentTotal + count}'),
                  backgroundColor: const Color(0xFF0D766E),
                ),
              );
            },
            child: const Text('Add Seats'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SeatInfo>>(
      stream: _service.streamSeats(),
      builder: (context, seatSnapshot) {
        final seats = seatSnapshot.data ?? [];
        final occupiedCount = seats.where((s) => s.isOccupied).length;
        final vacantCount = seats.length - occupiedCount;
        final totalSeats = seats.length;

        return StreamBuilder<List<StudentInfo>>(
          stream: _service.streamStudents(),
          builder: (context, studentSnapshot) {
            final students = studentSnapshot.data ?? [];
            final studentsCount = students.length;

            // Apply search filter
            final query = _searchCtrl.text.trim().toLowerCase();
            final filteredSeats = seats.where((seat) {
              if (query.isNotEmpty) {
                final matchNum = seat.seatNumber.toString().contains(query);
                final matchName = seat.studentName.toLowerCase().contains(query);
                if (!matchNum && !matchName) return false;
              }

              // Shift filter
              if (_selectedShift != 'ALL') {
                if (seat.shift.toLowerCase() != _selectedShift.toLowerCase()) return false;
              }

              // Status filter
              if (_selectedStatus == 'VACANT' && seat.isOccupied) return false;
              if (_selectedStatus == 'OCCUPIED' && !seat.isOccupied) return false;

              return true;
            }).toList();

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: MANAGEMENT / Space Grid & Actions (Image 1 & 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MANAGEMENT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Space Grid',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textNavy,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textNavy, size: 20),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Layout is clean.')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D766E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white, size: 22),
                                  onPressed: _showAddMoreSeatsDialog,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search Bar (Image 1 & 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Find student or seat...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4-Metric Summary Row: FILLED | VACANT | STUDENTS | SEATS (Image 1 & 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: _metricCard('$occupiedCount', 'FILLED', const Color(0xFF0D766E))),
                          const SizedBox(width: 8),
                          Expanded(child: _metricCard('$vacantCount', 'VACANT', const Color(0xFF16A34A))),
                          const SizedBox(width: 8),
                          Expanded(child: _metricCard('$studentsCount', 'STUDENTS', const Color(0xFFD97706))),
                          const SizedBox(width: 8),
                          Expanded(child: _metricCard('$totalSeats', 'SEATS', AppColors.textNavy)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section Pill: MAIN HALL ✏️ (Image 1 & 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D766E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MAIN HALL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Rows: SHIFT, STATUS, DUES (Image 1 & 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _filterRow(
                            'SHIFT',
                            ['ALL', 'FULL DAY'],
                            _selectedShift,
                            (val) => setState(() => _selectedShift = val),
                          ),
                          _filterRow(
                            'STATUS',
                            ['ALL', 'VACANT', 'OCCUPIED'],
                            _selectedStatus,
                            (val) => setState(() => _selectedStatus = val),
                          ),
                          _filterRow(
                            'DUES',
                            ['ALL', 'PAID', 'UNPAID', 'TRIAL'],
                            _selectedDues,
                            (val) => setState(() => _selectedDues = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Instruction Note (Image 1 & 2)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'ⓘ Long press section to rename or delete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2-Column Seat Cards Grid (Image 1 & 2)
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: filteredSeats.length + 1, // +1 for "ADD MORE SEATS" card
                        itemBuilder: (ctx, idx) {
                          // Position 0: ADD MORE SEATS TO MAIN HALL Card (Image 1 & 2)
                          if (idx == 0) {
                            return InkWell(
                              onTap: _showAddMoreSeatsDialog,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE6FFFA),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, color: Color(0xFF0D766E), size: 24),
                                      ),
                                      const SizedBox(height: 10),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          'ADD MORE SEATS TO MAIN HALL',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                            color: AppColors.textNavy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // Actual Seat Cards (idx - 1)
                          final seat = filteredSeats[idx - 1];
                          final isOccupied = seat.isOccupied;

                          // OCCUPIED / ASSIGNED SEAT CARD (Image 2)
                          if (isOccupied) {
                            final initials = seat.studentName.trim().isNotEmpty
                                ? (seat.studentName.trim().split(' ').length > 1
                                    ? '${seat.studentName.trim().split(' ')[0][0]}${seat.studentName.trim().split(' ')[1][0]}'.toUpperCase()
                                    : (seat.studentName.trim().length >= 2 ? seat.studentName.trim().substring(0, 2).toUpperCase() : seat.studentName.trim().toUpperCase()))
                                : 'GS';

                            return InkWell(
                              onTap: () => _showSeatOccupiedModal(seat),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row: Green dot, Seat number, and Trial badge (Image 2)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF16A34A),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${seat.seatNumber}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.textNavy,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.science_outlined, color: Color(0xFF0284C7), size: 14),
                                            SizedBox(width: 2),
                                            Text(
                                              '1d',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Circular Avatar with Gold/Yellow Border (Image 2)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFEAB308), width: 2.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Student Name & Shift Badge (Image 2)
                                    Column(
                                      children: [
                                        Text(
                                          seat.studentName.isNotEmpty ? seat.studentName.toUpperCase() : 'GSHSGSG',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDFA),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF99F6E4)),
                                          ),
                                          child: Text(
                                            seat.shift.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0D9488),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // AVAILABLE SEAT CARD (Image 1)
                          return InkWell(
                            onTap: () => _showAssignSeatModal(seat, students),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${seat.seatNumber}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Center(
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                      ),
                                      child: const Icon(Icons.add, color: Color(0xFF94A3B8), size: 22),
                                    ),
                                  ),
                                  const Center(
                                    child: Text(
                                      'AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _metricCard(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: options.map((opt) {
                final isSel = selected == opt;
                return InkWell(
                  onTap: () => onSelected(opt),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF0D766E) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? const Color(0xFF0D766E) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : AppColors.textNavy,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
