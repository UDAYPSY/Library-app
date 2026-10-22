# TrackMyLibrary — Technical Architecture & Engineering Specification

> **System Name:** TrackMyLibrary (Digital Library & Self-Study Room Operating System)  
> **Core Framework:** Flutter 3.24+ / Dart 3.3+ (Material Design 3)  
> **Architecture Pattern:** Hybrid Offline-First Reactive Streaming with Conditional Compilation  
> **Production Target:** Android APK / AAB, Web (PWA CanvasKit/HTML), Desktop  
> **Repository Location:** [TECHNICAL_ARCHITECTURE.md](file:///d:/Tutorial/Library-app/TECHNICAL_ARCHITECTURE.md)

---

## 1. System Architecture Overview

TrackMyLibrary employs a **Dual-Execution, Offline-First Reactive Architecture**. The application is designed to function completely offline on local device storage while seamlessly connecting to Google Cloud Firestore when cloud connectivity is present.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       APPLICATION ARCHITECTURE LAYERS                       │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                           PRESENTATION LAYER                            │
  │  • Seat Visual Grid      • Student KYC Wizard    • Digital ID Pass Card │
  │  • Financial Ledger Screen • Reports & Exports    • Settings & Branches  │
  └────────────────────────────────────┬────────────────────────────────────┘
                                       │ Watches Streams / Invokes Actions
                                       ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                     SERVICE & STATE MANAGEMENT LAYER                    │
  │  • LibraryService (Singleton, Reactive StreamControllers)               │
  │  • ExcelImportService (Regex CSV/TSV Clipboard Parser)                   │
  │  • FileExportService (Conditional Compilation: Web Blob vs Mobile IO)   │
  └──────────────────┬───────────────────────────────────┬──────────────────┘
                     │                                   │
      Offline Branch │ Local Persistence                 │ Cloud Sync
                     ▼                                   ▼
  ┌─────────────────────────────────────┐  ┌────────────────────────────────┐
  │        OFFLINE STORAGE LAYER        │  │       CLOUD FIREBASE LAYER     │
  │ • LocalStorageService (Conditional) │  │ • Cloud Firestore (NoSQL)     │
  │   - Web: window.localStorage        │  │ • Atomic Batch / Transactions  │
  │   - Mobile/IO: SharedPreferences    │  │ • Firestore Security Rules     │
  │ • JSON Disaster Recovery Snapshots  │  │ • Firebase Authentication      │
  └─────────────────────────────────────┘  └────────────────────────────────┘
```

---

## 2. Technology Stack & Key Dependencies

| Component | Library / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | `flutter` (Dart SDK `>=3.3.0 <4.0.0`) | Cross-platform core framework |
| **Cloud Database** | `cloud_firestore: ^5.4.4` | Real-time multi-device cloud synchronization |
| **Cloud Auth** | `firebase_auth: ^5.3.1` | User authentication & permission security |
| **Firebase Core** | `firebase_core: ^3.6.0` | Firebase project runtime connection |
| **QR Code Engine** | `qr_flutter: ^4.1.0` | Vector rendering of dynamic membership verification QR codes |
| **Media Capture** | `image_picker: ^1.1.2` | Native camera & gallery photo capture for member KYC |
| **Date Formatting** | `intl: ^0.19.0` | Dynamic currency, date, and Indian locale formatting |
| **External Intent** | `url_launcher: ^6.3.0` | WhatsApp URI deep-linking (`https://wa.me/...`) |
| **Testing** | `flutter_test` & `flutter_lints` | Unit, integration tests, and static code analysis |

---

## 3. Data Models & Entity Schema Design

All domain models are located in [lib/models/library_models.dart](file:///d:/Tutorial/Library-app/lib/models/library_models.dart).

### A. `StudentInfo` (Member Entity)
Represents a registered library member.
```dart
class StudentInfo {
  final String id;                  // Unique identifier (UUID or std_<timestamp>)
  final String name;                // Full name
  final String phone;               // Normalized 10-digit mobile number
  final int? seatNumber;            // Assigned physical seat (1..N) or null
  final String shift;               // 'Full Day', 'Morning', 'Evening', 'Night'
  final String status;              // 'ACTIVE', 'DUES', 'INACTIVE', 'TRIAL'
  final DateTime? feeDueDate;       // Next renewal deadline
  final DateTime? joinedAt;         // Enrollment timestamp
  final int monthlyFee;             // Agreed monthly fee rate (INR)
  final int duesAmount;             // Outstanding balance (INR)
  final String paymentMode;         // 'UPI', 'Cash', 'Card', 'Bank Transfer'
  final String note;                // Internal remarks
  final String fatherName;          // KYC: Father / Guardian name
  final String address;             // KYC: Permanent or local address
  final String aadhaarNumber;       // KYC: 12-digit Indian national ID
  final String preparationFor;      // Exam goal (e.g. UPSC, NEET, SSC)
  final String gender;              // 'Male', 'Female', 'Other'
  final String? photoBase64;        // Client-side compressed Base64 JPEG
  final String? sectionName;        // Hall or zone partition
}
```
**Derived Computations**:
- `effectiveDues`: Computes real-time dues based on `duesAmount` or `feeDueDate` lapse.
- `isDuesOverdue`: Boolean flag if current timestamp exceeds `feeDueDate`.
- `daysUntilDue`: Integer count of days remaining before expiration.

### B. `SeatInfo` (Physical Desk Entity)
Represents a physical workstation in the library.
```dart
class SeatInfo {
  final int seatNumber;             // 1-indexed seat number
  final bool isOccupied;            // Allocation flag
  final String studentId;           // Associated StudentInfo.id
  final String studentName;         // Cached name for fast UI rendering
  final String shift;               // Active shift for this seat
  final String sectionName;         // e.g. 'Main Reading Hall'
  final String lastUpdatedBy;       // Audit trail: Staff ID who modified seat
}
```

### C. `PaymentTransaction` (Financial Audit Entity)
```dart
class PaymentTransaction {
  final String id;                  // Unique receipt number (pay_<timestamp>)
  final String studentId;           // Target member ID
  final String studentName;         // Target member name
  final String studentPhone;        // Target member phone
  final int? seatNumber;            // Associated seat
  final String shift;               // Shift during payment
  final int amount;                 // Collected amount in INR
  final DateTime date;              // Timestamp of collection
  final DateTime? validUntil;       // Membership extended validity
  final String paymentMode;         // 'UPI', 'Cash', 'Card'
  final String collectedBy;         // Staff username who collected
  final String notes;               // Transaction notes
}
```

### D. `ExpenseItem` (Operating Cost Entity)
```dart
class ExpenseItem {
  final String id;                  // exp_<timestamp>
  final String title;               // e.g. 'High-Speed Broadband Bill'
  final String category;            // 'Utilities', 'Rent', 'Maintenance', etc.
  final int amount;                 // Expense in INR
  final DateTime date;              // Payment date
  final String paymentMode;         // 'UPI', 'Cash'
  final String note;                // Vendor / receipt info
}
```

### E. `LibraryBranch` & `StaffMember` (Multi-Tenancy & RBAC)
```dart
class LibraryBranch {
  final String id;                  // Branch identifier
  final String name;                // e.g. 'Floor 2 AC Hall'
  final String address;             // Physical branch location
  final int totalSeats;             // Capacity for this branch
}

class StaffMember {
  final String id;                  // staff_<timestamp>
  final String name;                // Staff member full name
  final String phone;               // Staff mobile number
  final String role;                // 'Admin' (all access) or 'Receptionist' (desk check-in)
  final bool isActive;              // Operational status flag
  final DateTime createdAt;         // Creation timestamp
}
```

---

## 4. Reactive State Management & Concurrency Control

All core business logic is centralized in **[lib/services/library_service.dart](file:///d:/Tutorial/Library-app/lib/services/library_service.dart)**.

### Broadcast Streams Pattern
The service exposes broadcast streams that UI widgets subscribe to via `StreamBuilder`:
```dart
static final StreamController<List<StudentInfo>> _mockStudentsController = 
    StreamController<List<StudentInfo>>.broadcast();
static final StreamController<List<SeatInfo>> _mockSeatsController = 
    StreamController<List<SeatInfo>>.broadcast();
static final StreamController<List<PaymentTransaction>> _mockPaymentsController = 
    StreamController<List<PaymentTransaction>>.broadcast();
static final StreamController<List<ExpenseItem>> _mockExpensesController = 
    StreamController<List<ExpenseItem>>.broadcast();
```

### 1-to-1 Seat Collision Locking Algorithm
To prevent double-booking across shifts, `assignSeatToExistingStudent` and `assignSeatAndRegisterStudent` enforce atomicity:
1. **Search Phase:** Check if the student currently occupies another desk.
2. **Vacate Phase:** If moving to a new seat, the prior seat is automatically wiped (`isOccupied = false`, `studentId = null`).
3. **Collision Check:** Check if the destination seat is already occupied by a different active student. If occupied, an exception is thrown before any mutation occurs.
4. **Assignment Phase:** The new seat is marked occupied, the student's `seatNumber` is updated, and both lists emit new unmodifiable snapshots through the stream controllers.

### Atomic Fee Collection & Dues Clearance
When `collectStudentFee` is invoked:
- Outstanding `duesAmount` is decremented by the collected amount (clamped to `0`).
- If dues reach `0`, status transitions to `ACTIVE` and `feeDueDate` extends by 30 days.
- A `PaymentTransaction` receipt is recorded in the ledger with payment mode (`UPI`, `Cash`).
- State is serialized immediately to offline storage and emitted to active UI streams.

---

## 5. Platform-Agnostic File I/O Architecture

To compile cleanly on both **Web (JavaScript/Wasm)** and **Native Mobile (Android/iOS/Desktop)** without import errors, the file export pipeline uses Dart's conditional compilation pattern:

```
lib/services/
├── file_export_service.dart   <-- Core façade with conditional exports
├── file_export_web.dart       <-- dart:html Blob & synthetic anchor download
├── file_export_io.dart        <-- dart:io File & path_provider document saving
└── file_export_stub.dart      <-- Fallback interface stub
```

```dart
// file_export_service.dart
export 'file_export_stub.dart'
    if (dart.library.html) 'file_export_web.dart'
    if (dart.library.io) 'file_export_io.dart';
```

- **Web Implementation (`file_export_web.dart`)**:
  Creates an in-memory `Blob`, generates a temporary `Url.createObjectUrlFromBlob(blob)`, creates a hidden `<a download="filename">` element, dispatches a programmatic `.click()`, and cleans up the object URL.
- **Native Implementation (`file_export_io.dart`)**:
  Retrieves device storage via `getApplicationDocumentsDirectory()`, writes the bytes/strings to disk, and triggers native file handlers.

---

## 6. Offline Persistence Engine

Similar to the file export pipeline, device storage uses conditional compilation:
```
lib/services/
├── local_storage_service.dart <-- Facade exposing static getString/saveString/remove
├── local_storage_web.dart     <-- Uses window.localStorage directly
├── local_storage_io.dart      <-- Uses file-backed persistence or SharedPreferences
└── local_storage_stub.dart    <-- In-memory Map fallback
```

### Storage Registry Keys:
- `app_library_students`: Serialized JSON array of all members.
- `app_library_payments`: Serialized JSON array of payment transactions.
- `app_library_expenses`: Serialized JSON array of library expenses.
- `app_library_profile`: JSON object containing library name, logo Base64, and address.
- `app_library_branches`: Registered branches and floor configurations.
- `app_library_active_branch`: Current active branch ID.
- `app_library_staff`: Staff directory and assigned roles.

---

## 7. Disaster Recovery & Full JSON Database Serialization

The backup engine in `LibraryService` serializes the **entire application database** into an atomic, portable JSON package:

```json
{
  "app": "TrackMyLibrary",
  "version": "2.0.0",
  "exported_at": "2026-10-22T07:30:00Z",
  "profile": { "name": "Prabhat Study Circle", "logo_base64": "...", "address": "..." },
  "branches": [ ... ],
  "sections": [ ... ],
  "staff": [ ... ],
  "students": [ ... ],
  "payments": [ ... ],
  "expenses": [ ... ]
}
```

### Rehydration Safety Engine:
1. Validates that incoming payload contains valid JSON and conforms to the `TrackMyLibrary` schema.
2. In-memory data structures are safely cleared and repopulated with restored records.
3. Automatically recomputes physical seat allocation from the restored student list.
4. Stream controllers broadcast new state across all open screens.
5. Flushes all restored entities to `LocalStorageService`.

---

## 8. Excel & Spreadsheet Ingestion Engine

Located in [lib/services/excel_import_service.dart](file:///d:/Tutorial/Library-app/lib/services/excel_import_service.dart).

- **Multi-Format Parsing**:
  Supports both standard comma-separated values (`CSV`) and Tab-Separated Values (`TSV`). This enables operators to select rows in Microsoft Excel or Google Sheets, press `Ctrl+C`, and paste directly into the app.
- **Normalization Pipeline**:
  1. Header row auto-detection and column mapping index calculation.
  2. Indian phone number normalization regex:
     ```dart
     static String normalizePhone(String raw) {
       final digits = raw.replaceAll(RegExp(r'\D'), '');
       if (digits.length == 10) return digits;
       if (digits.length > 10 && digits.startsWith('91')) return digits.substring(digits.length - 10);
       if (digits.length > 10 && digits.startsWith('0')) return digits.substring(digits.length - 10);
       return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
     }
     ```
  3. Seat boundary clamping and auto-assignment.
  4. Error logging collection: Bad rows are logged with row numbers and exact rejection reasons while valid rows proceed.

---

## 9. Production Error Boundary & Crash Protection

Implemented in [lib/main.dart](file:///d:/Tutorial/Library-app/lib/main.dart).

```dart
// Framework Exception Trap
FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  debugPrint('🛡️ [TrackMyLibrary Global Guard] ${details.exception}');
};

// UI Render Error Boundary
ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.amber, size: 48),
              const Text("Operational Error Boundary Reached"),
              ElevatedButton(onPressed: () => Navigator.maybePop(context), child: const Text("Return to Safety")),
            ],
          ),
        ),
      ),
    ),
  );
};
```

---

## 10. Automated Testing Strategy & CI/CD Pipeline

### Test Suites Structure:
All tests are located in `test/` and run using `flutter test`:
1. `test/financial_ledger_test.dart`: Fee collection, ledger decrements, expense lifecycle, transaction queries.
2. `test/seat_and_student_test.dart`: Phone normalization, anti-duplicate phone validation, 1-to-1 seat collision locking.
3. `test/excel_import_test.dart`: CSV template export, CSV parsing, Excel TSV clipboard parsing, row validation errors.
4. `test/backup_restore_test.dart`: Full JSON schema validation, complete disaster recovery state rehydration.
5. `test/multi_branch_and_staff_test.dart`: Branch switching, staff role permissions, active status toggling.

### GitHub Actions CI/CD Pipeline ([.github/workflows/build-apk.yml](file:///d:/Tutorial/Library-app/.github/workflows/build-apk.yml)):
- **Pre-Build Gate:** `flutter test` executes automatically across all 5 suites on Ubuntu runners.
- **Android Release:** Compiles release APK (`flutter build apk --release`) -> uploads `library-manager-apk` (~24.67 MB).
- **Web Release:** Compiles web bundle (`flutter build web --release --base-href /Library-app/`) -> deploys live to GitHub Pages (~7.51 MB).

---

## 11. Security & Compliance Architecture

1. **Cloud Firestore Rules ([firestore.rules](file:///d:/Tutorial/Library-app/firestore.rules))**:
   - Enforces authenticated access for reading/writing student, seat, payment, and expense documents.
   - Prevents unauthenticated writes or arbitrary data manipulation.
2. **Local Data Isolation**:
   - All student portraits are compressed client-side into Base64 JPEG strings and stored within the device's sandboxed local storage, eliminating external unauthenticated CDN/S3 bucket leaks.
3. **Audit Trails**:
   - Every physical seat assignment, payment collection, and expense record logs the `collected_by` / `last_updated_by` staff device ID for internal accountability.
