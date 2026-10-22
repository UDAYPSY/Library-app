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

    if (widget.initialTimeFilter == 'MONTHLY') {
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
    });
  }



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentTransaction>>(
      stream: _service.streamPayments(),
      builder: (context, snapshot) {
        final allPayments = snapshot.data ?? [];

        // Apply Search & Filters
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredPayments = allPayments.where((p) {
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

                        // Payment Method Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _paymentMethods.map((method) {
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

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _selectedPaymentMethod = method),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (AppColors.isDark(context) ? const Color(0xFF134E4A) : const Color(0xFFE6F4F1))
                                          : AppColors.subSurface(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : AppColors.cardBorderColor(context),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 14,
                                          color: isSelected ? AppColors.primaryTeal : AppColors.textMutedColor(context),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          method,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? AppColors.primaryTeal : AppColors.text(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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
                            final validUntilDate = DateFormat('dd-MMM-yyyy').format(p.date.add(const Duration(days: 30)));

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
                                      Text(
                                        p.studentName.isNotEmpty ? p.studentName : 'Student',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.text(context),
                                        ),
                                      ),
                                      Text(
                                        '₹${p.amount}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryTeal,
                                        ),
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

                                  // Third Row: Validity Period Box (Image 3)
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
                                        Text(
                                          '$formattedPaidDate — $validUntilDate',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
