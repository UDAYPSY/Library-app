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
    if (!_service.isAdmin) return; // Strict ownership enforcement: Only admin can toggle auto-backup
    await LocalStorageService.saveString(keyAutoBackupEnabled, enabled ? 'true' : 'false');
  }

  Future<String> getBackupEmail() async {
    final val = await LocalStorageService.getString(keyBackupEmail);
    if (val != null && val.trim().isNotEmpty) return val.trim();
    // Google Drive backup email belongs strictly to the Owner/Admin, never a staff member
    if (_service.profile.adminEmail.trim().isNotEmpty) {
      return _service.profile.adminEmail.trim();
    }
    if (_service.isAdmin && _service.currentUserEmail.trim().isNotEmpty) {
      return _service.currentUserEmail.trim();
    }
    return '';
  }

  Future<void> setBackupEmail(String email) async {
    if (!_service.isAdmin) return; // Strict ownership enforcement: Only admin can change Google Drive sync email
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

  String _escapeXml(dynamic value) {
    if (value == null) return '';
    return value
        .toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Generates a real multi-worksheet XML Spreadsheet 2003 (.xls) natively supported by Excel & Google Drive / Google Sheets
  String generateMasterExcelWorkbookXml() {
    _service.ensureInitialized();
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(now);
    final students = _service.currentStudents;
    final payments = _service.currentPayments;
    final expenses = _service.currentExpenses;
    final defaulters = students.where((s) => s.status != 'INACTIVE' && (s.hasDues || s.effectiveDues > 0)).toList();
    final fullJson = _service.exportFullBackupJson();
    final base64Payload = base64.encode(utf8.encode(fullJson));

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<?mso-application progid="Excel.Sheet"?>');
    buffer.writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    buffer.writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"');
    buffer.writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
    buffer.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"');
    buffer.writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">');

    // Styles
    buffer.writeln(' <Styles>');
    buffer.writeln('  <Style ss:ID="Default" ss:Name="Normal"><Alignment ss:Vertical="Center"/><Font ss:FontName="Calibri" ss:Size="11"/></Style>');
    buffer.writeln('  <Style ss:ID="HeaderTeal"><Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#0D9488" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>');
    buffer.writeln('  <Style ss:ID="HeaderGreen"><Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#15803D" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>');
    buffer.writeln('  <Style ss:ID="HeaderAmber"><Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#D97706" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>');
    buffer.writeln('  <Style ss:ID="HeaderSlate"><Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#475569" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>');
    buffer.writeln('  <Style ss:ID="MetaLabel"><Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#0F172A"/><Interior ss:Color="#F1F5F9" ss:Pattern="Solid"/><Alignment ss:Vertical="Center"/></Style>');
    buffer.writeln('  <Style ss:ID="NumberCell"><Alignment ss:Horizontal="Right" ss:Vertical="Center"/></Style>');
    buffer.writeln(' </Styles>');

    // Worksheet 1: Students & Members
    buffer.writeln(' <Worksheet ss:Name="Students &amp; Members">');
    buffer.writeln('  <Table>');
    buffer.writeln('   <Row ss:StyleID="HeaderGreen">');
    final sHeaders = ['Student ID', 'Full Name', 'Phone Number', 'Seat Number', 'Shift', 'Monthly Fee (INR)', 'Pending Dues (INR)', 'Joining Date', 'Fee Due Date', 'Status', 'Payment Mode', 'Address', 'Aadhaar / ID', 'Notes'];
    for (final h in sHeaders) {
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(h)}</Data></Cell>');
    }
    buffer.writeln('   </Row>');
    for (final s in students) {
      buffer.writeln('   <Row>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.id)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.name)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.phone)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.seatNumber != null ? "S-${s.seatNumber}" : "Unallocated")}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.shift)}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${s.monthlyFee}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${s.effectiveDues}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${s.joinedAt != null ? DateFormat("dd-MM-yyyy").format(s.joinedAt!) : "N/A"}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${s.feeDueDate != null ? DateFormat("dd-MM-yyyy").format(s.feeDueDate!) : "N/A"}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.status)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.paymentMode)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.address)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.aadhaarNumber)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(s.note)}</Data></Cell>');
      buffer.writeln('   </Row>');
    }
    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');

    // Worksheet 2: Fee Collections
    buffer.writeln(' <Worksheet ss:Name="Fee Collections">');
    buffer.writeln('  <Table>');
    buffer.writeln('   <Row ss:StyleID="HeaderTeal">');
    final pHeaders = ['Receipt ID', 'Date &amp; Time', 'Student Name', 'Phone', 'Seat Number', 'Shift', 'Amount (INR)', 'Payment Mode', 'Duration', 'Notes'];
    for (final h in pHeaders) {
      buffer.writeln('    <Cell><Data ss:Type="String">$h</Data></Cell>');
    }
    buffer.writeln('   </Row>');
    for (final p in payments) {
      buffer.writeln('   <Row>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.id)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${DateFormat("dd-MM-yyyy HH:mm").format(p.date)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.studentName)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.studentPhone)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.seatNumber != null ? "S-${p.seatNumber}" : "Unallocated")}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.shift)}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${p.amount}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.paymentMode)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${p.durationMonths != null ? "${p.durationMonths} Month(s)" : "Monthly"}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(p.notes)}</Data></Cell>');
      buffer.writeln('   </Row>');
    }
    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');

    // Worksheet 3: Pending Dues
    buffer.writeln(' <Worksheet ss:Name="Pending Dues &amp; Defaulters">');
    buffer.writeln('  <Table>');
    buffer.writeln('   <Row ss:StyleID="HeaderAmber">');
    final dHeaders = ['Student Name', 'Phone', 'Seat Number', 'Shift', 'Monthly Fee (INR)', 'Pending Dues (INR)', 'Due Date'];
    for (final h in dHeaders) {
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(h)}</Data></Cell>');
    }
    buffer.writeln('   </Row>');
    for (final d in defaulters) {
      buffer.writeln('   <Row>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(d.name)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(d.phone)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(d.seatNumber != null ? "S-${d.seatNumber}" : "Unallocated")}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(d.shift)}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${d.monthlyFee}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${d.effectiveDues}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${d.feeDueDate != null ? DateFormat("dd-MM-yyyy").format(d.feeDueDate!) : "N/A"}</Data></Cell>');
      buffer.writeln('   </Row>');
    }
    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');

    // Worksheet 4: Operating Expenses
    buffer.writeln(' <Worksheet ss:Name="Operating Expenses">');
    buffer.writeln('  <Table>');
    buffer.writeln('   <Row ss:StyleID="HeaderSlate">');
    final eHeaders = ['Expense ID', 'Date', 'Expense Title', 'Category', 'Amount (INR)', 'Payment Mode', 'Notes'];
    for (final h in eHeaders) {
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(h)}</Data></Cell>');
    }
    buffer.writeln('   </Row>');
    for (final e in expenses) {
      buffer.writeln('   <Row>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(e.id)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${DateFormat("dd-MM-yyyy").format(e.date)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(e.title)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(e.category)}</Data></Cell>');
      buffer.writeln('    <Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${e.amount}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(e.paymentMode)}</Data></Cell>');
      buffer.writeln('    <Cell><Data ss:Type="String">${_escapeXml(e.note)}</Data></Cell>');
      buffer.writeln('   </Row>');
    }
    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');

    // Worksheet 5: Disaster Recovery & Metadata
    buffer.writeln(' <Worksheet ss:Name="Disaster Recovery Payload">');
    buffer.writeln('  <Table>');
    buffer.writeln('   <Row ss:StyleID="HeaderTeal"><Cell><Data ss:Type="String">Configuration Parameter</Data></Cell><Cell><Data ss:Type="String">Value</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">Library Name</Data></Cell><Cell><Data ss:Type="String">${_escapeXml(_service.profile.libraryName)}</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">Export Timestamp</Data></Cell><Cell><Data ss:Type="String">$dateStr</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">Tenant ID</Data></Cell><Cell><Data ss:Type="String">${_escapeXml(_service.tenantId)}</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">Total Seats</Data></Cell><Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${_service.totalSeatsCount}</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">Registered Members</Data></Cell><Cell ss:StyleID="NumberCell"><Data ss:Type="Number">${students.length}</Data></Cell></Row>');
    buffer.writeln('   <Row><Cell ss:StyleID="MetaLabel"><Data ss:Type="String">SYSTEM_RESTORE_PAYLOAD</Data></Cell><Cell><Data ss:Type="String">$base64Payload</Data></Cell></Row>');
    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');

    buffer.writeln('</Workbook>');
    return buffer.toString();
  }

  /// Triggers backup creation and opens system save/share to Google Drive
  Future<bool> backupToGoogleDriveNow() async {
    try {
      final excelXml = generateMasterExcelWorkbookXml();
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'TrackMyLibrary_Master_Backup_$stamp.xls';
      final bytesLength = utf8.encode(excelXml).length;
      final sizeKb = (bytesLength / 1024).toStringAsFixed(1);

      final ok = await FileExportService.download(
        fileName: fileName,
        content: excelXml,
        mimeType: 'application/vnd.ms-excel;charset=utf-8',
      );

      if (ok) {
        final timeStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
        await LocalStorageService.saveString(keyLastBackupTime, timeStr);
        await LocalStorageService.saveString(keyLastBackupSize, '$sizeKb KB');
        await LocalStorageService.saveString(keyLastBackupStatus, 'Success (Multi-Sheet Excel)');
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

      // 2. Check if XML Spreadsheet (.xls) with embedded payload
      if (clean.contains('SYSTEM_RESTORE_PAYLOAD')) {
        final regex = RegExp(r'<Data ss:Type="String">([A-Za-z0-9+/=\r\n]{30,})</Data>');
        final match = regex.firstMatch(clean);
        if (match != null) {
          final payload = match.group(1)!.replaceAll('\r', '').replaceAll('\n', '').trim();
          final jsonString = utf8.decode(base64.decode(payload));
          return await _service.restoreFromBackupJson(jsonString);
        }
      }

      // 3. Check if Excel snapshot with embedded payload
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
