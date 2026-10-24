# TrackMyLibrary — AI & Developer Master Technical Manual
> **Comprehensive System Specification, Architectural Deep-Dive & Engineering Handbook**  
> *Version:* 2.2.0 • *Platform:* Flutter 3.24+ / Dart 3.3+ (Material 3) • *Target:* Android APK, Web PWA, Desktop  
> *Primary Contact & System Identity:* `manageyourlib@gmail.com` • `+91 9457464850`  
> *Target Audience:* Autonomous AI Agents, Lead Systems Architects, and Flutter Core Engineers

---

## 1. Executive Summary & System Philosophy

**TrackMyLibrary** is an enterprise-grade digital operating system and management SaaS purpose-built for self-study libraries, reading halls, and co-working spaces. It is engineered to replace fragmented physical registers, lost payment records, double-booked desks, and manual phone follow-ups with a reactive, unified application.

### Core Engineering Invariants
1. **Offline-First Data Sovereignty:** The system operates 100% autonomously without active internet connectivity. All entities serialize immediately to local platform storage. When cloud connectivity is present, it synchronizes with Google Cloud Firestore.
2. **Zero Inconsistent State:** Seat allocation, shift transitions, and financial ledger decrements execute with strict atomic validations. Double-booking desks within overlapping shifts is physically blocked by the core service.
3. **Deterministic Financial Math:** Upgrades, downgrades, discounts, and advance tenures follow transparent mathematical formulas. Excess credit from downgrades is preserved to the cent/rupee and adjusted against future renewal cycles.
4. **Conditional Compilation Purity:** The codebase runs seamlessly on both Native (Android/iOS/Desktop) and Web (PWA/CanvasKit) without relying on platform-exclusive packages that break cross-compilation.

---

## 2. High-Level Architecture & Component Map

The application follows a **Layered Reactive Broadcast Architecture** with centralized domain services and passive presentation components.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          APPLICATION ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                           PRESENTATION LAYER                            │
  │  • Interactive Visual Seat Map    • 3-Step Enrollment Wizard (KYC)      │
  │  • Member Profile & Digital Pass  • Financial Analytics & Ledger        │
  │  • Multi-Step Owner Onboarding    • Reports & Multi-Format Exporters    │
  └────────────────────────────────────┬────────────────────────────────────┘
                                       │ Subscribes to Broadcast Streams
                                       │ Dispatches Mutation Intents
                                       ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                     SERVICE & STATE MANAGEMENT LAYER                    │
  │  • LibraryService (Central Domain Singleton & Multi-Tenant Registry)    │
  │  • ThemeService (Reactive Light/Dark Slate Tokens)                      │
  │  • ExcelImportService (TSV/CSV Clipboard Regex Stream Parser)           │
  │  • FileExportService (Conditional Export Façade)                        │
  │  • LocalStorageService (Conditional Key-Value Façade)                   │
  └──────────────────┬───────────────────────────────────┬──────────────────┘
                     │                                   │
      Offline Branch │ Local Persistence                 │ Cloud Sync
                     ▼                                   ▼
  ┌─────────────────────────────────────┐  ┌────────────────────────────────┐
  │        OFFLINE STORAGE LAYER        │  │       CLOUD FIREBASE LAYER     │
  │ • Web: window.localStorage JSON     │  │ • Cloud Firestore (NoSQL)     │
  │ • Mobile: SharedPreferences / Files │  │ • Atomic Batch Mutations       │
  │ • Full JSON Snapshots (Disaster Rec)│  │ • Firestore Security Rules     │
  │ • In-Memory Fallback Map (Testing)  │  │ • Firebase Auth Session Guard  │
  └─────────────────────────────────────┘  └────────────────────────────────┘
```

---

## 3. Directory Structure & File Inventory

```
d:\Tutorial\Library-app\
├── .github/
│   └── workflows/
│       └── build-apk.yml            # CI/CD: Automated Tests, Android APK & Web Build
├── assets/                          # Branding emblems, sample icons & media
├── lib/
│   ├── main.dart                    # Application entry point & Global Error Boundary
│   ├── firebase_options.dart        # Platform Firebase configuration
│   ├── constants/
│   │   ├── app_colors.dart          # Adaptive color palette (Light & Slate Dark Mode)
│   │   └── app_theme.dart           # Material 3 ThemeData specifications
│   ├── models/
│   │   └── library_models.dart      # All Domain Entities, DTOs & JSON Serializers
│   ├── screens/
│   │   ├── login_screen.dart        # Admin Email & Staff PIN Authentication
│   │   ├── main_hub_screen.dart     # Root scaffold, bottom navigation & drawer
│   │   ├── dashboard_screen.dart    # Overview KPI cards & quick actions
│   │   ├── onboarding/              # 7-Screen guided library owner setup
│   │   │   ├── welcome_carousel_screen.dart
│   │   │   ├── admin_profile_screen.dart
│   │   │   ├── workspace_setup_screen.dart
│   │   │   ├── shift_setup_screen.dart
│   │   │   ├── seat_setup_screen.dart
│   │   │   ├── review_setup_screen.dart
│   │   │   └── setup_success_screen.dart
│   │   ├── seats/
│   │   │   └── seats_screen.dart    # Interactive floor grid & seat assignment modal
│   │   ├── students/
│   │   │   ├── student_directory_screen.dart # Member list with search & filters
│   │   │   ├── add_student_wizard_screen.dart # 3-Step enrollment & edit wizard
│   │   │   └── member_profile_screen.dart     # Member KYC, tenure, & digital ID
│   │   ├── payments/
│   │   │   └── revenue_screen.dart  # Revenue transactions & dues collection
│   │   ├── shifts/
│   │   │   └── shift_system_screen.dart # Custom shift timing & pricing editor
│   │   ├── analytics/
│   │   │   ├── financial_analytics_screen.dart # P&L, collections, expense metrics
│   │   │   └── add_expense_sheet.dart          # Operating cost recording sheet
│   │   ├── settings/
│   │   │   └── settings_screen.dart # Branch switcher, staff RBAC, backup & restore
│   │   └── tools/
│   │       ├── reports_exports_screen.dart    # Excel, CSV, PDF & vCard exporter
│   │       ├── whatsapp_automation_screen.dart# Message templates & broadcast
│   │       ├── library_branding_screen.dart   # Logo, crest, rules & Wi-Fi settings
│   │       ├── student_live_portal_screen.dart# Web QR access gate simulation
│   │       ├── share_qr_screen.dart           # Printable dynamic library QR
│   │       ├── refer_earn_screen.dart         # Referral rewards calculator
│   │       └── library_community_screen.dart  # Library notices & community board
│   └── services/
│       ├── library_service.dart     # Core domain singleton & reactive streams
│       ├── theme_service.dart       # Reactive Light/Dark ThemeMode controller
│       ├── excel_import_service.dart# CSV/TSV regex parser for bulk spreadsheet sync
│       ├── file_export_service.dart # Conditional export facade
│       ├── file_export_web.dart     # Web Blob & synthetic <a> click exporter
│       ├── file_export_io.dart      # Native Mobile/Desktop PathProvider exporter
│       ├── file_export_stub.dart    # Export fallback interface stub
│       ├── local_storage_service.dart# Conditional local persistence facade
│       ├── local_storage_web.dart   # window.localStorage implementation
│       ├── local_storage_io.dart    # SharedPreferences implementation
│       └── local_storage_stub.dart  # In-memory Map testing stub
├── test/                            # 8 Automated Unit, RBAC, and Integration Suites
│   ├── app_screens_compilation_test.dart
│   ├── auth_and_rbac_test.dart
│   ├── backup_restore_test.dart
│   ├── dark_mode_and_theme_test.dart
│   ├── excel_import_test.dart
│   ├── financial_ledger_test.dart
│   ├── multi_branch_and_staff_test.dart
│   └── seat_and_student_test.dart
├── firestore.rules                  # Cloud Firestore security & isolation rules
└── pubspec.yaml                     # Dependencies and asset declarations
```

---

## 4. Domain Data Models & Schema Design

All core data structures reside in [lib/models/library_models.dart](file:///d:/Tutorial/Library-app/lib/models/library_models.dart).

### 4.1 `StudentInfo` (Member Entity)
Represents an enrolled member in the library:
```dart
class StudentInfo {
  final String id;                  // Unique identifier: "std_<timestamp>"
  final String name;                // Full name
  final String phone;               // Normalized 10-digit mobile number
  final int? seatNumber;            // Assigned desk (1..N) or null if unallocated
  final String shift;               // 'Full Day', 'Morning', 'Evening', 'Night', etc.
  final String status;              // 'ACTIVE', 'DUES', 'INACTIVE', 'TRIAL'
  final DateTime? feeDueDate;       // Subscription expiry / next renewal deadline
  final DateTime? joinedAt;         // Immutable initial enrollment date
  final int monthlyFee;             // Monthly subscription fee in INR
  final int duesAmount;             // Unpaid outstanding balance in INR
  final String paymentMode;         // 'UPI', 'Cash', 'Card', 'Bank Transfer'
  final String note;                // Internal audit log (records original fees, shifts)
  final String fatherName;          // KYC: Father / Guardian name
  final String address;             // KYC: Permanent or residential address
  final String aadhaarNumber;       // KYC: 12-digit Indian national identity number
  final String preparationFor;      // Competitive exam goal (UPSC, NEET, SSC, etc.)
  final String gender;              // 'Male', 'Female', 'Other'
  final String? photoBase64;        // Client-compressed JPEG Base64 data URI
  final String? sectionName;        // Hall/zone partition (e.g. 'Main Reading Hall')
}
```
**Derived Getters**:
- `effectiveDues`: If `duesAmount > 0`, returns `duesAmount`. If `duesAmount == 0` but `feeDueDate` has lapsed past today, returns `monthlyFee`.
- `hasDues`: `effectiveDues > 0 || status == 'DUES'`.
- `isDuesOverdue`: `feeDueDate != null && feeDueDate.isBefore(today)`.
- `hasPhoto`: `photoBase64 != null && photoBase64.isNotEmpty`.

### 4.2 `SeatInfo` (Physical Desk Entity)
Represents a specific physical desk:
```dart
class SeatInfo {
  final int seatNumber;             // 1-indexed physical seat number
  final bool isOccupied;            // Allocation boolean
  final String studentId;           // ID of occupying student (if allocated)
  final String studentName;         // Cached occupant name for O(1) grid rendering
  final String shift;               // Shift of the occupant on this seat
  final String sectionName;         // Partition name (e.g. 'AC Cabin')
  final String lastUpdatedBy;       // Audit trail: Staff ID who modified allocation
}
```

### 4.3 `ShiftConfig` (Operating Shift Entity)
Defines operating hours and standard pricing:
```dart
class ShiftConfig {
  final String id;                  // e.g. 'shift_1'
  final String name;                // 'Full Day', 'Morning Shift', 'Evening Shift'
  final String startsAt;            // '06:00 AM'
  final String endsAt;              // '02:00 PM'
  final int monthlyFee;             // Default fee in INR (e.g. 500, 800)
  bool isActive;                    // Active toggle
}
```

### 4.4 `PaymentTransaction` (Financial Audit Entity)
```dart
class PaymentTransaction {
  final String id;                  // Receipt ID: "pay_<timestamp>"
  final String studentId;           // Enrolled student reference
  final String studentName;         // Cached student name
  final String studentPhone;        // Normalized phone
  final int? seatNumber;            // Desk reference
  final String shift;               // Shift during payment
  final int amount;                 // Collected amount in INR
  final DateTime date;              // Timestamp of collection
  final DateTime? validFrom;        // Start date of subscription period
  final DateTime? validUntil;       // End date of subscription period
  final int durationMonths;         // Number of months paid (1, 2, 3, etc.)
  final String paymentMode;         // 'UPI', 'Cash', 'Card'
  final String collectedBy;         // Staff username who accepted funds
  final String notes;               // Shift upgrade, advance note, receipt memo
}
```

### 4.5 `LibraryProfile` (Tenant Settings Entity)
Controls library configuration, branding, and WhatsApp automated notifications:
- `adminEmail`: Defaults to `manageyourlib@gmail.com`.
- `adminPhone`: Defaults to `9457464850`.
- `logoBase64`: Custom library crest/logo.
- `whatsappCredits`: Remaining SMS/WhatsApp notification balance.
- `welcomeTemplate`, `reminderTemplate`, `receiptTemplate`: Customizable notification templates with `{student_name}`, `{seat_number}`, `{due_amount}`, `{due_date}` tokens.

---

## 5. Core Business Logic & Algorithmic Rules

### 5.1 Shift Upgrade, Downgrade & Credit Adjustment Math
The upgrade/downgrade logic in [add_student_wizard_screen.dart](file:///d:/Tutorial/Library-app/lib/screens/students/add_student_wizard_screen.dart) handles mid-tenure shift alterations:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   SHIFT CHANGE FINANCIAL CALCULATION FLOW                   │
└─────────────────────────────────────────────────────────────────────────────┘

                  ┌─────────────────────────────────────────┐
                  │ Calculate Student Effective Paid        │
                  │ Coverage for the Current Billing Cycle  │
                  └────────────────────┬────────────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼                                             ▼
     [UPGRADE SCENARIO]                             [DOWNGRADE SCENARIO]
 New Fee > Effective Coverage                   New Fee < Effective Coverage
                │                                             │
                ▼                                             ▼
Upgrade Diff = (New Fee - Coverage)           Excess Credit = (Coverage - New Fee)
                │                                             │
   ┌────────────┴────────────┐                                ▼
   ▼                         ▼                  • Due Amount = ₹0
[Pay Now]             [Leave as Due]            • Status = 'ACTIVE'
Collected += Diff     Dues += Diff              • Credit adjusted next month
Status = 'ACTIVE'     Status = 'DUES'           • Note: "(Original paid: ₹Coverage)"
                                                              │
                                                              ▼
                                                    [UPGRADE BACK LATER]
                                                Recover original coverage
                                                Diff = (New Fee - Coverage) = ₹0
                                                Due = ₹0 (No double charging)
```

1. **Effective Coverage Discovery (`_studentEffectivePaidCoverage`)**:
   - Parses the student's internal notes for `(Original paid: ₹X)` or `₹X excess credit`.
   - Queries previous `PaymentTransaction` records for highest cycle payments.
   - Calculates `s.monthlyFee - s.duesAmount`.
2. **Upgrade Calculation**:
   - `_shiftUpgradeDifference = (_fixedMonthlyFee - _studentEffectivePaidCoverage).clamp(0, 999999)`.
   - In Step 3 (Review), the operator can click **Pay Upgrade (₹Diff)** or **Leave as Due (₹0 Paid)**.
3. **Downgrade Calculation**:
   - `_shiftDowngradeExcessCredit = (_studentEffectivePaidCoverage - _fixedMonthlyFee).clamp(0, 999999)`.
   - Due amount is locked at `₹0`.
   - Status remains `ACTIVE`.
   - An excess credit banner alerts the operator: *"Shift Downgraded: ₹X Excess Credit. Amount remains with library owner to adjust in next month."*
   - When saved, `shiftLog` appends `(Original paid: ₹Coverage)` to the student's note.
4. **Upgrade-Back Retention**:
   - If a downgraded student is upgraded back to their original tier (e.g. 500 back to 800), `_studentEffectivePaidCoverage` retrieves the `800` from the note.
   - Difference evaluates to `800 - 800 = 0`.
   - **No additional due payment is demanded.**

### 5.2 Seat Allocation & Multi-Shift Collision Rules
Enforced in [LibraryService.dart](file:///d:/Tutorial/Library-app/lib/services/library_service.dart) (`doShiftsConflict`):
- **Conflict Rules**:
  - Shifts with identical names always conflict.
  - Any shift containing `Full Day` or `24 Hours` conflicts with **all** other shifts.
  - Specific morning, afternoon, evening, and night shifts do **not** conflict with one another and can cleanly share the exact same physical desk.
- **Seat Card Badges** ([seats_screen.dart](file:///d:/Tutorial/Library-app/lib/screens/seats/seats_screen.dart)):
  - Top-left: Dot indicator + Seat Number (`• 1`).
  - Top-right: Tenure days indicator with flask icon (`⚗️ Xd`, e.g. `⚗️ 5d`), using `#0284C7`.
  - If dues exist: `Due ₹300 ⚗️ 5d`.
  - If multiple occupants share the seat: `2S ⚗️ 5d`.

### 5.3 Fixed Joining Date & Membership Tenure System
- In [add_student_wizard_screen.dart](file:///d:/Tutorial/Library-app/lib/screens/students/add_student_wizard_screen.dart), the Joining Date field is permanently locked with a `Fixed / Non-editable` badge.
  - When creating a new student: Fixed to today (`DateTime.now()`).
  - When editing an existing student: Fixed to original `s.joinedAt`.
- **Tenure Formula**:
  ```dart
  final studentJoin = student.joinedAt ?? DateTime.now();
  final daysCompleted = (DateTime.now().difference(DateTime(studentJoin.year, studentJoin.month, studentJoin.day)).inDays + 1).clamp(1, 99999);
  ```

### 5.4 Multi-Month Advance Billing & Date Calculation
- When a student pays for $N$ months ($N \ge 1$):
  - `_validUntilDate` extends to $N$ months from `_fromDate`.
  - Total fee calculates as `_fixedMonthlyFee * months`.
  - If the student is already active and paying in advance, illegal overlapping dates are blocked with a validation warning.

### 5.5 Phone Normalization & Duplicate Prevention
Indian phone numbers are normalized to 10 digits before saving or querying:
```dart
static String normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return digits;
  if (digits.length > 10 && digits.startsWith('91')) return digits.substring(digits.length - 10);
  if (digits.length > 10 && digits.startsWith('0')) return digits.substring(digits.length - 10);
  return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
}
```

---

## 6. Authentication, Multi-Tenancy & RBAC

Located in [lib/services/library_service.dart](file:///d:/Tutorial/Library-app/lib/services/library_service.dart) and [lib/screens/login_screen.dart](file:///d:/Tutorial/Library-app/lib/screens/login_screen.dart):

1. **Role Hierarchy**:
   - `Admin`: Full permissions (view revenue, configure shifts, delete students, export data, manage branches).
     - Standard credentials: `manageyourlib@gmail.com` (password: `admin123` or custom).
     - Legacy support: `nivi@library.com`.
     - Direct contact number: `9457464850`.
   - `Receptionist`: Desk operations only (seat check-in, search members, collect standard renewal fees). Blocked from editing shift pricing or deleting database records. Authenticates via 4-digit PIN.
2. **Multi-Tenant Data Namespacing**:
   - In Firestore, collections are namespaced under `/libraries/{tenantId}/...` (`students`, `seats`, `payments`, `expenses`, `branches`).

---

## 7. Guided Onboarding Process

Located in [lib/screens/onboarding/](file:///d:/Tutorial/Library-app/lib/screens/onboarding/):
Designed for first-time library owners to set up their branch in under 2 minutes:
1. `welcome_carousel_screen.dart`: Visual value proposition slides.
2. `admin_profile_screen.dart`: Owner name, library name, phone (`9457464850`), email (`manageyourlib@gmail.com`).
3. `workspace_setup_screen.dart`: City, address, Wi-Fi details, library rules.
4. `shift_setup_screen.dart`: Operating shifts selection and fee tiers.
5. `seat_setup_screen.dart`: Total desk capacity, section naming (*Main Hall, AC Cabin*).
6. `review_setup_screen.dart`: Summary inspection with 1-tap confirmation.
7. `setup_success_screen.dart`: Animation and direct entry into the Main Hub.

---

## 8. Adaptive Theme & Design System

Located in [lib/constants/app_colors.dart](file:///d:/Tutorial/Library-app/lib/constants/app_colors.dart) and [lib/services/theme_service.dart](file:///d:/Tutorial/Library-app/lib/services/theme_service.dart):
- **Light Mode**: Clean aesthetic with `#0D9488` (Teal), `#0284C7` (Sky Blue), `#F8FAFC` (Slate Surface), `#0F172A` (Navy Text).
- **Dark Mode**: Premium Slate `#0F172A` background, `#1E293B` cards, `#334155` borders, and high-contrast `#F8FAFC` text.
- Widgets call `AppColors.card(context)`, `AppColors.text(context)`, and `AppColors.cardBorderColor(context)` to adapt dynamically.

---

## 9. Automated Testing & Verification Suite

All tests reside in `test/` and run locally or on GitHub Actions via `flutter test`:

| Test Suite | Purpose |
| :--- | :--- |
| `seat_and_student_test.dart` | Phone normalization, duplicate phone detection, 1-to-1 seat collision locking, shift conflict rules, multi-month tenure calculations, shift upgrade/downgrade financial calculations, tenure days completed calculations. |
| `financial_ledger_test.dart` | Fee collection, dues decrementing, expense additions, payment ledger queries. |
| `auth_and_rbac_test.dart` | Admin authentication (`manageyourlib@gmail.com`), receptionist PIN login, session management, multi-tenant isolation. |
| `dark_mode_and_theme_test.dart`| ThemeService toggle, Material 3 flags, dynamic slate color tokens. |
| `backup_restore_test.dart` | Full JSON schema export, complete state rehydration, invalid payload handling. |
| `excel_import_test.dart` | CSV/TSV parsing from Microsoft Excel, auto-header detection, row validation errors. |
| `multi_branch_and_staff_test.dart` | Multi-branch creation, branch switching, staff active toggles. |
| `app_screens_compilation_test.dart` | Top-level widget construction and compilation sanity checks. |

---

## 10. AI Agent Engineering Guidelines

When any AI assistant or developer is tasked with extending or modifying this project, the following instructions **must** be obeyed:

### Critical Invariants (DO NOT VIOLATE)
1. **Never break offline capability:** Do not introduce network-blocking code in synchronous initialization flows. All writes must succeed locally via `LibraryService` first.
2. **Never change canonical contact details:** Everywhere in the app, the primary contact email must remain `manageyourlib@gmail.com` and phone `9457464850`.
3. **Always preserve shift credit calculation:** Never charge a student twice when they upgrade back to an earlier paid shift tier. Always inspect `(Original paid: ₹X)` in student notes.
4. **Preserve non-editable Joining Date:** The joining date is the immutable anchor for tenure. Never allow user input to overwrite `joinedAt`.
5. **Always date-normalize tenure days:** Always compute days completed using date-only normalization (`DateTime(year, month, day)`), clamped to $\ge 1$.
6. **Keep conditional exports intact:** Never import `dart:html` or `dart:io` directly in screens or shared services. Always route through `file_export_service.dart` or `local_storage_service.dart`.
7. **Always verify compilation:** Ensure `flutter test` succeeds with 0 failures before pushing code.

### Step-by-Step Guide for Adding New Features
1. **Adding a New Data Field to Students**:
   - Update `StudentInfo` in `lib/models/library_models.dart`.
   - Update `toMap()` and `fromMap()` serializers.
   - Update `updateStudent` and `assignSeatAndRegisterStudent` in `LibraryService`.
   - Expose the field in `add_student_wizard_screen.dart` and `member_profile_screen.dart`.
   - Add a unit test in `test/seat_and_student_test.dart`.
2. **Adding a New Operating Screen**:
   - Create screen in `lib/screens/<category>/`.
   - Wrap interactive content in `StreamBuilder` connected to `LibraryService.instance` streams.
   - Use `AppColors` semantic getters (`AppColors.card(context)`, etc.) for seamless Dark Mode.
   - Add navigation entry in `main_hub_screen.dart` or `settings_screen.dart`.

---

## 11. Technical Roadmap & Future Improvements

1. **Biometric & RFID Turnstile Integration**:
   - MQTT or HTTP Webhook listener in `LibraryService` to automatically mark daily attendance when a member taps an RFID card or scans their dynamic QR pass.
2. **Razorpay / UPI Intent Payment Gateway**:
   - Optional online payment link generation via UPI Dynamic QR for students to pay dues from their own mobile phones.
3. **SMS & WhatsApp Cloud API Gateway**:
   - Direct background webhook dispatch to WhatsApp Business Cloud API in addition to the current `url_launcher` intent.
4. **Thermal Receipt Printer Support**:
   - Bluetooth ESC/POS printing service for instant 58mm/80mm physical paper receipts.
