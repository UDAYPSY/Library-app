import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/library_models.dart';
import 'file_export_service.dart';
import 'library_service.dart';
import 'local_storage_service.dart';

class DisasterRecoveryService {
  final LibraryService _service;

  DisasterRecoveryService({LibraryService? service})
      : _service = service ?? LibraryService();

  static const String keyAutoBackupEnabled = 'gdrive_auto_backup_enabled';
  static const String keyBackupEmail = 'gdrive_backup_email';
  static const String keyLastBackupTime = 'gdrive_last_backup_time';
  static const String keyLastBackupSize = 'gdrive_last_backup_size';
  static const String keyLastBackupStatus = 'gdrive_last_backup_status';
  static const String keyLastSnapshotContent = 'gdrive_last_snapshot_content';

  Future<bool> isAutoBackupEnabled() async {
    final val = await LocalStorageService.getString(keyAutoBackupEnabled);
    return val == null || val == 'true';
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await LocalStorageService.saveString(keyAutoBackupEnabled, enabled ? 'true' : 'false');
  }

  Future<String> getBackupEmail() async {
    final val = await LocalStorageService.getString(keyBackupEmail);
    if (val != null && val.trim().isNotEmpty) return val.trim();
    return _service.currentUserEmail.isNotEmpty
        ? _service.currentUserEmail
        : _service.profile.adminEmail;
  }

  Future<void> setBackupEmail(String email) async {
    await LocalStorageService.saveString(keyBackupEmail, email.trim());
  }

  Future<String?> getLastBackupTime() async {
    return await LocalStorageService.getString(keyLastBackupTime);
  }

  Future<String?> getLastBackupSize() async {
    return await LocalStorageService.getString(keyLastBackupSize);
  }

  Future<String?> getLastBackupStatus() async {
    return await LocalStorageService.getString(keyLastBackupStatus);
  }

  Future<String?> getLatestAutoBackupContent() async {
    return await LocalStorageService.getString(keyLastSnapshotContent);
  }

  /// Runs background automated snapshot update without blocking UI
  Future<bool> runAutomatedBackupCycle({bool force = false}) async {
    final enabled = await isAutoBackupEnabled();
    if (!enabled && !force) return false;

    try {
      final snapshot = generateMasterExcelSnapshot();
      final now = DateTime.now();
      final bytesLength = utf8.encode(snapshot).length;
      final sizeKb = (bytesLength / 1024).toStringAsFixed(1);
      final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);

      await LocalStorageService.saveString(keyLastSnapshotContent, snapshot);
      await LocalStorageService.saveString(keyLastBackupTime, timeStr);
      await LocalStorageService.saveString(keyLastBackupSize, '$sizeKb KB');
      await LocalStorageService.saveString(keyLastBackupStatus, 'Auto-Synced (Excel)');

      return true;
    } catch (e) {
      await LocalStorageService.saveString(keyLastBackupStatus, 'Failed: $e');
      return false;
    }
  }

  String _cleanCsvField(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (str.contains(',') || str.contains('"') || str.contains(';')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Generates a rich, multi-section formatted master archive compatible with Excel & Google Sheets
  String generateMasterExcelSnapshot() {
    _service.ensureInitialized();
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(now);
    final students = _service.currentStudents;
    final payments = _service.currentPayments;
    final expenses = _service.currentExpenses;

    // Header banner
    buffer.writeln('# ==============================================================================');
    buffer.writeln('# TRACKMYLIBRARY MASTER DISASTER RECOVERY & AUDIT ARCHIVE');
    buffer.writeln('# Library: ${_service.profile.libraryName.toUpperCase()}');
    buffer.writeln('# Exported on: $dateStr');
    buffer.writeln('# Tenant Cloud ID: ${_service.tenantId}');
    buffer.writeln('# Admin Contact: ${_service.profile.adminEmail} | ${_service.profile.adminPhone}');
    buffer.writeln('# Capacity: ${_service.totalSeatsCount} Total Seats | Active Members: ${students.where((s) => s.status != 'INACTIVE').length}');
    buffer.writeln('# ==============================================================================\n');

    // SECTION 1: ALL REGISTERED STUDENTS
    buffer.writeln('### SECTION 1: ALL REGISTERED STUDENTS & MEMBERS ###');
    final studentHeaders = [
      'Student ID',
      'Full Name',
      'Phone Number',
      'Seat Number',
      'Study Shift',
      'Monthly Fee (INR)',
      'Pending Dues (INR)',
      'Joining Date',
      'Fee Due Date',
      'Status',
      'Payment Mode',
      'Address',
      'Aadhaar / ID',
      'Audit Trail Notes',
    ];
    buffer.writeln(studentHeaders.map(_cleanCsvField).join(','));
    for (final s in students) {
      buffer.writeln([
        s.id,
        s.name,
        s.phone,
        s.seatNumber != null ? 'S-${s.seatNumber}' : 'Unallocated',
        s.shift,
        s.monthlyFee,
        s.effectiveDues,
        s.joinedAt != null ? DateFormat('dd-MM-yyyy').format(s.joinedAt!) : 'N/A',
        s.feeDueDate != null ? DateFormat('dd-MM-yyyy').format(s.feeDueDate!) : 'N/A',
        s.status,
        s.paymentMode,
        s.address,
        s.aadhaarNumber,
        s.note,
      ].map(_cleanCsvField).join(','));
    }

    // SECTION 2: PAYMENT & FEE COLLECTION LEDGER
    buffer.writeln('\n### SECTION 2: PAYMENT & FEE COLLECTION TRANSACTIONS ###');
    final paymentHeaders = [
      'Receipt ID',
      'Date & Time',
      'Student Name',
      'Phone',
      'Seat Number',
      'Shift',
      'Amount Paid (INR)',
      'Payment Mode',
      'Tenure Period',
      'Transaction Notes',
    ];
    buffer.writeln(paymentHeaders.map(_cleanCsvField).join(','));
    for (final p in payments) {
      buffer.writeln([
        p.id,
        DateFormat('dd-MM-yyyy HH:mm').format(p.date),
        p.studentName,
        p.studentPhone,
        p.seatNumber != null ? 'S-${p.seatNumber}' : 'Unallocated',
        p.shift,
        p.amount,
        p.paymentMode,
        p.durationMonths != null ? '${p.durationMonths} Month(s)' : 'Monthly',
        p.notes,
      ].map(_cleanCsvField).join(','));
    }

    // SECTION 3: PENDING DUES & DEFAULTERS
    buffer.writeln('\n### SECTION 3: PENDING DUES & DEFAULTERS ###');
    final defaulters = students.where((s) => s.status != 'INACTIVE' && (s.hasDues || s.effectiveDues > 0)).toList();
    final dueHeaders = [
      'Student Name',
      'Phone',
      'Seat Number',
      'Shift',
      'Monthly Fee (INR)',
      'Pending Dues (INR)',
      'Due Date',
    ];
    buffer.writeln(dueHeaders.map(_cleanCsvField).join(','));
    for (final d in defaulters) {
      buffer.writeln([
        d.name,
        d.phone,
        d.seatNumber != null ? 'S-${d.seatNumber}' : 'Unallocated',
        d.shift,
        d.monthlyFee,
        d.effectiveDues,
        d.feeDueDate != null ? DateFormat('dd-MM-yyyy').format(d.feeDueDate!) : 'N/A',
      ].map(_cleanCsvField).join(','));
    }

    // SECTION 4: OPERATING EXPENSES
    buffer.writeln('\n### SECTION 4: OPERATING EXPENSES ###');
    final expenseHeaders = [
      'Expense ID',
      'Date',
      'Expense Title',
      'Category',
      'Amount (INR)',
      'Payment Mode',
      'Notes',
    ];
    buffer.writeln(expenseHeaders.map(_cleanCsvField).join(','));
    for (final e in expenses) {
      buffer.writeln([
        e.id,
        DateFormat('dd-MM-yyyy').format(e.date),
        e.title,
        e.category,
        e.amount,
        e.paymentMode,
        e.note,
      ].map(_cleanCsvField).join(','));
    }

    // SECTION 5: EMBEDDED LOSSLESS JSON FOR 1-CLICK SYSTEM RESTORE
    buffer.writeln('\n### SECTION 5: COMPLETE SYSTEM RESTORE PAYLOAD (BASE64) ###');
    final fullJson = _service.exportFullBackupJson();
    final base64Payload = base64.encode(utf8.encode(fullJson));
    buffer.writeln('# SYSTEM_RESTORE_PAYLOAD_BEGIN');
    buffer.writeln(base64Payload);
    buffer.writeln('# SYSTEM_RESTORE_PAYLOAD_END');

    return buffer.toString();
  }

  /// Triggers backup creation and opens system save/share to Google Drive
  Future<bool> backupToGoogleDriveNow() async {
    try {
      final snapshot = generateMasterExcelSnapshot();
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'TrackMyLibrary_Backup_$stamp.csv';
      final bytesLength = utf8.encode(snapshot).length;
      final sizeKb = (bytesLength / 1024).toStringAsFixed(1);

      final ok = await FileExportService.download(
        fileName: fileName,
        content: snapshot,
        mimeType: 'text/csv;charset=utf-8',
      );

      if (ok) {
        final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
        await LocalStorageService.saveString(keyLastBackupTime, timeStr);
        await LocalStorageService.saveString(keyLastBackupSize, '$sizeKb KB');
        await LocalStorageService.saveString(keyLastBackupStatus, 'Success');
      }
      return ok;
    } catch (e) {
      await LocalStorageService.saveString(keyLastBackupStatus, 'Failed: $e');
      return false;
    }
  }

  /// One-click cloud re-sync from Google Cloud Firestore
  Future<Map<String, dynamic>> restoreFromFirestoreCloud() async {
    _service.ensureInitialized();
    if (!_service.isFirebaseConnected) {
      return {
        'success': false,
        'message': 'Cloud Firebase is not connected on this device.',
      };
    }

    try {
      final studentsSnap = await _service.db.collection('libraries').doc(_service.tenantId).collection('students').get();
      final paymentsSnap = await _service.db.collection('libraries').doc(_service.tenantId).collection('payments').get();
      final expensesSnap = await _service.db.collection('libraries').doc(_service.tenantId).collection('expenses').get();
      final profileSnap = await _service.db.collection('libraries').doc(_service.tenantId).collection('settings').doc('branding').get();

      int studentCount = 0;
      if (studentsSnap.docs.isNotEmpty) {
        final list = studentsSnap.docs.map((d) => StudentInfo.fromFirestore(d.id, d.data())).toList();
        _service.mockStudentsList.clear();
        _service.mockStudentsList.addAll(list);
        _service.syncSeatsWithStudents();
        _service.notifyStudentsChanged();
        studentCount = list.length;
      }

      int paymentCount = 0;
      if (paymentsSnap.docs.isNotEmpty) {
        final list = paymentsSnap.docs.map((d) => PaymentTransaction.fromFirestore(d.id, d.data())).toList();
        _service.mockPaymentsList.clear();
        _service.mockPaymentsList.addAll(list);
        _service.notifyPaymentsChanged();
        paymentCount = list.length;
      }

      int expenseCount = 0;
      if (expensesSnap.docs.isNotEmpty) {
        final list = expensesSnap.docs.map((d) => ExpenseItem.fromFirestore(d.id, d.data())).toList();
        _service.mockExpensesList.clear();
        _service.mockExpensesList.addAll(list);
        _service.notifyExpensesChanged();
        expenseCount = list.length;
      }

      if (profileSnap.exists && profileSnap.data() != null) {
        _service.profile = LibraryProfile.fromMap(profileSnap.data()!);
      }

      await _service.saveLocalState();

      return {
        'success': true,
        'studentCount': studentCount,
        'paymentCount': paymentCount,
        'expenseCount': expenseCount,
        'message': 'Successfully restored $studentCount students, $paymentCount payments, and $expenseCount expenses from Cloud Firestore!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cloud re-sync failed: $e',
      };
    }
  }

  /// Restores complete database from raw backup content (JSON or Excel Snapshot with embedded payload)
  Future<Map<String, dynamic>> restoreFromBackupContent(String rawContent) async {
    _service.ensureInitialized();
    final clean = rawContent.trim();
    if (clean.isEmpty) {
      return {'success': false, 'error': 'Backup content cannot be empty.'};
    }

    try {
      // 1. Check if raw JSON directly
      if (clean.startsWith('{') && clean.endsWith('}')) {
        return await _service.restoreFromBackupJson(clean);
      }

      // 2. Check if Excel snapshot with embedded payload
      if (clean.contains('# SYSTEM_RESTORE_PAYLOAD_BEGIN') && clean.contains('# SYSTEM_RESTORE_PAYLOAD_END')) {
        final startIndex = clean.indexOf('# SYSTEM_RESTORE_PAYLOAD_BEGIN') + '# SYSTEM_RESTORE_PAYLOAD_BEGIN'.length;
        final endIndex = clean.indexOf('# SYSTEM_RESTORE_PAYLOAD_END');
        final base64Payload = clean.substring(startIndex, endIndex).replaceAll('\r', '').replaceAll('\n', '').trim();
        final jsonString = utf8.decode(base64.decode(base64Payload));
        return await _service.restoreFromBackupJson(jsonString);
      }

      return {
        'success': false,
        'error': 'Unrecognized backup format. Please provide a valid TrackMyLibrary backup file or JSON.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to parse backup content: $e'};
    }
  }
}
