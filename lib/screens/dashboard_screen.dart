import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import 'students/member_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isFirebaseReady;
  final String? firebaseError;

  const DashboardScreen({
    super.key,
    this.isFirebaseReady = false,
    this.firebaseError,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LibraryService _service = LibraryService();
  int _selectedTab = 0;
  bool _dismissedBanner = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_library_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text(
              _service.profile.libraryName.trim().isNotEmpty ? _service.profile.libraryName.trim() : 'Digital Library Hub',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        elevation: 0.5,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh data',
            icon: const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.isFirebaseReady && !_dismissedBanner) _buildDemoModeBanner(),
          Expanded(
            child: _selectedTab == 0
                ? _buildSeatGridTab()
                : _buildStudentsListTab(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Seats Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Students',
          ),
        ],
      ),
    );
  }

  Widget _buildDemoModeBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Preview Mode: To sync seats live across multiple devices, add your Firebase keys in lib/firebase_options.dart.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFB45309)),
            onPressed: () => setState(() => _dismissedBanner = true),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGridTab() {
    return StreamBuilder<List<SeatInfo>>(
      stream: _service.streamSeats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 56, color: Colors.amber),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load seat data',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final seats = snapshot.data!;
        final totalSeats = seats.length;
        final occupiedCount = seats.where((s) => s.isOccupied).length;
        final vacantCount = totalSeats - occupiedCount;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total Seats', '$totalSeats', const Color(0xFF64748B)),
                  _statItem('Occupied', '$occupiedCount', const Color(0xFFEF4444)),
                  _statItem('Vacant', '$vacantCount', const Color(0xFF10B981)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemCount: totalSeats,
                itemBuilder: (context, index) {
                  final seat = seats[index];
                  final isOccupied = seat.isOccupied;

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _handleSeatClick(seat),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOccupied
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        border: Border.all(
                          color: isOccupied
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chair_alt,
                            color: isOccupied
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S-${seat.seatNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isOccupied && seat.studentName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Text(
                                seat.studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _statItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  void _handleSeatClick(SeatInfo seat) {
    if (seat.isOccupied) {
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
      return;
    }
    _showRegistrationSheet(seat.seatNumber);
  }

  void _showRegistrationSheet(int seatNum) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String shift = 'Full Day';
    String? nameError;
    String? phoneError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Seat S-$seatNum (Fee: ₹500/mo)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Student Full Name',
                  errorText: nameError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Phone Number',
                  errorText: phoneError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: shift,
                items: ['Full Day', 'Morning (6AM - 2PM)', 'Evening (2PM - 10PM)']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setModalState(() => shift = v);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Shift',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();

                    bool hasErr = false;
                    if (name.isEmpty) {
                      setModalState(() => nameError = 'Please enter student name');
                      hasErr = true;
                    } else {
                      setModalState(() => nameError = null);
                    }

                    if (phone.isEmpty || phone.length < 10) {
                      setModalState(() => phoneError = 'Enter a valid 10-digit phone number');
                      hasErr = true;
                    } else {
                      setModalState(() => phoneError = null);
                    }

                    if (hasErr) return;

                    Navigator.pop(ctx);
                    try {
                      await _service.assignSeatAndRegisterStudent(
                        seatNumber: seatNum,
                        studentName: name,
                        phone: phone,
                        shift: shift,
                        deviceUserId: 'Desk_Manager',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student registered & ₹500 fee logged!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Confirm & Collect ₹500',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsListTab() {
    return StreamBuilder<List<StudentInfo>>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 56, color: Colors.amber),
                  const SizedBox(height: 12),
                  const Text('Error loading student records'),
                  const SizedBox(height: 6),
                  Text('${snapshot.error}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data!;
        if (students.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No registered students yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap any vacant seat in the Seats Map to register.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final dateFormat = DateFormat('dd MMM yyyy');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: students.length,
          itemBuilder: (context, idx) {
            final s = students[idx];
            final seatLabel = s.seatNumber != null ? 'S-${s.seatNumber}' : 'None';
            final dueDateStr = s.feeDueDate != null ? dateFormat.format(s.feeDueDate!) : 'N/A';

            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    seatLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text('Shift: ${s.shift} • Phone: ${s.phone}'),
                    Text(
                      'Renewal Due: $dueDateStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF22C55E)),
                  tooltip: 'Send WhatsApp fee reminder',
                  onPressed: () => _sendWhatsAppReminder(s),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendWhatsAppReminder(StudentInfo s) async {
    final cleanPhone = s.phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid student phone number')),
      );
      return;
    }

    final libName = _service.profile.libraryName.trim().isNotEmpty
        ? _service.profile.libraryName.trim()
        : 'the library';
    final feeAmount = s.effectiveDues > 0 ? s.effectiveDues : (s.monthlyFee > 0 ? s.monthlyFee : 500);
    final message =
        'Hello ${s.name}, this is a reminder from $libName that your monthly seat renewal fee of ₹$feeAmount is scheduled. Please confirm renewal at the desk.';
    final url = Uri.parse(
      'https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }
}