# TrackMyLibrary — End-User Guide

**A complete, step-by-step guide to running your study hall or library with TrackMyLibrary.**

---

## Table of Contents
1. [Getting Started & Signing In](#1-getting-started--signing-in)
2. [First-Time Library Setup Wizard](#2-first-time-library-setup-wizard)
3. [App Navigation & Roles](#3-app-navigation--roles)
4. [Home Dashboard](#4-home-dashboard)
5. [Managing Students & Admissions](#5-managing-students--admissions)
6. [Seats & Multi-Shift Management](#6-seats--multi-shift-management)
7. [Fee Collection, Dues & WhatsApp Receipts](#7-fee-collection-dues--whatsapp-receipts)
8. [Expenses & Financial Analytics](#8-expenses--financial-analytics)
9. [Student Portal, Self-Registration & QR Standee](#9-student-portal-self-registration--qr-standee)
10. [WhatsApp Tools, Branding & Reports](#10-whatsapp-tools-branding--reports)
11. [Branches, Staff Accounts & Security](#11-branches-staff-accounts--security)
12. [Backups, Excel Import/Export & Disaster Recovery](#12-backups-excel-importexport--disaster-recovery)
13. [Appearance & Language (English / हिंदी)](#13-appearance--language-english--हिंदी)
14. [Quick Troubleshooting & FAQs](#14-quick-troubleshooting--faqs)

---

## 1. Getting Started & Signing In

On the login screen, choose between two modes at the top:

- **Owner / Admin**: Full access to seats, student admissions, fee collection, revenue reports, analytics, branches, staff accounts, and settings.
  - Sign in with your **Owner Email or Mobile** and **Password / PIN**.
  - Or tap **Continue with Google** to sign in with Google and enable cloud sync.
  - Use **Forgot Password?** on the login screen to receive a Firebase password reset email.
- **Staff / Desk**: Restricted daily-operations login for team members.
  - Enter the staff member's **Registered Mobile or Email** and their **4-digit PIN**.
  - If a staff member forgets their PIN, the Library Owner can check or manage staff accounts under **Settings → User Management**.
- **Fingerprint / Biometric Login**: Once you sign in and tag your device fingerprint under **Settings → Fingerprint Login Tag**, a biometric button appears next to Sign In for one-touch access.
- **Quick Demo Mode**: On the login screen, you can tap **Admin Demo** or **Staff Reception** to preview the app with sample credentials (`1234`).

---

## 2. First-Time Library Setup Wizard

If you are registering a new library (or signing in with Google for the first time), the onboarding wizard walks you through setting up your space:

1. **Workspace Setup**: Enter your library name and location/address.
2. **Seat & Section Setup**: Configure your hall/section names (for example, *Main Hall*) and seat range (default starts at Seats `1–35`).
3. **Shift Setup**: Review, rename, adjust timings, set monthly fees, or add custom shifts. Default active shifts are:
   - **Full Day**: `06:00 AM – 10:00 PM` (₹500/month default)
   - **Morning Shift**: `06:00 AM – 02:00 PM` (₹600/month default)
   - **Evening Shift**: `02:00 PM – 10:00 PM` (₹600/month default)
   - **Night Shift**: `10:00 PM – 06:00 AM` (₹500/month default)
   - **24 Hours**: `12:00 AM – 11:59 PM` (₹1,500/month default)
4. **Admin Profile**: Confirm your owner name, contact phone, and library details.
5. **Review & Finish**: Verify your summary and launch the main dashboard.

---

## 3. App Navigation & Roles

The bottom navigation bar adapts automatically to the signed-in user's role:

| Tab | What It Does | Who Can See It |
| :--- | :--- | :--- |
| **Home** | Daily overview, Quick Actions, Pending Dues banner, Manage & Tools grids | Everyone |
| **Students** | Student directory, search, status filters, admission wizard, and Member Profiles / ID Cards | Everyone |
| **Seats** | Interactive seat grid by shift & section, vacant/occupied status, assign/swap/vacate seats | Owner & Desk Staff (hidden for *Accountant & Fees*) |
| **Payments** | Fee collection ledger, payment history, and dues tracking | Owner / Admin |
| **Analytics** | Revenue vs. expense charts, net profit metrics, and expense logging | Owner / Admin |
| **Settings** | Language, theme, profile, branches, staff, backups, branding, and legal links | Everyone (admin tools visible only to Owner) |

---

## 4. Home Dashboard

The **Home** tab gives you one-tap access to daily library tasks:

- **Branch Selector**: Tap the active branch badge near the top to switch between branches/floors or choose **All Branches (Combined)** (Owner only).
- **Quick Actions**: Swipe horizontally for shortcuts:
  - **Add Student** — Launches the 3-step admission wizard.
  - **Send Reminders** — Jumps directly to students with pending dues (`DUES`).
  - **Log Expense** — Opens the quick expense entry sheet.
  - **View Reports** *(Owner)* / **Seat Layout** *(Staff)* — Opens Analytics or Seats.
  - **Student Portal** — Opens the QR & Standee screen.
- **Pending Dues Banner**: Shows total unpaid dues and how many students have pending balances; tap **Collect** to jump straight to them.
- **Manage Grid**: Quick tiles for **Students**, **Seats**, **Payments**, **Shifts**, **Analytics**, and **Student ID**.
- **Tools & More Grid**: Direct access to **WhatsApp**, **Reports**, **Student Portal**, **Branding**, **Refer & Earn**, and **Community**.

---

## 5. Managing Students & Admissions

### Adding a New Student (3-Step Wizard)
Tap **+ Add Student** from **Home** or the **Students** tab:

1. **Step 1 — Basic Info**: Enter full name, 10-digit mobile number, optional email, guardian/exam details, address, and optional photo.
2. **Step 2 — Schedule & Fees**:
   - Choose a **Shift** (e.g., *Morning Shift*, *Evening Shift*, *Full Day*).
   - Pick an available **Seat** (seats already occupied in that shift are blocked so double-booking cannot happen).
   - Choose tenure (e.g., 1 month or multi-month), fee collected today, payment method, and next due date.
3. **Step 3 — Review**: Confirm all details and save the admission.

### Finding & Managing Existing Students
In the **Students** tab:
- **Search**: Search by student name, phone number, or seat number.
- **Filter**: Filter by status (`RECENT`, `ALL`, `ACTIVE`, `DUES`, etc.) or by shift.
- **Member Profile**: Tap any student to view their full profile, payment history, notes, **Digital Student ID Card**, **Collect Fee**, **Change Seat**, **Upgrade Shift**, **Call**, or **WhatsApp** actions.

---

## 6. Seats & Multi-Shift Management

Because multiple students can share the same desk at different times of day, the **Seats** tab tracks occupancy per shift:

- **Color & Status**: Quickly see which seats are **Filled** vs. **Vacant** for the selected shift and section (e.g., *Main Hall*).
- **Conflict Protection**:
  - A **Full Day** student occupies both Morning and Evening windows, blocking *Morning* and *Evening* bookings on that seat.
  - A **Morning Shift** seat remains available for **Evening Shift** or **Night Shift** students.
- **Seat Actions**:
  - Tap a **Vacant Seat** to assign a student directly.
  - Tap an **Occupied Seat** to view occupant details, collect due fees, **Change / Swap Seat**, or **Vacate Seat** when the student leaves.

### Configuring Shifts
Open **Manage → Shifts** (or **Settings → Shift Management** as Owner) to toggle shifts active/inactive, edit start/end times and monthly fees, or create custom shift slots.

---

## 7. Fee Collection, Dues & WhatsApp Receipts

### Recording a Payment
1. Open **Payments** (or tap **Collect Fee** on a student's card/profile).
2. Confirm the amount being paid, payment mode (UPI, Cash, Card, Bank Transfer), and period covered.
3. Save the payment to update the student's dues and advance their next due date.

### Sending Receipts & Reminders
- After recording a payment or from **WhatsApp Automation**, send pre-formatted payment receipts or fee due reminders directly to the student on WhatsApp (with automatic clipboard fallback if WhatsApp cannot open directly).

---

## 8. Expenses & Financial Analytics

*(Available to Owner / Admin)*

1. Open the **Analytics** tab (or tap **Log Expense** from **Home**).
2. Tap **+ Add Expense** to log recurring or one-off costs such as electricity, Wi-Fi, water, cleaning, or maintenance.
3. Review **Gross Revenue**, **Operating Expenses**, **Net Profit**, and occupancy trends across the selected period.

---

## 9. Student Portal, Self-Registration & QR Standee

Open **Student Portal** from **Home → Quick Actions / Tools & More**, or **Settings → DIGITAL ACCESS → Student Self-Service Portal & QR Standee**:

- **Self-Admission QR**: New applicants scan the QR code to fill out a self-registration form from their own phone (including photo/selfie upload, Aadhaar/phone validation, and rules acceptance).
- **Live Seat & Student Portal**: Existing students can check live seat availability, view their seat/dues status, and record gate check-ins.
- **Reception Poster / Standee**: Copy or share the formatted reception notice and QR link for printing or posting to WhatsApp groups.
- **Custom Portal URL**: Update the web portal host URL if you host your portal on a custom domain or GitHub Pages.

---

## 10. WhatsApp Tools, Branding & Reports

- **WhatsApp Automation** (*Home → Tools & More → WhatsApp*, or *Settings → AUTOMATION*):
  - Send individual or bulk fee due reminders (including **Copy All Reminder Messages**).
  - Message filtered students via WhatsApp or SMS.
  - Customize reusable templates under **Settings → Message Templates** (Welcome Note, Payment Receipt, Fee Due Reminder, Seat Allotment, Seat Change, Shift Change, General Follow-up).
- **Library Branding** (*Home → Tools & More → Branding*, or *Settings → Library Branding*, Owner only):
  - Upload a custom library logo or choose a preset emblem.
  - Pick your accent color palette, badge/receipt theme, library motto, and optional ID card watermark crest.
- **Reports & Exports** (*Home → Tools & More → Reports*, or *Settings → Reports & Exports*, Owner only):
  - Download `.csv` files for Microsoft Excel, copy tab-separated rows to paste into Excel, preview tables inside the app, or share summaries to WhatsApp.

---

## 11. Branches, Staff Accounts & Security

*(Configured by Owner / Admin in **Settings**)*

- **Multi-Branch & Floor Management**:
  - Go to **Settings → Add New Library Branch** to add extra floors, halls, or locations with their own seat capacities.
  - Switch views anytime via **Settings → Branch Switcher** or the branch chip on **Home**.
- **Staff Accounts & Permissions**:
  - Go to **Settings → User Management → Add Staff Member**.
  - Assign a name, mobile/email, assigned branch, 4-digit PIN, and one of these roles:
    - **Receptionist & Desk**
    - **Shift Manager**
    - **Accountant & Fees** *(fee & student view; no seat layout edits)*
    - **Night Supervisor**
    - **Branch Assistant**
  - Staff members are automatically locked to their assigned branch and cannot view Owner-only revenue analytics, delete records, or modify global library settings.
- **Security**:
  - **Settings → Security & Master Password**: View your Cloud Auth UID and update your Admin password.
  - **Settings → Fingerprint Login Tag**: Link or unlink 1-touch fingerprint login for your account on the current device.

---

## 12. Backups, Excel Import/Export & Disaster Recovery

Keep your library records safe and portable from **Settings → DATA & SECURITY** and **Settings → Google Drive & Cloud Recovery**:

- **Full Library Backup (`.JSON`)**: Export a complete offline snapshot of students, payments, seats, and settings.
- **Restore Library from Backup**: Rehydrate your database on a new phone or after reinstalling by restoring from a saved backup.
- **Export Student Master (`.CSV`)**: Download a spreadsheet of all registered students (`Student ID`, `Full Name`, `Phone`, `Seat Number`, `Shift`, `Monthly Fee`, `Status`, `Joined Date`, `Dues Amount`, `Section`).
- **Bulk Student Import**: Download the `.csv` Excel template or paste rows directly from Excel to import multiple students at once (with a summary showing imported rows, skipped rows, warnings, and errors).
- **Google Drive & Cloud Recovery** *(Owner)*: Configure target Google Drive email for Excel backups, synchronize from Google Cloud Firestore, or paste/restore a backup snapshot.
- **Save Students to Contacts** *(Owner)*: Export/save student contacts so names appear on incoming calls and in WhatsApp.

---

## 13. Appearance & Language (English / हिंदी)

Under **Settings → APPEARANCE & LANGUAGE**:

- **App Language / भाषा**: Switch between **English** and **हिंदी (Hindi)** at any time.
- **Theme Mode**: Choose **Light**, **Dark**, or **System Default**.

---

## 14. Quick Troubleshooting & FAQs

**Why can't I assign a seat that looks empty in a shift?**
Check whether the seat is booked under **Full Day** (`06:00 AM – 10:00 PM`) or **24 Hours**. Overlapping shifts block each other automatically to prevent double-booking.

**Why don't staff members see the Payments or Analytics tabs?**
By design, **Payments**, **Analytics**, **Reports**, **Branch Switching**, and **Staff/Security Settings** are restricted to the **Owner / Admin** account.

**What if WhatsApp doesn't open when sending a receipt or reminder?**
TrackMyLibrary automatically copies the formatted message to your clipboard so you can paste and send it manually in WhatsApp or SMS.

**How do I contact support?**
Go to **Settings → SUPPORT & FEEDBACK** for direct **Contact on WhatsApp** (`+91 94574 64850`) or **Email Support** (`manageyourlib@gmail.com`).
