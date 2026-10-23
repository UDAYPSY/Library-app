import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../shifts/shift_system_screen.dart';

class AddStudentWizardScreen extends StatefulWidget {
  final StudentInfo? studentToEdit;
  final int? initialSeatNumber;
  final String? initialSectionName;
  final String? initialShift;

  const AddStudentWizardScreen({
    super.key,
    this.studentToEdit,
    this.initialSeatNumber,
    this.initialSectionName,
    this.initialShift,
  });

  @override
  State<AddStudentWizardScreen> createState() => _AddStudentWizardScreenState();
}

class _AddStudentWizardScreenState extends State<AddStudentWizardScreen> {
  final LibraryService _service = LibraryService();
  int _currentStep = 0; // 0 = Basic Info, 1 = Schedule & Fees, 2 = Review

  bool get isEditing => widget.studentToEdit != null;

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
  int _selectedDurationMonths = 1; // 1, 2, 3, 5, 6, 12 months
  bool _isTrial = false;

  // Timeline & Payment Variables (unified with Record Payment modal)
  DateTime _fromDate = DateTime.now();
  DateTime _validUntilDate = DateTime.now().add(const Duration(days: 30));
  DateTime _paymentDate = DateTime.now();
  String _selectedPaymentMethod = 'UPI';

  int get _fixedMonthlyFee => _selectedShift.monthlyFee > 0 ? _selectedShift.monthlyFee : 500;
  int get _calculatedTotalFee => _fixedMonthlyFee * _selectedDurationMonths;

  int get _studentCurrentShiftMonthlyFee {
    if (widget.studentToEdit == null) return _fixedMonthlyFee;
    final s = widget.studentToEdit!;
    if (s.monthlyFee > 0) return s.monthlyFee;
    final match = _service.shifts.where((sh) => sh.name.toLowerCase() == s.shift.toLowerCase());
    if (match.isNotEmpty && match.first.monthlyFee > 0) {
      return match.first.monthlyFee;
    }
    return 500;
  }

  // Actual fee already paid by student for the current active membership cycle
  int get _currentCyclePaidAmount {
    if (widget.studentToEdit == null) return 0;
    final s = widget.studentToEdit!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDueActive = s.feeDueDate != null && !s.feeDueDate!.isBefore(today);
    if (!isDueActive && s.status != 'ACTIVE') return 0;

    final cycleStart = s.feeDueDate != null
        ? s.feeDueDate!.subtract(const Duration(days: 35))
        : (s.joinedAt ?? now.subtract(const Duration(days: 30)));

    final studentPayments = _service.currentPayments.where((p) {
      final matchesStudent = (s.id.isNotEmpty && p.studentId == s.id) ||
          (s.phone.isNotEmpty && LibraryService.normalizePhone(p.studentPhone) == LibraryService.normalizePhone(s.phone));
      if (!matchesStudent) return false;
      return !p.date.isBefore(cycleStart);
    }).toList();

    int totalPaidInCycle = 0;
    for (var p in studentPayments) {
      totalPaidInCycle += p.amount;
    }

    // Baseline fallback: if no transaction log exists, use student's monthly fee minus dues
    if (totalPaidInCycle == 0) {
      if (s.duesAmount == 0 && s.monthlyFee > 0) {
        totalPaidInCycle = s.monthlyFee;
      } else if (s.duesAmount > 0 && s.monthlyFee > 0) {
        totalPaidInCycle = (s.monthlyFee - s.duesAmount).clamp(0, s.monthlyFee);
      }
    }

    // If student is marked active with 0 dues, they paid at least s.monthlyFee
    if (s.duesAmount == 0 && s.monthlyFee > totalPaidInCycle) {
      totalPaidInCycle = s.monthlyFee;
    }

    // Check if student notes record an excess credit from a previous downgrade
    final matchCredit = RegExp(r'₹(\d+)\s+excess credit to adjust').firstMatch(s.note);
    if (matchCredit != null) {
      final credit = int.tryParse(matchCredit.group(1) ?? '0') ?? 0;
      if (credit > 0 && (s.monthlyFee + credit) > totalPaidInCycle) {
        totalPaidInCycle = s.monthlyFee + credit;
      }
    }

    return totalPaidInCycle;
  }

  bool get _isStudentInPaidActiveTenure {
    if (widget.studentToEdit == null) return false;
    final s = widget.studentToEdit!;
    if (s.status == 'INACTIVE' || s.status == 'TRIAL') return false;
    if (s.duesAmount > 0) return false;
    if (s.feeDueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(s.feeDueDate!.year, s.feeDueDate!.month, s.feeDueDate!.day);
      return !dueDay.isBefore(today);
    }
    return s.status == 'ACTIVE';
  }

  // Shift upgrade difference in ongoing cycle (₹0 if same/lower price, >0 if higher price)
  int get _shiftUpgradeDifference {
    if (widget.studentToEdit == null) return 0;
    final paid = _currentCyclePaidAmount;
    final diff = _fixedMonthlyFee - paid;
    return diff > 0 ? diff : 0;
  }

  // Excess credit when downgrading shift in ongoing cycle
  int get _shiftDowngradeExcessCredit {
    if (widget.studentToEdit == null) return 0;
    if (!_isStudentInPaidActiveTenure) return 0;
    final paid = _currentCyclePaidAmount;
    final diff = paid - _fixedMonthlyFee;
    return diff > 0 ? diff : 0;
  }

  // Fixed / Non-editable Already Paid for existing students
  int get _alreadyPaidAmount {
    if (widget.studentToEdit == null) return 0;
    return _currentCyclePaidAmount;
  }

  // Auto-calculated Due Amount
  int get _dueAmount {
    if (widget.studentToEdit == null) return _calculatedTotalFee;
    final s = widget.studentToEdit!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDueActive = s.feeDueDate != null && !s.feeDueDate!.isBefore(today);

    if (_isStudentInPaidActiveTenure) {
      final upgradeDiff = _shiftUpgradeDifference;
      if (_selectedDurationMonths == 1) {
        return upgradeDiff;
      } else {
        final advanceMonths = _selectedDurationMonths - 1;
        return upgradeDiff + (_fixedMonthlyFee * advanceMonths);
      }
    }

    if (s.duesAmount > 0 && isDueActive) {
      final paid = _currentCyclePaidAmount;
      final currentCycleCost = _fixedMonthlyFee;
      final upgradeDiff = (currentCycleCost - (paid + s.duesAmount)) > 0
          ? (currentCycleCost - (paid + s.duesAmount))
          : 0;
      if (_selectedDurationMonths == 1) {
        return s.duesAmount + upgradeDiff;
      } else {
        final advanceMonths = _selectedDurationMonths - 1;
        return s.duesAmount + upgradeDiff + (_fixedMonthlyFee * advanceMonths);
      }
    }

    return _calculatedTotalFee;
  }

  void _updateDuration(int months) {
    setState(() {
      _selectedDurationMonths = months;
      if (widget.studentToEdit != null) {
        final s = widget.studentToEdit!;
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final isDueActive = s.feeDueDate != null && !s.feeDueDate!.isBefore(today);

        if (isDueActive) {
          if (months == 1) {
            _validUntilDate = s.feeDueDate!;
          } else {
            final base = s.feeDueDate!;
            _validUntilDate = DateTime(base.year, base.month + (months - 1), base.day);
          }
        } else {
          _validUntilDate = DateTime(_fromDate.year, _fromDate.month + months, _fromDate.day);
        }
        final due = _dueAmount;
        if (due == 0) {
          _amountPaidCtrl.text = '0';
        } else {
          final current = int.tryParse(_amountPaidCtrl.text.trim());
          if (current == null || current > due) {
            _amountPaidCtrl.text = '0';
          }
        }
      } else {
        _validUntilDate = DateTime(_fromDate.year, _fromDate.month + months, _fromDate.day);
        _amountPaidCtrl.text = '$_calculatedTotalFee';
      }
    });
  }

  // Step 3: Review Options
  bool _saveToContacts = true;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paymentDate = now;

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
    _feeCtrl.text = '$_fixedMonthlyFee';
    _amountPaidCtrl.text = '$_calculatedTotalFee';
    if (_service.sections.isNotEmpty) {
      _selectedSection = _service.sections.first.name;
    }

    if (widget.studentToEdit != null) {
      final s = widget.studentToEdit!;
      _fullNameCtrl.text = s.name;
      _phoneCtrl.text = s.phone;
      if (s.joinedAt != null) _joiningDate = s.joinedAt!;
      _fatherNameCtrl.text = s.fatherName;
      _addressCtrl.text = s.address;
      _aadhaarCtrl.text = s.aadhaarNumber;
      _preparationCtrl.text = s.preparationFor;
      _notesCtrl.text = s.note;
      if (s.gender.isNotEmpty) _gender = s.gender;
      _selectedSection = s.sectionName;
      _selectedSeat = s.seatNumber;
      _photoBase64 = s.photoBase64;
      _isTrial = s.status == 'TRIAL';
      if (s.paymentMode.isNotEmpty) _selectedPaymentMethod = s.paymentMode;

      final shiftMatch = _service.shifts.where((sh) => sh.name.toLowerCase() == s.shift.toLowerCase());
      if (shiftMatch.isNotEmpty) {
        _selectedShift = shiftMatch.first;
      }
      _feeCtrl.text = '$_fixedMonthlyFee';

      final today = DateTime(now.year, now.month, now.day);
      final hasPendingCurrentDue = s.duesAmount > 0 &&
          s.feeDueDate != null &&
          !s.feeDueDate!.isBefore(today);
      final isExpired = s.feeDueDate == null || s.feeDueDate!.isBefore(today);

      if (hasPendingCurrentDue) {
        _fromDate = s.joinedAt ?? s.feeDueDate!.subtract(const Duration(days: 30));
        _validUntilDate = s.feeDueDate!;
      } else if (isExpired) {
        _fromDate = now;
        _validUntilDate = DateTime(_fromDate.year, _fromDate.month + _selectedDurationMonths, _fromDate.day);
      } else {
        _fromDate = s.joinedAt ?? s.feeDueDate!.subtract(const Duration(days: 30));
        _validUntilDate = s.feeDueDate!;
      }

      final initialDue = _dueAmount;
      _amountPaidCtrl.text = '0';
    } else {
      if (widget.initialSeatNumber != null) {
        _selectedSeat = widget.initialSeatNumber;
      }
      if (widget.initialSectionName != null && widget.initialSectionName!.isNotEmpty) {
        _selectedSection = widget.initialSectionName!;
      }
      if (widget.initialShift != null && widget.initialShift!.isNotEmpty) {
        final shiftMatch = _service.shifts.where((sh) => sh.name.toLowerCase() == widget.initialShift!.toLowerCase());
        if (shiftMatch.isNotEmpty) {
          _selectedShift = shiftMatch.first;
        }
      }
      _fromDate = _joiningDate;
      _validUntilDate = DateTime(_fromDate.year, _fromDate.month + _selectedDurationMonths, _fromDate.day);
      _feeCtrl.text = '$_fixedMonthlyFee';
      _amountPaidCtrl.text = '$_calculatedTotalFee';
    }
  }

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Member Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF0D9488)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _photoBase64 = base64Encode(bytes);
                      });
                    }
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF16A34A)),
                ),
                title: const Text('Take a Photo (Camera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 80);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _photoBase64 = base64Encode(bytes);
                      });
                    }
                  } catch (_) {}
                },
              ),
              if (_photoBase64 != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _photoBase64 = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWelcomeWhatsApp(String name, String phone, int? seatNum, String shift) async {
    final cleanPhone = LibraryService.normalizePhone(phone);
    final msg = _service.profile.welcomeTemplate
        .replaceAll('{student_name}', name)
        .replaceAll('{library_name}', _service.profile.libraryName)
        .replaceAll('{seat_number}', seatNum != null ? '$seatNum' : 'Unallocated')
        .replaceAll('{shift}', shift);
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
      setState(() {
        _joiningDate = picked;
        if (widget.studentToEdit == null) {
          _fromDate = _joiningDate;
          _validUntilDate = DateTime(_fromDate.year, _fromDate.month + _selectedDurationMonths, _fromDate.day);
        }
      });
    }
  }

  void _goToStep2() {
    if (_fullNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter member\'s full name')),
      );
      return;
    }
    final phone = _phoneCtrl.text.trim();
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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final aadhaar = _aadhaarCtrl.text.trim();
    if (aadhaar.isNotEmpty && aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar number (UID) must be exactly 12 digits.'),
          backgroundColor: Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_service.isDuplicateStudentPhone(phone, excludeStudentId: widget.studentToEdit?.id)) {
      final existing = _service.findStudentByPhone(phone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicate Entry: Student "${existing?.name ?? "Enrolled"}" is already registered with phone $phone. No duplicate student entry can be done!'),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _goToStep3() {
    if (_selectedSeat != null) {
      final isCurrent = widget.studentToEdit != null &&
          widget.studentToEdit!.seatNumber == _selectedSeat &&
          widget.studentToEdit!.shift.toLowerCase() == _selectedShift.name.toLowerCase();
      if (!isCurrent && _service.isSeatOccupied(_selectedSeat!, shift: _selectedShift.name, excludeStudentId: widget.studentToEdit?.id)) {
        final occ = _service.getStudentForSeat(_selectedSeat!, shift: _selectedShift.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seat S-$_selectedSeat is already occupied for ${_selectedShift.name}${occ != null ? " by ${occ.name}" : ""}. It cannot be assigned to another member.'),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Overlap prevention: If student is active with 0 dues and shift NOT changed, advance period cannot overlap!
    if (widget.studentToEdit != null) {
      final s = widget.studentToEdit!;
      final isShiftChanged = s.shift.toLowerCase() != _selectedShift.name.toLowerCase();
      if (_isStudentInPaidActiveTenure && !isShiftChanged && _selectedDurationMonths > 1 && _fromDate.isBefore(s.feeDueDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Overlapping period not allowed! Student membership is already paid until ${DateFormat('dd-MMM-yyyy').format(s.feeDueDate!)}. Only advance payments starting from ${DateFormat('dd-MMM-yyyy').format(s.feeDueDate!)} are allowed.'),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    _feeCtrl.text = '$_fixedMonthlyFee';
    final maxPayable = widget.studentToEdit != null ? _dueAmount : _calculatedTotalFee;
    final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? (widget.studentToEdit != null ? 0 : maxPayable);
    _amountPaidCtrl.text = '${parsedPaid.clamp(0, maxPayable)}';
    setState(() => _currentStep = 2);
  }

  Future<void> _finishAndSave() async {
    final name = _fullNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final seatNum = _selectedSeat;

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number must be exactly 10 digits.'),
          backgroundColor: Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final aadhaar = _aadhaarCtrl.text.trim();
    if (aadhaar.isNotEmpty && aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar number (UID) must be exactly 12 digits.'),
          backgroundColor: Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (seatNum != null) {
      final isCurrent = widget.studentToEdit != null &&
          widget.studentToEdit!.seatNumber == seatNum &&
          widget.studentToEdit!.shift.toLowerCase() == _selectedShift.name.toLowerCase();
      if (!isCurrent && _service.isSeatOccupied(seatNum, shift: _selectedShift.name, excludeStudentId: widget.studentToEdit?.id)) {
        final occ = _service.getStudentForSeat(seatNum, shift: _selectedShift.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seat S-$seatNum is already occupied for ${_selectedShift.name}${occ != null ? " by ${occ.name}" : ""}. It cannot be assigned to another member.'),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_service.isDuplicateStudentPhone(phone, excludeStudentId: widget.studentToEdit?.id)) {
      final existing = _service.findStudentByPhone(phone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicate Entry: Student "${existing?.name ?? "Enrolled"}" already exists with phone $phone!'),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fixedMonthly = _fixedMonthlyFee;
    final totalCalculatedFee = _calculatedTotalFee;
    final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? totalCalculatedFee;
    final finalPaidAmount = parsedPaid.clamp(0, totalCalculatedFee);
    final finalDuesAmount = (totalCalculatedFee - finalPaidAmount).clamp(0, 999999);

    final String finalStatus;
    if (_isTrial) {
      finalStatus = 'TRIAL';
    } else if (finalPaidAmount == totalCalculatedFee && finalPaidAmount > 0) {
      finalStatus = 'ACTIVE';
    } else {
      finalStatus = 'DUES';
    }

    try {
      if (widget.studentToEdit != null) {
        final s = widget.studentToEdit!;
        final oldShift = s.shift;
        final isShiftChanged = oldShift.toLowerCase() != _selectedShift.name.toLowerCase();
        final oldMonthly = _studentCurrentShiftMonthlyFee;

        // Overlap prevention: Only if student is active, shift NOT changed, and advance months selected
        if (_isStudentInPaidActiveTenure && !isShiftChanged && _selectedDurationMonths > 1 && _fromDate.isBefore(s.feeDueDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Overlapping period not allowed! Student membership is already paid until ${DateFormat('dd-MMM-yyyy').format(s.feeDueDate!)}. Only advance payments are allowed.'),
              backgroundColor: const Color(0xFFE11D48),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final dueAmount = _dueAmount;
        final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? 0;
        final collectedNow = parsedPaid.clamp(0, dueAmount);
        final editDuesAmount = (dueAmount - collectedNow).clamp(0, 999999);

        final String editStatus;
        if (_isTrial) {
          editStatus = 'TRIAL';
        } else if (editDuesAmount == 0) {
          editStatus = 'ACTIVE';
        } else {
          editStatus = 'DUES';
        }

        // Record shift change in notes if shift changed
        String shiftLog = '';
        if (isShiftChanged) {
          final excess = _shiftDowngradeExcessCredit;
          if (excess > 0) {
            shiftLog = 'Shift changed: $oldShift → ${_selectedShift.name} (₹$fixedMonthly/mo). ₹$excess excess credit to adjust in next month.';
          } else {
            shiftLog = 'Shift changed: $oldShift (₹$oldMonthly/mo) → ${_selectedShift.name} (₹$fixedMonthly/mo) on ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}';
          }
        }

        String finalNotes = _notesCtrl.text.trim();
        if (isShiftChanged) {
          if (finalNotes.isEmpty) {
            finalNotes = shiftLog;
          } else if (!finalNotes.contains(shiftLog)) {
            finalNotes = '$finalNotes\n• $shiftLog';
          }
        }

        // CRITICAL SYNC: Record payment in financial ledger & transaction stream
        if (collectedNow > 0) {
          final paymentNotes = isShiftChanged
              ? 'Shift upgrade: $oldShift → ${_selectedShift.name} • ₹$collectedNow collected'
              : 'Payment collected via Edit Student Details ($_selectedDurationMonths mo)';
          await _service.recordPayment(
            studentId: s.id,
            studentName: name,
            phone: phone,
            seatNumber: seatNum,
            shift: _selectedShift.name,
            amount: collectedNow,
            date: _paymentDate,
            paymentMode: _selectedPaymentMethod,
            notes: paymentNotes,
          );
        }

        await _service.updateStudent(
          studentId: s.id,
          name: name,
          phone: phone,
          shift: _selectedShift.name,
          seatNumber: seatNum,
          note: finalNotes,
          monthlyFee: fixedMonthly,
          duesAmount: editDuesAmount,
          status: editStatus,
          feeDueDate: _validUntilDate,
          fatherName: _fatherNameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          aadhaarNumber: _aadhaarCtrl.text.trim(),
          preparationFor: _preparationCtrl.text.trim(),
          gender: _gender,
          sectionName: _selectedSection,
          photoBase64: _photoBase64,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isShiftChanged
                  ? 'Shift updated to ${_selectedShift.name}${collectedNow > 0 ? " & payment of ₹$collectedNow recorded" : ""}!'
                  : (collectedNow > 0
                      ? 'Student $name updated & payment of ₹$collectedNow recorded!'
                      : 'Student $name profile updated successfully!')),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      await _service.assignSeatAndRegisterStudent(
        seatNumber: seatNum,
        studentName: name,
        phone: phone,
        shift: _selectedShift.name,
        deviceUserId: _service.profile.adminName,
        feeAmount: finalPaidAmount,
        monthlyFee: fixedMonthly,
        duesAmount: finalDuesAmount,
        durationMonths: _selectedDurationMonths,
        paymentMode: _selectedPaymentMethod,
        status: finalStatus,
        joiningDate: _joiningDate,
        validUntil: _validUntilDate,
        paymentDate: _paymentDate,
        note: _notesCtrl.text.trim(),
        fatherName: _fatherNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        aadhaarNumber: _aadhaarCtrl.text.trim(),
        preparationFor: _preparationCtrl.text.trim(),
        gender: _gender,
        photoBase64: _photoBase64,
      );

      if (mounted) {
        if (!_isTrial && _service.profile.autoWelcomeMessage) {
          _sendWelcomeWhatsApp(name, phone, seatNum, _selectedShift.name);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isTrial
                ? 'Trial Student $name registered successfully!'
                : (finalDuesAmount > 0
                    ? 'Student $name registered with ₹$finalDuesAmount pending due!'
                    : 'Student $name added successfully (Fully Paid)!')),
            backgroundColor: _isTrial
                ? const Color(0xFFD97706)
                : (finalDuesAmount > 0 ? const Color(0xFFE11D48) : AppColors.successGreen),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                  Text(
                    isEditing ? 'Edit Student' : 'Add Student',
                    style: const TextStyle(
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
        // Circular Dashed "Add Photo" Picker (Real ImagePicker)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(60),
              onTap: _pickPhoto,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF0D9488),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: _photoBase64 != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_photoBase64!),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 36, color: Color(0xFF0D9488)),
                          SizedBox(height: 6),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

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
                hintText: '9876543210 (10 digits)',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
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

              _fieldLabel('Aadhaar Number (12-Digit UID)', isRequired: false),
              const SizedBox(height: 6),
              _formTextField(
                controller: _aadhaarCtrl,
                hintText: '12-digit UID',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
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

  Widget _durationChip({required String label, required int months}) {
    final isSelected = _selectedDurationMonths == months;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _updateDuration(months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.textNavy,
          ),
        ),
      ),
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
                    child: Text('Unallocated (No Seat)', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ...List.generate(_service.totalSeatsCount, (i) => i + 1).map(
                    (s) {
                      final isCurrent = widget.studentToEdit != null && widget.studentToEdit!.seatNumber == s;
                      final isOcc = _service.isSeatOccupied(s, shift: _selectedShift.name, excludeStudentId: widget.studentToEdit?.id) && !isCurrent;
                      final occStudent = isOcc ? _service.getStudentForSeat(s, shift: _selectedShift.name) : null;
                      return DropdownMenuItem<int?>(
                        value: s,
                        enabled: !isOcc,
                        child: Row(
                          children: [
                            Text(
                              'Seat S-$s',
                              style: TextStyle(
                                fontWeight: isOcc ? FontWeight.w500 : FontWeight.w700,
                                color: isOcc ? const Color(0xFF94A3B8) : (isCurrent ? const Color(0xFF0D9488) : AppColors.textNavy),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                                ),
                              )
                            else if (isOcc)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Occupied${occStudent != null ? " • ${occStudent.name}" : ""}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Available',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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
                            _feeCtrl.text = '$_fixedMonthlyFee';
                            _updateDuration(_selectedDurationMonths);
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

          // Seat conflict warning if seat is occupied in newly selected shift
          Builder(
            builder: (context) {
              if (_selectedSeat == null) return const SizedBox.shrink();
              final isOcc = _service.isSeatOccupied(
                _selectedSeat!,
                shift: _selectedShift.name,
                excludeStudentId: widget.studentToEdit?.id,
              );
              final occStudent = isOcc ? _service.getStudentForSeat(_selectedSeat!, shift: _selectedShift.name) : null;
              if (occStudent != null && occStudent.id != widget.studentToEdit?.id) {
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seat S-$_selectedSeat is occupied in "${_selectedShift.name}" by ${occStudent.name}. Please select an available seat in the Seat Allocation dropdown above.',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 18),

          // Month Selection (Payment Duration / Advance Period)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fieldLabel('Month Selection', isRequired: false),
              if (_selectedDurationMonths > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_selectedDurationMonths Months Advance',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final s = widget.studentToEdit;
              final isShiftChanged = s != null && _selectedShift.name.toLowerCase() != s.shift.toLowerCase();
              final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              final hasPendingCurrentDue = s != null &&
                  s.duesAmount > 0 &&
                  s.feeDueDate != null &&
                  !s.feeDueDate!.isBefore(today);

              String firstChipLabel = '1 Month';
              if (hasPendingCurrentDue) {
                firstChipLabel = 'Clear Due (₹${s.duesAmount})';
              } else if (_isStudentInPaidActiveTenure && isShiftChanged) {
                final diff = _shiftUpgradeDifference;
                firstChipLabel = diff > 0 ? 'Shift Upgrade (₹$diff)' : 'Shift Change (₹0 Due)';
              } else if (_isStudentInPaidActiveTenure) {
                firstChipLabel = 'Current Plan (₹0 Due)';
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _durationChip(
                      label: firstChipLabel,
                      months: 1,
                    ),
                    const SizedBox(width: 8),
                    _durationChip(
                      label: (hasPendingCurrentDue || (_isStudentInPaidActiveTenure && isShiftChanged)) ? '2 Mo (+1 Adv)' : '2 Months',
                      months: 2,
                    ),
                    const SizedBox(width: 8),
                    _durationChip(
                      label: (hasPendingCurrentDue || (_isStudentInPaidActiveTenure && isShiftChanged)) ? '3 Mo (+2 Adv)' : '3 Months',
                      months: 3,
                    ),
                    const SizedBox(width: 8),
                    _durationChip(label: '5 Months ⭐', months: 5),
                    const SizedBox(width: 8),
                    _durationChip(label: '6 Months', months: 6),
                    const SizedBox(width: 8),
                    _durationChip(label: '1 Year (12M)', months: 12),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Monthly Fee (Fixed) & Total Fee (Calculated) Row
          Row(
            children: [
              // Monthly Fee (Fixed, Non-editable)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _fieldLabel('Monthly Fee', isRequired: false),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 10, color: Color(0xFF64748B)),
                              SizedBox(width: 2),
                              Text(
                                'Fixed',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹$_fixedMonthlyFee / mo',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Total Fee (Calculated)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Total Fee (₹)', isRequired: true),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹$_calculatedTotalFee',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D766E),
                            ),
                          ),
                          Text(
                            '($_selectedDurationMonths mo)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // For existing students: Show Fixed / Non-editable Already Paid card (Requirement 4)
          if (widget.studentToEdit != null) ...[
            Row(
              children: [
                _fieldLabel('Already Paid (₹)', isRequired: false),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'FIXED / LOCKED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹$_alreadyPaidAmount',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  const Text('Non-editable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Amount Paid Now (Capped at due amount for editing, or total fee for new)
          Builder(
            builder: (context) {
              final isEdit = widget.studentToEdit != null;
              final totalFee = _calculatedTotalFee;
              final maxPayable = isEdit ? _dueAmount : totalFee;
              final parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? (isEdit ? 0 : maxPayable);
              final currentPaid = parsedPaid.clamp(0, maxPayable);
              final remainingDues = (maxPayable - currentPaid).clamp(0, 999999);

              final bool isFullyPaid = currentPaid == maxPayable && maxPayable > 0;
              final bool isPartiallyPaid = currentPaid > 0 && currentPaid < maxPayable;
              final bool isUnpaid = currentPaid == 0;
              final bool isShiftChanged = widget.studentToEdit != null &&
                  _selectedShift.name.toLowerCase() != widget.studentToEdit!.shift.toLowerCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _fieldLabel(widget.studentToEdit != null ? 'Due Amount to Accept (₹)' : 'Amount Paid Now (₹)', isRequired: true),
                      // Auto-determined payment status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isFullyPaid
                              ? const Color(0xFFDCFCE7)
                              : (isPartiallyPaid ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFullyPaid
                                ? const Color(0xFF86EFAC)
                                : (isPartiallyPaid ? const Color(0xFFFDE68A) : const Color(0xFFFECDD3)),
                          ),
                        ),
                        child: Text(
                          isFullyPaid
                              ? '✓ Fully Paid'
                              : (isPartiallyPaid ? 'Partially Paid' : (maxPayable == 0 ? '✓ No Dues' : 'Unpaid')),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isFullyPaid
                                ? const Color(0xFF15803D)
                                : (isPartiallyPaid ? const Color(0xFFB45309) : (maxPayable == 0 ? const Color(0xFF15803D) : const Color(0xFFDC2626))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _formTextField(
                    controller: _amountPaidCtrl,
                    hintText: 'Enter amount to collect (max ₹$maxPayable)',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final p = int.tryParse(val.trim());
                      if (p != null && p > maxPayable) {
                        _amountPaidCtrl.text = '$maxPayable';
                        _amountPaidCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _amountPaidCtrl.text.length));
                      }
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quick action chips
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            _amountPaidCtrl.text = '$maxPayable';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFullyPaid ? const Color(0xFFE6F4F1) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFullyPaid ? AppColors.primaryTeal : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            widget.studentToEdit != null ? (isShiftChanged ? 'Pay Upgrade (₹$maxPayable)' : 'Accept Due (₹$maxPayable)') : 'Full Paid (₹$totalFee)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isFullyPaid ? AppColors.primaryTeal : const Color(0xFF475569),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUnpaid ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isUnpaid ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            widget.studentToEdit != null ? 'Leave as Due (₹0 Paid)' : 'Unpaid / ₹0 Paid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isUnpaid ? const Color(0xFFE11D48) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Calculated Payment Status & Remaining Balance Banner
                  if (remainingDues > 0)
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
                                  isUnpaid
                                      ? 'Payment Status: Unpaid • Due: ₹$remainingDues'
                                      : 'Payment Status: Partially Paid • Remaining Due: ₹$remainingDues',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isEdit
                                      ? 'Paid ₹$currentPaid now of ₹$maxPayable due (Remaining Due: ₹$remainingDues • ₹$_alreadyPaidAmount already paid for current cycle)'
                                      : 'Paid ₹$currentPaid of ₹$totalFee total fee ($totalFee - $currentPaid = ₹$remainingDues remaining)',
                                  style: const TextStyle(
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
                              isEdit
                                  ? 'Payment Status: Fully Paid (₹$currentPaid Paid now • ₹$_alreadyPaidAmount already paid) • Active'
                                  : 'Payment Status: Fully Paid (₹$currentPaid) • Remaining Balance: ₹0 • Active',
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

          // Membership Validity & Payment Timeline Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF0D766E)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Membership Validity & Payment Timeline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Active Membership & Shift Update Informational Banner
                Builder(
                  builder: (context) {
                    final s = widget.studentToEdit;
                    if (s == null) return const SizedBox.shrink();
                    final isShiftChanged = _selectedShift.name.toLowerCase() != s.shift.toLowerCase();

                    if (_isStudentInPaidActiveTenure) {
                      if (isShiftChanged) {
                        final diff = _shiftUpgradeDifference;
                        final excess = _shiftDowngradeExcessCredit;
                        if (diff > 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.upgrade_rounded, size: 20, color: Color(0xFFD97706)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Shift upgraded: ${s.shift} → ${_selectedShift.name} (₹$_fixedMonthlyFee/mo). Price difference of ₹$diff applies for the current tenure ending ${DateFormat('dd-MMM-yyyy').format(s.feeDueDate!)}. If not paid now, it will be added as pending dues.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (excess > 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.savings_rounded, size: 20, color: Color(0xFF2563EB)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Shift downgraded: ${s.shift} → ${_selectedShift.name} (₹$_fixedMonthlyFee/mo). Student already paid ₹$_currentCyclePaidAmount for current cycle. ₹$excess excess credit remains with the library to adjust in next month.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF059669)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Shift updated: ${s.shift} → ${_selectedShift.name}. Same price tier (₹$_fixedMonthlyFee/mo). Student already paid ₹$_currentCyclePaidAmount for current cycle. No extra charges or dues.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } else if (s.feeDueDate != null) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF0F766E)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Active plan paid until ${DateFormat('dd-MMM-yyyy').format(s.feeDueDate!)}. Any new payment is strictly an Advance Renewal starting from this date (overlapping periods not allowed).',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // From Date & Valid Until Date Row
                Builder(
                  builder: (context) {
                    final s = widget.studentToEdit;
                    final isShiftChanged = s != null && _selectedShift.name.toLowerCase() != s.shift.toLowerCase();
                    final minDate = (_isStudentInPaidActiveTenure && !isShiftChanged && _selectedDurationMonths > 1 && s?.feeDueDate != null)
                        ? s!.feeDueDate!
                        : DateTime(2020);

                    return Row(
                      children: [
                        // From Date Picker
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('From Date', isRequired: false),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  final initialD = _fromDate.isBefore(minDate) ? minDate : _fromDate;
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initialD,
                                    firstDate: minDate,
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _fromDate = picked;
                                      _validUntilDate = DateTime(
                                        _fromDate.year,
                                        _fromDate.month + _selectedDurationMonths,
                                        _fromDate.day,
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd-MMM-yyyy').format(_fromDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textNavy,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Valid Until Date (LOCKED / AUTO-POPULATED NON-EDITABLE)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _fieldLabel('Valid Until Date', isRequired: false),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Auto',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd-MMM-yyyy').format(_validUntilDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                    const Icon(Icons.lock_clock_rounded, size: 16, color: Color(0xFF0D9488)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Payment Date
                _fieldLabel('Payment Date', isRequired: false),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _paymentDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd-MMM-yyyy').format(_paymentDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textNavy,
                          ),
                        ),
                        const Icon(Icons.today_rounded, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment Method Selector
                _fieldLabel('Payment Method', isRequired: false),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final method in ['UPI', 'Cash', 'Card', 'Online'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedPaymentMethod = method),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMethod == method ? AppColors.primaryTeal : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedPaymentMethod == method ? AppColors.primaryTeal : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                method,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedPaymentMethod == method ? Colors.white : AppColors.textNavy,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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

    final isEdit = widget.studentToEdit != null;
    final s = widget.studentToEdit;
    final totalFee = _calculatedTotalFee;
    final isShiftChanged = s != null && s.shift.toLowerCase() != _selectedShift.name.toLowerCase();

    final int alreadyPaid = isEdit ? _alreadyPaidAmount : 0;
    final int maxPayable = isEdit ? _dueAmount : totalFee;
    final int parsedPaid = int.tryParse(_amountPaidCtrl.text.trim()) ?? (isEdit ? 0 : maxPayable);
    final int reviewPaidNow = parsedPaid.clamp(0, maxPayable);
    final int reviewRemainingDues = (maxPayable - reviewPaidNow).clamp(0, 999999);

    final String reviewStatus;
    final Color reviewStatusColor;
    if (_isTrial) {
      reviewStatus = 'TRIAL STUDENT';
      reviewStatusColor = const Color(0xFFD97706);
    } else if (reviewRemainingDues > 0) {
      reviewStatus = 'FEE DUE (₹$reviewRemainingDues)';
      reviewStatusColor = const Color(0xFFE11D48);
    } else {
      reviewStatus = 'ACTIVE (PAID)';
      reviewStatusColor = const Color(0xFF059669);
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
                child: _photoBase64 != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_photoBase64!),
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
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
                      reviewStatus,
                      valueColor: reviewStatusColor,
                    ),
                  ),
                  Expanded(
                    child: _reviewItem(
                      'SHIFTS',
                      isShiftChanged ? '${_selectedShift.name} (Changed from ${s.shift})' : _selectedShift.name,
                      valueColor: isShiftChanged ? const Color(0xFFD97706) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('MONTHLY FEE', '₹$_fixedMonthlyFee / mo')),
                  Expanded(child: _reviewItem('DURATION', '$_selectedDurationMonths ${_selectedDurationMonths == 1 ? "Month" : "Months"}')),
                ],
              ),
              const SizedBox(height: 16),
              if (isEdit) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _reviewItem('ALREADY PAID', '₹$alreadyPaid (Current cycle)')),
                    Expanded(
                      child: _reviewItem(
                        'PAID NOW',
                        '₹$reviewPaidNow Paid',
                        valueColor: reviewPaidNow > 0 ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _reviewItem('PLAN FEE', '₹$totalFee')),
                    Expanded(
                      child: _reviewItem(
                        reviewRemainingDues > 0 ? 'DUE AMOUNT' : 'DUE STATUS',
                        reviewRemainingDues > 0 ? '₹$reviewRemainingDues DUE' : '₹0 Due (Clear)',
                        valueColor: reviewRemainingDues > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _reviewItem('TOTAL FEE', '₹$totalFee')),
                    Expanded(
                      child: _reviewItem(
                        reviewRemainingDues > 0 ? 'DUE AMOUNT' : 'AMOUNT PAID',
                        reviewRemainingDues > 0 ? '₹$reviewRemainingDues DUE (₹$reviewPaidNow Paid)' : '₹$reviewPaidNow PAID (Full)',
                        valueColor: reviewRemainingDues > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('FROM DATE', DateFormat('dd-MMM-yyyy').format(_fromDate))),
                  Expanded(
                    child: _reviewItem(
                      'VALID UNTIL',
                      DateFormat('dd-MMM-yyyy').format(_validUntilDate),
                      valueColor: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _reviewItem('PAYMENT DATE', DateFormat('dd-MMM-yyyy').format(_paymentDate))),
                  Expanded(child: _reviewItem('PAYMENT MODE', _selectedPaymentMethod)),
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
                            _currentStep == 1
                                ? 'Continue'
                                : (isEditing ? 'Save Changes' : 'Finish & Save'),
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
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
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
