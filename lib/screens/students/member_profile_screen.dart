import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/library_models.dart';
import '../../services/library_service.dart';
import '../../widgets/collect_payment_modal.dart';
import 'add_student_wizard_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final StudentInfo student;
  final int memberId;

  const MemberProfileScreen({
    super.key,
    required this.student,
    required this.memberId,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final LibraryService _service = LibraryService();
  late StudentInfo _student;
  bool _showFullAadhaar = false;

  String _formatAadhaar(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 4) return raw;
    if (_showFullAadhaar) {
      if (clean.length == 12) {
        return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
      }
      return raw;
    }
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• $last4';
  }

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  void _refreshStudent() {
    final updated = _service.currentStudents.firstWhere(
      (s) => s.id == _student.id,
      orElse: () => _student,
    );
    setState(() {
      _student = updated;
    });
  }

  Future<void> _launchUrlStr(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $urlStr')),
        );
      }
    }
  }

  void _openWhatsApp() {
    _showMessagingModal(isWhatsApp: true);
  }

  void _openSms() {
    _showMessagingModal(isWhatsApp: false);
  }

  void _showMessagingModal({required bool isWhatsApp, String initialAction = 'General Follow-up'}) {
    String selectedAction = initialAction;
    bool useWhatsApp = isWhatsApp;
    
    final customRemarkCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    String generateActionMessage(String action, String customRemark) {
      String rawTpl;
      switch (action) {
        case 'Seat Change':
          rawTpl = _service.profile.seatChangeTemplate;
          break;
        case 'Shift Change':
          rawTpl = _service.profile.shiftChangeTemplate;
          break;
        case 'Seat Allotment':
          rawTpl = _service.profile.seatAllotmentTemplate;
          break;
        case 'Fee Reminder':
          rawTpl = _service.profile.reminderTemplate;
          break;
        case 'Custom':
          return 'Hello ${_student.name}, this is from ${_service.profile.libraryName}.';
        case 'General Follow-up':
        default:
          rawTpl = _service.profile.followupTemplate;
          break;
      }

      var msg = _service.formatTemplate(
        rawTpl,
        student: _student,
        customNote: customRemark.trim(),
      );

      if (customRemark.trim().isNotEmpty && !rawTpl.contains('{note}')) {
        msg += '\n\n📌 Note: ${customRemark.trim()}';
      }
      return msg;
    }

    messageCtrl.text = generateActionMessage(selectedAction, '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: useWhatsApp ? const Color(0xFFECFDF5) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              useWhatsApp ? Icons.chat_bubble_outline_rounded : Icons.sms_outlined,
                              color: useWhatsApp ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                useWhatsApp ? 'Send WhatsApp' : 'Send SMS',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                              ),
                              Text(
                                'To: ${_student.name} (${_student.phone})',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Channel Toggle (WhatsApp / SMS)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => useWhatsApp = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: useWhatsApp ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: useWhatsApp ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: useWhatsApp ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'WhatsApp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: useWhatsApp ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => useWhatsApp = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !useWhatsApp ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !useWhatsApp ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)] : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sms_outlined, size: 16, color: !useWhatsApp ? const Color(0xFF0284C7) : const Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SMS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: !useWhatsApp ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action-Specific Template Selection Chips
                  const Text('Select Action Draft Template:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Seat Change',
                        'Shift Change',
                        'Seat Allotment',
                        'Fee Reminder',
                        'General Follow-up',
                        'Custom',
                      ].map((action) {
                        final isSel = selectedAction == action;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              action,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : AppColors.textNavy,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: useWhatsApp ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (_) {
                              setModalState(() {
                                selectedAction = action;
                                messageCtrl.text = generateActionMessage(action, customRemarkCtrl.text);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional Custom Remark for THIS dispatch (does not dump whole historical notes)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Custom Remark to Message:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                      Text('(Optional)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: customRemarkCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Fee extension granted till Friday; 2nd floor silent zone assigned...',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        messageCtrl.text = generateActionMessage(selectedAction, val);
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Editable Message Preview
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Draft Message to Send:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textNavy)),
                      Text('(Fully Editable)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons: Send & Copy
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: useWhatsApp ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: Icon(useWhatsApp ? Icons.chat_bubble_outline_rounded : Icons.sms_outlined, size: 20),
                            label: Text(
                              useWhatsApp ? 'Send on WhatsApp' : 'Send via SMS',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            onPressed: () async {
                              final textToSend = messageCtrl.text.trim();
                              final remark = customRemarkCtrl.text.trim();
                              if (remark.isNotEmpty) {
                                final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
                                final updatedNotes = LibraryService.appendNote(_student.note, 'Follow-up ($selectedAction) on $dateStr: $remark');
                                final updated = _student.copyWith(note: updatedNotes);
                                await _service.updateStudentInfo(updated);
                                _refreshStudent();
                              }
                              Navigator.pop(ctx);
                              if (useWhatsApp) {
                                _service.useWhatsAppCredit(1);
                                final sent = await LibraryService.sendWhatsAppDirect(
                                  phone: _student.phone,
                                  message: textToSend,
                                );
                                if (!sent) {
                                  Clipboard.setData(ClipboardData(text: textToSend));
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open WhatsApp. Message copied to clipboard!')),
                                    );
                                  }
                                }
                              } else {
                                final sent = await LibraryService.sendSmsDirect(
                                  phone: _student.phone,
                                  message: textToSend,
                                );
                                if (!sent) {
                                  Clipboard.setData(ClipboardData(text: textToSend));
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open SMS app. Message copied to clipboard!')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          tooltip: 'Copy Message',
                          icon: const Icon(Icons.copy_rounded, color: AppColors.textNavy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: messageCtrl.text.trim()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message copied to clipboard!'), behavior: SnackBarBehavior.floating),
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

  void _openDialer() {
    final cleanPhone = LibraryService.normalizePhone(_student.phone);
    _launchUrlStr('tel:$cleanPhone');
  }

  void _copyPhone() {
    Clipboard.setData(ClipboardData(text: _student.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_student.phone} to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  void _showSaveContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('Save Contact', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
          ],
        ),
        content: Text(
          'Save ${_student.name} (${_student.phone}) to your phone contacts?\n\nSeat: #${_student.seatNumber ?? 'Unallocated'}\nShift: ${_student.shift}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _copyPhone();
            },
            child: const Text('Copy to Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddStudentWizardScreen(studentToEdit: _student),
      ),
    );
    if (result == true || mounted) {
      _refreshStudent();
    }
  }

  void _showChangeSeatDialog() {
    int? tempSeat = _student.seatNumber;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text('Change / Swap Seat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Seat: #${_student.seatNumber ?? 'Unallocated'}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              const Text('Select New Seat Number:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textNavy)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: tempSeat,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: List.generate(_service.totalSeatsCount, (i) => i + 1).map((num) {
                  final isCurrent = num == _student.seatNumber;
                  final isOcc = _service.isSeatOccupied(num, shift: _student.shift, excludeStudentId: _student.id) && !isCurrent;
                  return DropdownMenuItem<int>(
                    value: num,
                    enabled: !isOcc,
                    child: Text(
                      'Seat #$num ${isCurrent ? '(Current)' : (isOcc ? '(Occupied)' : '(Available)')}',
                      style: TextStyle(
                        color: isOcc ? Colors.grey : AppColors.textNavy,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() => tempSeat = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (tempSeat != null) {
                  await _service.assignSeatToExistingStudent(
                    newSeatNumber: tempSeat!,
                    studentId: _student.id,
                    shift: _student.shift,
                  );
                  Navigator.pop(ctx);
                  _refreshStudent();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seat updated to #$tempSeat successfully!'), backgroundColor: AppColors.primaryTeal),
                    );
                  }
                }
              },
              child: const Text('Assign Seat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStudent() {
    final isInactive = _student.status == 'INACTIVE';

    if (isInactive) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Text('Permanently Delete?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete ${_student.name}? This will completely wipe all member data and cannot be undone.',
            style: const TextStyle(fontSize: 14, color: AppColors.textNavy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _service.permanentlyDeleteStudent(_student.id, _student.seatNumber);
                Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_student.name} permanently deleted from records.'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Student', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to remove ${_student.name}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textNavy, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 20),
                    ),
                    title: const Text('Move to Inactive Tab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Frees Seat #${_student.seatNumber ?? "—"} while preserving past payment and membership history for future renewal.', style: const TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _service.markStudentInactive(_student.id, _student.seatNumber);
                      if (mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${_student.name} moved to Inactive and seat freed.'), backgroundColor: const Color(0xFFD97706)),
                        );
                      }
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Permanently Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFEF4444))),
                    subtitle: const Text('Completely purges this student record from the database. Cannot be undone.', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _service.permanentlyDeleteStudent(_student.id, _student.seatNumber);
                      if (mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${_student.name} permanently deleted.'), backgroundColor: Colors.black87),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentSheet() {
    showCollectPaymentModal(
      context,
      _student,
      onPaymentRecorded: _refreshStudent,
    );
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.note_add_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('Add Member Note', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textNavy)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a remark or note for this student profile:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter notes, follow-up, or remarks...',
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final text = noteCtrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                final dateStr = DateFormat('dd-MMM-yyyy').format(DateTime.now());
                final userNote = 'Remark on $dateStr: $text';
                await _service.updateStudent(
                  studentId: _student.id,
                  name: _student.name,
                  phone: _student.phone,
                  shift: _student.shift,
                  seatNumber: _student.seatNumber,
                  note: userNote,
                );
                _refreshStudent();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note added to student profile!'),
                      backgroundColor: Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        await _service.updateStudent(
          studentId: _student.id,
          name: _student.name,
          phone: _student.phone,
          shift: _student.shift,
          seatNumber: _student.seatNumber,
          note: _student.note,
          monthlyFee: _student.monthlyFee,
          duesAmount: _student.duesAmount,
          status: _student.status,
          feeDueDate: _student.feeDueDate,
          fatherName: _student.fatherName,
          address: _student.address,
          aadhaarNumber: _student.aadhaarNumber,
          preparationFor: _student.preparationFor,
          gender: _student.gender,
          sectionName: _student.sectionName,
          photoBase64: base64Str,
        );
        _refreshStudent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member profile photo updated successfully!'),
              backgroundColor: Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    await _service.updateStudent(
      studentId: _student.id,
      name: _student.name,
      phone: _student.phone,
      shift: _student.shift,
      seatNumber: _student.seatNumber,
      note: _student.note,
      photoBase64: '',
    );
    _refreshStudent();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member photo removed.'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Member Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D9488)),
                ),
                title: const Text('Take Photo via Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfilePhoto(ImageSource.gallery);
                },
              ),
              if (_student.hasPhoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeProfilePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildIdCardPassText() {
    final libName = _service.profile.libraryName;
    final dueStr = _student.feeDueDate != null ? DateFormat('dd-MMM-yyyy').format(_student.feeDueDate!) : 'N/A';
    final seatStr = _student.seatNumber != null ? '#${_student.seatNumber}' : 'Unallocated';
    final baseUrl = _service.profile.portalBaseUrl.trim().isNotEmpty
        ? _service.profile.portalBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://udaypsy.github.io/Library-app';
    final qrVerifyUrl = '$baseUrl/#/portal?lib=${_service.tenantId}&verify=${_student.id}&seat=${_student.seatNumber ?? 0}&student=${Uri.encodeComponent(_student.name)}';

    return '''
📇 *OFFICIAL DIGITAL ID CARD*
🏛️ *${libName.toUpperCase()}*
----------------------------------------
👤 *Member Name:* ${_student.name}
🆔 *Member ID:* #${widget.memberId}
🪑 *Assigned Seat:* $seatStr
⏰ *Shift:* ${_student.shift}
📅 *Valid Till:* $dueStr
✅ *Status:* ${_student.status}
----------------------------------------
📲 *Digital Verification Pass:*
$qrVerifyUrl

Please present this Digital Pass upon entering the study hall.
_Powered by TrackMyLibrary_
'''.trim();
  }

  Future<void> _shareDigitalIdCardWhatsApp() async {
    final cleanPhone = _student.phone.replaceAll(RegExp(r'\D'), '');
    final target = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final message = _buildIdCardPassText();
    final uri = Uri.parse('https://wa.me/$target?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _copyDigitalIdCard() {
    Clipboard.setData(ClipboardData(text: _buildIdCardPassText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Digital Membership Pass copied to clipboard!'),
        backgroundColor: Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showIdCardSheet() {
    final initials = _student.name.trim().isNotEmpty
        ? (_student.name.trim().split(' ').length > 1
            ? '${_student.name.trim().split(' ')[0][0]}${_student.name.trim().split(' ')[1][0]}'.toUpperCase()
            : (_student.name.trim().length >= 2 ? _student.name.trim().substring(0, 2).toUpperCase() : _student.name.trim().toUpperCase()))
        : 'ST';

    final enrollDateStr = _student.joinedAt != null
        ? DateFormat('dd-MMM-yyyy').format(_student.joinedAt!)
        : DateFormat('dd-MMM-yyyy').format(DateTime.now());

    final dueStr = _student.feeDueDate != null
        ? DateFormat('dd-MMM-yyyy').format(_student.feeDueDate!)
        : 'Active Regular';

    final baseUrl = _service.profile.portalBaseUrl.trim().isNotEmpty
        ? _service.profile.portalBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')
        : 'https://udaypsy.github.io/Library-app';
    final qrVerifyUrl = '$baseUrl/#/portal?lib=${_service.tenantId}&verify=${_student.id}&seat=${_student.seatNumber ?? 0}&student=${Uri.encodeComponent(_student.name)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_service.profile.logoBase64 != null && _service.profile.logoBase64!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_service.profile.logoBase64!),
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_library_rounded, color: Color(0xFF0D9488), size: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _service.profile.libraryName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Color(0xFF0D9488),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Digital Card Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Ribbon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'OFFICIAL DIGITAL PASS',
                                  style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            Text(
                              'PASS #${widget.memberId}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            // Student Photo & Core Details
                            Row(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24, width: 2),
                                  ),
                                  child: _student.hasPhoto
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Image.memory(
                                            base64Decode(_student.photoBase64!),
                                            width: 76,
                                            height: 76,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _student.name,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Phone: ${_student.phone}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Enrolled: $enrollDateStr',
                                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Seat & Shift Matrix
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('SEAT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60)),
                                      const SizedBox(height: 2),
                                      Text('#${_student.seatNumber ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                                    ],
                                  ),
                                  Container(height: 22, width: 1, color: Colors.white24),
                                  Column(
                                    children: [
                                      const Text('SHIFT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60)),
                                      const SizedBox(height: 2),
                                      Text(_student.shift, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                                    ],
                                  ),
                                  Container(height: 22, width: 1, color: Colors.white24),
                                  Column(
                                    children: [
                                      const Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white60)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _student.status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: _student.status == 'ACTIVE' ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Verification QR Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  QrImageView(
                                    data: qrVerifyUrl,
                                    version: QrVersions.auto,
                                    size: 130,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF0F172A),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Scan to verify membership at front desk',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Validity Pill
                            Text(
                              'VALIDITY: $dueStr',
                              style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Share Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text('Share Pass via WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _shareDigitalIdCardWhatsApp();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Membership Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copyDigitalIdCard();
                    },
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
    final initials = _student.name.trim().isNotEmpty
        ? (_student.name.trim().split(' ').length > 1
            ? '${_student.name.trim().split(' ')[0][0]}${_student.name.trim().split(' ')[1][0]}'.toUpperCase()
            : (_student.name.trim().length >= 2 ? _student.name.trim().substring(0, 2).toUpperCase() : _student.name.trim().toUpperCase()))
        : 'ST';

    final enrolledDateStr = _student.joinedAt != null
        ? DateFormat('dd-MMM-yyyy').format(_student.joinedAt!)
        : DateFormat('dd-MMM-yyyy').format(DateTime.now());

    final studentJoin = _student.joinedAt ?? DateTime.now();
    final daysIn = (DateTime.now().difference(DateTime(studentJoin.year, studentJoin.month, studentJoin.day)).inDays + 1).clamp(1, 99999);

    final validityStr = _student.feeDueDate != null
        ? 'Valid until ${DateFormat('dd-MMM-yyyy').format(_student.feeDueDate!)}'
        : 'No active payment';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back Button + Title + Search Button (Image 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: AppColors.textNavy, size: 26),
                    ),
                  ),
                  const Text(
                    'Member Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textNavy,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Member profile search active'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.search, color: AppColors.textNavy, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Profile Sections (Images 2, 3, 4, 5)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Profile Card (Image 2)
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
                        children: [
                          // Avatar + Name + Badges
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar Squircle with Camera Badge (Tappable to upload/change photo)
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _showPhotoOptions,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: _student.hasPhoto
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.memory(
                                                base64Decode(_student.photoBase64!),
                                                width: 68,
                                                height: 68,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _student.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        // Status Chip
                                        _buildStatusBadge(_student),
                                        // Gender Chip (Image 2)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDF2F8),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFCE7F3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.female, size: 12, color: Color(0xFFDB2777)),
                                              const SizedBox(width: 2),
                                              Text(
                                                (_student.gender.isNotEmpty ? _student.gender : 'MALE').toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFDB2777),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Member ID Chip (Image 2)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDFA),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFCCFBF1)),
                                          ),
                                          child: Text(
                                            'ID: ${widget.memberId}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Trial / Days In Chip (Image 2)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFBAE6FD)),
                                      ),
                                      child: Text(
                                        _student.status == 'TRIAL'
                                            ? 'TRIAL • $daysIn DAYS IN'
                                            : 'ACTIVE • $daysIn DAYS IN',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3 Stat Cards Row (Image 2)
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  topText: '#${_student.seatNumber ?? '—'}',
                                  bottomText: 'SEAT',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  topText: _student.shift,
                                  bottomText: 'SHIFT',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statCard(
                                  topText: _student.hasDues ? '₹${_student.effectiveDues}' : 'PAID',
                                  bottomText: _student.hasDues ? 'DUES' : 'FEES',
                                  textColor: _student.hasDues ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),

                          // Advance Balance Box with Library
                          if (_student.advanceAmount > 0) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0D059669), blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ADVANCE MONEY WITH LIBRARY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${_student.advanceAmount}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Credit available with library. Automatically adjusted in next renewal or shift upgrades.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Collect Payment Button (Image 2)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                              label: const Text(
                                'Collect Payment',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              onPressed: _showRecordPaymentSheet,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick Actions Row 1: WhatsApp | SMS (Image 2)
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _openWhatsApp,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                        SizedBox(width: 8),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: _openSms,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFBAE6FD)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_outlined, size: 18, color: Color(0xFF0284C7)),
                                        SizedBox(width: 8),
                                        Text(
                                          'SMS',
                                          style: TextStyle(
                                            color: Color(0xFF0284C7),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick Actions Row 2: ID Card | Edit | Swap | Delete (Image 2)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: _showIdCardSheet,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.badge_outlined, size: 18, color: AppColors.textNavy),
                                        SizedBox(width: 6),
                                        Text(
                                          'ID Card',
                                          style: TextStyle(
                                            color: AppColors.textNavy,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Edit Button (Navigates to Edit flow, Images 6, 7, 8)
                              InkWell(
                                onTap: _openEditStudent,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.textNavy),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Change Seat Button
                              InkWell(
                                onTap: _showChangeSeatDialog,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(Icons.swap_horiz_rounded, size: 22, color: AppColors.textNavy),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete/Deactivate Button
                              InkWell(
                                onTap: _confirmDeleteStudent,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Library Membership Section (Images 2 & 3)
                    const Text(
                      'Library Membership',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Workspace
                          _membershipItem(
                            icon: Icons.apartment_rounded,
                            label: 'Workspace',
                            valueWidget: Text(
                              '${_student.sectionName} • Pos ${_student.seatNumber ?? 'Unallocated'}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textNavy),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCCFBF1)),
                              ),
                              child: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF0D9488)),
                            ),
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Schedule
                          _membershipItem(
                            icon: Icons.access_time_filled_rounded,
                            label: 'Schedule',
                            valueWidget: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _student.shift.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '06:00 AM - 10:00 PM',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textNavy),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Monthly Fee
                          _membershipItem(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Monthly Fee',
                            valueWidget: Text(
                              '₹${_student.monthlyFee}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textNavy),
                            ),
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Membership Validity
                          _membershipItem(
                            icon: Icons.verified_user_rounded,
                            label: 'Membership Validity',
                            valueWidget: Text(
                              validityStr,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _student.feeDueDate != null ? AppColors.textNavy : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (_student.advanceAmount > 0) ...[
                            const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
                            _membershipItem(
                              icon: Icons.savings_outlined,
                              label: 'Advance Balance',
                              valueWidget: Text(
                                '₹${_student.advanceAmount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Personal Information Section (Images 3, 4, 5)
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Phone with Quick Actions Bar (Image 3)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDFA),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.call_rounded, color: Color(0xFF0D9488), size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                          const SizedBox(height: 2),
                                          Text(
                                            _student.phone.isNotEmpty ? _student.phone : 'Not provided',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 4 Action Buttons: Copy | Chat | Call | Save (Image 3)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _phoneActionBtn(
                                        icon: Icons.copy_rounded,
                                        label: 'Copy',
                                        onTap: _copyPhone,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _phoneActionBtn(
                                        icon: Icons.chat_bubble_outline_rounded,
                                        label: 'Chat',
                                        iconColor: const Color(0xFF10B981),
                                        textColor: const Color(0xFF10B981),
                                        bgColor: const Color(0xFFECFDF5),
                                        borderColor: const Color(0xFFA7F3D0),
                                        onTap: _openWhatsApp,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _phoneActionBtn(
                                        icon: Icons.phone_outlined,
                                        label: 'Call',
                                        iconColor: const Color(0xFF0D9488),
                                        textColor: const Color(0xFF0D9488),
                                        bgColor: const Color(0xFFF0FDFA),
                                        borderColor: const Color(0xFF99F6E4),
                                        onTap: _openDialer,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _phoneActionBtn(
                                        icon: Icons.person_add_alt_1_rounded,
                                        label: 'Save',
                                        iconColor: const Color(0xFF0284C7),
                                        textColor: const Color(0xFF0284C7),
                                        bgColor: const Color(0xFFF0F9FF),
                                        borderColor: const Color(0xFFBAE6FD),
                                        onTap: _showSaveContactDialog,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Father Name (Image 3 & 4)
                          _personalInfoRow(
                            icon: Icons.people_alt_outlined,
                            label: 'Father Name',
                            value: _student.fatherName.isNotEmpty ? _student.fatherName : 'Not provided',
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Address (Image 3 & 4)
                          _personalInfoRow(
                            icon: Icons.home_outlined,
                            label: 'Address',
                            value: _student.address.isNotEmpty ? _student.address : 'Not provided',
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Aadhaar Number (DPDP Act Masked with Reveal Toggle)
                          _personalInfoRow(
                            icon: Icons.credit_card_outlined,
                            label: 'Aadhaar Number (Protected)',
                            value: _student.aadhaarNumber.isNotEmpty
                                ? _formatAadhaar(_student.aadhaarNumber)
                                : 'Not provided',
                            trailing: _student.aadhaarNumber.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      _showFullAadhaar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                    tooltip: _showFullAadhaar ? 'Hide Aadhaar' : 'Show full Aadhaar',
                                    onPressed: () {
                                      setState(() {
                                        _showFullAadhaar = !_showFullAadhaar;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Preparation For (Image 4 & 5)
                          _personalInfoRow(
                            icon: Icons.school_outlined,
                            label: 'Preparation For',
                            value: _student.preparationFor.isNotEmpty ? _student.preparationFor : 'General Studies',
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Enrolled On (Image 4 & 5)
                          _personalInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Enrolled On (Fixed)',
                            value: '$enrolledDateStr ($daysIn days completed)',
                          ),
                          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),

                          // Member Remarks (Image 4 & 5)
                          _personalInfoRow(
                            icon: Icons.description_outlined,
                            label: 'Member Remarks',
                            value: _student.note.isNotEmpty ? _student.note : 'No remarks recorded',
                            iconBgColor: const Color(0xFFFFFBEB),
                            iconColor: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Notes & Activity History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notes & Activity History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textNavy,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0D9488),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.note_add_rounded, size: 16),
                          label: const Text(
                            'Add Note',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          onPressed: _showAddNoteDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNotesTimelineCard(enrolledDateStr),
                    const SizedBox(height: 24),

                    // 5. Payment History Section
                    StreamBuilder<List<PaymentTransaction>>(
                      stream: _service.streamPayments(),
                      builder: (context, paySnap) {
                        final allPayments = paySnap.data ?? _service.currentPayments;
                        final studentPhoneNorm = LibraryService.normalizePhone(_student.phone);

                        final studentPayments = allPayments.where((p) {
                          // Primary match: unique student ID
                          if (p.studentId.isNotEmpty) {
                            return p.studentId == _student.id;
                          }
                          // Fallback ONLY for legacy payments without studentId: match normalized phone
                          if (studentPhoneNorm.isNotEmpty &&
                              p.studentPhone.isNotEmpty &&
                              LibraryService.normalizePhone(p.studentPhone) == studentPhoneNorm) {
                            return true;
                          }
                          return false;
                        }).toList();

                        studentPayments.sort((a, b) => b.date.compareTo(a.date));
                        final totalPaid = studentPayments.fold<int>(0, (sum, p) => sum + p.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Payment History',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${studentPayments.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0D9488),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  icon: const Icon(Icons.add_card_rounded, size: 16),
                                  label: const Text(
                                    'Collect Fee',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  onPressed: _showRecordPaymentSheet,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (studentPayments.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 38,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No transaction history yet',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No payments have been recorded for ${_student.name}.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D9488),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: const Text(
                                        'Collect First Payment',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: _showRecordPaymentSheet,
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              // Total summary banner
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TOTAL COLLECTED',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹$totalPaid',
                                          style: const TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 36,
                                      width: 1,
                                      color: const Color(0xFF334155),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'TRANSACTIONS',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${studentPayments.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 36,
                                      width: 1,
                                      color: const Color(0xFF334155),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'LAST PAID',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yy').format(studentPayments.first.date),
                                          style: const TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Payment cards list
                              ...studentPayments.map((p) => _buildPaymentItemCard(p)),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StudentInfo st) {
    if (st.status == 'INACTIVE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Text('● INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
      );
    }
    if (st.status == 'TRIAL') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text('● TRIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
      );
    }
    if (st.hasDues) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: const Text('● DUES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE11D48))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Text('● ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
    );
  }

  Widget _statCard({
    required String topText,
    required String bottomText,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(
            topText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textColor ?? AppColors.textNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bottomText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _membershipItem({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0D9488), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 3),
                valueWidget,
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _personalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconBgColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor ?? const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor ?? const Color(0xFF0D9488), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textNavy,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _phoneActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Color? bgColor,
    Color? borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor ?? const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppColors.textNavy),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textColor ?? AppColors.textNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTimelineCard(String enrolledDateStr) {
    final noteLines = _student.note
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_student.hasDues) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pending Dues: ₹${_student.effectiveDues} due for active membership',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (noteLines.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.event_note_outlined, size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    const Text(
                      'No activity notes recorded yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _showAddNoteDialog,
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(noteLines.length, (index) {
              final rawLine = noteLines[index];
              var line = rawLine;
              while (line.startsWith('•')) {
                line = line.substring(1).trim();
              }

              final lower = line.toLowerCase();
              IconData icon = Icons.notes_rounded;
              Color iconColor = const Color(0xFF64748B);
              Color bgColor = const Color(0xFFF8FAFC);
              String title = 'REMARK / NOTE';

              if (lower.contains('admission') || lower.contains('admitted')) {
                icon = Icons.how_to_reg_rounded;
                iconColor = const Color(0xFF0284C7);
                bgColor = const Color(0xFFF0F9FF);
                title = 'ADMISSION';
              } else if (lower.contains('shift')) {
                icon = Icons.swap_calls_rounded;
                iconColor = const Color(0xFF4F46E5);
                bgColor = const Color(0xFFEEF2FF);
                title = lower.contains('downgrade')
                    ? 'SHIFT DOWNGRADE'
                    : (lower.contains('upgrade') ? 'SHIFT UPGRADE' : 'SHIFT CHANGE');
              } else if (lower.contains('seat')) {
                icon = Icons.chair_alt_rounded;
                iconColor = const Color(0xFF0D9488);
                bgColor = const Color(0xFFF0FDFA);
                title = lower.contains('vacated') || lower.contains('unassigned')
                    ? 'SEAT VACATED'
                    : 'SEAT UPDATE';
              } else if (lower.contains('due payment') || (lower.contains('payment') && lower.contains('due'))) {
                icon = Icons.pending_actions_rounded;
                iconColor = const Color(0xFFE11D48);
                bgColor = const Color(0xFFFFF1F2);
                title = 'DUE PAYMENT';
              } else if (lower.contains('payment') || lower.contains('fee')) {
                icon = Icons.payments_rounded;
                iconColor = const Color(0xFF059669);
                bgColor = const Color(0xFFECFDF5);
                title = 'FEE PAYMENT';
              } else if (lower.contains('inactive')) {
                icon = Icons.person_off_rounded;
                iconColor = const Color(0xFFEF4444);
                bgColor = const Color(0xFFFEF2F2);
                title = 'MEMBER DEACTIVATED';
              } else if (lower.contains('reactivate')) {
                icon = Icons.person_add_rounded;
                iconColor = const Color(0xFF16A34A);
                bgColor = const Color(0xFFF0FDF4);
                title = 'MEMBER REACTIVATED';
              } else if (lower.contains('photo')) {
                icon = Icons.camera_alt_rounded;
                iconColor = const Color(0xFF0891B2);
                bgColor = const Color(0xFFECFEFF);
                title = 'PHOTO UPDATE';
              } else if (lower.contains('trial')) {
                icon = Icons.timer_outlined;
                iconColor = const Color(0xFFD97706);
                bgColor = const Color(0xFFFFFBEB);
                title = 'TRIAL STATUS';
              } else if (lower.contains('dues')) {
                icon = Icons.pending_actions_rounded;
                iconColor = const Color(0xFFE11D48);
                bgColor = const Color(0xFFFFF1F2);
                title = 'PENDING DUES';
              }

              return _buildNoteActivityItem(
                icon: icon,
                iconColor: iconColor,
                bgColor: bgColor,
                title: title,
                content: line,
                isLast: index == noteLines.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNoteActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textNavy,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceipt(PaymentTransaction p) async {
    final seatText = p.seatNumber != null ? 'S-${p.seatNumber}' : 'Unassigned';
    final text = '🏛️ *${_service.profile.libraryName}*\n'
        '📄 *FEE PAYMENT RECEIPT*\n'
        '--------------------------------\n'
        '👤 *Member:* ${_student.name}\n'
        '📱 *Phone:* ${_student.phone}\n'
        '🪑 *Seat:* $seatText (${p.shift})\n'
        '💰 *Amount Paid:* ₹${p.amount}\n'
        '💳 *Mode:* ${p.paymentMode}\n'
        '📅 *Date:* ${DateFormat('dd MMM yyyy, hh:mm a').format(p.date)}\n'
        '🔖 *Receipt ID:* ${p.id}\n'
        '${p.notes.trim().isNotEmpty ? '📝 *Notes:* ${p.notes}\n' : ''}'
        '--------------------------------\n'
        'Thank you for your payment! Please keep this receipt for your records.';
    final encoded = Uri.encodeComponent(text);
    final phoneClean = LibraryService.normalizePhone(_student.phone);
    final uri = phoneClean.isNotEmpty && phoneClean.length >= 10
        ? Uri.parse('https://wa.me/91$phoneClean?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildPaymentItemCard(PaymentTransaction p) {
    IconData modeIcon;
    Color modeColor;
    Color modeBg;

    final modeUpper = p.paymentMode.toUpperCase();
    if (modeUpper.contains('CASH')) {
      modeIcon = Icons.payments_rounded;
      modeColor = const Color(0xFF16A34A);
      modeBg = const Color(0xFFECFDF5);
    } else if (modeUpper.contains('CARD')) {
      modeIcon = Icons.credit_card_rounded;
      modeColor = const Color(0xFF8B5CF6);
      modeBg = const Color(0xFFF5F3FF);
    } else if (modeUpper.contains('BANK') || modeUpper.contains('CHEQUE')) {
      modeIcon = Icons.account_balance_rounded;
      modeColor = const Color(0xFFF59E0B);
      modeBg = const Color(0xFFFFFBEB);
    } else {
      modeIcon = Icons.qr_code_2_rounded;
      modeColor = const Color(0xFF0284C7);
      modeBg = const Color(0xFFF0F9FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Top row: Amount + Mode + Date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        '₹${p.amount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: modeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(modeIcon, size: 13, color: modeColor),
                          const SizedBox(width: 4),
                          Text(
                            p.paymentMode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: modeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(p.date),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // Second row: Seat & Shift, Receipt ID, WhatsApp share
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chair_alt_rounded, size: 14, color: Color(0xFF0D9488)),
                          const SizedBox(width: 4),
                          Text(
                            p.seatNumber != null ? 'Seat S-${p.seatNumber}' : 'Unallocated Seat',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.shift,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receipt ID: ${p.id.replaceAll('pay_', '')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Share Receipt on WhatsApp',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF16A34A)),
                  ),
                  onPressed: () => _shareReceipt(p),
                ),
              ],
            ),
          ),
          // Optional Notes / Remarks
          if (p.notes.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.notes.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                        height: 1.3,
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
  }
}
