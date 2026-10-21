import 'package:flutter/material.dart';
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

    // Available shifts from library
    final availableShifts = _service.shifts.isNotEmpty
        ? _service.shifts.map((s) => s.name).toSet().toList()
        : ['Full Day', 'Morning Shift', 'Evening Shift', 'Night Shift', '24 Hours'];
    String selectedShift = selectedStudent?.shift ?? (seat.shift.isNotEmpty ? seat.shift : availableShifts.first);
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

    // Payment collection dropdown
    int feePaidNow = 0;
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
                            const Text('Collect Fee Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
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
                                  value: feePaidNow,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(value: 0, child: Text('₹0 (No pay now)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                    DropdownMenuItem(value: selectedFeePlan, child: Text('₹$selectedFeePlan (Full)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => feePaidNow = val);
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
                          Navigator.pop(ctx);
                          await _service.assignSeatToExistingStudent(
                            newSeatNumber: seat.seatNumber,
                            studentId: selectedStudent!.id,
                            shift: selectedShift,
                            sectionName: selectedSection,
                            feePaidNow: feePaidNow,
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

                          Navigator.pop(ctx);
                          await _service.assignSeatAndRegisterStudent(
                            seatNumber: seat.seatNumber,
                            studentName: name,
                            phone: phone,
                            shift: selectedShift,
                            deviceUserId: _service.profile.adminName,
                            feeAmount: feePaidNow,
                            monthlyFee: selectedFeePlan,
                            duesAmount: (selectedFeePlan - feePaidNow).clamp(0, 999999),
                            paymentMode: paymentMode,
                            status: (feePaidNow >= selectedFeePlan && feePaidNow > 0) ? 'ACTIVE' : 'DUES',
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

  void _showChangeSeatDialog(SeatInfo currentSeat, List<SeatInfo> allSeats) {
    final vacantSeats = allSeats.where((s) => !s.isOccupied).toList();
    if (vacantSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other vacant seats available right now.')),
      );
      return;
    }
    int selectedNewSeat = vacantSeats.first.seatNumber;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Move ${currentSeat.studentName}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move from Seat S-${currentSeat.seatNumber} to an available seat:',
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
                    items: vacantSeats.map((vs) {
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
                  studentId: currentSeat.studentId,
                  shift: currentSeat.shift,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${currentSeat.studentName} moved to Seat S-$selectedNewSeat. Seat S-${currentSeat.seatNumber} is now vacant.'),
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

  void _showSeatOccupiedModal(SeatInfo seat, List<SeatInfo> allSeats) {
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
                          'Seat S-${seat.seatNumber} • ${seat.shift}',
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
            // View Member Profile (Image 2)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: const Text('View Member Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                onPressed: () {
                  Navigator.pop(ctx);
                  final student = _service.currentStudents.firstWhere(
                    (s) => (seat.studentId.isNotEmpty && s.id == seat.studentId) || s.seatNumber == seat.seatNumber,
                    orElse: () => _service.getStudentForSeat(seat.seatNumber) ?? StudentInfo(
                      id: seat.studentId.isNotEmpty ? seat.studentId : 'S-${seat.seatNumber}',
                      name: seat.studentName.isNotEmpty ? seat.studentName : 'Student S-${seat.seatNumber}',
                      phone: '',
                      seatNumber: seat.seatNumber,
                      shift: seat.shift,
                    ),
                  );
                  final idx = _service.currentStudents.indexWhere((s) => s.id == student.id);
                  final memberId = idx != -1 ? idx + 1 : seat.seatNumber;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberProfileScreen(student: student, memberId: memberId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
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
                            content: Text('Seat S-${seat.seatNumber} is now vacant and available.'),
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
                      _showChangeSeatDialog(seat, allSeats);
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
            // Apply search, shift, status, and dues filters
            final query = _searchCtrl.text.trim().toLowerCase();
            final filteredSeats = seats.where((seat) {
              if (query.isNotEmpty) {
                final matchNum = seat.seatNumber.toString().contains(query);
                final matchName = seat.studentName.toLowerCase().contains(query);
                if (!matchNum && !matchName) return false;
              }

              // Shift filter
              if (_selectedShift.toUpperCase() != 'ALL') {
                if (!seat.isOccupied) return false;
                final seatShift = seat.shift.trim().toUpperCase();
                final selShift = _selectedShift.trim().toUpperCase();
                if (seatShift != selShift &&
                    !seatShift.contains(selShift) &&
                    !selShift.contains(seatShift)) {
                  return false;
                }
              }

              // Status filter
              if (_selectedStatus == 'VACANT' && seat.isOccupied) return false;
              if (_selectedStatus == 'OCCUPIED' && !seat.isOccupied) return false;

              // Dues filter (PAID, UNPAID, TRIAL)
              if (_selectedDues != 'ALL') {
                if (!seat.isOccupied) return false;
                final student = students.firstWhere(
                  (s) => (seat.studentId.isNotEmpty && s.id == seat.studentId) || s.seatNumber == seat.seatNumber,
                  orElse: () => StudentInfo(id: '', name: seat.studentName, phone: ''),
                );
                final hasDues = student.hasDues || student.effectiveDues > 0 || student.duesAmount > 0 || student.status == 'DUES';
                final isTrial = student.status == 'TRIAL';

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

                          // OCCUPIED / ASSIGNED SEAT CARD
                          if (isOccupied) {
                            final student = students.firstWhere(
                              (s) => (seat.studentId.isNotEmpty && s.id == seat.studentId) || s.seatNumber == seat.seatNumber,
                              orElse: () => _service.getStudentForSeat(seat.seatNumber) ?? StudentInfo(
                                id: seat.studentId.isNotEmpty ? seat.studentId : 'S-${seat.seatNumber}',
                                name: seat.studentName.isNotEmpty ? seat.studentName : 'Student S-${seat.seatNumber}',
                                phone: '',
                                seatNumber: seat.seatNumber,
                                shift: seat.shift,
                              ),
                            );
                            final studentIdx = students.indexWhere((s) => s.id == student.id);
                            final memberId = studentIdx != -1 ? studentIdx + 1 : seat.seatNumber;
                            final hasDues = student.hasDues || student.effectiveDues > 0 || student.duesAmount > 0 || student.status == 'DUES';
                            final isTrial = student.status == 'TRIAL';

                            final initials = seat.studentName.trim().isNotEmpty
                                ? (seat.studentName.trim().split(' ').length > 1
                                    ? '${seat.studentName.trim().split(' ')[0][0]}${seat.studentName.trim().split(' ')[1][0]}'.toUpperCase()
                                    : (seat.studentName.trim().length >= 2 ? seat.studentName.trim().substring(0, 2).toUpperCase() : seat.studentName.trim().toUpperCase()))
                                : 'GS';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MemberProfileScreen(
                                      student: student,
                                      memberId: memberId,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () => _showSeatOccupiedModal(seat, seats),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: hasDues ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row: Status dot, Seat number, and dynamic Dues/Paid/Trial badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: isTrial
                                                    ? const Color(0xFF0284C7)
                                                    : (hasDues ? const Color(0xFFEF4444) : const Color(0xFF16A34A)),
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
                                        if (hasDues)
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

                                    // Circular Avatar with Gold/Yellow Border
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

                                    // Student Name & Shift Badge
                                    Column(
                                      children: [
                                        Text(
                                          seat.studentName.isNotEmpty ? seat.studentName.toUpperCase() : 'OCCUPIED',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
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
