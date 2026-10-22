# TrackMyLibrary — Customer Functionality & Feature Specification

> **Product Name:** TrackMyLibrary (Digital Library & Self-Study Room Operating System)  
> **Target Audience:** Library Owners, Study Room Operators, Co-working Hubs, Front-Desk Managers, and Desk Staff  
> **Supported Platforms:** Android Tablets & Phones, Windows/Mac/Linux Desktop Browsers, iPads & Chromebooks (PWA)  
> **Architecture:** Offline-First Hybrid (100% Data Sovereignty with Optional Cloud Sync)

---

## Executive Overview

**TrackMyLibrary** is an enterprise-grade digital operating system tailored specifically for self-study libraries, reading rooms, and co-working spaces. It eliminates chaotic paper registers, lost fee records, seat double-booking, and manual WhatsApp follow-ups by centralizing the entire library workflow into a single, highly visual, and offline-resilient dashboard.

---

## Comprehensive Feature Matrix: Functionality Provided to Customers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TRACKMYLIBRARY PLATFORM MATRIX                        │
├─────────────────────┬─────────────────────┬─────────────────────────────────┤
│  1. SEAT & SHIFT    │  2. MEMBER & KYC    │  3. DIGITAL ID PASS & QR        │
│  • Visual Seat Grid │  • Photo KYC Capture│  • High-Res ID Card Pass        │
│  • 1-to-1 Seat Lock │  • Normalized Phone │  • Dynamic Scannable QR         │
│  • Multi-Shift Mgmt │  • Anti-Duplicate   │  • 1-Tap WhatsApp Dispatch      │
│  • Section Zoning   │  • Aadhaar & Goal   │  • Print & PDF Export           │
├─────────────────────┼─────────────────────┼─────────────────────────────────┤
│  4. FINANCIAL LEDGER│  5. SPREADSHEET SYNC│  6. MULTI-BRANCH & STAFF        │
│  • 1-Tap Fee Collect│  • Excel/CSV Export │  • Multi-Location Switcher      │
│  • Cash / UPI Audit │  • Clipboard TSV In │  • Floor & Capacity Config      │
│  • GST Tax Invoices │  • CSV Template Gen │  • Role Boundaries (Admin/Desk) │
│  • Expense Tracking │  • vCard Phone Sync │  • Staff Active Status Toggle   │
├─────────────────────┴─────────────────────┴─────────────────────────────────┤
│  7. DATA SOVEREIGNTY & DISASTER RECOVERY                                    │
│  • 100% Offline-First Operation (LocalStorage)                              │
│  • 1-Click Full JSON Snapshot Backup (Logo, Members, Ledger, Photos)        │
│  • Rehydration Engine with Pre-Restore Inspection Modal                     │
│  • Production Error Boundary with Disaster Recovery "Return to Safety" UI   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Visual Physical Seat Map & Shift Management

The seat allocation engine gives library staff a bird's-eye view of every physical desk in the library.

- **Visual Interactive Floor Map**:
  - Dynamically renders all library seats (e.g., S-1 to S-100+) in a responsive grid.
  - Color-coded instant status indicators:
    - **Green / Subtle Grey:** Seat Available for allocation.
    - **Deep Indigo / Blue:** Occupied by an active member.
    - **Amber / Orange:** Occupied by a member with pending dues.
- **Strict 1-to-1 Seat Collision Lock**:
  - Eliminates accidental double-booking. A seat can only belong to exactly one member per shift.
  - Reallocating a member automatically vacates their old seat across the entire database.
- **Multi-Shift Configuration**:
  - **Full Day** (24 Hours or all-day study).
  - **Morning Shift** (e.g., 6:00 AM – 2:00 PM).
  - **Afternoon / Evening Shift** (e.g., 2:00 PM – 10:00 PM).
  - **Night Shift** (e.g., 10:00 PM – 6:00 AM).
- **Section & Zone Partitioning**:
  - Organize seats by areas: *Main Reading Hall*, *AC Cabin Section*, *Silent Discussion Zone*, etc.
- **1-Tap Quick Desk Actions**:
  - Tap any seat to view the current occupant, phone number, dues status, swap seats, vacate the desk, or collect renewal fees on the spot.

---

## 2. Member Enrollment, Photo KYC & Directory Management

A full-fledged student information system designed for fast walk-in admissions.

- **Multi-Step Onboarding Wizard**:
  - Fast, guided registration capturing essential KYC data in under 60 seconds.
- **Member Photo KYC Capture**:
  - **Live Camera Capture**: Take student portraits directly using device webcam/phone camera.
  - **Gallery File Upload**: Upload existing portrait photos from disk.
  - Saved as client-side optimized Base64 image tokens (embedded into ID cards and backups).
- **Anti-Duplicate Phone Protection**:
  - Indian phone normalization: Automatically cleans and standardizes phone formats (`+91 98765 43210`, `09876543210`, `91-98765-43210` -> `9876543210`).
  - Blocks duplicate student creation if the phone number already exists in active records.
  - Intelligently excludes the student's own ID during profile edits.
- **Comprehensive Demographic Profile**:
  - Full Name, Normalized Mobile Phone, Father's Name, Full Residential Address.
  - Aadhaar Identification Number (for local security & police verification compliance).
  - Target Competitive Exam Goal (UPSC, NEET, JEE, SSC CGL, Banking, State PCS, CA, GATE).
  - Monthly Subscription Fee, Initial Payment, and Fee Due Date.
- **Instant Search & Multi-Filters**:
  - Filter members by shift, payment dues, active/inactive, or search by name, seat number, and phone number in real time.

---

## 3. Digital Membership ID Pass & WhatsApp Integration

Replaces expensive plastic ID cards with modern, scannable digital passes that can be shared over WhatsApp.

- **High-Resolution Digital Member Pass**:
  - Styled with custom Library Crest, Member Photo, Seat Number, Shift Badge, and Expiry Date.
- **Scannable Dynamic QR Code**:
  - Renders a high-contrast 2D QR code encoding member ID, shift, and subscription validity.
  - Receptionists can scan the pass at the entrance to verify membership status in seconds.
- **1-Tap WhatsApp Member Pass Dispatch**:
  - Formats a personalized welcome message with member details, desk assignment, renewal dates, and digital pass link.
  - Opens student's WhatsApp in 1 click without manually saving their number first.
- **Print / PDF Pass Export**:
  - Export and download passes for physical desk lamination or printing.

---

## 4. Financial Ledger, Due Clearance, Invoicing & Expense Tracking

A complete financial accounting system tailored for subscription-based study hubs.

- **1-Tap Fee Collection & Dues Clearance**:
  - Recording a payment instantly recalculates student dues to `₹0`, resets status to `ACTIVE`, extends subscription validity by 30 days, and logs a permanent ledger record.
- **Multi-Mode Payment Support**:
  - Record payments as **UPI**, **Cash**, **Card**, or **Bank Transfer**.
- **Permanent Payment Audit Ledger**:
  - Timestamped chronological ledger recording payment ID, student name, seat number, amount, payment mode, and collecting staff member.
- **Official Commercial Tax Invoices**:
  - Generates itemized, print-ready tax invoices (`.txt` / `.pdf`) compliant with Indian GST requirements:
    - HSN/SAC Service Code: `998313` (Commercial Study & Facility Services).
    - Calculated Base Amount, CGST, SGST, and Total Paid.
    - Unique Transaction Invoice Number, Library Address & GSTIN.
- **Library Expense Tracker**:
  - Track day-to-day running costs: High-Speed Wi-Fi Internet, Electricity Bills, Premises Rent, Newspaper/Magazine Subscriptions, Cleaning Supplies, Maintenance, and Refreshments.
  - Add, filter, categorize, and delete expenses with payment mode tracking.
- **Real-Time Financial Dashboard**:
  - Instant revenue metrics: Total Collections This Month, Pending Dues, Total Expenses, and Net Operating Margin.

---

## 5. Excel-First Spreadsheet Sync & Contact Export

Gives operators complete freedom from proprietary lock-in.

- **1-Click CSV Template Generator**:
  - Exports a standard column template (`Full Name, Phone Number, Shift, Seat Number, Monthly Fee, Father Name, Address`) ready to open in Microsoft Excel or Google Sheets.
- **Dual-Engine Bulk Importer**:
  - **CSV File Upload**: Import hundreds of legacy students in seconds.
  - **Excel Clipboard Paste (TSV)**: Copy rows directly from a Microsoft Excel or Google Sheets spreadsheet and paste directly into the app; automatically detects tab-separated delimiters!
  - Validates rows, flags formatting errors, prevents duplicate phones, and auto-occupies seats.
- **1-Click Full CSV Directory Export**:
  - Download active students, dues list, and payment ledgers as `.csv` files for offline auditing.
- **vCard (VCF) Contact Sync**:
  - Exports the entire student contact directory as a `.vcf` file.
  - Library staff can import this file into their phone in 1 tap, automatically enabling WhatsApp caller ID for all enrolled library members.

---

## 6. Multi-Branch & Multi-Floor Management

Designed for library operators expanding across multiple locations or floors.

- **Multi-Branch Switcher**:
  - Instant branch dropdown selector (e.g., *Branch 1 - Ground Floor*, *Branch 2 - 2nd Floor AC Hall*).
  - Switching branches automatically switches the active library profile, address, and seating capacity across all student passes and invoices.
- **Branch Configuration**:
  - Add new branches with custom names, addresses, and individual seat counts.
- **Staff Accounts & Role Boundaries**:
  - **Admin / Owner Role**: Full access to financial ledgers, database backup/restore, tax invoices, staff management, and settings.
  - **Receptionist / Desk Staff Role**: Scoped access for seat check-ins, fee collections, walk-in student registrations, and daily attendance.
  - Instant toggle to activate or deactivate staff accounts.

---

## 7. Data Sovereignty, 1-Click Backup & Offline Operation

Ensures the customer's business never stops, even without an active internet connection.

- **100% Offline-First Architecture**:
  - Runs natively on device local storage (`LocalStorageService`). Operates flawlessly during broadband internet or Wi-Fi outages.
- **1-Click Full Database Backup (`.json`)**:
  - Exports a single comprehensive snapshot file containing:
    - Library Name, Crest Branding & Base64 Logo
    - Branch Locations & Floor Plans
    - Seating Sections & Shifts
    - Complete Student Directory (including Base64 portraits & KYC)
    - Full Payment Transaction History
    - Complete Expense Ledger
    - Staff Accounts & Roles
- **Interactive Restore Validator Modal**:
  - Upload or paste a backup JSON package.
  - Displays instant schema verification stats (Student Count, Payment Count, Expense Count) with a 1-tap **"Confirm & Restore Data Now"** safeguard.
- **Production Error Boundaries**:
  - Catches unexpected UI rendering or layout exceptions, replacing standard crashes with an enterprise recovery card offering **"Return to Safety"** or **"Reload Workspace"**.

---

## Summary of Customer Benefits

| Operational Challenge | How TrackMyLibrary Solves It |
| :--- | :--- |
| **Lost or messy paper registers** | Centralized, searchable digital directory with instant phone/seat lookup |
| **Double-booked seats & shift confusion** | Strict 1-to-1 seat collision locking with color-coded shift mapping |
| **Uncollected monthly fees & missed dues** | Real-time dues alerts, 1-tap fee collection, and dynamic 30-day renewals |
| **Expensive physical PVC card printing** | Scannable high-resolution digital passes with 1-tap WhatsApp sharing |
| **Staff accountability & cash leaks** | Timestamped payment & expense ledger recording staff user ID |
| **Fear of cloud lock-in or data loss** | 100% offline persistence, portable CSV exports, and 1-click JSON backup/restore |
| **Multi-branch or floor expansion** | Built-in multi-branch switcher with independent capacity management |
