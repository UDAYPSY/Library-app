# TrackMyLibrary — AI Agent Work Instructions
> **File Purpose:** Standalone, self-contained task queue for AI agents and developers.
> **Read this file BEFORE starting any work on this project.**
> **Cross-reference:** `AI_TECHNICAL_MANUAL.md` for architecture, domain models, and business logic rules.
> **Rule:** Complete tasks in the order listed. Do NOT skip a Phase unless explicitly told to do so.
> **Verification:** After every task, run `flutter test` and confirm 0 failures before moving on.

---

## How to Use This File

1. Pick the next `[ ]` unchecked task in **Phase 1**.
2. Read the **Files to Edit**, **Implementation Pattern**, and **Acceptance Criteria** for that task.
3. Implement the change.
4. Run `flutter test`. Fix any failures before marking the task done.
5. Change `[ ]` to `[x]` and commit with the message format: `fix(phase1): <task title>`.

---

## Absolute Rules (Never Violate)

Before writing a single line of code, internalize these constraints:

1. **Never remove offline capability.** All writes must succeed locally via `LibraryService` before attempting cloud sync. Do NOT add `await` on Firestore calls in the main write path.
2. **Never change contact identity.** Email `manageyourlib@gmail.com` and phone `9457464850` must remain everywhere in the app.
3. **Never overwrite `joinedAt`.** The student joining date is immutable. Adding/editing a student must never change `s.joinedAt` once set.
4. **Never import `dart:html` or `dart:io` in screens.** Always use `file_export_service.dart` or `local_storage_service.dart` facades.
5. **Never break shift credit math.** Never charge a student twice when upgrading back to a previously paid shift tier. Always read `(Original paid: Rs.X)` from student notes.
6. **Run `flutter test` after EVERY change.** Zero tolerance for broken tests.

---

## Phase 1 — Security and Legal (Do First, Mandatory Before Any Launch)

### Task 1.1 — Fix Firestore Security Rules
- **Status:** `[x]`
- **Priority:** Critical
- **File to Edit:** `firestore.rules`
- **Problem:** Current rules use `if true` — anyone on the internet can read/write all student data including Aadhaar and photos. The `|| true` on delete rules defeats the auth check.

**Implementation Pattern:**
Replace the entire `firestore.rules` with properly secured rules. All read/write requires caller Firebase Auth UID to match the `libraryId` path segment.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isLibraryOwner(libraryId) {
      return request.auth != null && request.auth.uid == libraryId;
    }

    match /libraries/{libraryId} {
      allow read, write: if isLibraryOwner(libraryId);

      match /students/{studentId} {
        allow read: if isLibraryOwner(libraryId);
        allow create, update: if isLibraryOwner(libraryId)
                              && request.resource.data.name is string
                              && request.resource.data.name.size() > 0
                              && request.resource.data.phone is string;
        allow delete: if isLibraryOwner(libraryId);
      }

      match /seats/{seatId} {
        allow read, write: if isLibraryOwner(libraryId);
      }

      match /payments/{paymentId} {
        allow read: if isLibraryOwner(libraryId);
        allow create: if isLibraryOwner(libraryId)
                      && request.resource.data.amount is number
                      && request.resource.data.amount > 0;
        allow update, delete: if false;
      }

      match /expenses/{expenseId} {
        allow read, write: if isLibraryOwner(libraryId);
      }

      match /settings/{docId} {
        allow read, write: if isLibraryOwner(libraryId);
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Acceptance Criteria:**
- `firestore.rules` contains NO instance of `if true` at the top level.
- `|| true` pattern does NOT appear anywhere.
- All rules require `request.auth != null`.

---

### Task 1.2 — Implement Real Firebase Auth Login
- **Status:** `[x]`
- **Priority:** Critical
- **Files to Edit:** `lib/screens/login_screen.dart`, `lib/services/library_service.dart`, `lib/main.dart`

**Problem:** Login validates against hardcoded strings. `firebase_auth` is installed but `signInWithEmailAndPassword` is never called. Firestore rules cannot verify identity.

**Implementation Pattern:**

In `library_service.dart` replace local credential check:
```dart
Future<Map<String, dynamic>> signInAdmin({required String email, required String password}) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final uid = credential.user?.uid ?? '';
    currentAdminId = uid;
    currentRole = 'admin';
    _isLoggedIn = true;
    _tenantId = uid;
    await _loadFromFirestore();
    return {'success': true, 'role': 'admin', 'uid': uid};
  } on FirebaseAuthException catch (e) {
    String message = 'Login failed';
    if (e.code == 'user-not-found') message = 'No account found with this email.';
    if (e.code == 'wrong-password') message = 'Incorrect password.';
    if (e.code == 'too-many-requests') message = 'Too many attempts. Try again later.';
    return {'success': false, 'error': message};
  }
}

Future<void> signOut() async {
  await FirebaseAuth.instance.signOut();
  _isLoggedIn = false;
  currentRole = '';
  currentAdminId = '';
}
```

In `main.dart` after Firebase.initializeApp():
```dart
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null) {
  LibraryService().currentAdminId = currentUser.uid;
  LibraryService()._isLoggedIn = true;
}
```

**Acceptance Criteria:**
- Login calls `FirebaseAuth.instance.signInWithEmailAndPassword()`.
- Wrong password shows error message, does NOT crash.
- Refreshing the web app or restarting the Android app does NOT log out a previously logged-in user.
- `flutter test` passes.

---

### Task 1.3 — Remove Hardcoded Password from Source Code
- **Status:** `[x]`
- **Priority:** Critical
- **Files to Edit:** `lib/services/library_service.dart`

**Problem:** String `'admin123'` or any plaintext password in source code is visible to anyone with GitHub repo access.

**Implementation Pattern:**
1. Search for any hardcoded password strings: `admin123`, `password`, `pwd`.
2. Remove ALL hardcoded password comparisons.
3. The ONLY valid password check must go through `FirebaseAuth.instance.signInWithEmailAndPassword()`.
4. Create the default admin Firebase Auth account manually via Firebase Console > Authentication > Add User.

**Acceptance Criteria:**
- `grep -r "admin123" lib/` returns zero results.
- No plaintext password appears in `lib/`.

---

### Task 1.4 — Hash Staff PINs Before Storage
- **Status:** `[x]`
- **Priority:** Critical
- **Files to Edit:** `lib/models/library_models.dart`, `lib/services/library_service.dart`, `lib/screens/settings/settings_screen.dart`

**Problem:** Staff PINs are stored as plaintext strings in `StaffMember` model.

**Implementation Pattern:**

Add `crypto: ^3.0.6` to `pubspec.yaml` dependencies.

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

static String hashPin(String pin) {
  final bytes = utf8.encode(pin);
  return sha256.convert(bytes).toString();
}

static bool verifyPin(String inputPin, String storedHash) {
  return hashPin(inputPin) == storedHash;
}
```

In `StaffMember`, rename field from `pin` to `pinHash` and update all serializers.
When creating/editing staff in settings, always call `hashPin(rawPin)` before saving.
In login flow, use `verifyPin(enteredPin, staff.pinHash)`.

**Acceptance Criteria:**
- `StaffMember.pinHash` stores a 64-character SHA-256 hex string, never the raw PIN.
- `grep -r ".pin ==" lib/` returns zero results.
- `flutter test` passes.

---

### Task 1.5 — Add Privacy Policy and Terms of Service Links
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `lib/screens/login_screen.dart`, `lib/screens/onboarding/welcome_carousel_screen.dart`

**Implementation Pattern:**

Add tappable links at the bottom of the Login screen and last onboarding slide:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://manageyourlib.com/privacy')),
      child: const Text('Privacy Policy',
        style: TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline, fontSize: 12)),
    ),
    const Text(' • ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    GestureDetector(
      onTap: () => launchUrl(Uri.parse('https://manageyourlib.com/terms')),
      child: const Text('Terms of Service',
        style: TextStyle(color: Color(0xFF0284C7), decoration: TextDecoration.underline, fontSize: 12)),
    ),
  ],
)
```

Also create `web/privacy.html` and `web/terms.html` placeholder pages.

**Acceptance Criteria:**
- Privacy Policy and Terms links visible and tappable on the login screen.
- Tapping opens browser tab, does NOT crash on any platform.

---

### Task 1.6 — Add Firebase App Check
- **Status:** `[x]`
- **Priority:** Critical
- **Files to Edit:** `pubspec.yaml`, `lib/main.dart`

**Problem:** Without App Check, anyone who copies your Firebase project ID can call Firestore from scripts/Postman bypassing auth.

Add to `pubspec.yaml`:
```yaml
firebase_app_check: ^0.3.1+2
```

In `main.dart` after Firebase.initializeApp():
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
  webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
);
```

**Acceptance Criteria:**
- App Check activated in `main.dart`.
- Firebase Console > App Check shows the app registered.
- `flutter test` passes (mock App Check in test environment).

---

## Phase 2 — Play Store Launch and Monitoring

### Task 2.1 — Set Up APK Release Signing
- **Status:** `[x]`
- **Priority:** Critical
- **Files to Edit:** `.github/workflows/build-apk.yml`

**Problem:** CI builds an unsigned APK. Play Store requires a release-signed APK with a permanent keystore.

**Step A — Generate keystore once (locally):**
```bash
keytool -genkey -v -keystore trackmylibrary-release.jks \
  -alias trackmylibrary -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=TrackMyLibrary, OU=Dev, O=ManageYourLib, L=India, ST=UP, C=IN"
```

**Step B — Add GitHub Secrets:**
- `KEYSTORE_BASE64` = base64-encoded keystore
- `KEY_ALIAS` = trackmylibrary
- `KEY_PASSWORD` = your password
- `STORE_PASSWORD` = your store password

**Step C — Update `build-apk.yml`:**
```yaml
- name: Decode Keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/trackmylibrary-release.jks

- name: Compile Release APK
  env:
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
    STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
  run: flutter build apk --release --no-tree-shake-icons
```

**Acceptance Criteria:**
- CI produces a signed APK (jarsigner -verify succeeds).
- `*.jks` is in `.gitignore`, NOT committed.

---

### Task 2.2 — Add Firebase Crashlytics
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `pubspec.yaml`, `lib/main.dart`

Add to `pubspec.yaml`:
```yaml
firebase_crashlytics: ^4.1.3
```

In `main.dart`, replace current error handler:
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

Replace `debugPrint('Error: ...')` in `catch` blocks in `library_service.dart` with:
```dart
FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Context description');
```

**Acceptance Criteria:**
- A test crash appears in Firebase Console > Crashlytics within 5 minutes.
- `flutter test` passes.

---

### Task 2.3 — Add Image Compression Before Storage
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `pubspec.yaml` and any file calling `ImagePicker()`

**Problem:** Phone photos are 4-8MB. Stored as Base64 in Firestore documents which have a 1MB limit.

Add to `pubspec.yaml`:
```yaml
flutter_image_compress: ^2.3.0
```

Replace image pick and store flow:
```dart
Future<String?> _pickAndCompressPhoto() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image == null) return null;
  final compressed = await FlutterImageCompress.compressWithFile(
    image.path, minWidth: 400, minHeight: 400, quality: 70, format: CompressFormat.jpeg,
  );
  if (compressed == null) return null;
  return 'data:image/jpeg;base64,${base64Encode(compressed)}';
}
```

**Acceptance Criteria:**
- A stored photo Base64 string decodes to <= 250KB.
- `flutter test` passes.

---

### Task 2.4 — Input Sanitization and Field Validation
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `lib/screens/students/add_student_wizard_screen.dart`

Add sanitizer utility:
```dart
String _sanitize(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');
```

Add these validations before saving a student:
```dart
if (_nameController.text.trim().length < 2) error = 'Name must be at least 2 characters';
if (_nameController.text.trim().length > 100) error = 'Name is too long (max 100 chars)';

final phone = LibraryService.normalizePhone(_phoneController.text);
if (phone.length != 10) error = 'Enter a valid 10-digit phone number';

final aadhaar = _aadhaarController.text.replaceAll(' ', '');
if (aadhaar.isNotEmpty && (aadhaar.length != 12 || int.tryParse(aadhaar) == null)) {
  error = 'Aadhaar must be exactly 12 digits';
}

if (_addressController.text.length > 500) error = 'Address is too long (max 500 chars)';
```

Apply `_sanitize()` to name, address, fatherName, preparationFor before saving.

**Acceptance Criteria:**
- A student with 1-character name cannot be saved.
- A 13-digit Aadhaar shows a validation error.
- Tests added to `seat_and_student_test.dart`.
- `flutter test` passes.

---

### Task 2.5 — Custom Domain for Web App
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `.github/workflows/build-apk.yml`

After registering `manageyourlib.com`:

Create `web/CNAME` with content: `app.manageyourlib.com`

Update web build in `build-apk.yml`:
```yaml
flutter build web --release --base-href "/"
```

Configure GitHub Pages custom domain in repo Settings > Pages.

**Acceptance Criteria:**
- Web app loads at custom domain with valid HTTPS.
- No JS console errors about incorrect base-href.

---

## Phase 3 — Payments and SaaS Monetization

### Task 3.1 — Razorpay UPI QR for Student Due Collection
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `pubspec.yaml`, `lib/screens/payments/revenue_screen.dart`, `lib/screens/students/member_profile_screen.dart`

Add to `pubspec.yaml`:
```yaml
razorpay_flutter: ^1.3.7
```

In member profile screen, add "Collect Payment" button that:
1. Opens Razorpay SDK for the due amount.
2. On success callback, calls `LibraryService().recordPayment()` and sets status to ACTIVE.

IMPORTANT: Store Razorpay key in `lib/constants/api_keys.dart` listed in `.gitignore`.
Provide `api_keys.dart.example` template in the repo.

**Acceptance Criteria:**
- "Collect Payment" button appears when `student.hasDues == true`.
- Successful payment updates student status and records a PaymentTransaction.
- API key is NOT committed to git.
- `flutter test` passes.

---

### Task 3.2 — SaaS Trial Period and License Check
- **Status:** `[x]`
- **Priority:** High
- **Files to Edit:** `lib/models/library_models.dart`, `lib/services/library_service.dart`, `lib/main.dart`

Add to `LibraryProfile`:
```dart
DateTime? trialStartedAt;
DateTime? subscriptionExpiresAt;

bool get isTrialExpired {
  if (subscriptionExpiresAt != null && subscriptionExpiresAt!.isAfter(DateTime.now())) return false;
  if (trialStartedAt == null) return false;
  return DateTime.now().difference(trialStartedAt!).inDays > 30;
}

int get trialDaysRemaining {
  if (trialStartedAt == null) return 30;
  return (30 - DateTime.now().difference(trialStartedAt!).inDays).clamp(0, 30);
}
```

In `main.dart`, after loading profile, check `isTrialExpired`. If true, show blocking non-dismissable dialog:
"Your 30-day free trial has ended. Subscribe at Rs.299/month to continue.
Contact: manageyourlib@gmail.com | 9457464850"

Store subscription in Firestore: `/libraries/{libraryId}/settings/subscription`.

**Acceptance Criteria:**
- Library with `trialStartedAt` 31 days ago sees subscription dialog on launch.
- Library with valid future `subscriptionExpiresAt` uses the app normally.
- `flutter test` passes.

---

### Task 3.3 — Push Notifications for Due Reminders
- **Status:** `[x]`
- **Priority:** Medium
- **Files to Edit:** `pubspec.yaml`, `lib/main.dart`
- **New File:** `functions/index.js`

Add to `pubspec.yaml`:
```yaml
firebase_messaging: ^15.1.3
```

In `main.dart`:
```dart
await FirebaseMessaging.instance.requestPermission();
final token = await FirebaseMessaging.instance.getToken();
if (token != null) await LibraryService().saveDeviceToken(token);
```

Create `functions/index.js` with a scheduled Cloud Function that runs daily at 9:00 AM IST, queries students with feeDueDate == tomorrow, and sends FCM push notification to the library owner.

**Acceptance Criteria:**
- Library owner receives push notification listing students with dues due tomorrow.
- `flutter test` passes.

---

### Task 3.4 — Email Receipt on Payment
- **Status:** `[x]`
- **Priority:** Medium
- **New File:** `functions/sendReceipt.js`

Firestore trigger on new `/libraries/{libraryId}/payments/{paymentId}` document:
- Reads student email if available.
- Sends HTML email receipt via SendGrid.
- Email contains: student name, seat number, amount paid, payment mode, validity period.

**Acceptance Criteria:**
- Payment receipt email sent within 30 seconds of recording a payment.

---

## Phase 4 — Scale and Polish

### Task 4.1 — App Version Check and Forced Update
- **Status:** `[x]`
- **Priority:** Medium
- **Files to Edit:** `pubspec.yaml`, `lib/main.dart`

Add to `pubspec.yaml`:
```yaml
package_info_plus: ^8.1.1
```

In `main.dart` after initialization:
```dart
final packageInfo = await PackageInfo.fromPlatform();
final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
final configDoc = await FirebaseFirestore.instance.collection('config').doc('app_version').get();
final minBuild = (configDoc.data()?['min_build'] as int?) ?? 1;

if (currentBuild < minBuild) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Update Required'),
      content: const Text('Please update TrackMyLibrary to continue.'),
      actions: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://play.google.com/store/...')),
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}
```

**Acceptance Criteria:**
- When `config/app_version.min_build` > installed build, non-dismissable update dialog appears.

---

### Task 4.2 — Data Sync Conflict Resolution
- **Status:** `[x]`
- **Priority:** Medium
- **Files to Edit:** `lib/services/library_service.dart`

Add `updatedAt: DateTime?` to `StudentInfo`, `SeatInfo`, and other mutable models.

In `updateStudent()`:
```dart
final existing = students.firstWhere((s) => s.id == student.id);
if (student.updatedAt != null && existing.updatedAt != null &&
    student.updatedAt!.isBefore(existing.updatedAt!)) {
  // Conflict: notify UI
  return false;
}
final updated = student.copyWith(updatedAt: DateTime.now());
```

Show SnackBar: "This student was modified on another device. Please refresh and try again."

**Acceptance Criteria:**
- Unit test in `seat_and_student_test.dart` demonstrates conflict detection.
- `flutter test` passes.

---

### Task 4.3 — Database Schema Migration
- **Status:** `[x]`
- **Priority:** Medium
- **Files to Edit:** `lib/services/library_service.dart`

Add `schemaVersion: int` to local JSON snapshot:
```dart
final snapshot = {
  'schemaVersion': 3,
  'students': students.map((s) => s.toMap()).toList(),
  // ...
};
```

On load, if `schemaVersion < current`, run migration:
```dart
void _migrateSchema(Map<String, dynamic> data, {required int fromVersion}) {
  if (fromVersion < 2) {
    for (final s in data['students'] as List) {
      s.putIfAbsent('gender', () => 'Male');
    }
  }
  if (fromVersion < 3) {
    for (final s in data['students'] as List) {
      s.putIfAbsent('updatedAt', () => null);
    }
  }
}
```

**Acceptance Criteria:**
- Old schema version 1 JSON correctly migrated to version 3 on load.
- `backup_restore_test.dart` includes migration test.
- `flutter test` passes.

---

### Task 4.4 — Hindi Localization
- **Status:** `[x]`
- **Priority:** Medium
- **New Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_hi.arb`

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
flutter:
  generate: true
```

Create `lib/l10n/app_en.arb` and `lib/l10n/app_hi.arb` with translations for all UI strings.
Add language toggle in `settings_screen.dart`.

**Acceptance Criteria:**
- Setting language to Hindi shows Hindi on all main tabs and login screen.
- `flutter test` passes.

---

### Task 4.5 — iOS Platform Support
- **Status:** `[x]`
- **Priority:** Medium

Steps:
1. On a Mac, run `flutter create --platforms ios .` in project root.
2. Set Bundle Identifier: `com.trackmylibrary.app`.
3. Configure signing with Apple Developer account.
4. Add to `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>TrackMyLibrary needs photo access to add member profile photos.</string>
<key>NSCameraUsageDescription</key>
<string>TrackMyLibrary needs camera access to capture member photos.</string>
```
5. Test: `flutter run -d "iPhone 15"`

**Acceptance Criteria:**
- App runs on iOS Simulator without errors.
- Photo picker works on iOS.

---

## External Accounts Needed (Human Action Required)

| # | Action | URL | Cost |
|---|--------|-----|------|
| A1 | Create Google Play Console account | play.google.com/console | Rs. 2,000 one-time |
| A2 | Register domain manageyourlib.com | namecheap.com | ~Rs. 800/year |
| A3 | Create Razorpay merchant account | razorpay.com | Free (2% per txn) |
| A4 | Upgrade Firebase to Blaze plan | console.firebase.google.com | Pay-as-you-go |
| A5 | Apple Developer account (iOS) | developer.apple.com | Rs. 7,500/year |
| A6 | SendGrid account (email receipts) | sendgrid.com | Free 100/day |
| A7 | Write and host Privacy Policy | GitHub Pages | Free |
| A8 | Create admin account in Firebase Console > Authentication > Add User | console.firebase.google.com | Free |
| A9 | Provide Razorpay API Key to developer | razorpay.com > Settings > API Keys | — |
| A10 | Provide reCAPTCHA v3 site key for web App Check | google.com/recaptcha | Free |

---

## Task Progress Summary

| Phase | Tasks | Done | Remaining |
|-------|-------|------|-----------|
| Phase 1 — Security and Legal | 6 | 6 | 0 |
| Phase 2 — Play Store Launch | 5 | 5 | 0 |
| Phase 3 — Payments and SaaS | 4 | 4 | 0 |
| Phase 4 — Scale and Polish | 5 | 5 | 0 |
| **Total** | **20** | **20** | **0** |

---

*Last updated: 2026-10-24 | Maintained by: AI Agent / TrackMyLibrary Dev Team*
*Contact: manageyourlib@gmail.com | +91 9457464850*
