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

  String _selectedYear = '2026'; // Selected in 2.jpeg
  String _selectedMonth = 'Oct'; // Selected in 2.jpeg

  final List<String> _years = ['All Years', '2025', '2026'];
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

  @override
  void initState() {
    super.initState();
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
    });
  }

  void _openRecordPaymentModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '500');
    final notesCtrl = TextEditingController();
    String paymentMode = 'UPI';
    int? seatNum;

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
                    const Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textNavy),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentMode,
                        items: ['UPI', 'Cash']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setModalState(() => paymentMode = v ?? paymentMode),
                        decoration: const InputDecoration(
                          labelText: 'Mode',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: seatNum,
                        hint: const Text('Seat (Optional)'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('No Seat')),
                          ...List.generate(_service.totalSeatsCount, (i) => i + 1).map(
                            (s) => DropdownMenuItem<int?>(value: s, child: Text('Seat S-$s')),
                          ),
                        ],
                        onChanged: (v) => setModalState(() => seatNum = v),
                        decoration: const InputDecoration(
                          labelText: 'Seat Allocation',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || amt <= 0) return;
                      Navigator.pop(ctx);

                      await _service.recordPayment(
                        studentName: name,
                        phone: phoneCtrl.text.trim(),
                        seatNumber: seatNum,
                        amount: amt,
                        paymentMode: paymentMode,
                        notes: notesCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment of ₹$amt recorded for $name!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Save Payment Record',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

          return true;
        }).toList();

        final totalRevenue = filteredPayments.fold<int>(0, (sum, p) => sum + p.amount);

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
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
                              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textNavy),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Revenue',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textNavy,
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
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
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search name or notes...',
                              hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                                      color: isSelected ? AppColors.primaryTeal : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      yr,
                                      style: TextStyle(
                                        fontSize: 12,
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
                                      color: isSelected ? AppColors.primaryTeal : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : AppColors.textNavy,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
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
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No records found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try adjusting your filters or record a\nnew payment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
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
                                      color: const Color(0xFFE6F4F1),
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

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightMint,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.receipt_rounded, color: AppColors.primaryTeal, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.studentName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Seat $seatStr • ${p.shift} (${p.paymentMode})',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+₹${p.amount}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.successGreen,
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openRecordPaymentModal,
            backgroundColor: AppColors.primaryTeal,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
