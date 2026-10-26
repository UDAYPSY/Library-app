# TrackMyLibrary — AI & Developer Master Technical & Operational Manual
> **Enterprise System Specification, Architectural Deep-Dive, Business Logic Handbook & Production-Readiness Blueprint**  
> *Version:* 3.0.0 • *Platform:* Flutter 3.24+ / Dart 3.3+ (Material 3) • *Target:* Android APK, Web PWA, Windows/macOS Desktop  
> *Canonical Primary Contact & Admin Identity:* `manageyourlib@gmail.com` • `+91 9457464850`  
> *Target Audience:* Autonomous AI Agents, Lead Software Architects, Flutter Engineers, and Library Operations Leads

---

## 1. Executive Summary & Domain Mission

**TrackMyLibrary** is a reactive, offline-first digital operating system engineered specifically for self-study libraries, reading rooms, digital study hubs, and co-working spaces. 

In physical self-study libraries (prevalent across India and global academic hubs), dozens to hundreds of competitive exam aspirants (UPSC, NEET, JEE, SSC, Banking, CA) rent dedicated or shared study desks across varying time shifts. Library owners typically struggle with:
1. **Seat collisions:** Two students assigned to the same physical desk during overlapping time slots.
2. **Financial leakage & dues tracking:** Uncollected monthly subscription fees and untracked partial payments.
3. **Complicated shift adjustments:** When students switch between full-day, morning, evening, or night shifts mid-month, calculating fee differences, refunds, or advance credits manually causes friction and errors.
4. **Connectivity issues:** Reading halls are often situated in basements or soundproofed zones with spotty internet, making pure cloud-based tools unreliable.
5. **Loss of audit history:** Manual registers get misplaced, notes on paper get torn, and staff members fail to record who collected cash or who moved a student's seat.

TrackMyLibrary addresses these challenges with deterministic mathematical logic, offline-first data sovereignty, physical seat collision locks, and automated financial ledger synchronization.

---

## 2. Non-Technical Library Operations Guide

This section explains the business and operational domain so any AI or engineer understands how study libraries function in the real world.

### 2.1 Physical Space Layout
- **Desks / Seats:** Physical cubicles or tables numbered sequentially (e.g., Seat #1 to #150).
- **Sections / Zones:** Physical partitions of the library, such as:
  - *Main Hall:* Standard ventilated reading room.
  - *AC Cabin / Silent Zone:* Air-conditioned quiet zone with premium pricing.
  - *Discussion / Laptop Room:* Desks equipped with power outlets for computer work.
- **Lockers:** Auxiliary storage units rented to students for heavy books and notes.

### 2.2 Shift Mechanics
Study spaces run on **time shifts** to maximize desk occupancy and keep pricing accessible:
- **Full Day (e.g., 06:00 AM – 11:00 PM):** Highest fee tier (e.g., ₹1,000/mo). Occupies the seat throughout the entire day.
- **Half Day / Split Shifts:**
  - *Morning Shift (e.g., 06:00 AM – 02:00 PM):* Mid-tier fee (e.g., ₹600/mo).
  - *Evening Shift (e.g., 02:00 PM – 10:00 PM):* Mid-tier fee (e.g., ₹600/mo).
  - *Night Shift (e.g., 10:00 PM – 06:00 AM):* Lower-tier fee (e.g., ₹400/mo).
- **Shift Collision Rule:**
  - A desk allocated to a *Full Day* student **cannot** be allocated to anyone else.
  - A desk allocated to a *Morning* student **can** simultaneously be allocated to an *Evening* student and a *Night* student because their hours do not overlap.

### 2.3 Student Membership Lifecycle
```
             ┌──────────────┐
             │ Registration │
             └──────┬───────┘
                    ▼
             ┌──────────────┐
             │ Trial Member │ ── (Converts or Drops)
             └──────┬───────┘
                    ▼
     ┌──────────────────────────────┐
     │  Active Member (Dues = 0)    │ ◄──┐
     └──────────────┬───────────────┘    │ Renewal /
                    ▼                    │ Dues Payment
     ┌──────────────────────────────┐    │
     │  Dues Member (Fee Overdue)   │ ───┘
     └──────────────┬───────────────┘
                    ▼
     ┌──────────────────────────────┐
     │  Inactive Member (Vacated)   │
     └──────────────────────────────┘
```
1. **Admission / KYC:** Student registers with Name, Phone, Father's Name, Permanent Address, Aadhaar Number, Target Exam (e.g., UPSC, NEET), Photo, and Joining Date.
2. **Tenure & Due Date:** The initial registration sets a validity window (e.g., 1 month, 3 months, 6 months). The `feeDueDate` represents the deadline for the next renewal payment.
3. **Grace Period & Dues:** If a student's due date lapses without renewal, their status automatically transitions to `DUES`, and their pending dues amount equals their monthly fee.
4. **Vacation / Seat Release:** If a student leaves, their seat is freed for others, but their profile, KYC, and financial audit history remain archived indefinitely.

---

## 3. Financial Engine & Accounting Architecture

The financial engine in `TrackMyLibrary` implements double-entry principles to ensure that revenue metrics reflect actual net earnings rather than unearned advance liabilities.

### 3.1 Advance Money vs. Revenue Distinction
- **Cash Flow vs. Revenue:**
  - When a student pays ₹1,000 for a Full Day shift, ₹1,000 is recorded as revenue for that tenure.
  - If the student downgrades mid-cycle to Morning Shift (₹700), the net purchase cost of their current tenure is now only ₹700.
  - The remaining ₹300 is **Advance Credit** (unearned revenue / library liability) held on behalf of the student for future renewals.
  - **Ledger Invariant:** The original payment transaction in the `payments` collection must be adjusted from ₹1,000 down to ₹700. The ₹300 is credited to `student.advanceAmount`. Total revenue in the payments tab accurately drops to ₹700.

### 3.2 Shift Upgrade & Downgrade Mathematical Formulas

#### Formula 1: Student Effective Paid Coverage (`_studentEffectivePaidCoverage`)
Calculates the total monetary value covered by the student for their active membership cycle:
$$\text{Coverage} = \max\left(0, (\text{CurrentMonthlyFee} \times \text{TenureMonths}) - \text{DuesAmount} + \text{AdvanceAmount}\right)$$

#### Formula 2: Shift Downgrade (Excess Credit Calculation)
When switching from higher-tier shift (e.g., Full Day @ ₹1,000) to lower-tier shift (e.g., Morning @ ₹700):
$$\text{TargetTenureCost} = \text{NewMonthlyFee} \times \text{TenureMonths}$$
$$\text{ExcessCredit} = \max\left(0, \text{Coverage} - \text{TargetTenureCost}\right)$$
- `student.advanceAmount` $\leftarrow \text{student.advanceAmount} + \text{ExcessCredit}$
- `student.duesAmount` $\leftarrow 0$
- `student.status` $\leftarrow \text{'ACTIVE'}$
- `adjustLastPaymentForShiftChange`:
  $$\text{UpdatedTransactionAmount} = \max\left(0, \text{OriginalAmount} - \text{ExcessCredit}\right)$$
  Transaction shift is updated to `NewShift`, and an audit memo is appended.

#### Formula 3: Shift Upgrade (Due Difference Calculation)
When switching from lower-tier shift (e.g., Morning @ ₹700) to higher-tier shift (e.g., Full Day @ ₹1,000):
$$\text{UpgradeDiff} = \max\left(0, \text{TargetTenureCost} - \text{Coverage}\right)$$
- If the student has existing `advanceAmount`:
  $$\text{AdvanceConsumed} = \min(\text{student.advanceAmount}, \text{UpgradeDiff})$$
  $$\text{NetPayable} = \text{UpgradeDiff} - \text{AdvanceConsumed}$$
- If paid immediately:
  - Record payment of ₹NetPayable.
  - Transaction ledger restores the previous purchase amount by `AdvanceConsumed`.
- If unpaid:
  - `student.duesAmount` $\leftarrow \text{NetPayable}$
  - `student.status` $\leftarrow \text{'DUES'}$

#### Formula 4: Multi-Upgrade / Downgrade Idempotency
- If a student is downgraded (1,000 → 700, ₹300 advance credit), then upgraded back (700 → 1,000, consuming the ₹300 advance credit), and then downgraded again (1,000 → 700), the system:
  1. Detects that the ₹300 advance credit was already consumed during the upgrade.
  2. Does not double-accumulate stale advance credits.
  3. Calculates fresh excess credit of ₹300 only for the current action.

---

## 4. High-Level Architecture & Technical Stack

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SYSTEM ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                           PRESENTATION LAYER                            │
  │  • Interactive Visual Seat Map    • 3-Step Enrollment Wizard (KYC)      │
  │  • Member Profile & Timeline      • Payments & Revenue Ledger           │
  │  • Multi-Step Owner Onboarding    • Financial Analytics (P&L)           │
  │  • Reports & Multi-Format Exports • Settings & Multi-Branch Switcher    │
  └────────────────────────────────────┬────────────────────────────────────┘
                                       │ Subscribes to Broadcast Streams
                                       │ Calls Async Service Methods
                                       ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                     SERVICE & STATE MANAGEMENT LAYER                    │
  │  • LibraryService (Central Domain Singleton & Reactive Broadcast Hub)   │
  │  • ThemeService (Reactive Light/Slate Dark Mode Tokens)                 │
  │  • ExcelImportService (Regex TSV/CSV Stream Parser)                     │
  │  • FileExportService (Conditional Export Façade for Web & Native)       │
  │  • LocalStorageService (Conditional Key-Value Façade)                   │
  └──────────────────┬───────────────────────────────────┬──────────────────┘
                     │                                   │
      Offline Branch │ Local Persistence                 │ Cloud Sync (Auto)
                     ▼                                   ▼
  ┌─────────────────────────────────────┐  ┌────────────────────────────────┐
  │        OFFLINE STORAGE LAYER        │  │       CLOUD FIREBASE LAYER     │
  │ • Web: window.localStorage JSON     │  │ • Cloud Firestore (NoSQL)     │
  │ • Mobile: SharedPreferences / Files │  │ • Atomic Multi-Doc Mutations  │
  │ • Full JSON Snapshots (Backup)      │  │ • Strict Tenant Security Rules │
  │ • In-Memory Fallback Map            │  │ • Firebase Auth Session Guard  │
  └─────────────────────────────────────┘  └────────────────────────────────┘
```

### 4.1 Technology Stack Details
- **Framework:** Flutter 3.24.x (Channel Stable)
- **Language:** Dart 3.3+ (Sound Null Safety)
- **Design System:** Material 3 with customized dark/light tokens (`AppColors`)
- **Backend / Cloud Database:** Google Cloud Firestore (Multi-Tenant)
- **Local Persistence:** Conditional façade (`SharedPreferences` on Native, `window.localStorage` on Web)
- **State Management:** Reactive broadcast streams via Dart `StreamController<List<T>>.broadcast()`
- **CI/CD:** GitHub Actions compiling release APKs, building Web PWAs, and publishing to GitHub Releases and GitHub Pages.

---

## 5. Directory Structure & File Inventory

```
d:\Tutorial\Library-app\
├── .github/
│   ├── scripts/
│   │   └── patch_android_gradle.py      # Automated CI script configuring AGP 8.6 & Kotlin 2.0
│   └── workflows/
│       └── build-apk.yml                # CI/CD: Automated Tests, Android APK & Web App deploy
├── android/                             # Native Android project configuration
│   ├── app/
│   │   ├── build.gradle                 # MinSDK 23, TargetSDK 34, ProGuard & Keystore config
│   │   └── src/main/AndroidManifest.xml # Permissions: Internet, Storage, Camera, Call
├── assets/                              # Brand logos, placeholder graphics & icons
├── lib/
│   ├── main.dart                        # Application entry point & Global Error Boundary
│   ├── firebase_options.dart            # Multi-platform Firebase configuration
│   ├── constants/
│   │   ├── app_colors.dart              # Adaptive color tokens (Light & Slate Dark Mode)
│   │   └── app_theme.dart               # Material 3 ThemeData specifications
│   ├── models/
│   │   └── library_models.dart          # All Domain Entities, DTOs & JSON Serializers
│   ├── screens/
│   │   ├── login_screen.dart            # Admin Email & Staff PIN Authentication
│   │   ├── main_hub_screen.dart         # Root scaffold, bottom navigation & drawer
│   │   ├── dashboard_screen.dart        # Overview KPI cards & quick actions
│   │   ├── onboarding/                  # 7-Screen guided library owner setup
│   │   │   ├── welcome_carousel_screen.dart
│   │   │   ├── admin_profile_screen.dart
│   │   │   ├── workspace_setup_screen.dart
│   │   │   ├── shift_setup_screen.dart
│   │   │   ├── seat_setup_screen.dart
│   │   │   ├── review_setup_screen.dart
│   │   │   └── setup_success_screen.dart
│   │   ├── seats/
│   │   │   └── seats_screen.dart        # Interactive floor grid & seat assignment modal
│   │   ├── students/
│   │   │   ├── student_directory_screen.dart # Member list with search & filters
│   │   │   ├── add_student_wizard_screen.dart # 3-Step enrollment & edit wizard
│   │   │   └── member_profile_screen.dart     # Member KYC, tenure, & digital ID
│   │   ├── payments/
│   │   │   └── revenue_screen.dart      # Revenue transactions & dues collection
│   │   ├── shifts/
│   │   │   └── shift_system_screen.dart # Custom shift timing & pricing editor
│   │   ├── analytics/
│   │   │   ├── financial_analytics_screen.dart # P&L, collections, expense metrics
│   │   │   └── add_expense_sheet.dart          # Operating cost recording sheet
│   │   ├── settings/
│   │   │   └── settings_screen.dart     # Branch switcher, staff RBAC, backup & restore
│   │   └── tools/
│   │       ├── reports_exports_screen.dart    # Excel, CSV, PDF & vCard exporter
│   │       ├── whatsapp_automation_screen.dart# Message templates & broadcast
│   │       ├── library_branding_screen.dart   # Logo, crest, rules & Wi-Fi settings
│   │       ├── student_live_portal_screen.dart# Web QR access gate simulation
│   │       ├── share_qr_screen.dart           # Printable dynamic library QR
│   │       ├── refer_earn_screen.dart         # Referral rewards calculator
│   │       └── library_community_screen.dart  # Library notices & community board
│   ├── services/
│   │   ├── library_service.dart         # Core domain singleton & reactive streams
│   │   ├── theme_service.dart           # Reactive Light/Dark ThemeMode controller
│   │   ├── excel_import_service.dart    # CSV/TSV regex parser for bulk spreadsheet sync
│   │   ├── file_export_service.dart     # Conditional export facade
│   │   ├── file_export_web.dart         # Web Blob & synthetic <a> click exporter
│   │   ├── file_export_io.dart          # Native Mobile/Desktop PathProvider exporter
│   │   ├── file_export_stub.dart        # Export fallback interface stub
│   │   ├── local_storage_service.dart   # Conditional local persistence facade
│   │   ├── local_storage_web.dart       # window.localStorage implementation
│   │   ├── local_storage_io.dart        # SharedPreferences implementation
│   │   └── local_storage_stub.dart      # In-memory Map testing stub
│   └── widgets/
│       └── collect_payment_modal.dart   # Dues & renewal payment collection bottom sheet
├── test/                                # 8 Automated Unit, RBAC, and Integration Suites
│   ├── app_screens_compilation_test.dart
│   ├── auth_and_rbac_test.dart
│   ├── backup_restore_test.dart
│   ├── dark_mode_and_theme_test.dart
│   ├── excel_import_test.dart
│   ├── financial_ledger_test.dart
│   ├── multi_branch_and_staff_test.dart
│   └── seat_and_student_test.dart
├── firestore.rules                      # Cloud Firestore security & isolation rules
└── pubspec.yaml                         # Dependencies and asset declarations
```

---

## 6. Domain Data Models & Database Schemas

All domain entities reside in [`lib/models/library_models.dart`](file:///d:/Tutorial/Library-app/lib/models/library_models.dart).

### 6.1 `StudentInfo` (Member Entity)
```dart
class StudentInfo {
  final String id;                  // Unique identifier: "std_<timestamp>_<counter>"
  final String name;                // Full name
  final String phone;               // Normalized 10-digit mobile number
  final int? seatNumber;            // Assigned desk (1..N) or null if unallocated
  final String shift;               // 'Full Day', 'Morning', 'Evening', 'Night', etc.
  final String status;              // 'ACTIVE', 'DUES', 'INACTIVE', 'TRIAL'
  final DateTime? feeDueDate;       // Next renewal deadline / subscription expiry
  final DateTime? joinedAt;         // Immutable initial enrollment date
  final int monthlyFee;             // Monthly subscription fee in INR
  final int duesAmount;             // Unpaid outstanding balance in INR
  final int advanceAmount;          // Credit held by library from shift downgrades / advance
  final String paymentMode;         // 'UPI', 'Cash', 'Card', 'Net Banking'
  final String note;                // Immutable chronological audit trail
  final String fatherName;          // KYC: Father or Guardian's name
  final String address;             // KYC: Residential address
  final String aadhaarNumber;       // KYC: 12-digit Indian national identity number
  final String preparationFor;      // Target exam (UPSC, NEET, JEE, SSC, etc.)
  final String gender;              // 'Male', 'Female', 'Other'
  final String photoBase64;         // Compressed JPEG Base64 data URI
  final String sectionName;         // Partition name (e.g., 'Main Hall')
  final DateTime? updatedAt;        // Timestamp for optimistic locking
}
```

### 6.2 `SeatInfo` (Desk Entity)
```dart
class SeatInfo {
  final int seatNumber;             // 1-indexed desk identifier
  final bool isOccupied;            // Desk allocation status
  final String? studentId;          // Occupant reference
  final String? studentName;        // Cached occupant name for O(1) floor rendering
  final String? shift;              // Occupant shift
  final String sectionName;         // Section partition (e.g. 'Main Hall')
  final String lastUpdatedBy;       // Staff username or 'Desk_Manager'
}
```

### 6.3 `ShiftConfig` (Shift Configuration Entity)
```dart
class ShiftConfig {
  final String id;                  // e.g., 'shift_1'
  final String name;                // 'Full Day', 'Morning Shift', 'Evening Shift'
  final String startsAt;            // '06:00 AM'
  final String endsAt;              // '02:00 PM'
  final int monthlyFee;             // Standard monthly rate in INR
  bool isActive;                    // Active toggle
}
```

### 6.4 `PaymentTransaction` (Financial Ledger Record)
```dart
class PaymentTransaction {
  final String id;                  // Receipt ID: "pay_<timestamp>"
  final String studentId;           // Student reference
  final String studentName;         // Cached name
  final String studentPhone;        // Normalized phone
  final int? seatNumber;            // Desk reference
  final String shift;               // Shift during purchase
  final int amount;                 // Collected amount in INR (adjusted on downgrade)
  final DateTime date;              // Timestamp of collection
  final String paymentMode;         // 'UPI', 'Cash', 'Card'
  final String notes;               // Audit details, tenure period, receipt memo
  final DateTime? validFrom;        // Subscription period start date
  final DateTime? validUntil;       // Subscription period end date
  final int? durationMonths;        // Number of months paid
}
```

### 6.5 `ExpenseItem` (Operating Expenditure Entity)
```dart
class ExpenseItem {
  final String id;                  // "exp_<timestamp>"
  final String title;               // 'Electricity Bill', 'Wi-Fi Fiber Renewal', 'Newspapers'
  final int amount;                 // Expense cost in INR
  final String category;            // 'Utility', 'Rent', 'Maintenance', 'Salaries'
  final DateTime date;              // Expense date
  final String paymentMode;         // 'UPI', 'Cash', 'Bank Transfer'
  final String notes;               // Memo / Invoice reference
}
```

---

## 7. Core Subsystems & Implementation Details

### 7.1 Reactive Domain Singleton (`LibraryService`)
All business logic is centralized in [`lib/services/library_service.dart`](file:///d:/Tutorial/Library-app/lib/services/library_service.dart).
- **Initialization:** `ensureInitialized()` loads local JSON state from `LocalStorageService`. If Firebase is configured, it establishes Firestore snapshot listeners.
- **Streams Exposed:**
  - `streamStudents()` $\rightarrow$ `Stream<List<StudentInfo>>`
  - `streamSeats()` $\rightarrow$ `Stream<List<SeatInfo>>`
  - `streamPayments()` $\rightarrow$ `Stream<List<PaymentTransaction>>`
  - `streamExpenses()` $\rightarrow$ `Stream<List<ExpenseItem>>`
  - `streamShifts()` $\rightarrow$ `Stream<List<ShiftConfig>>`
- **In-Memory Cache:** `_mockStudents`, `_mockSeats`, `_mockPayments`, `_mockExpenses`. Every mutation immediately emits an unmodifiable list copy to active UI streams and invokes `_saveLocalState()` asynchronously.

### 7.2 Multi-Stage Date-Sorted Payment Adjustment (`adjustLastPaymentForShiftChange`)
When a student's shift changes, this method executes:
```dart
Future<void> adjustLastPaymentForShiftChange({
  required String studentId,
  String? phone,
  String? studentName,
  required String newShift,
  required int targetTenureCost,
  int advanceCredited = 0,
  int advanceConsumed = 0,
  String? noteDetails,
})
```
1. **Firestore Query Cascades:** Looks up payments by `student_id`. If empty, cascades to `student_phone`, normalized phone, and `student_name`. If still empty, scans the recent tenant payments collection with client-side normalization.
2. **Latest Transaction Target:** Sorts all matching payments by `date` descending. Picks the newest transaction (`sortedDocs.first`).
3. **Idempotency Check:** If `latestDoc['shift']` is already `newShift`, it exits immediately.
4. **Amount Recalculation:**
   - On downgrade: reduces the payment amount by `advanceCredited` down to `targetTenureCost`.
   - On upgrade: restores the payment amount by `advanceConsumed`.
5. **Dual Persistence:** Updates Firestore document and updates `_mockPayments` in memory, emitting the updated list to `_mockPaymentsController`.

### 7.3 Persistent Chronological Audit Notes (`appendNote`)
Student notes serve as an unalterable operational audit log.
- **Rule:** When modifying a student, existing notes are **never** overwritten or replaced.
- **Method:** `LibraryService.appendNote(existingNote, newEntry)`:
  - If `existingNote` is empty, returns `newEntry`.
  - Otherwise, checks if `newEntry` already exists in `existingNote` (preventing duplicates).
  - Appends with a bullet separator: `"$existingNote • $newEntry"`.
- **Automatic Audit Triggers:**
  - *Admission:* `"Admission on 26-Oct-2026: Shift Full Day (Seat S-12, ₹1000/mo)..."`
  - *Seat Change:* `"Seat changed: S-12 → S-15 (Full Day) on 26-Oct-2026."`
  - *Shift Downgrade:* `"Shift downgraded: Full Day (₹1000/mo) → Morning (₹700/mo)... ₹300 excess credit remains..."`
  - *Shift Upgrade:* `"Shift upgraded: Morning (₹700/mo) → Full Day (₹1000/mo)..."`
  - *Due Payment Collected:* `"Due payment of ₹300 collected via UPI on 26-Oct-2026..."`
  - *Status Reactivation:* `"Member reactivated (ACTIVE) on 26-Oct-2026."`
  - *Photo Update:* `"Profile photo updated on 26-Oct-2026."`

### 7.4 Seat Collision Algorithm (`isSeatOccupied` & `doShiftsConflict`)
```dart
static bool doShiftsConflict(String shiftA, String shiftB) {
  final a = shiftA.trim().toLowerCase();
  final b = shiftB.trim().toLowerCase();
  if (a == b) return true;
  if (a.contains('full day') || b.contains('full day')) return true;
  if (a.contains('24 hours') || b.contains('24 hours')) return true;
  return false;
}
```
- In `isSeatOccupied(int seatNumber, {String? shift, String? excludeStudentId})`:
  - Finds all occupants of `seatNumber` excluding `excludeStudentId`.
  - For each occupant, checks `doShiftsConflict(occupant.shift, requestedShift)`.
  - If any conflict occurs, the seat is marked occupied and disabled in the UI.

---

## 8. Authentication, RBAC & Multi-Tenancy

### 8.1 Roles & Permissions
1. **Admin / Owner (`manageyourlib@gmail.com`):**
   - Full read/write access across all screens.
   - Configure shifts, prices, seat layouts, branches.
   - Delete students, clear records, import/export backups.
   - View revenue, profit & loss, and operational analytics.
2. **Staff / Receptionist (4-Digit PIN):**
   - Desk check-in/check-out.
   - View seat availability and search members.
   - Collect subscription renewals and dues.
   - **Blocked from:** deleting students, modifying shift fees, exporting financial ledgers, or changing admin settings.

### 8.2 Multi-Tenant Data Isolation
In Cloud Firestore, all collections are scoped under the tenant ID:
`/libraries/{tenantId}/students/{studentId}`
`/libraries/{tenantId}/seats/{seatId}`
`/libraries/{tenantId}/payments/{paymentId}`
`/libraries/{tenantId}/expenses/{expenseId}`
`/libraries/{tenantId}/branches/{branchId}`

Security rules in [`firestore.rules`](file:///d:/Tutorial/Library-app/firestore.rules) verify that `request.auth.uid` matches the tenant administrator's authorization token.

---

## 9. CI/CD Pipeline & Automated Verification

The project is governed by GitHub Actions in [`.github/workflows/build-apk.yml`](file:///d:/Tutorial/Library-app/.github/workflows/build-apk.yml).

### 9.1 Pipeline Workflow Stages
1. **Scaffolding & Dependency Patching:**
   - Executes `.github/scripts/patch_android_gradle.py` to ensure Android Gradle Plugin 8.6+ and Kotlin 2.0+ compatibility with Java 17.
   - Runs `flutter pub get`.
2. **Automated Test Suite:**
   - Executes `flutter test` across all 8 test suites.
   - Fails the build if any test encounters an error.
3. **Android Release Compilation:**
   - Decodes base64 release keystore from GitHub Secret `KEYSTORE_BASE64` to `android/app/trackmylibrary-release.jks`.
   - Compiles signed APK: `flutter build apk --release --no-tree-shake-icons`.
   - Uploads APK artifact and publishes to GitHub Releases (`latest` tag).
4. **Flutter Web Compilation & Deployment:**
   - Compiles web application: `flutter build web --release --base-href /Library-app/`.
   - Deploys static bundle directly to GitHub Pages.

---

## 10. Complete Production-Readiness Blueprint

To ensure TrackMyLibrary operates reliably for thousands of concurrent libraries, follow this exhaustive production-readiness roadmap.

### 10.1 Security & Authentication Hardening
- [ ] **Enforce Firebase App Check:** Register Android SHA-256 fingerprint with Play Integrity and Web reCAPTCHA v3 to prevent unauthorized API calls.
- [ ] **Firestore Rate Limiting:** Apply write throttling rules in `firestore.rules` preventing rapid bulk deletions or scraping.
- [ ] **Biometric / PIN Screen Lock:** Add local biometric (Fingerprint / Face ID) lock in mobile settings for desk operators when switching away from the app.

### 10.2 Database & Data Integrity
- [ ] **Composite Indexes:** Ensure composite Firestore indexes are defined in `firestore.indexes.json` for queries combining `student_id` + `date` (descending) and `shift` + `date`.
- [ ] **Soft Deletions:** Implement soft deletion (`deleted_at` timestamp) instead of hard document drops so deleted records can be restored.
- [ ] **Offline Sync Conflict Resolution:** Enhance optimistic locking (`updatedAt`) with automated three-way field-level merges for offline-created changes.

### 10.3 Performance & Asset Optimization
- [ ] **Image Compression Pipeline:** Integrate `flutter_image_compress` in `member_profile_screen.dart` to clamp student profile photos to under 150 KB before base64 encoding.
- [ ] **Virtual Floor Grid:** In `seats_screen.dart`, utilize `GridView.builder` with windowing to keep memory usage flat even in 500+ seat mega-libraries.
- [ ] **Lazy Query Pagination:** Paginate `streamPayments()` and `streamExpenses()` with cursor-based chunking (50 records per page) to optimize memory on low-end Android devices.

### 10.4 Observability & Monitoring
- [ ] **Crashlytics Integration:** Initialize `firebase_crashlytics` in `main.dart`'s `runZonedGuarded` block to capture uncaught Flutter framework and native errors.
- [ ] **Performance Tracing:** Wrap database calls and Excel parsing routines in Firebase Performance traces to monitor latency.

---

## 11. AI Agent Non-Negotiable Invariants

When any AI assistant or developer is tasked with extending or modifying this project, the following instructions **must** be obeyed:

1. **Preserve Offline Autonomy:** Never add network-blocking calls in synchronous initialization flows. All writes must succeed locally via `LibraryService` first.
2. **Preserve Canonical Contact Details:** Everywhere in the app, the primary contact email must remain `manageyourlib@gmail.com` and phone `9457464850`.
3. **Preserve Shift Financial Math:** On shift downgrades, excess funds must always reduce the payment transaction amount in the ledger and credit `student.advanceAmount`. When upgrading, advance credits must be consumed before demanding new dues.
4. **Preserve Immutable Joining Date:** The joining date is the anchor for tenure calculation. Never allow edit forms to overwrite `joinedAt`.
5. **Preserve Chronological Audit Trails:** Never wipe or replace `student.note`. Always use `LibraryService.appendNote` to preserve history.
6. **Preserve Conditional Compilation:** Never import `dart:html` or `dart:io` directly in UI screens or shared services. Always route through `file_export_service.dart` or `local_storage_service.dart`.
7. **Always Run Tests Before Completion:** Ensure all automated tests in `test/` compile and pass with 0 errors.
