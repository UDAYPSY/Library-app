import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';

class RevenueScreen extends StatefulWidget {
  final String? initialTimeFilter; // e.g. 'TODAY', 'MONTHLY'

  const RevenueScreen({super.key, this.initialTimeFilter});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final LibraryService _service = LibraryService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _monthScrollCtrl = ScrollController();

  late String _selectedYear;
  late String _selectedMonth;
  late final List<String> _years;
  DateTime? _selectedDate; // Specific Date Filter

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  final List<String> _months = [
    'All Months',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  String _selectedPaymentMethod = 'All Methods';
  final List<String> _paymentMethods = [
    'All Methods',
    'UPI',
    'Cash',
    'Card',
    'Net Banking / Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final curY = DateTime.now().year;
    _years = ['All Years', '${curY - 2}', '${curY - 1}', '$curY', '${curY + 1}'];
    _selectedYear = '$curY';
    _selectedMonth = DateFormat('MMM').format(DateTime.now());
    _applyInitialFilter();
  }

  @override
  void didUpdateWidget(covariant RevenueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTimeFilter != null &&
        widget.initialTimeFilter != oldWidget.initialTimeFilter) {
      _applyInitialFilter();
    }
  }

  void _applyInitialFilter() {
    final now = DateTime.now();
    _selectedYear = '${now.year}';
    final monthShort = DateFormat('MMM').format(now);
    if (_months.contains(monthShort)) {
      _selectedMonth = monthShort;
    } else {
      _selectedMonth = 'Oct';
    }

    if (widget.initialTimeFilter == 'TODAY') {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedMonth = monthShort;
      _selectedYear = '${now.year}';
    } else if (widget.initialTimeFilter == 'MONTHLY') {
      _selectedDate = null;
      _selectedMonth = monthShort;
      _selectedYear = '${now.year}';
    }

    // Auto-scroll months to make current month visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_monthScrollCtrl.hasClients) return;
      final mIdx = _months.indexOf(_selectedMonth);
      if (mIdx > 4) {
        _monthScrollCtrl.animateTo(
          (mIdx - 3) * 60.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _monthScrollCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedYear = 'All Years';
      _selectedMonth = 'All Months';
      _selectedPaymentMethod = 'All Methods';
      _selectedDate = null;
    });
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentTransaction>>(
      stream: _service.streamPayments(),
      initialData: _service.currentPayments,
      builder: (context, snapshot) {
        final allPayments = snapshot.data ?? _service.currentPayments;

        // Apply Search & Filters
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredPayments = allPayments.where((p) {
          // Specific date filter
          if (_selectedDate != null) {
            if (!_isSameDay(p.date, _selectedDate)) return false;
          }

          // Search filter
          if (query.isNotEmpty) {
            final matchName = p.studentName.toLowerCase().contains(query);
            final matchNotes = p.notes.toLowerCase().contains(query);
            final matchPhone = p.studentPhone.contains(query);
            final matchSeat = 's-${p.seatNumber}'.contains(query);
            if (!matchName && !matchNotes && !matchPhone && !matchSeat) return false;
          }

          // Year filter
          if (_selectedYear != 'All Years') {
            final y = int.tryParse(_selectedYear);
            if (y != null && p.date.year != y) return false;
          }

          // Month filter
          if (_selectedMonth != 'All Months') {
            final pMonth = DateFormat('MMM').format(p.date);
            if (pMonth.toLowerCase() != _selectedMonth.toLowerCase()) return false;
          }

          // Payment method filter
          if (_selectedPaymentMethod != 'All Methods') {
            final pMode = p.paymentMode.toUpperCase();
            if (_selectedPaymentMethod == 'UPI' && !pMode.contains('UPI')) return false;
            if (_selectedPaymentMethod == 'Cash' && !pMode.contains('CASH')) return false;
            if (_selectedPaymentMethod == 'Card' && !pMode.contains('CARD')) return false;
            if (_selectedPaymentMethod == 'Net Banking / Cheque' &&
                !pMode.contains('BANK') &&
                !pMode.contains('CHEQUE') &&
                !pMode.contains('ONLINE') &&
                !pMode.contains('NET')) return false;
          }

          return true;
        }).toList();

        final totalRevenue = filteredPayments.fold<int>(0, (sum, p) => sum + p.amount);

        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Revenue, • 0 Transactions, TOTAL ₹0 (Image 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            IconButton(
                              icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revenue',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${filteredPayments.length} Transactions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textMutedColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$totalRevenue',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter Card (Image 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderColor(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.subSurface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorderColor(context)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: AppColors.text(context), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search name or notes...',
                              hintStyle: TextStyle(color: AppColors.textSubtleColor(context), fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMutedColor(context), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date Filter Chips Row: [All Dates] [Today] [Yesterday] [Select Date]
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // All Dates
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _selectedDate = null),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _selectedDate == null ? AppColors.primaryTeal : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedDate == null ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                      ),
                                    ),
                                    child: Text(
                                      'All Dates',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedDate == null ? Colors.white : AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Today
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final now = DateTime.now();
                                    setState(() {
                                      _selectedDate = DateTime(now.year, now.month, now.day);
                                      _selectedYear = '${now.year}';
                                      _selectedMonth = DateFormat('MMM').format(now);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _isSameDay(_selectedDate, DateTime.now()) ? AppColors.primaryTeal : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isSameDay(_selectedDate, DateTime.now()) ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                      ),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _isSameDay(_selectedDate, DateTime.now()) ? Colors.white : AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Yesterday
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    final yest = DateTime.now().subtract(const Duration(days: 1));
                                    setState(() {
                                      _selectedDate = DateTime(yest.year, yest.month, yest.day);
                                      _selectedYear = '${yest.year}';
                                      _selectedMonth = DateFormat('MMM').format(yest);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))) ? AppColors.primaryTeal : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))) ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                      ),
                                    ),
                                    child: Text(
                                      'Yesterday',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))) ? Colors.white : AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Calendar Date Picker Button
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? now,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primaryTeal,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = DateTime(picked.year, picked.month, picked.day);
                                      _selectedYear = '${picked.year}';
                                      _selectedMonth = DateFormat('MMM').format(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectedDate != null &&
                                            !_isSameDay(_selectedDate, DateTime.now()) &&
                                            !_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                        ? AppColors.primaryTeal
                                        : AppColors.subSurface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedDate != null &&
                                              !_isSameDay(_selectedDate, DateTime.now()) &&
                                              !_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                          ? AppColors.primaryTeal
                                          : AppColors.cardBorderColor(context),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 14,
                                        color: _selectedDate != null &&
                                                !_isSameDay(_selectedDate, DateTime.now()) &&
                                                !_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                            ? Colors.white
                                            : AppColors.primaryTeal,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('dd-MMM-yyyy').format(_selectedDate!)
                                            : 'Select Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedDate != null &&
                                                  !_isSameDay(_selectedDate, DateTime.now()) &&
                                                  !_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                              ? Colors.white
                                              : AppColors.text(context),
                                        ),
                                      ),
                                      if (_selectedDate != null) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => setState(() => _selectedDate = null),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: _selectedDate != null &&
                                                    !_isSameDay(_selectedDate, DateTime.now()) &&
                                                    !_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))
                                                ? Colors.white
                                                : AppColors.textMutedColor(context),
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
                        const SizedBox(height: 10),

                        // Year Filter Chips Row: [All Years] [2025] [2026] (Image 2)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _years.map((yr) {
                              final isSelected = _selectedYear == yr;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _selectedYear = yr),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryTeal : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                      ),
                                    ),
                                    child: Text(
                                      yr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Month Filter Chips Row: [Aug] [Sep] [Oct] [Nov] [Dec] (Image 2)
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            controller: _monthScrollCtrl,
                            scrollDirection: Axis.horizontal,
                            itemCount: _months.length,
                            itemBuilder: (ctx, i) {
                              final m = _months[i];
                              final isSelected = _selectedMonth == m;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(() => _selectedMonth = m),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryTeal : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : AppColors.text(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Payment Method Dropdown
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                'METHOD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.textMutedColor(context),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.subSurface(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedPaymentMethod != 'All Methods'
                                        ? AppColors.primaryTeal
                                        : AppColors.cardBorderColor(context),
                                    width: _selectedPaymentMethod != 'All Methods' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _paymentMethods.contains(_selectedPaymentMethod)
                                        ? _selectedPaymentMethod
                                        : 'All Methods',
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.primaryTeal,
                                      size: 20,
                                    ),
                                    dropdownColor: AppColors.card(context),
                                    borderRadius: BorderRadius.circular(12),
                                    items: _paymentMethods.map((method) {
                                      final isSelected = _selectedPaymentMethod == method;
                                      IconData icon;
                                      if (method == 'UPI') {
                                        icon = Icons.qr_code_2_rounded;
                                      } else if (method == 'Cash') {
                                        icon = Icons.payments_rounded;
                                      } else if (method == 'Card') {
                                        icon = Icons.credit_card_rounded;
                                      } else if (method == 'Net Banking / Cheque') {
                                        icon = Icons.account_balance_rounded;
                                      } else {
                                        icon = Icons.tune_rounded;
                                      }

                                      return DropdownMenuItem<String>(
                                        value: method,
                                        child: Row(
                                          children: [
                                            Icon(
                                              icon,
                                              size: 15,
                                              color: isSelected ? AppColors.primaryTeal : AppColors.textMutedColor(context),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              method,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                color: isSelected ? AppColors.primaryTeal : AppColors.text(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedPaymentMethod = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Content Area: Empty State Box (Image 2) OR Transactions List
                Expanded(
                  child: filteredPayments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.cardBorderColor(context),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.subSurface(context),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: AppColors.textSubtleColor(context),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No records found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text(context),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your filters or record a\nnew payment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMutedColor(context),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _resetFilters,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.isDark(context) ? const Color(0xFF133E3B) : const Color(0xFFE6F4F1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Reset Filters',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: filteredPayments.length,
                          itemBuilder: (ctx, i) {
                            final p = filteredPayments[i];
                            final dateStr = DateFormat('dd MMM yyyy').format(p.date);
                            final seatStr = p.seatNumber != null ? 'S-${p.seatNumber}' : 'Unallocated';

                            final formattedPaidDate = DateFormat('dd-MMM-yyyy').format(p.date);

                            // Tenure dates and duration calculation
                            final DateTime tenureStart = p.validFrom ?? p.date;
                            final DateTime tenureEnd;
                            final int tenureMonths;

                            if (p.validUntil != null) {
                              tenureEnd = p.validUntil!;
                              tenureMonths = p.durationMonths ??
                                  (((tenureEnd.year - tenureStart.year) * 12 + (tenureEnd.month - tenureStart.month)).clamp(1, 120));
                            } else if (p.durationMonths != null && p.durationMonths! > 0) {
                              tenureMonths = p.durationMonths!;
                              tenureEnd = DateTime(tenureStart.year, tenureStart.month + tenureMonths, tenureStart.day);
                            } else {
                              // Extract duration from notes if available (e.g., "2 Months Advance Fees" or "3 mo")
                              final match = RegExp(r'(\d+)\s*(?:month|mo)', caseSensitive: false).firstMatch(p.notes);
                              if (match != null) {
                                tenureMonths = int.tryParse(match.group(1) ?? '1') ?? 1;
                                tenureEnd = DateTime(tenureStart.year, tenureStart.month + tenureMonths, tenureStart.day);
                              } else {
                                tenureMonths = 1;
                                tenureEnd = DateTime(tenureStart.year, tenureStart.month + 1, tenureStart.day);
                              }
                            }

                            final formattedStart = DateFormat('dd-MMM-yyyy').format(tenureStart);
                            final formattedEnd = DateFormat('dd-MMM-yyyy').format(tenureEnd);
                            final tenureLabel = tenureMonths == 1
                                ? '1 Month'
                                : (tenureMonths % 12 == 0
                                    ? '${tenureMonths ~/ 12} Year${tenureMonths ~/ 12 > 1 ? "s" : ""}'
                                    : '$tenureMonths Months');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.cardBorderColor(context)),
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
                                  // Top Row: Student Name & Amount (Image 3)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.studentName.isNotEmpty ? p.studentName : 'Student',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.text(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${p.amount}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Recorded',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Second Row: Paid on Date & Payment Mode Pill (Image 3)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: AppColors.textSubtleColor(context),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Paid on $formattedPaidDate',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSubtleColor(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.isDark(context) ? const Color(0xFF0C4A6E) : const Color(0xFFF0F9FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.isDark(context) ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD)),
                                        ),
                                        child: Text(
                                          p.paymentMode.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.isDark(context) ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Third Row: Validity Period Box with Accurate Multi-Month / Multi-Year Tenure
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.cardBorderColor(context)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          size: 15,
                                          color: AppColors.textSubtleColor(context),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$formattedStart — $formattedEnd',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text(context),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tenureLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.isDark(context) ? AppColors.mintAccent : const Color(0xFF0F766E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (p.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: p.notes.toLowerCase().contains('due')
                                            ? (AppColors.isDark(context) ? const Color(0xFF451A03) : const Color(0xFFFFFBEB))
                                            : (AppColors.isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: p.notes.toLowerCase().contains('due')
                                              ? (AppColors.isDark(context) ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                                              : AppColors.cardBorderColor(context),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            p.notes.toLowerCase().contains('due') ? Icons.assignment_late_outlined : Icons.notes_rounded,
                                            size: 13,
                                            color: p.notes.toLowerCase().contains('due') ? const Color(0xFFD97706) : AppColors.textSubtleColor(context),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              p.notes,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: p.notes.toLowerCase().contains('due')
                                                    ? (AppColors.isDark(context) ? const Color(0xFFFDE68A) : const Color(0xFFB45309))
                                                    : AppColors.textSubtleColor(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
  }
}
