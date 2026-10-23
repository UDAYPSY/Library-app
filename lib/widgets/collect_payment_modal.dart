import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';

/// Shows a comprehensive payment collection modal for any student.
/// Used both when clicking "Pay" on student cards and "Collect Payment" in member profile.
/// Supports 1-month default, multi-month advance fees (1, 2, 3, 5, 6, 12 months),
/// and customizable membership validity dates.
Future<void> showCollectPaymentModal(
  BuildContext context,
  StudentInfo student, {
  VoidCallback? onPaymentRecorded,
}) async {
  final service = LibraryService();
  final defaultMonthly = student.monthlyFee > 0 ? student.monthlyFee : 500;
  final now = DateTime.now();

  // Dues & Expiry state
  final bool hasUnexpiredDue = student.duesAmount > 0 &&
      student.feeDueDate != null &&
      student.feeDueDate!.isAfter(now);
  final bool isExpired = student.feeDueDate == null || student.feeDueDate!.isBefore(now);

  int alreadyPaid = 0;
  DateTime fromDate;
  DateTime untilDate;
  int selectedAdvanceMonths = 1;

  if (hasUnexpiredDue) {
    alreadyPaid = (defaultMonthly - student.duesAmount).clamp(0, defaultMonthly);
    fromDate = student.joinedAt ?? student.feeDueDate!.subtract(const Duration(days: 30));
    untilDate = student.feeDueDate!;
  } else if (isExpired) {
    alreadyPaid = 0;
    fromDate = now;
    untilDate = DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
  } else {
    alreadyPaid = 0;
    fromDate = student.feeDueDate!;
    untilDate = DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
  }

  final initialTotalFee = hasUnexpiredDue ? defaultMonthly : defaultMonthly * selectedAdvanceMonths;
  final initialDue = hasUnexpiredDue
      ? student.duesAmount
      : (initialTotalFee - alreadyPaid).clamp(0, initialTotalFee);

  final dueAmountCtrl = TextEditingController(text: '$initialDue');
  final notesCtrl = TextEditingController(
    text: hasUnexpiredDue
        ? 'Dues cleared for period ending ${DateFormat('dd-MMM-yyyy').format(untilDate)}'
        : (isExpired
            ? '1 Month Membership Fee Renewal'
            : '1 Month Advance Renewal Fee'),
  );
  DateTime paymentDate = DateTime.now();
  String selectedMethod = 'UPI';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF0F5F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (sheetContext, setModalState) {
        final isDark = AppColors.isDark(sheetContext);

        void applyDuration(int months) {
          setModalState(() {
            selectedAdvanceMonths = months;
            if (months > 0) {
              if (hasUnexpiredDue) {
                if (months == 1) {
                  final due = student.duesAmount;
                  dueAmountCtrl.text = '$due';
                  untilDate = student.feeDueDate!;
                  notesCtrl.text = 'Dues cleared for period ending ${DateFormat('dd-MMM-yyyy').format(untilDate)}';
                } else {
                  final total = defaultMonthly * months;
                  final due = (total - alreadyPaid).clamp(0, total);
                  dueAmountCtrl.text = '$due';
                  final base = student.feeDueDate!;
                  untilDate = DateTime(base.year, base.month + (months - 1), base.day);
                  notesCtrl.text = '$months Months Fee (${student.duesAmount} Due + ${months - 1} mo Advance)';
                }
              } else {
                final total = defaultMonthly * months;
                final due = total;
                dueAmountCtrl.text = '$due';
                untilDate = DateTime(fromDate.year, fromDate.month + months, fromDate.day);
                if (months > 1) {
                  notesCtrl.text = '$months Months Advance Fees Paid';
                } else {
                  notesCtrl.text = isExpired ? '1 Month Membership Fee Renewal' : '1 Month Advance Renewal Fee';
                }
              }
            }
          });
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Centered Drag Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Top Header Row: Record Payment + Admin Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Payment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text(sheetContext),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track & collect membership fees',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF134E4A) : const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14, color: AppColors.primaryTeal),
                          const SizedBox(width: 4),
                          Text(
                            service.profile.adminName.isNotEmpty ? service.profile.adminName : 'Admin',
                            style: const TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Member Info Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D9488),
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
                              student.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(sheetContext),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Seat: ${student.seatNumber != null ? "S-${student.seatNumber}" : "Unallocated"} • Shift: ${student.shift}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$defaultMonthly / mo',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          if (student.effectiveDues > 0)
                            Text(
                              'Due: ₹${student.effectiveDues}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Advance Fee Period Selector (Feature 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Duration / Advance Period',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(sheetContext),
                      ),
                    ),
                    if (selectedAdvanceMonths > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCFBF1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedAdvanceMonths Months Advance',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _durationChip(
                        label: hasUnexpiredDue ? 'Clear Due (₹${student.duesAmount})' : '1 Month',
                        isSelected: selectedAdvanceMonths == 1,
                        isDark: isDark,
                        onTap: () => applyDuration(1),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: hasUnexpiredDue ? '2 Mo (+1 Adv)' : '2 Months',
                        isSelected: selectedAdvanceMonths == 2,
                        isDark: isDark,
                        onTap: () => applyDuration(2),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: hasUnexpiredDue ? '3 Mo (+2 Adv)' : '3 Months',
                        isSelected: selectedAdvanceMonths == 3,
                        isDark: isDark,
                        onTap: () => applyDuration(3),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: '5 Months ⭐',
                        isSelected: selectedAdvanceMonths == 5,
                        isDark: isDark,
                        onTap: () => applyDuration(5),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: '6 Months',
                        isSelected: selectedAdvanceMonths == 6,
                        isDark: isDark,
                        onTap: () => applyDuration(6),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: '1 Year',
                        isSelected: selectedAdvanceMonths == 12,
                        isDark: isDark,
                        onTap: () => applyDuration(12),
                      ),
                      const SizedBox(width: 8),
                      _durationChip(
                        label: 'Custom',
                        isSelected: selectedAdvanceMonths == 0,
                        isDark: isDark,
                        onTap: () {
                          setModalState(() {
                            selectedAdvanceMonths = 0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Period Fee & Fixed Already Paid & Due Amount to Accept (Requirement 4)
                Builder(
                  builder: (ctx) {
                    final totalPeriodFee = hasUnexpiredDue
                        ? (selectedAdvanceMonths == 1 ? defaultMonthly : defaultMonthly * selectedAdvanceMonths)
                        : (selectedAdvanceMonths > 0 ? defaultMonthly * selectedAdvanceMonths : defaultMonthly);
                    final calculatedDue = hasUnexpiredDue
                        ? (selectedAdvanceMonths == 1 ? student.duesAmount : (totalPeriodFee - alreadyPaid).clamp(0, totalPeriodFee))
                        : (totalPeriodFee - alreadyPaid).clamp(0, totalPeriodFee);
                    final enteredPaid = int.tryParse(dueAmountCtrl.text.trim()) ?? calculatedDue;
                    final currentCollect = enteredPaid.clamp(0, calculatedDue);
                    final remainingAfter = (calculatedDue - currentCollect).clamp(0, calculatedDue);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Period Fee
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF134E4A).withOpacity(0.4) : const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Fee (${selectedAdvanceMonths > 0 ? "$selectedAdvanceMonths mo" : "Custom"}):',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              Text(
                                '₹$totalPeriodFee',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Already Paid (Fixed / Non-editable)
                        Row(
                          children: [
                            Text(
                              'Already Paid (₹)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(sheetContext),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.currency_rupee, color: Color(0xFF0D9488), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$alreadyPaid',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text(sheetContext),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Non-editable',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Due Amount to Accept (Only Due Amount accepted, auto-calculated)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due Amount to Accept (₹)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(sheetContext),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Text(
                                'Max Payable: ₹$calculatedDue',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0D9488)),
                          ),
                          child: TextField(
                            controller: dueAmountCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text(sheetContext),
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.currency_rupee, color: Color(0xFF0D9488), size: 20),
                              hintText: 'Enter amount to collect',
                            ),
                            onChanged: (val) {
                              final p = int.tryParse(val.trim());
                              if (p != null && p > calculatedDue) {
                                dueAmountCtrl.text = '$calculatedDue';
                                dueAmountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: dueAmountCtrl.text.length));
                              }
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Status pill under Due input
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: remainingAfter == 0
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: remainingAfter == 0
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Text(
                                remainingAfter == 0
                                    ? '✓ Full Due Cleared (₹0 Due)'
                                    : 'Remaining Due: ₹$remainingAfter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: remainingAfter == 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                // From & Until (Membership Validity Date) (Feature 5)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text(sheetContext),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: fromDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  fromDate = picked;
                                  final m = selectedAdvanceMonths > 0 ? selectedAdvanceMonths : 1;
                                  untilDate = DateTime(fromDate.year, fromDate.month + m, fromDate.day);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd-MMM-yyyy').format(fromDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text(sheetContext),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF64748B)),
                                ],
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
                          Row(
                            children: [
                              Text(
                                'Valid Until Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text(sheetContext),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primaryTeal),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: untilDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  untilDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF0D9488),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd-MMM-yyyy').format(untilDate),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF0D9488)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Date
                Text(
                  'Payment Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(sheetContext),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setModalState(() => paymentDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd-MMM-yyyy').format(paymentDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(sheetContext),
                          ),
                        ),
                        const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(sheetContext),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _methodButton('Cash', Icons.payments_outlined, selectedMethod == 'Cash', isDark, () {
                      setModalState(() => selectedMethod = 'Cash');
                    }),
                    const SizedBox(width: 8),
                    _methodButton('UPI', Icons.phone_android_rounded, selectedMethod == 'UPI', isDark, () {
                      setModalState(() => selectedMethod = 'UPI');
                    }),
                    const SizedBox(width: 8),
                    _methodButton('Card', Icons.credit_card_rounded, selectedMethod == 'Card', isDark, () {
                      setModalState(() => selectedMethod = 'Card');
                    }),
                    const SizedBox(width: 8),
                    _methodButton('Online', Icons.account_balance_rounded, selectedMethod == 'Online', isDark, () {
                      setModalState(() => selectedMethod = 'Online');
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes (Optional)
                Text(
                  'Notes / Remarks (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(sheetContext),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(sheetContext),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add remark (e.g. advance payment, discount note)...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Buttons: [ Discard ]  [ Save Payment ]
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
                          foregroundColor: isDark ? Colors.white : AppColors.textNavy,
                          side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Discard',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          'Save Payment',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        onPressed: () async {
                          final totalPeriodFee = hasUnexpiredDue
                              ? (selectedAdvanceMonths == 1 ? defaultMonthly : defaultMonthly * selectedAdvanceMonths)
                              : (selectedAdvanceMonths > 0 ? defaultMonthly * selectedAdvanceMonths : defaultMonthly);
                          final calculatedDue = hasUnexpiredDue
                              ? (selectedAdvanceMonths == 1 ? student.duesAmount : (totalPeriodFee - alreadyPaid).clamp(0, totalPeriodFee))
                              : (totalPeriodFee - alreadyPaid).clamp(0, totalPeriodFee);
                          final rawPaid = int.tryParse(dueAmountCtrl.text.trim()) ?? calculatedDue;
                          final paid = rawPaid.clamp(0, calculatedDue);
                          final remainingDues = (calculatedDue - paid).clamp(0, 999999);
                          Navigator.pop(ctx);

                          if (paid > 0) {
                            await service.recordPayment(
                              studentId: student.id,
                              studentName: student.name,
                              phone: student.phone,
                              seatNumber: student.seatNumber,
                              shift: student.shift,
                              amount: paid,
                              date: paymentDate,
                              paymentMode: selectedMethod,
                              notes: notesCtrl.text.trim().isNotEmpty
                                  ? notesCtrl.text.trim()
                                  : (remainingDues == 0 ? 'Full payment received' : 'Partial payment received'),
                            );
                          }

                          await service.updateStudent(
                            studentId: student.id,
                            name: student.name,
                            phone: student.phone,
                            shift: student.shift,
                            seatNumber: student.seatNumber,
                            duesAmount: remainingDues,
                            status: remainingDues > 0 ? 'DUES' : 'ACTIVE',
                            feeDueDate: untilDate,
                          );

                          onPaymentRecorded?.call();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                remainingDues > 0
                                    ? 'Payment of ₹$paid recorded. Remaining ₹$remainingDues due. Valid until ${DateFormat('dd-MMM-yyyy').format(untilDate)}'
                                    : 'Payment of ₹$paid recorded! Active until ${DateFormat('dd-MMM-yyyy').format(untilDate)}',
                              ),
                              backgroundColor: remainingDues > 0 ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                              behavior: SnackBarBehavior.floating,
                            ),
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
      },
    ),
  );
}

Widget _durationChip({
  required String label,
  required bool isSelected,
  required bool isDark,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0D9488)
            : (isDark ? const Color(0xFF334155) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textNavy),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
}

Widget _methodButton(String label, IconData icon, bool isSelected, bool isDark, VoidCallback onTap) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D9488)
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textNavy),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
