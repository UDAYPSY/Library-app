import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../students/member_profile_screen.dart';

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
    bool isNewStudentMode = students.isEmpty;
    StudentInfo? selectedStudent = students.where((s) => s.seatNumber == null).isNotEmpty
        ? students.firstWhere((s) => s.seatNumber == null)
        : (students.isNotEmpty ? students.first : null);

    final newNameCtrl = TextEditingController();
    final newPhoneCtrl = TextEditingController();
    String? phoneError;

    // Available shifts from library - exclude shifts conflicting with current active occupants of this seat
    final seatOccupants = students.where((s) => s.seatNumber == seat.seatNumber && s.status != 'INACTIVE').toList();
    final allLibraryShifts = _service.shifts.isNotEmpty
        ? _service.shifts.map((s) => s.name).toSet().toList()
        : ['Full Day', 'Morning Shift', 'Evening Shift', 'Night Shift', '24 Hours'];
    final nonConflictingShifts = allLibraryShifts.where((sh) {
      return !seatOccupants.any((occ) => LibraryService.doShiftsConflict(occ.shift, sh, allShifts: _service.shifts));
    }).toList();
    final availableShifts = nonConflictingShifts.isNotEmpty ? nonConflictingShifts : allLibraryShifts;

    String selectedShift = selectedStudent?.shift ??
        (_selectedShift.toUpperCase() != 'ALL' && availableShifts.contains(_selectedShift)
            ? _selectedShift
            : (seat.shift.isNotEmpty && availableShifts.contains(seat.shift) ? seat.shift : availableShifts.first));
    if (!availableShifts.contains(selectedShift)) {
      selectedShift = availableShifts.first;
    }

    // Available sections
    final availableSections = _service.sections.isNotEmpty
        ? _service.sections.map((s) => s.name).toSet().toList()
        : ['Main Hall'];
    String selectedSection = seat.sectionName.isNotEmpty && availableSections.contains(seat.sectionName)
        ? seat.sectionName
        : availableSections.first;

    // Fee plans
    final feePlans = [300, 400, 500, 600, 700, 800, 1000, 1200];
    int selectedFeePlan = selectedStudent != null && feePlans.contains(selectedStudent.monthlyFee)
        ? selectedStudent.monthlyFee
        : 500;

    // Payment collection
    int feePaidNow = 0;
    final feePaidCtrl = TextEditingController(text: '0');
    String paymentMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          // Look up last payment for selected student
          final lastPayment = selectedStudent != null
              ? _service.getLastPaymentForStudent(
                  studentId: selectedStudent!.id,
                  phone: selectedStudent!.phone,
                  name: selectedStudent!.name,
                )
              : null;

          return Padding(
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Seat S-${seat.seatNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$selectedSection • Space Grid',
                            style: const TextStyle(
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
                  const SizedBox(height: 14),

                  // Mode Switcher: Enrolled Student vs Register New Student
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                isNewStudentMode = false;
                                if (selectedStudent != null) {
                                  selectedShift = selectedStudent!.shift;
                                  if (!availableShifts.contains(selectedShift)) {
                                    selectedShift = availableShifts.first;
                                  }
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isNewStudentMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isNewStudentMode
                                    ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Enrolled Student',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: !isNewStudentMode ? AppColors.textNavy : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isNewStudentMode = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isNewStudentMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isNewStudentMode
                                    ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '+ Register New',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isNewStudentMode ? AppColors.textNavy : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isNewStudentMode) ...[
                    // SELECT STUDENT DROPDOWN
                    const Text(
                      'Select Student',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                    ),
                    const SizedBox(height: 6),
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
                          value: selectedStudent,
                          isExpanded: true,
                          items: students.map((s) {
                            final seatTag = s.seatNumber != null ? 'Seat S-${s.seatNumber}' : 'No Seat';
                            final feeTag = s.hasDues ? 'Dues: ₹${s.effectiveDues}' : (s.status == 'TRIAL' ? 'Trial' : 'Paid');
                            return DropdownMenuItem<StudentInfo>(
                              value: s,
                              child: Text(
                                '${s.name} (${s.phone}) • $seatTag • $feeTag',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedStudent = val;
                                selectedShift = val.shift;
                                if (!availableShifts.contains(selectedShift)) {
                                  selectedShift = availableShifts.first;
                                }
                                selectedFeePlan = feePlans.contains(val.monthlyFee) ? val.monthlyFee : 500;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // AUTO-POPULATED STUDENT DETAILS & 1-SEAT ENFORCEMENT
                    if (selectedStudent != null) ...[
                      // Student Details Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEAB308), width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      selectedStudent!.name.isNotEmpty
                                          ? selectedStudent!.name.substring(0, 1).toUpperCase()
                                          : 'S',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedStudent!.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                                      ),
                                      Text(
                                        'Phone: ${selectedStudent!.phone}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: selectedStudent!.status == 'TRIAL'
                                        ? const Color(0xFFE0F2FE)
                                        : (selectedStudent!.hasDues ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    selectedStudent!.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: selectedStudent!.status == 'TRIAL'
                                          ? const Color(0xFF0284C7)
                                          : (selectedStudent!.hasDues ? const Color(0xFFE11D48) : const Color(0xFF16A34A)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // ONE STUDENT ONE SEAT NOTICE
                            if (selectedStudent!.seatNumber != null && selectedStudent!.seatNumber != seat.seatNumber)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Currently assigned to Seat S-${selectedStudent!.seatNumber}. Re-assigning to Seat S-${seat.seatNumber} will vacate Seat S-${selectedStudent!.seatNumber} (One student can only occupy 1 seat).',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (selectedStudent!.seatNumber == null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Student is unallocated. Seat will be allocated exclusively.',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FEE STATUS (PAID OR PENDING DUES AUTOMATICALLY DISPLAYED)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedStudent!.hasDues ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedStudent!.hasDues ? const Color(0xFFFECDD3) : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      selectedStudent!.hasDues
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_rounded,
                                      color: selectedStudent!.hasDues ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedStudent!.hasDues ? 'FEE PENDING / DUES' : 'FEE FULLY PAID',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: selectedStudent!.hasDues ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedStudent!.hasDues
                                      ? 'Due Date: ${selectedStudent!.feeDueDate != null ? DateFormat('dd MMM yyyy').format(selectedStudent!.feeDueDate!) : 'Immediate'} • Plan: ₹${selectedStudent!.monthlyFee}/mo'
                                      : 'Valid Until: ${selectedStudent!.feeDueDate != null ? DateFormat('dd MMM yyyy').format(selectedStudent!.feeDueDate!) : 'Active'} • Plan: ₹${selectedStudent!.monthlyFee}/mo',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              selectedStudent!.hasDues
                                  ? '₹${selectedStudent!.effectiveDues}'
                                  : '₹0 Due',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: selectedStudent!.hasDues ? const Color(0xFFE11D48) : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // LAST FEE PAID DETAILS (AUTOMATICALLY DISPLAYED)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.textNavy),
                                SizedBox(width: 6),
                                Text(
                                  'LAST FEE PAID DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: AppColors.textNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (lastPayment != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${lastPayment.amount}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0D766E),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6FFFA),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      lastPayment.paymentMode,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D766E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paid on ${DateFormat('dd MMM yyyy, hh:mm a').format(lastPayment.date)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                              if (lastPayment.notes.isNotEmpty)
                                Text(
                                  'Note: ${lastPayment.notes}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                            ] else ...[
                              const Text(
                                'No previous fee payment transactions on record for this student.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ] else ...[
                    // REGISTER NEW STUDENT FORM (WITH DUPLICATE VALIDATION)
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
                        controller: newNameCtrl,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Rahul Sharma',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Phone Number (No Duplicates Allowed)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: phoneError != null ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: newPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (val) {
                          if (_service.isDuplicateStudentPhone(val.trim())) {
                            final dup = _service.findStudentByPhone(val.trim());
                            setModalState(() => phoneError = 'Duplicate: Already enrolled as "${dup?.name}"');
                          } else {
                            setModalState(() => phoneError = null);
                          }
                        },
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 9876543210',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    if (phoneError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          phoneError!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],

                  // ALL OTHER DETAILS IN DROPDOWNS (Shift, Section, Plan, Mode, Collect)
                  const Text(
                    'ASSIGNMENT SETTINGS (DROPDOWNS)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),

                  // Shift & Section Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
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
                                  value: selectedShift,
                                  isExpanded: true,
                                  items: availableShifts
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedShift = val);
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
                            const Text('Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
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
                                  value: selectedSection,
                                  isExpanded: true,
                                  items: availableSections
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedSection = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Monthly Fee Plan & Payment Collection Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Fee Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedFeePlan,
                                  isExpanded: true,
                                  items: feePlans
                                      .map((fee) => DropdownMenuItem(value: fee, child: Text('₹$fee / mo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedFeePlan = val);
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
                            const Text('Collect Fee Now (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                            const SizedBox(height: 6),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: feePaidCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.currency_rupee, size: 16, color: Color(0xFF0D766E)),
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val.trim()) ?? 0;
                                  if (parsed > selectedFeePlan) {
                                    feePaidCtrl.text = '$selectedFeePlan';
                                    feePaidCtrl.selection = TextSelection.fromPosition(TextPosition(offset: feePaidCtrl.text.length));
                                  }
                                  setModalState(() {
                                    feePaidNow = (int.tryParse(feePaidCtrl.text.trim()) ?? 0).clamp(0, selectedFeePlan);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      feePaidNow = selectedFeePlan;
                                      feePaidCtrl.text = '$selectedFeePlan';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: feePaidNow == selectedFeePlan ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: feePaidNow == selectedFeePlan ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text('Full (₹$selectedFeePlan)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: feePaidNow == selectedFeePlan ? const Color(0xFF059669) : const Color(0xFF64748B))),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      feePaidNow = 0;
                                      feePaidCtrl.text = '0';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: feePaidNow == 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: feePaidNow == 0 ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text('₹0 Due', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: feePaidNow == 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
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
                            value: paymentMode,
                            isExpanded: true,
                            items: ['UPI', 'Cash', 'Card', 'Net Banking']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => paymentMode = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SUBMIT BUTTON
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
                        if (!isNewStudentMode) {
                          if (selectedStudent == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a student from the dropdown')),
                            );
                            return;
                          }
                          if (_service.isSeatOccupied(seat.seatNumber, shift: selectedShift, excludeStudentId: selectedStudent!.id)) {
                            final occ = _service.getStudentForSeat(seat.seatNumber, shift: selectedShift);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Seat S-${seat.seatNumber} is already occupied for "$selectedShift"${occ != null ? " by ${occ.name}" : ""}.'),
                                backgroundColor: const Color(0xFFE11D48),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final effectiveFeePaid = (int.tryParse(feePaidCtrl.text.trim()) ?? feePaidNow).clamp(0, selectedFeePlan);
                          Navigator.pop(ctx);
                          await _service.assignSeatToExistingStudent(
                            newSeatNumber: seat.seatNumber,
                            studentId: selectedStudent!.id,
                            shift: selectedShift,
                            sectionName: selectedSection,
                            feePaidNow: effectiveFeePaid,
                            paymentMode: paymentMode,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Seat S-${seat.seatNumber} successfully assigned to ${selectedStudent!.name}!'),
                                backgroundColor: const Color(0xFF0D766E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          final name = newNameCtrl.text.trim();
                          final phone = newPhoneCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter student name')),
                            );
                            return;
                          }
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter phone number')),
                            );
                            return;
                          }
                          if (phone.length != 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mobile number must be exactly 10 digits.'),
                                backgroundColor: Color(0xFFE11D48),
                              ),
                            );
                            return;
                          }
                          if (_service.isDuplicateStudentPhone(phone)) {
                            final dup = _service.findStudentByPhone(phone);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Duplicate: Student "${dup?.name}" already exists with this phone! No duplicate entry allowed.'),
                                backgroundColor: const Color(0xFFE11D48),
                              ),
                            );
                            return;
                          }
                          if (_service.isSeatOccupied(seat.seatNumber, shift: selectedShift)) {
                            final occ = _service.getStudentForSeat(seat.seatNumber, shift: selectedShift);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Seat S-${seat.seatNumber} is already occupied for "$selectedShift"${occ != null ? " by ${occ.name}" : ""}.'),
                                backgroundColor: const Color(0xFFE11D48),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final effectiveFeePaid = (int.tryParse(feePaidCtrl.text.trim()) ?? feePaidNow).clamp(0, selectedFeePlan);
                          final effectiveDues = (selectedFeePlan - effectiveFeePaid).clamp(0, 999999);
                          final effectiveStatus = (effectiveFeePaid == selectedFeePlan && effectiveFeePaid > 0) ? 'ACTIVE' : 'DUES';

                          Navigator.pop(ctx);
                          await _service.assignSeatAndRegisterStudent(
                            seatNumber: seat.seatNumber,
                            studentName: name,
                            phone: phone,
                            shift: selectedShift,
                            deviceUserId: _service.profile.adminName,
                            feeAmount: effectiveFeePaid,
                            monthlyFee: selectedFeePlan,
                            duesAmount: effectiveDues,
                            paymentMode: paymentMode,
                            status: effectiveStatus,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('New student $name registered & assigned to Seat S-${seat.seatNumber}!'),
                                backgroundColor: const Color(0xFF0D766E),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        !isNewStudentMode ? 'Confirm Seat S-${seat.seatNumber} Assignment' : 'Register & Assign Seat S-${seat.seatNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangeSeatDialog(SeatInfo currentSeat, List<SeatInfo> allSeats, {StudentInfo? targetStudent}) {
    final studentName = targetStudent?.name ?? (currentSeat.studentName.isNotEmpty ? currentSeat.studentName : 'Student');
    final studentId = targetStudent?.id ?? currentSeat.studentId;
    final studentShift = targetStudent?.shift ?? currentSeat.shift;

    final candidateSeats = allSeats.where((s) {
      if (s.seatNumber == currentSeat.seatNumber) return false;
      return _service.isSeatAvailableForShift(s.seatNumber, studentShift);
    }).toList();

    if (candidateSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No other seats available for $studentShift right now.')),
      );
      return;
    }
    int selectedNewSeat = candidateSeats.first.seatNumber;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Move $studentName', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move from Seat S-${currentSeat.seatNumber} to an available seat for $studentShift:',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedNewSeat,
                    isExpanded: true,
                    items: candidateSeats.map((vs) {
                      return DropdownMenuItem<int>(
                        value: vs.seatNumber,
                        child: Text('Seat S-${vs.seatNumber} (${vs.sectionName})', style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedNewSeat = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D766E),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dlgCtx);
                await _service.changeSeat(
                  fromSeatNumber: currentSeat.seatNumber,
                  toSeatNumber: selectedNewSeat,
                  studentId: studentId,
                  shift: studentShift,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$studentName moved to Seat S-$selectedNewSeat ($studentShift).'),
                      backgroundColor: const Color(0xFF0D766E),
                    ),
                  );
                }
              },
              child: const Text('Confirm Move'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeatOccupiedModal(SeatInfo seat, List<SeatInfo> allSeats, List<StudentInfo> allStudents) {
    // Find all active students on this seat
    final seatOccupants = allStudents.where((s) => s.seatNumber == seat.seatNumber && s.status != 'INACTIVE').toList();

    if (seatOccupants.isEmpty) {
      final fallback = _service.getStudentForSeat(seat.seatNumber) ?? StudentInfo(
        id: seat.studentId.isNotEmpty ? seat.studentId : 'S-${seat.seatNumber}',
        name: seat.studentName.isNotEmpty ? seat.studentName : 'Student S-${seat.seatNumber}',
        phone: '',
        seatNumber: seat.seatNumber,
        shift: seat.shift,
      );
      seatOccupants.add(fallback);
    }

    final allLibraryShifts = _service.shifts.isNotEmpty
        ? _service.shifts.map((s) => s.name).toSet().toList()
        : ['Morning Shift', 'Evening Shift', 'Night Shift', 'Full Day'];

    final bool hasFullDay = seatOccupants.any((s) {
      final sh = s.shift.toLowerCase();
      return sh.contains('full') || sh.contains('24');
    });

    final vacantShifts = hasFullDay
        ? <String>[]
        : allLibraryShifts.where((sh) {
            final shLow = sh.toLowerCase();
            if (shLow.contains('full') || shLow.contains('24')) return false;
            return !seatOccupants.any((occ) => LibraryService.doShiftsConflict(occ.shift, sh));
          }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalCtx).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chair_alt_rounded, color: Color(0xFF0284C7), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seat S-${seat.seatNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            seat.sectionName.isNotEmpty ? seat.sectionName : 'Main Hall',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: seatOccupants.length > 1 ? const Color(0xFFF3E8FF) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: seatOccupants.length > 1 ? const Color(0xFFD8B4FE) : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Text(
                          seatOccupants.length > 1
                              ? '${seatOccupants.length} Members'
                              : '1 Member',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: seatOccupants.length > 1 ? const Color(0xFF7E22CE) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textNavy),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'ASSIGNED MEMBERS ACROSS SHIFTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable list of occupant cards
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...seatOccupants.map((occ) {
                        final idx = allStudents.indexWhere((s) => s.id == occ.id);
                        final memberId = idx != -1 ? idx + 1 : seat.seatNumber;
                        final hasDues = occ.hasDues || occ.effectiveDues > 0;
                        final initials = occ.name.trim().isNotEmpty
                            ? (occ.name.trim().split(' ').length > 1
                                ? '${occ.name.trim().split(' ')[0][0]}${occ.name.trim().split(' ')[1][0]}'.toUpperCase()
                                : (occ.name.trim().length >= 2 ? occ.name.trim().substring(0, 2).toUpperCase() : occ.name.trim().toUpperCase()))
                            : 'M';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: hasDues ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar
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
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
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
                                          occ.name.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE0F2FE),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                occ.shift,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0369A1),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Member #$memberId',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Due / Paid badge
                                  if (hasDues)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFECDD3)),
                                      ),
                                      child: Text(
                                        'Due ₹${occ.effectiveDues}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFE11D48),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Text(
                                        'Paid',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (occ.phone.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      occ.phone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Primary action: View Member Profile
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D9488),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.person_rounded, size: 18),
                                  label: Text(
                                    'View Profile (${occ.name.split(' ').first})',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemberProfileScreen(
                                          student: occ,
                                          memberId: memberId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Sub-actions: Change seat & Vacate seat for this member
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0D766E),
                                        side: const BorderSide(color: Color(0xFF99F6E4)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.sync_alt_rounded, size: 16),
                                      label: const Text('Move Seat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showChangeSeatDialog(seat, allSeats, targetStudent: occ);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.cancel_outlined, size: 16),
                                      label: const Text('Vacate Shift', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await _service.vacateSeat(seat.seatNumber, occ.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${occ.name} vacated from Seat S-${seat.seatNumber} (${occ.shift}).'),
                                              backgroundColor: Colors.black87,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      // Vacant Shifts Section (if any shifts are available on this seat)
                      if (vacantShifts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Available Shifts on this Seat:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: vacantShifts.map((sh) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Text(
                                      '✓ $sh',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                                  label: const Text(
                                    'Assign Student to Remaining Shift',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showAssignSeatModal(seat, allStudents);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SeatInfo>>(
      stream: _service.streamSeats(),
      builder: (context, seatSnapshot) {
        final seats = seatSnapshot.data ?? [];
        final int occupiedCount;
        if (_selectedShift.toUpperCase() == 'ALL') {
          occupiedCount = seats.where((s) => s.isOccupied).length;
        } else {
          occupiedCount = seats.where((s) => _service.isSeatOccupied(s.seatNumber, shift: _selectedShift)).length;
        }
        final vacantCount = seats.length - occupiedCount;
        final totalSeats = seats.length;

        return StreamBuilder<List<StudentInfo>>(
          stream: _service.streamStudents(),
          builder: (context, studentSnapshot) {
            final students = studentSnapshot.data ?? [];
            final studentsCount = students.length;

            // Apply search filter
            // Apply search, shift, status, and dues filters
            final query = _searchCtrl.text.trim().toLowerCase();
            final filteredSeats = seats.where((seat) {
              final seatStudents = students.where((s) => s.seatNumber == seat.seatNumber && s.status != 'INACTIVE').toList();

              if (query.isNotEmpty) {
                final matchNum = seat.seatNumber.toString().contains(query);
                final matchName = seatStudents.any((s) => s.name.toLowerCase().contains(query)) ||
                    seat.studentName.toLowerCase().contains(query);
                if (!matchNum && !matchName) return false;
              }

              // Shift-wise occupancy check
              final bool isOccInView;
              final StudentInfo? studentInShift;
              if (_selectedShift.toUpperCase() == 'ALL') {
                isOccInView = seatStudents.isNotEmpty || seat.isOccupied;
                studentInShift = seatStudents.isNotEmpty ? seatStudents.first : null;
              } else {
                studentInShift = seatStudents.cast<StudentInfo?>().firstWhere(
                  (s) => s != null && LibraryService.doShiftsConflict(s.shift, _selectedShift),
                  orElse: () => null,
                );
                isOccInView = studentInShift != null;
              }

              // Status filter
              if (_selectedStatus == 'VACANT' && isOccInView) return false;
              if (_selectedStatus == 'OCCUPIED' && !isOccInView) return false;

              // Dues filter (PAID, UNPAID, TRIAL)
              if (_selectedDues != 'ALL') {
                if (!isOccInView || studentInShift == null) return false;
                final hasDues = studentInShift.hasDues || studentInShift.effectiveDues > 0 || studentInShift.duesAmount > 0 || studentInShift.status == 'DUES';
                final isTrial = studentInShift.status == 'TRIAL';

                if (_selectedDues == 'PAID') {
                  if (hasDues || isTrial) return false;
                } else if (_selectedDues == 'UNPAID') {
                  if (!hasDues) return false;
                } else if (_selectedDues == 'TRIAL') {
                  if (!isTrial) return false;
                }
              }

              return true;
            }).toList();

            return Scaffold(
              backgroundColor: AppColors.scaffold(context),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MANAGEMENT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.textMutedColor(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Space Grid',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text(context),
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
                                  color: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.cardBorderColor(context)),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.text(context), size: 20),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Layout is clean.')),
                                    );
                                  },
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
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorderColor(context)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Find student or seat...',
                            hintStyle: TextStyle(color: AppColors.textSubtleColor(context), fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMutedColor(context), size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
                          Expanded(child: _metricCard('$totalSeats', 'SEATS', AppColors.isDark(context) ? AppColors.darkTextPrimary : AppColors.textNavy)),
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
                            ['ALL', ..._service.shifts.map((s) => s.name.toUpperCase()).toSet()],
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
                        itemCount: filteredSeats.length,
                        itemBuilder: (ctx, idx) {
                          // Actual Seat Cards
                          final seat = filteredSeats[idx];
                          final seatStudents = students.where((s) => s.seatNumber == seat.seatNumber && s.status != 'INACTIVE').toList();
                          final bool isOccupied;
                          final StudentInfo student;

                          if (_selectedShift.toUpperCase() == 'ALL') {
                            isOccupied = seatStudents.isNotEmpty || seat.isOccupied;
                            student = seatStudents.isNotEmpty
                                ? seatStudents.first
                                : (_service.getStudentForSeat(seat.seatNumber) ?? StudentInfo(
                                    id: seat.studentId.isNotEmpty ? seat.studentId : 'S-${seat.seatNumber}',
                                    name: seat.studentName.isNotEmpty ? seat.studentName : 'Student S-${seat.seatNumber}',
                                    phone: '',
                                    seatNumber: seat.seatNumber,
                                    shift: seat.shift,
                                  ));
                          } else {
                            final shiftStudent = seatStudents.cast<StudentInfo?>().firstWhere(
                              (s) => s != null && LibraryService.doShiftsConflict(s.shift, _selectedShift),
                              orElse: () => null,
                            );
                            isOccupied = shiftStudent != null;
                            student = shiftStudent ?? StudentInfo(
                              id: 'S-${seat.seatNumber}',
                              name: 'Student S-${seat.seatNumber}',
                              phone: '',
                              seatNumber: seat.seatNumber,
                              shift: _selectedShift,
                            );
                          }

                          // OCCUPIED / ASSIGNED SEAT CARD
                          if (isOccupied) {
                            final isMultiOccupant = seatStudents.length > 1;
                            final anyDues = seatStudents.any((s) => s.hasDues || s.effectiveDues > 0);
                            final studentIdx = students.indexWhere((s) => s.id == student.id);
                            final memberId = studentIdx != -1 ? studentIdx + 1 : seat.seatNumber;
                            final hasDues = student.hasDues || student.effectiveDues > 0 || student.duesAmount > 0 || student.status == 'DUES';
                            final isTrial = student.status == 'TRIAL';

                            final String cardInitials;
                            if (isMultiOccupant) {
                              final firstInit = seatStudents[0].name.trim().isNotEmpty ? seatStudents[0].name.trim()[0].toUpperCase() : 'S';
                              final secondInit = seatStudents[1].name.trim().isNotEmpty ? seatStudents[1].name.trim()[0].toUpperCase() : 'S';
                              cardInitials = '$firstInit/$secondInit';
                            } else if (seat.studentName.trim().isNotEmpty) {
                              cardInitials = seat.studentName.trim().split(' ').length > 1
                                  ? '${seat.studentName.trim().split(' ')[0][0]}${seat.studentName.trim().split(' ')[1][0]}'.toUpperCase()
                                  : (seat.studentName.trim().length >= 2 ? seat.studentName.trim().substring(0, 2).toUpperCase() : seat.studentName.trim().toUpperCase());
                            } else {
                              cardInitials = 'GS';
                            }

                            final displayName = isMultiOccupant
                                ? seatStudents.map((s) => s.name.trim().split(' ').first).join(' & ')
                                : (seat.studentName.isNotEmpty ? seat.studentName.toUpperCase() : 'OCCUPIED');

                            final displayShift = isMultiOccupant
                                ? seatStudents.map((s) => s.shift.split(' ').first).join(' • ')
                                : seat.shift.toUpperCase();

                            return InkWell(
                              onTap: () => _showSeatOccupiedModal(seat, seats, students),
                              onLongPress: () => _showSeatOccupiedModal(seat, seats, students),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: (anyDues || hasDues)
                                        ? (AppColors.isDark(context) ? const Color(0xFF7F1D1D) : const Color(0xFFFECDD3))
                                        : (isMultiOccupant ? const Color(0xFFD8B4FE) : AppColors.cardBorderColor(context)),
                                    width: isMultiOccupant ? 1.5 : 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row: Status dot, Seat number, and dynamic Dues/Paid/Trial/Multi-shift badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: isMultiOccupant
                                                    ? const Color(0xFF8B5CF6)
                                                    : (isTrial
                                                        ? const Color(0xFF0284C7)
                                                        : (hasDues ? const Color(0xFFEF4444) : const Color(0xFF16A34A))),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${seat.seatNumber}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.text(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isMultiOccupant)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3E8FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFD8B4FE)),
                                            ),
                                            child: Text(
                                              '${seatStudents.length} SHIFTS',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF7E22CE),
                                              ),
                                            ),
                                          )
                                        else if (hasDues)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 13),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Due ₹${student.effectiveDues}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFE11D48),
                                                ),
                                              ),
                                            ],
                                          )
                                        else if (isTrial)
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.science_outlined, color: Color(0xFF0284C7), size: 13),
                                              SizedBox(width: 2),
                                              Text(
                                                'Trial',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0284C7),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 13),
                                              SizedBox(width: 2),
                                              Text(
                                                'Paid',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),

                                    // Circular Avatar with Gold/Purple Border
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isMultiOccupant ? const Color(0xFF7C3AED) : const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isMultiOccupant ? const Color(0xFFC084FC) : const Color(0xFFEAB308),
                                          width: 2.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          cardInitials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Student Name & Shift Badge
                                    Column(
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.text(context),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isMultiOccupant
                                                ? const Color(0xFFF3E8FF)
                                                : (AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFF0FDFA)),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isMultiOccupant
                                                  ? const Color(0xFFD8B4FE)
                                                  : (AppColors.isDark(context) ? const Color(0xFF0D9488) : const Color(0xFF99F6E4)),
                                            ),
                                          ),
                                          child: Text(
                                            displayShift,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isMultiOccupant
                                                  ? const Color(0xFF7E22CE)
                                                  : (AppColors.isDark(context) ? AppColors.mintAccent : const Color(0xFF0D9488)),
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
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.cardBorderColor(context)),
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.text(context),
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
                                        border: Border.all(color: AppColors.cardBorderColor(context), width: 1.5),
                                      ),
                                      child: Icon(Icons.add, color: AppColors.textMutedColor(context), size: 22),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'AVAILABLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: AppColors.textMutedColor(context),
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderColor(context)),
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
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textMutedColor(context),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 58,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textMutedColor(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: options.map((opt) {
                final isSel = selected.toUpperCase() == opt.toUpperCase();
                return InkWell(
                  onTap: () => onSelected(opt),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (AppColors.isDark(context) ? AppColors.mintAccent : const Color(0xFF0D766E))
                          : AppColors.card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? (AppColors.isDark(context) ? AppColors.mintAccent : const Color(0xFF0D766E))
                            : AppColors.cardBorderColor(context),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSel
                            ? (AppColors.isDark(context) ? const Color(0xFF0F172A) : Colors.white)
                            : AppColors.text(context),
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
