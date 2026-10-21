import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../shifts/shift_system_screen.dart';

class AddStudentWizardScreen extends StatefulWidget {
  const AddStudentWizardScreen({super.key});

  @override
  State<AddStudentWizardScreen> createState() => _AddStudentWizardScreenState();
}

class _AddStudentWizardScreenState extends State<AddStudentWizardScreen> {
  final LibraryService _service = LibraryService();
  int _currentStep = 0; // 0 = Basic Info, 1 = Schedule & Fees, 2 = Review

  // Step 1: Basic Info Controllers
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  final TextEditingController _fatherNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  String _gender = 'Male'; // Male or Female

  // Additional Details (Optional)
  final TextEditingController _preparationCtrl = TextEditingController();
  final TextEditingController _aadhaarCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  // Step 2: Schedule & Fees
  String _selectedSection = 'Main Hall';
  int? _selectedSeat; // null = unallocated
  late ShiftConfig _selectedShift;
  final TextEditingController _feeCtrl = TextEditingController();
  final TextEditingController _amountPaidCtrl = TextEditingController();
  bool _isTrial = false;

  // Step 3: Review Options
  bool _saveToContacts = true;

  @override
  void initState() {
    super.initState();
    final activeShifts = _service.shifts.where((s) => s.isActive).toList();
    if (activeShifts.isNotEmpty) {
      _selectedShift = activeShifts.first;
    } else if (_service.shifts.isNotEmpty) {
      _selectedShift = _service.shifts.first;
    } else {
      _selectedShift = ShiftConfig(
        id: 'shift_1',
        name: 'Full Day',
        startsAt: '06:00 AM',
        endsAt: '10:00 PM',
        monthlyFee: 500,
        isActive: true,
      );
    }
    _feeCtrl.text = '${_selectedShift.monthlyFee}';
    _amountPaidCtrl.text = '${_selectedShift.monthlyFee}';
    if (_service.sections.isNotEmpty) {
      _selectedSection = _service.sections.first.name;
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _fatherNameCtrl.dispose();
    _addressCtrl.dispose();
    _preparationCtrl.dispose();
    _aadhaarCtrl.dispose();
    _notesCtrl.dispose();
    _feeCtrl.dispose();
    _amountPaidCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.textNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  void _goToStep2() {
    if (_fullNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter member\'s full name')),
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _goToStep3() {
    final fee = int.tryParse(_feeCtrl.text.trim());
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly fee')),
      );
      return;
    }
    if (_amountPaidCtrl.text.trim().isEmpty) {
      _amountPaidCtrl.text = _feeCtrl.text.trim();
    }
    setState(() => _currentStep = 2);
  }

  Future<void> _finishAndSave() async {
    final name = _fullNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final seatNum = _selectedSeat;

    final shiftFee = _selectedShift.monthlyFee > 0 ? _selectedShift.monthlyFee : 500;
    final parsedMonthly = int.tryParse(_feeCtrl.text.trim()) ?? shiftFee;
    final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? parsedMonthly;

    int finalMonthlyFee;
    int finalPaidAmount;
    int finalDuesAmount;

    if (parsedMonthly == 0) {
      // User entered 000 or 0 in monthly fee: shift fee is standard, paid is 0, full shift fee is due!
      finalMonthlyFee = shiftFee;
      finalPaidAmount = 0;
      finalDuesAmount = shiftFee;
    } else if (parsedMonthly < shiftFee && parsedPaid == parsedMonthly) {
      // User entered a number less than standard shift fee 500 (e.g. 200 or 300)
      finalMonthlyFee = shiftFee;
      finalPaidAmount = parsedMonthly;
      finalDuesAmount = shiftFee - parsedMonthly;
    } else {
      finalMonthlyFee = parsedMonthly;
      finalPaidAmount = parsedPaid.clamp(0, parsedMonthly);
      finalDuesAmount = (parsedMonthly - finalPaidAmount).clamp(0, 999999);
    }

    final String finalStatus;
    if (_isTrial) {
      finalStatus = 'TRIAL';
    } else if (finalDuesAmount > 0 || finalPaidAmount == 0) {
      finalStatus = 'DUES';
    } else {
      finalStatus = 'ACTIVE';
    }

    await _service.assignSeatAndRegisterStudent(
      seatNumber: seatNum,
      studentName: name,
      phone: phone,
      shift: _selectedShift.name,
      deviceUserId: _service.profile.adminName,
      feeAmount: finalPaidAmount,
      monthlyFee: finalMonthlyFee,
      duesAmount: finalDuesAmount,
      paymentMode: 'UPI',
      status: finalStatus,
      joiningDate: _joiningDate,
      note: _notesCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTrial
              ? 'Trial Student $name registered successfully!'
              : (finalDuesAmount > 0
                  ? 'Student $name registered with ₹$finalDuesAmount pending due (categorized in DUES & REMAINING)!'
                  : 'Student $name added successfully (Fully Paid)!')),
          backgroundColor: _isTrial
              ? const Color(0xFFD97706)
              : (finalDuesAmount > 0 ? const Color(0xFFE11D48) : AppColors.successGreen),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close Button + Title (Images 2, 4, 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: AppColors.textNavy, size: 20),
                      ),
                    ),
                  ),
                  const Text(
                    'Add Student',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textNavy,
                    ),
                  ),
                ],
              ),
            ),

            // Step Indicator (Images 2, 4, 5)
            _buildStepIndicator(),

            // Content Area (Step 1, Step 2, or Step 3)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP INDICATOR HEADER (Images 2, 4, 5)
  // -------------------------------------------------------------
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stepItem(
                stepIndex: 0,
                label: 'Basic Info',
                isCompleted: _currentStep > 0,
                isActive: _currentStep == 0,
              ),
              _stepItem(
                stepIndex: 1,
                label: 'Schedule & Fees',
                isCompleted: _currentStep > 1,
                isActive: _currentStep == 1,
              ),
              _stepItem(
                stepIndex: 2,
                label: 'Review',
                isCompleted: false,
                isActive: _currentStep == 2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar line
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              double progress = 0.33;
              if (_currentStep == 1) progress = 0.66;
              if (_currentStep == 2) progress = 1.0;

              return Stack(
                children: [
                  Container(
                    height: 3,
                    width: totalWidth,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Container(
                    height: 3,
                    width: totalWidth * progress,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required int stepIndex,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    final circleColor = (isCompleted || isActive) ? AppColors.primaryTeal : const Color(0xFFF1F5F9);
    final textColor = (isCompleted || isActive) ? Colors.white : const Color(0xFF94A3B8);
    final labelColor = isActive ? AppColors.textNavy : const Color(0xFF64748B);

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CURRENT STEP CONTENT
  // -------------------------------------------------------------
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2ScheduleAndFees();
      case 2:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------------------
  // STEP 1: BASIC INFO (Images 2 & 3)
  // -------------------------------------------------------------
  Widget _buildStep1BasicInfo() {
    final dateStr = DateFormat('dd-MMM-yyyy').format(_joiningDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Form Card (Image 2)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Full Name', isRequired: true),
              const SizedBox(height: 6),
              _formTextField(
                controller: _fullNameCtrl,
                hintText: 'Enter member\'s full name',
              ),
              const SizedBox(height: 16),

              _fieldLabel('Phone Number', isRequired: true),
              const SizedBox(height: 6),
              _formTextField(
                controller: _phoneCtrl,
                hintText: '98765 43210',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Joining Date', isRequired: true),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickJoiningDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textNavy,
                        ),
                      ),
                      const Icon(Icons.calendar_month_outlined, color: Color(0xFF64748B), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _fieldLabel('Father Name (Optional)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _fatherNameCtrl,
                hintText: 'Enter father\'s name',
              ),
              const SizedBox(height: 16),

              _fieldLabel('Address (Optional)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _addressCtrl,
                hintText: 'Enter full address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Gender', isRequired: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _genderButton(
                      label: '♂ Male',
                      isSelected: _gender == 'Male',
                      onTap: () => setState(() => _gender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _genderButton(
                      label: '♀ Female',
                      isSelected: _gender == 'Female',
                      onTap: () => setState(() => _gender = 'Female'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section Title: Additional Details (Optional) (Image 3)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Additional Details (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textNavy,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Additional Details Card (Image 3)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Preparation For (Optional)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _preparationCtrl,
                hintText: 'Type or select exam...',
                prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(height: 16),

              _fieldLabel('Aadhaar Number (Optional)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _aadhaarCtrl,
                hintText: '12-digit UID',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _fieldLabel('Notes (Optional)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _notesCtrl,
                hintText: 'Any specific instructions or notes...',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: SCHEDULE & FEES (Image 4)
  // -------------------------------------------------------------
  Widget _buildStep2ScheduleAndFees() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Select Section', isRequired: false),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _service.sections.map((sec) {
                final isSelected = _selectedSection == sec.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedSection = sec.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        sec.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textNavy,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          _fieldLabel('Seat Allocation', isRequired: false),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedSeat,
                isExpanded: true,
                hint: const Text(
                  'Select item',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Unallocated', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ...List.generate(_service.totalSeatsCount, (i) => i + 1).map(
                    (s) => DropdownMenuItem<int?>(
                      value: s,
                      child: Text('Seat S-$s', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSeat = v),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Shift Selection Row with Manage Shifts link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fieldLabel('Shift Selection', isRequired: false),
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShiftSystemScreen()),
                  );
                  setState(() {
                    final found = _service.shifts.firstWhere(
                      (s) => s.id == _selectedShift.id || s.name == _selectedShift.name,
                      orElse: () => _service.shifts.isNotEmpty ? _service.shifts.first : _selectedShift,
                    );
                    _selectedShift = found;
                    _feeCtrl.text = '${found.monthlyFee}';
                    _amountPaidCtrl.text = '${found.monthlyFee}';
                  });
                },
                child: const Row(
                  children: [
                    Text(
                      'Manage Shifts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // All Shifts Horizontal List
          Builder(
            builder: (context) {
              final shiftsToDisplay = _service.shifts;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: shiftsToDisplay.map((sh) {
                    final isSelected = _selectedShift.id == sh.id ||
                        _selectedShift.name.toLowerCase() == sh.name.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _selectedShift = sh;
                            sh.isActive = true;
                            _feeCtrl.text = '${sh.monthlyFee}';
                            _amountPaidCtrl.text = '${sh.monthlyFee}';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 170,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryTeal : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x330D9488),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sh.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textNavy,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                color: isSelected ? Colors.white24 : const Color(0xFFF1F5F9),
                                height: 1,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${sh.startsAt} - ${sh.endsAt}',
                                style: TextStyle(
                                  color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${sh.monthlyFee}',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.primaryTeal,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Monthly Fees & Amount Paid Row with live dues computation
          Builder(
            builder: (context) {
              final shiftFee = _selectedShift.monthlyFee > 0 ? _selectedShift.monthlyFee : 500;
              final parsedFee = int.tryParse(_feeCtrl.text.trim()) ?? shiftFee;
              final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? parsedFee;

              int calcMonthly;
              int calcPaid;
              int calcDues;

              if (parsedFee == 0) {
                calcMonthly = shiftFee;
                calcPaid = 0;
                calcDues = shiftFee;
              } else if (parsedFee < shiftFee && parsedPaid == parsedFee) {
                calcMonthly = shiftFee;
                calcPaid = parsedFee;
                calcDues = shiftFee - parsedFee;
              } else {
                calcMonthly = parsedFee;
                calcPaid = parsedPaid.clamp(0, parsedFee);
                calcDues = (parsedFee - calcPaid).clamp(0, 999999);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Monthly Fees (₹)', isRequired: true),
                            const SizedBox(height: 8),
                            _formTextField(
                              controller: _feeCtrl,
                              hintText: '500',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final newFee = int.tryParse(val.trim());
                                setState(() {
                                  if (newFee != null && newFee > 0) {
                                    _amountPaidCtrl.text = '$newFee';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Amount Paid Now (₹)', isRequired: true),
                            const SizedBox(height: 8),
                            _formTextField(
                              controller: _amountPaidCtrl,
                              hintText: '500',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick chips
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _amountPaidCtrl.text = _feeCtrl.text.trim().isNotEmpty && _feeCtrl.text.trim() != '0'
                                ? _feeCtrl.text.trim()
                                : '$shiftFee';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: calcDues == 0 ? const Color(0xFFE6F4F1) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: calcDues == 0 ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            'Full Paid (₹$parsedFee)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: calcDues == 0 ? AppColors.primaryTeal : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _amountPaidCtrl.text = '0';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: calcPaid == 0 ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: calcPaid == 0 ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            'Unpaid / ₹0 Due',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: calcPaid == 0 ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dues Status Preview Banner
                  if (calcDues > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Due: ₹$calcDues',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Categorized in DUES and REMAINING tabs (Not in PAID)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFBE123C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fully Paid (₹$calcMonthly) • Categorized under PAID tab',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Trial Student Registration Option
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _isTrial ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isTrial ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isTrial ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: _isTrial ? const Color(0xFFD97706) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trial Student Registration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _isTrial ? const Color(0xFF92400E) : AppColors.textNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isTrial
                            ? 'Member registered as TRIAL with no immediate dues'
                            : 'Regular active member with standard fee cycle',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isTrial ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isTrial,
                  activeColor: const Color(0xFFD97706),
                  onChanged: (val) {
                    setState(() => _isTrial = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 3: REVIEW (Image 5)
  // -------------------------------------------------------------
  Widget _buildStep3Review() {
    final name = _fullNameCtrl.text.trim().isNotEmpty ? _fullNameCtrl.text.trim() : 'Student';
    final initials = name.split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();
    final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '9876543210';
    final dateStr = DateFormat('dd-MMM-yyyy').format(_joiningDate);
    final prep = _preparationCtrl.text.trim().isNotEmpty ? _preparationCtrl.text.trim() : 'General';
    final father = _fatherNameCtrl.text.trim().isNotEmpty ? _fatherNameCtrl.text.trim() : 'N/A';
    final address = _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : 'N/A';
    final notes = _notesCtrl.text.trim();

    final shiftFee = _selectedShift.monthlyFee > 0 ? _selectedShift.monthlyFee : 500;
    final parsedFee = int.tryParse(_feeCtrl.text.trim()) ?? shiftFee;
    final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? parsedFee;

    int reviewMonthly;
    int reviewPaid;
    int reviewDues;

    if (parsedFee == 0) {
      reviewMonthly = shiftFee;
      reviewPaid = 0;
      reviewDues = shiftFee;
    } else if (parsedFee < shiftFee && parsedPaid == parsedFee) {
      reviewMonthly = shiftFee;
      reviewPaid = parsedFee;
      reviewDues = shiftFee - parsedFee;
    } else {
      reviewMonthly = parsedFee;
      reviewPaid = parsedPaid.clamp(0, parsedFee);
      reviewDues = (parsedFee - reviewPaid).clamp(0, 999999);
    }

    return Column(
      children: [
        // Main Review Card (Image 5)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            children: [
              // Avatar Circle
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0284C7),
                ),
                child: Center(
                  child: Text(
                    initials.isNotEmpty ? initials : 'ST',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 18),

              // 2-Column Summary Grid (Image 5)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('JOINED', dateStr)),
                  Expanded(child: _reviewItem('GENDER', _gender)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _reviewItem(
                      'STATUS',
                      _isTrial
                          ? 'TRIAL STUDENT'
                          : (reviewDues > 0 ? 'FEE DUE (₹$reviewDues)' : 'ACTIVE (PAID)'),
                      valueColor: _isTrial
                          ? const Color(0xFFD97706)
                          : (reviewDues > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669)),
                    ),
                  ),
                  Expanded(child: _reviewItem('SHIFTS', _selectedShift.name)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('MONTHLY FEE', '₹$reviewMonthly')),
                  Expanded(
                    child: _reviewItem(
                      reviewDues > 0 ? 'DUE AMOUNT' : 'AMOUNT PAID',
                      reviewDues > 0 ? '₹$reviewDues DUE' : '₹$reviewPaid PAID',
                      valueColor: reviewDues > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _reviewItem(
                      'SEAT',
                      _selectedSeat != null ? 'Seat S-$_selectedSeat' : 'Unallocated',
                    ),
                  ),
                  Expanded(child: _reviewItem('PREPARING FOR', prep)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('FATHER', father)),
                  Expanded(child: _reviewItem('ADDRESS', address)),
                ],
              ),

              // Notes Box (Image 5)
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFEF3C7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description_rounded, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text(
                            'NOTES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notes,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Save to Phone Contacts Option (Image 5)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _saveToContacts,
                activeColor: AppColors.primaryTeal,
                onChanged: (v) => setState(() => _saveToContacts = v ?? false),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save to phone contacts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textNavy,
                      ),
                    ),
                    Text(
                      'Their name will show on incoming calls',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF64748B), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textNavy,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // BOTTOM BUTTONS BAR
  // -------------------------------------------------------------
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: _currentStep == 0
          ? SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _goToStep2,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _currentStep -= 1),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, color: AppColors.textNavy, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _currentStep == 1 ? _goToStep3 : _finishAndSave,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 1 ? 'Continue' : 'Finish & Save',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentStep == 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper Form Fields
  Widget _fieldLabel(String text, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textNavy,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _formTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textNavy),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: prefixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _genderButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.textNavy,
            ),
          ),
        ),
      ),
    );
  }
}
