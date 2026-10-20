import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/library_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LibraryService _service = LibraryService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Library Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: _selectedTab == 0 ? _buildSeatGridTab() : _buildStudentsListTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Seats Map'),
          NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Students'),
        ],
      ),
    );
  }

  Widget _buildSeatGridTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.streamSeats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final seatDocs = snapshot.data!.docs;
        // Generate a 50-seat layout view
        final totalSeats = 50;
        final seatMap = {for (var doc in seatDocs) doc.get('seat_number'): doc};

        int occupiedCount = seatDocs.where((d) => (d.data() as Map<String, dynamic>)['is_occupied'] == true).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total Seats', '$totalSeats', Colors.blueGrey),
                  _statItem('Occupied', '$occupiedCount', Colors.redAccent),
                  _statItem('Vacant', '${totalSeats - occupiedCount}', Colors.green),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: totalSeats,
                itemBuilder: (context, index) {
                  final seatNum = index + 1;
                  final doc = seatMap[seatNum];
                  final isOccupied = doc != null && (doc.data() as Map<String, dynamic>)['is_occupied'] == true;
                  final studentName = isOccupied ? doc.get('student_name') ?? '' : '';

                  return GestureDetector(
                    onTap: () => _handleSeatClick(seatNum, doc),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOccupied ? Colors.red.shade100 : Colors.green.shade100,
                        border: Border.all(color: isOccupied ? Colors.red : Colors.green, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chair_alt,
                            color: isOccupied ? Colors.red.shade700 : Colors.green.shade700,
                            size: 24,
                          ),
                          Text('S-$seatNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (isOccupied)
                            Text(
                              studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
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
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _handleSeatClick(int seatNum, DocumentSnapshot? doc) {
    final isOccupied = doc != null && (doc.data() as Map<String, dynamic>)['is_occupied'] == true;

    if (isOccupied) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Seat $seatNum Details'),
          content: Text('Student: ${doc.get('student_name')}\nShift: ${doc.get('shift')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await _service.vacateSeat(seatNum, doc.get('student_id'));
              },
              child: const Text('Vacate Seat', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      _showRegistrationSheet(seatNum);
    }
  }

  void _showRegistrationSheet(int seatNum) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String shift = 'Full Day';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Seat S-$seatNum (Fee: ₹500/mo)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: shift,
              items: ['Full Day', 'Morning (6AM - 2PM)', 'Evening (2PM - 10PM)']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => shift = v ?? shift,
              decoration: const InputDecoration(labelText: 'Select Shift', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _service.assignSeatAndRegisterStudent(
                      seatNumber: seatNum,
                      studentName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      shift: shift,
                      deviceUserId: 'Desk_Manager',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student registered & ₹500 fee logged!')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Confirm & Collect ₹500', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.streamStudents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text('No registered students yet.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, idx) {
            final s = docs[idx].data() as Map<String, dynamic>;
            final seat = s['seat_number'] ?? 'None';
            final phone = s['phone'] ?? '';
            final name = s['name'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: Text('S-$seat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Shift: ${s['shift']} | Status: ${s['status']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.message, color: Colors.green),
                  onPressed: () async {
                    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                    final url = Uri.parse('https://wa.me/91$cleanPhone?text=Hello%20$name,%20your%20library%20monthly%20seat%20renewal%20fee%20of%20Rs.500%20is%20scheduled.');
                    if (await canLaunchUrl(url)) launchUrl(url);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}