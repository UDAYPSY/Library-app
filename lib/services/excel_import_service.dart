import '../models/library_models.dart';
import 'library_service.dart';

class ExcelImportResult {
  final int totalRows;
  final int successfullyImported;
  final int skippedRows;
  final List<String> warnings;
  final List<String> errorMessages;

  ExcelImportResult({
    required this.totalRows,
    required this.successfullyImported,
    required this.skippedRows,
    required this.warnings,
    required this.errorMessages,
  });
}

class ExcelImportService {
  /// Generates a standard CSV template for library owners to fill in Excel
  /// Includes optional columns for migrating existing ongoing library registers.
  static String generateTemplateCsv() {
    return 'Full Name,Phone Number,Shift,Seat Number,Monthly Fee,Father Name,Address,Joining Date,Next Fee Due Date,Past Dues\n'
        'Aarav Sharma,9876543210,Full Day,1,800,Ramesh Sharma,Patna Bihar,15-08-2026,18-11-2026,0\n'
        'Priya Singh,9812345678,Morning,2,500,Vijay Singh,Boring Road Patna,01-09-2026,12-11-2026,200\n'
        'Rohan Verma,9988776655,Evening,,500,Suresh Verma,Kankarbagh Patna,10-10-2026,10-11-2026,0\n';
  }

  /// Parses date strings in various formats: dd-MM-yyyy, dd/MM/yyyy, yyyy-MM-dd
  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final parts = clean.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        // yyyy-MM-dd
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      } else {
        // dd-MM-yyyy or dd/MM/yyyy
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.tryParse(clean);
  }

  /// Parses CSV or TSV text pasted/uploaded from Microsoft Excel or Google Sheets
  static ExcelImportResult parseAndImport(String input, LibraryService service) {
    final lines = input.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return ExcelImportResult(
        totalRows: 0,
        successfullyImported: 0,
        skippedRows: 0,
        warnings: [],
        errorMessages: ['Provided Excel text is empty.'],
      );
    }

    final warnings = <String>[];
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;

    // Detect if first line is a header
    int startIndex = 0;
    final firstLineLower = lines[0].toLowerCase();
    if (firstLineLower.contains('name') || firstLineLower.contains('phone') || firstLineLower.contains('student')) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final fields = _splitLine(line);

      if (fields.isEmpty || fields.every((f) => f.isEmpty)) {
        skipped++;
        continue;
      }

      final name = fields.isNotEmpty ? fields[0].trim() : '';
      if (name.isEmpty) {
        errors.add('Row ${i + 1}: Student name is missing.');
        skipped++;
        continue;
      }

      final rawPhone = fields.length > 1 ? fields[1].trim() : '';
      final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length < 10) {
        errors.add('Row ${i + 1} ($name): Phone number must have at least 10 digits.');
        skipped++;
        continue;
      }

      // Shift
      String shift = 'Full Day';
      if (fields.length > 2 && fields[2].trim().isNotEmpty) {
        final rawShift = fields[2].trim().toLowerCase();
        if (rawShift.contains('morn')) {
          shift = 'Morning';
        } else if (rawShift.contains('even')) {
          shift = 'Evening';
        } else if (rawShift.contains('night')) {
          shift = 'Night';
        } else {
          shift = 'Full Day';
        }
      }

      // Seat Number
      int? seatNum;
      if (fields.length > 3 && fields[3].trim().isNotEmpty) {
        final rawSeat = fields[3].replaceAll(RegExp(r'[^0-9]'), '');
        final parsed = int.tryParse(rawSeat);
        if (parsed != null && parsed >= 1 && parsed <= service.totalSeatsCount) {
          if (service.isSeatOccupied(parsed)) {
            warnings.add('Row ${i + 1} ($name): Seat #S-$parsed already occupied. Registered as unallocated seat.');
            seatNum = null;
          } else {
            seatNum = parsed;
          }
        } else if (parsed != null) {
          warnings.add('Row ${i + 1} ($name): Seat #$parsed exceeds total seats (${service.totalSeatsCount}). Saved as unallocated.');
          seatNum = null;
        }
      }

      // Monthly Fee
      int monthlyFee = 800;
      if (fields.length > 4 && fields[4].trim().isNotEmpty) {
        final rawFee = fields[4].replaceAll(RegExp(r'[^0-9]'), '');
        final parsed = int.tryParse(rawFee);
        if (parsed != null && parsed > 0) {
          monthlyFee = parsed;
        }
      }

      // Father Name & Address
      final fatherName = fields.length > 5 ? fields[5].trim() : '';
      final address = fields.length > 6 ? fields[6].trim() : '';

      // Optional Ongoing Library Migration Fields:
      // Column 7: Joining Date (e.g. 15-08-2026)
      final rawJoiningDate = fields.length > 7 ? fields[7].trim() : '';
      final parsedJoiningDate = _parseDate(rawJoiningDate);
      final effectiveJoiningDate = parsedJoiningDate ?? DateTime.now();

      // Column 8: Next Fee Due Date (e.g. 18-11-2026)
      final rawNextDueDate = fields.length > 8 ? fields[8].trim() : '';
      final parsedNextDueDate = _parseDate(rawNextDueDate);
      final effectiveDueDate = parsedNextDueDate ??
          DateTime(effectiveJoiningDate.year, effectiveJoiningDate.month + 1, effectiveJoiningDate.day);

      // Column 9: Previous Past Dues (e.g. 500)
      int pastDues = 0;
      if (fields.length > 9 && fields[9].trim().isNotEmpty) {
        final rawDues = fields[9].replaceAll(RegExp(r'[^0-9]'), '');
        final parsed = int.tryParse(rawDues);
        if (parsed != null && parsed > 0) {
          pastDues = parsed;
        }
      }

      // Calculate initial status
      final now = DateTime.now();
      String status = 'Active';
      if (pastDues > 0) {
        status = 'DUES';
      } else if (effectiveDueDate.isBefore(now)) {
        status = 'DUES';
      }

      final note = (parsedNextDueDate != null || pastDues > 0 || parsedJoiningDate != null)
          ? 'Onboarded from paper register (Next Due: ${effectiveDueDate.day}-${effectiveDueDate.month}-${effectiveDueDate.year}${pastDues > 0 ? ", Past Dues: ₹$pastDues" : ""}).'
          : '';

      final newStudent = StudentInfo(
        id: 'STD-${DateTime.now().millisecondsSinceEpoch}-${i + 1}',
        name: name,
        phone: cleanPhone,
        shift: shift,
        seatNumber: seatNum,
        monthlyFee: monthlyFee,
        status: status,
        joinedAt: effectiveJoiningDate,
        feeDueDate: effectiveDueDate,
        duesAmount: pastDues,
        note: note,
        fatherName: fatherName,
        address: address,
      );

      service.addStudent(newStudent);
      imported++;
    }

    return ExcelImportResult(
      totalRows: lines.length - startIndex,
      successfullyImported: imported,
      skippedRows: skipped,
      warnings: warnings,
      errorMessages: errors,
    );
  }

  static List<String> _splitLine(String line) {
    // Check if line is Tab-Separated (direct copy-paste from Excel)
    if (line.contains('\t')) {
      return line.split('\t').map((s) => s.trim()).toList();
    }

    // Otherwise standard CSV with quotes
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }
}
