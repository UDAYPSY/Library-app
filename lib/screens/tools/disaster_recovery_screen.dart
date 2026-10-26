import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/disaster_recovery_service.dart';
import '../../services/library_service.dart';

class DisasterRecoveryScreen extends StatefulWidget {
  const DisasterRecoveryScreen({super.key});

  @override
  State<DisasterRecoveryScreen> createState() => _DisasterRecoveryScreenState();
}

class _DisasterRecoveryScreenState extends State<DisasterRecoveryScreen> {
  final LibraryService _service = LibraryService();
  late final DisasterRecoveryService _recoveryService;

  bool _isLoading = false;
  bool _isAutoBackupEnabled = true;
  String _backupEmail = '';
  String? _lastBackupTime;
  String? _lastBackupSize;
  String? _lastBackupStatus;

  @override
  void initState() {
    super.initState();
    _recoveryService = DisasterRecoveryService(service: _service);
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final auto = await _recoveryService.isAutoBackupEnabled();
    final email = await _recoveryService.getBackupEmail();
    final time = await _recoveryService.getLastBackupTime();
    final size = await _recoveryService.getLastBackupSize();
    final status = await _recoveryService.getLastBackupStatus();

    if (mounted) {
      setState(() {
        _isAutoBackupEnabled = auto;
        _backupEmail = email;
        _lastBackupTime = time;
        _lastBackupSize = size;
        _lastBackupStatus = status;
      });
    }
  }

  Future<void> _toggleAutoBackup(bool val) async {
    setState(() => _isAutoBackupEnabled = val);
    await _recoveryService.setAutoBackupEnabled(val);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? 'Automatic Google Drive sync scheduled for daily export.'
                : 'Automatic sync paused. Manual backup remains active anytime.',
          ),
          backgroundColor: AppColors.primaryIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditEmailDialog() {
    final emailCtrl = TextEditingController(text: _backupEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: AppColors.primaryIndigo),
            SizedBox(width: 10),
            Text('Backup Google Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Google Drive account / Gmail address where you want daily Excel recovery snapshots archived:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Google Account / Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newEmail = emailCtrl.text.trim();
              if (newEmail.isNotEmpty) {
                await _recoveryService.setBackupEmail(newEmail);
                setState(() => _backupEmail = newEmail);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackupNow() async {
    setState(() => _isLoading = true);
    try {
      final success = await _recoveryService.backupToGoogleDriveNow();
      await _loadBackupSettings();
      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Backup Exported!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your master disaster recovery archive has been generated and prepared for Google Drive sync.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📁 File: TrackMyLibrary_Backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('👥 Registered Members: ${_service.currentStudents.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('💰 Payment Records: ${_service.currentPayments.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('📊 Operating Expenses: ${_service.currentExpenses.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'On Android, select "Save to Drive" in the share sheet to upload this directly to your personal Google Drive folder.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK, Got It'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate backup snapshot. Please check device storage permissions.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmCloudReSync() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB), size: 28),
            SizedBox(width: 10),
            Text('1-Click Cloud Re-sync', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will query Google Cloud Firestore for your isolated tenant library and synchronize all students, payment receipts, expenses, and settings down to this device.',
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            SizedBox(height: 10),
            Text(
              '⚠️ Use this if you switched devices or reinstalled the app and want your live cloud database restored in one click.',
              style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeCloudReSync();
            },
            child: const Text('Start Cloud Re-sync'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeCloudReSync() async {
    setState(() => _isLoading = true);
    try {
      final res = await _recoveryService.restoreFromFirestoreCloud();
      if (!mounted) return;

      if (res['success'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Text('Cloud Re-sync Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              res['message']?.toString() ?? 'All records have been synchronized from Google Cloud Firestore.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Cloud re-sync failed.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFileRestoreModal() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                    'Restore from Backup File',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textNavy),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Open your downloaded TrackMyLibrary Excel/CSV file or JSON backup archive, copy all content, and paste it below for instant lossless restoration:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textCtrl,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste complete CSV or JSON backup content here...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: const Text('Confirm & Restore Database', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final raw = textCtrl.text.trim();
                    if (raw.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please paste your backup content.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      final result = await _recoveryService.restoreFromBackupContent(raw);
                      if (!mounted) return;

                      if (result['success'] == true) {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                                SizedBox(width: 10),
                                Text('Restoration Successful!'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Students Restored: ${result['students'] ?? 0}'),
                                Text('Payments Restored: ${result['payments'] ?? 0}'),
                                Text('Expenses Restored: ${result['expenses'] ?? 0}'),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your library database has been fully restored to its exact previous state.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryIndigo,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(c);
                                  setState(() {});
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['error']?.toString() ?? 'Restore failed.'),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = _service.currentStudents;
    final payments = _service.currentPayments;
    final expenses = _service.currentExpenses;
    final isConnected = _service.isFirebaseConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Google Drive & Disaster Recovery',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textNavy,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: _loadBackupSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryIndigo),
                  SizedBox(height: 16),
                  Text('Processing disaster recovery operation...',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO STATUS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    '100% DISASTER-PROOF',
                                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isConnected ? const Color(0xFF22C55E).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: isConnected ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isConnected ? 'Cloud Live' : 'Offline Cache',
                                    style: TextStyle(
                                      color: isConnected ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _service.profile.libraryName.isNotEmpty ? _service.profile.libraryName : 'TrackMyLibrary',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Cloud Tenant UID: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            Expanded(
                              child: Text(
                                _service.tenantId,
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _service.tenantId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tenant UID copied to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _statChip('Students', '${students.length}', const Color(0xFF38BDF8)),
                            const SizedBox(width: 8),
                            _statChip('Payments', '${payments.length}', const Color(0xFF34D399)),
                            const SizedBox(width: 8),
                            _statChip('Expenses', '${expenses.length}', const Color(0xFFFBBF24)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // GOOGLE DRIVE EXCEL SYNC CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_to_drive_rounded, color: Color(0xFFD97706), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Google Drive Auto-Sync', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textNavy)),
                                  Text('Daily multi-sheet Excel spreadsheet export', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isAutoBackupEnabled,
                              activeColor: const Color(0xFFD97706),
                              onChanged: _toggleAutoBackup,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Backup Account:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            InkWell(
                              onTap: _showEditEmailDialog,
                              child: Row(
                                children: [
                                  Text(
                                    _backupEmail.isNotEmpty ? _backupEmail : 'Set Google Account',
                                    style: const TextStyle(fontSize: 13, color: AppColors.primaryIndigo, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryIndigo),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Last Backup:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            Text(
                              _lastBackupTime != null ? '$_lastBackupTime (${_lastBackupSize ?? ''})' : 'Not yet backed up',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                        if (_lastBackupStatus != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _lastBackupStatus == 'Success' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _lastBackupStatus!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _lastBackupStatus == 'Success' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: const Text('Backup to Google Drive Now (Excel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: _handleBackupNow,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // RECOVERY ACTIONS
                  const Text('DISASTER RECOVERY OPTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
                  const SizedBox(height: 10),

                  // 1-CLICK CLOUD RE-SYNC
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.cloud_download_rounded, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('1-Click Cloud Re-sync', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textNavy)),
                                  Text('Restore database from Google Cloud Firestore', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'If you cleared your phone cache or logged in on a new device, click below to re-download all student profiles, payment ledgers, and seat configs from your isolated cloud storage.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('Synchronize from Cloud Now', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _confirmCloudReSync,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // RESTORE FROM EXCEL / FILE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFDC2626)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Restore from Backup File', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textNavy)),
                                  Text('Lossless import from Excel / CSV snapshot', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upload or paste any previous TrackMyLibrary CSV or JSON backup to reconstruct your entire library database with 100% fidelity.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Paste & Restore Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _showFileRestoreModal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DISASTER-PROOF ARCHITECTURE ACCORDION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF1D4ED8), size: 20),
                            SizedBox(width: 8),
                            Text('Disaster-Proof Architecture', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _guaranteeRow(Icons.check_circle_outline, 'Human-Readable Excel: Can be opened and reviewed on any PC or phone.'),
                        _guaranteeRow(Icons.check_circle_outline, 'Machine-Restorable: Base64 system state embedded in every snapshot.'),
                        _guaranteeRow(Icons.check_circle_outline, 'Multi-Tenant Isolated: Bound to your unique Firebase Auth UID.'),
                        _guaranteeRow(Icons.check_circle_outline, 'Zero Data Loss: All past transaction IDs, dues, dates, and shifts preserved.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _guaranteeRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
