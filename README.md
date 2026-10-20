# 📚 Digital Library Seat & Fee Manager

A cross-platform Flutter application designed for self-study digital libraries and study centers to manage seat occupancy in real-time, register students, track monthly renewal fees, and send instant WhatsApp fee reminders.

---

## 🚀 Key Features

- **Interactive 50-Seat Grid**: Visual map color-coded by occupancy status (Green for Vacant, Red for Occupied).
- **Atomic Multi-Device Sync**: Prevents double-booking across multiple manager devices using Cloud Firestore transactions.
- **Student Record Management**: View all active members, seat numbers, shifts, and renewal due dates.
- **WhatsApp Fee Reminders**: 1-tap direct WhatsApp integration to notify students of upcoming renewal fees (₹500/month).
- **Instant Cloud Build (GitHub Actions)**: Automated CI/CD pipeline builds the production Android APK and Web app on every push to `main`.
- **Offline / Preview Mode**: Fully functional preview fallback so you can test the UI and workflows immediately.

---

## 📥 How to Download the APK

1. Go to the [Actions Tab](https://github.com/UDAYPSY/Library-app/actions) in this repository.
2. Click on the latest workflow run: **Build Android APK and Web App**.
3. Under the **Artifacts** section at the bottom, click **`library-manager-apk`** to download `app-release.apk`.
4. Transfer and install the `.apk` on any Android device (enable "Install unknown apps" if prompted).

---

## 🌐 Live Web Version (GitHub Pages)

You can also run the web dashboard directly from your browser:
- **URL**: `https://udaypsy.github.io/Library-app/`
- *(To enable: Go to **Settings** > **Pages** > Set **Source** to **GitHub Actions**)*.

---

## ⚙️ Connecting Your Live Firebase Project

By default, the app runs in **Preview Mode**. To enable live cloud sync across all your manager devices:

1. Visit [Firebase Console](https://console.firebase.google.com/) and create a project.
2. In **Firestore Database**, create a database and paste the security rules provided in [firestore.rules](firestore.rules).
3. Register your app (Android package: `com.example.library_manager` or Web).
4. Open [`lib/firebase_options.dart`](lib/firebase_options.dart) and paste your project's `apiKey`, `appId`, and `projectId`.
5. Push to GitHub, and the GitHub Action will recompile your APK with live Firebase enabled!

---

## 🛠️ Project Structure

```
├── .github/workflows/
│   └── build-apk.yml        # Cloud CI/CD pipeline for APK & Web
├── lib/
│   ├── firebase_options.dart # Firebase configuration
│   ├── main.dart            # Application entry point with safe startup
│   ├── screens/
│   │   └── dashboard_screen.dart # 50-seat grid and student directory UI
│   └── services/
│       └── library_service.dart  # Firestore streams & transactions
├── firestore.rules          # Firestore security rules
└── pubspec.yaml             # Flutter dependencies
```
