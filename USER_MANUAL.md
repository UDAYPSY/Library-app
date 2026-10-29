# TrackMyLibrary — Complete User Guide & Manual
**Modern Library & Study Hall Management Application**

---

## Welcome to TrackMyLibrary!
**TrackMyLibrary** is a professional management system built specifically for modern libraries, study halls, and co-working spaces. It simplifies daily desk operations, automates fee collection, manages multi-shift seat allocations, tracks student attendance, and handles multiple branches or floors effortlessly.

Whether you run a single 35-seat study room or a multi-branch enterprise across multiple cities, this guide will walk you through every feature in simple, everyday language.

---

## Table of Contents
1. [Getting Started & Logging In](#1-getting-started--logging-in)
2. [Navigating the App](#2-navigating-the-app)
3. [The Home Dashboard](#3-the-home-dashboard)
4. [Managing Students & Admissions](#4-managing-students--admissions)
5. [Interactive Seats & Shift Management](#5-interactive-seats--shift-management)
6. [Fee Collections, Receipts & Dues Tracking](#6-fee-collections-receipts--dues-tracking)
7. [Daily Expenses & Net Profit Analytics](#7-daily-expenses--net-profit-analytics)
8. [Multi-Branch & Floor Management](#8-multi-branch--floor-management)
9. [Staff User Management & Role Security](#9-staff-user-management--role-security)
10. [Student Digital ID Card & QR Codes](#10-student-digital-id-card--qr-codes)
11. [Student Self-Service Portal](#11-student-self-service-portal)
12. [WhatsApp Tools & Broadcast Announcements](#12-whatsapp-tools--broadcast-announcements)
13. [Data Backup, Restore & Disaster Recovery](#13-data-backup-restore--disaster-recovery)
14. [Troubleshooting & Frequently Asked Questions](#14-troubleshooting--frequently-asked-questions)

---

## 1. Getting Started & Logging In

### First Time Setup
When you open TrackMyLibrary for the first time:
1. You can sign in using your **Google Account** (Cloud Sync enabled) or use **Offline Local Mode**.
2. **Default Administrator PIN**: If running in offline mode, your default administrator PIN is **`1234`**. You can change this anytime under **Settings &rarr; Security & Master PIN**.
3. Complete your library profile: Enter your Library Name, City/Address, Admin Phone Number, and your **UPI ID** (e.g. `yourname@upi` or your 10-digit phone number) so students can pay you directly via QR code.

### Staff Logins
- Staff members (Desk Receptionists, Branch Managers, Accountants) can log in using their **10-digit mobile number** or **email** and their **assigned 4-digit PIN**.
- When staff members log in, the app automatically switches to their assigned branch and hides administrative menus based on their permissions.

---

## 2. Navigating the App

The main navigation bar at the bottom gives you 1-tap access to 6 core sections:

| Tab Name | Icon | What You Do Here |
| :--- | :--- | :--- |
| **Home** | Grid Icon | High-level summary, live seat gauge, quick actions, and revenue highlights. |
| **Students** | People Icon | Search, filter, view profiles, register new members, and download ID cards. |
| **Seats** | Chair Icon | Interactive seat grid, shift-wise occupation, vacant seat discovery, and seat swapping. |
| **Payments** | Card Icon | Complete transaction history, dues list, fee collections, and WhatsApp receipts. |
| **Analytics** | Bar Chart | Revenue charts, daily expenses, net profit, and Excel financial exports. |
| **Settings** | Gear Icon | Branches, staff management, shifts/pricing, backup/restore, and branding. |

---

## 3. The Home Dashboard

The Home screen provides a real-time overview of your library:
- **Greeting & Active Branch Badge**: Right under your greeting, tap the **Branch Chip** (e.g., *Main Campus • 35 Seats*) to instantly switch between floors or locations.
- **Seat Occupancy Gauge**: Displays your occupied seats vs. total seats capacity with an occupancy percentage bar.
- **Financial Cards**:
  - **Today's Collections**: Revenue collected since 12:00 AM today.
  - **Active Dues**: Total pending balance across all enrolled students.
  - **This Month's Revenue**: Total fee collections for the active calendar month.
  - **Total Active Students**: Headcount of members currently holding an active desk membership.
- **Quick Action Bar**:
  - **+ Add Student**: Opens the step-by-step admission wizard.
  - **Collect Fee**: Quickly record a payment without navigating to student details.
  - **Broadcast**: Send an alert or notice to your active students via WhatsApp.
  - **Shifts & Slots**: View and adjust daily shift hours and standard rates.

---

## 4. Managing Students & Admissions

### Registering a New Student (+ Add Student Wizard)
1. Tap the green **+** button on the bottom right of the **Students** tab or tap **+ Add Student** on the Home screen.
2. **Step 1: Personal Details**:
   - Enter Full Name, 10-Digit Mobile Number, Optional Email, Father's Name, Gender, Preparation Exam (e.g., UPSC, NEET, Banking), and Address.
   - Upload or take a profile photo (optional).
3. **Step 2: Shift & Seat Allocation**:
   - Choose a shift (e.g., *Full Day*, *Morning Shift*, *Evening Shift*, *Night Shift*, or *24 Hours*).
   - Tap **Select Seat**: The interactive grid will highlight available seats for that shift in green. Seats occupied during that same shift are marked in red and cannot be double-booked.
   - You can also register a student as **Unallocated** if they study in common open areas.
4. **Step 3: Fees & Tenure**:
   - Select membership duration (e.g., 1 Month, 3 Months, 6 Months, or 1 Year).
   - Enter fee collected today, any initial discount, and remaining dues (if any).
   - Choose payment mode: **UPI**, **Cash**, **Card**, or **Bank Transfer**.
5. Tap **Register Student**. The app automatically:
   - Reserves the seat for that shift.
   - Creates a digital payment invoice in the financial ledger.
   - Prepares a WhatsApp welcome message and digital receipt ready to send.

### Student Directory & Search
- **Search Bar**: Type any student name, phone number, or seat number (e.g. `S-12`) for instant search results.
- **Filters**: Quickly filter students by **Active**, **Pending Dues**, **Trial**, or **Inactive**.
- **Member Profile**:
  - Tap any student card to view their full profile, joining date, tenure expiry date, assigned seat, emergency phone, and notes log.
  - **Action Buttons**: Call, WhatsApp, download Digital Student ID card, assign/change seat, or mark inactive.

---

## 5. Interactive Seats & Shift Management

TrackMyLibrary features an intelligent, multi-shift visual seat grid.

### How Shifts Work
Because library desks are used throughout different hours of the day, a single physical seat can accommodate different students in different shifts without conflict:
- **Morning Shift** (06:00 AM – 02:00 PM)
- **Evening Shift** (02:00 PM – 10:00 PM)
- **Night Shift** (10:00 PM – 06:00 AM)
- **Full Day** (06:00 AM – 10:00 PM)
- **24 Hours** (All day access)

> **Conflict Safeguard**: If a seat is occupied by a *Full Day* student, the system will block *Morning* or *Evening* students on that same seat. If a seat is only occupied in the *Morning*, the seat remains available for *Evening* or *Night* students.

### Seat Grid Actions
1. **View Occupant**: Tap any seat number to view who sits there, their shift, due date, and contact number.
2. **Vacate Seat**: Tap **Vacate Seat** when a student leaves. This frees the seat for that shift while keeping the student's payment history and profile intact.
3. **Swap / Change Seat**: Tap **Change Seat** on the student's profile to reassign them to any currently vacant seat.

---

## 6. Fee Collections, Receipts & Dues Tracking

### Collecting Due Payments
1. Open the **Payments** tab or tap **Collect Fee** on any student card.
2. Select or search the student. The app automatically displays their current pending dues and next due date.
3. Enter amount being paid and payment mode (UPI, Cash, etc.).
4. Tap **Confirm Payment**.
5. The student's balance updates immediately, and a formal digital receipt is created.

### 1-Click WhatsApp Invoices
- Every recorded payment features a green **WhatsApp Receipt** button.
- Tapping it opens WhatsApp with a pre-formatted, polite message containing:
  - Library Name and Address
  - Receipt Number & Date
  - Student Name & Seat Number
  - Amount Paid & Remaining Dues (if any)
  - Valid Period (e.g., 01-Nov to 30-Nov)
  - Library Admin Contact Number

### Tracking Overdue Members
- The **Payments &rarr; Dues** section displays all students whose renewal dates have arrived or who have partial dues remaining.
- Tap **Send Due Reminder** to send a courteous reminder via WhatsApp with one tap.

---

## 7. Daily Expenses & Net Profit Analytics

TrackMyLibrary provides a full business ledger so you know your exact take-home profit:

### Adding an Expense
1. Go to the **Analytics** tab.
2. Scroll to the **Expenses** section and tap **+ Add Expense**.
3. Enter title (e.g. *Electricity Bill*, *High-Speed Wi-Fi*, *Cleaning Supplies*, *Water Can Delivery*, *Newspapers*).
4. Select category and enter the amount.
5. Tap **Save Expense**.

### Understanding Your Metrics
- **Gross Revenue**: All fees collected during the period.
- **Operating Expenses**: Total outflows recorded.
- **Net Profit**: Gross Revenue minus Operating Expenses.
- **Occupancy Rate**: Percentage of active seats generating revenue across all shifts.

---

## 8. Multi-Branch & Floor Management

If you operate multiple reading rooms, multiple floors, or different campus locations:

### Switching Between Branches
- **From Dashboard**: Tap the branch chip under the admin greeting at the top of the Home screen. Select your desired branch or select **All Branches (Combined)** to view overall totals.
- **From Settings**: Go to **Settings &rarr; Branch Switcher**.

### Adding a New Branch or Floor
1. Go to **Settings &rarr; Library Branches**.
2. Tap **Add New Library Branch**.
3. Enter:
   - Branch Name (e.g., *2nd Floor Silent Zone*, *South Campus Branch*).
   - Address / Location.
   - Total Seats Capacity (e.g., 50).
4. Tap **Save Branch**.
5. The visual seat map and member list automatically size to this branch's seat capacity.

---

## 9. Staff User Management & Role Security

Keep your business secure by giving staff members their own login credentials without exposing admin settings or bank accounts.

### Staff Roles & Permissions
| Role | Can Manage Seats? | Can Collect Fees? | Can View Total Revenue? | Can Add/Remove Staff? |
| :--- | :---: | :---: | :---: | :---: |
| **Administrator** | Yes | Yes | Yes | Yes |
| **Branch Manager** | Yes | Yes | Yes (Branch Only) | No |
| **Desk Receptionist** | Yes | Yes | No | No |
| **Accountant & Fees** | No | Yes | Yes | No |

### Adding a Staff Member
1. Open **Settings &rarr; User Management**.
2. Tap **+ Add Staff Member**.
3. Enter Name, Mobile Number, Email, Assigned Role, and their Assigned Branch.
4. Set a 4-digit PIN for them.
5. Tap **Create Staff Account**.
6. When the staff member logs into the app on their phone or tablet, they will automatically be locked to their assigned branch.

---

## 10. Student Digital ID Card & QR Codes

Provide professional digital identity cards to your students:
1. Open any student's profile.
2. Tap **Student ID Card**.
3. A student card is generated with:
   - Library Emblem / Logo
   - Student Photo & Name
   - Student ID & Seat Number
   - Shift & Expiry Date
   - QR Code for front-desk verification
4. Tap **Share / Download** to send it directly to the student on WhatsApp or save as an image.

---

## 11. Student Self-Service Portal & QR Standee

Students can check their own seat details, fee status, and library announcements online without needing staff assistance.

### How to Access the Portal & QR Standee in the App:
You can open this screen from any of the following 3 places:
1. **Home Screen (Quick Actions)**: Swipe horizontally across the **Quick Actions** row and tap the purple **Student Portal (Live QR & Standee)** card.
2. **Home Screen (Tools & More)**: Scroll down to the **Tools & More** section and tap **Student Portal**.
3. **Settings Tab**: Go to the **Settings** tab (gear icon at the bottom right), scroll down to **DIGITAL ACCESS**, and tap **Student Self-Service Portal & QR Standee**.

### What You Can Do in the Student Portal Screen:
- **Toggle Mode 1: Desk Self-Admission QR**:
  - Lets new prospective aspirants scan the QR code to fill out their admission application directly from their own phones and choose their shift.
- **Toggle Mode 2: Live Seat Availability & Student Portal**:
  - Lets enrolled students check their live seat allocation, view renewal dates, check pending dues, view library rules, and see Wi-Fi details.
- **Tap "Open Public Preview"**:
  - Instantly launches the live student portal preview directly inside the app so you can test and view what students experience.
- **Tap "Share / Download Standee"**:
  - Generates a branded reception standee with your library's QR code, UPI address, and Wi-Fi password to print and place on your front desk.

---

## 12. WhatsApp Tools & Broadcast Announcements

Communicate with your entire student body in seconds:
1. Go to the Home screen and tap **WhatsApp Tools** or **Broadcast Notice**.
2. **Options Available**:
   - **Send Notice to All Active Students**: Ideal for holiday notices, maintenance reminders, or festival greetings.
   - **Direct WhatsApp Chat**: Chat with any student without needing to save their number in your personal phone contacts.
   - **Payment Reminder Broadcast**: Politely notify members with upcoming due dates.

---

## 13. Data Backup, Restore & Disaster Recovery

Your data belongs to you. TrackMyLibrary ensures you never lose a single record:

### 1-Click Cloud Sync
- When connected to Firebase / Google Cloud, all admissions, payments, and seat updates synchronize across all your phones, tablets, and computers automatically.

### Full Offline JSON Backup
1. Go to **Settings &rarr; Disaster Recovery & Backups**.
2. Tap **Export Full Database Backup (JSON)**.
3. Save the downloaded backup file safely to Google Drive, WhatsApp, or your computer.
4. If you change your phone, tap **Restore Backup File** to rehydrate your entire library database in 5 seconds.

### Excel Spreadsheet Export
- Tap **Export Students to Excel (.xls)** to download your complete student directory with phone numbers, seats, dues, and join dates.
- Compatible with Microsoft Excel, Google Sheets, and LibreOffice.

---

## 14. Troubleshooting & Frequently Asked Questions

#### Q1: A seat shows occupied, but I need to put a student in a different shift. Why is it blocked?
> **Answer**: Check the existing occupant's shift. If the current student is registered for *Full Day* (06:00 AM to 10:00 PM), that seat is occupied for both Morning and Evening hours. To put two students on one seat, ensure one student has *Morning Shift* (06:00 AM – 02:00 PM) and the other has *Evening Shift* (02:00 PM – 10:00 PM).

#### Q2: What is the default Master Admin PIN?
> **Answer**: In offline or local mode, the default PIN is **`1234`**. You can change your password anytime under **Settings &rarr; Security & Master PIN**.

#### Q3: How do I change my library's UPI payment address?
> **Answer**: Go to **Settings &rarr; Library Profile**. Update your **UPI ID** (e.g. `9876543210@upi` or `mylibrary@okhdfcbank`). All payment QR codes will instantly route to your new UPI account.

#### Q4: What happens when a student's month ends?
> **Answer**: The student's status automatically turns to **DUES** or **EXPIRED**, and they will appear on the top of the **Dues List** in the Payments tab. When they pay for the new month, tap **Collect Fee**, and their due date will advance by their selected tenure.

#### Q5: Can a receptionist delete financial records or change library settings?
> **Answer**: No. Financial deletion and sensitive settings are strictly locked to the **Administrator** role. Receptionists and desk staff can only register admissions, assign seats, and collect fees.

---
*TrackMyLibrary — Enterprise Study Hall & Library Management System.*
