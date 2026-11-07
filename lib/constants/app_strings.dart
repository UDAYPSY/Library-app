/// Supported app languages
enum AppLanguage {
  en,
  hi,
}

/// Centralized strings and Hindi / English translations for TrackMyLibrary.
class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _strings = {
    // Navigation Hub
    'nav_home': {AppLanguage.en: 'Home', AppLanguage.hi: 'होम'},
    'nav_students': {AppLanguage.en: 'Students', AppLanguage.hi: 'छात्र'},
    'nav_seats': {AppLanguage.en: 'Seats', AppLanguage.hi: 'सीटें'},
    'nav_payments': {AppLanguage.en: 'Payments', AppLanguage.hi: 'भुगतान'},
    'nav_analytics': {AppLanguage.en: 'Analytics', AppLanguage.hi: 'एनालिटिक्स'},
    'nav_settings': {AppLanguage.en: 'Settings', AppLanguage.hi: 'सेटिंग्स'},

    // General & Actions
    'app_name': {AppLanguage.en: 'Track My Library', AppLanguage.hi: 'ट्रैक माय लाइब्रेरी'},
    'save': {AppLanguage.en: 'Save', AppLanguage.hi: 'सुरक्षित करें'},
    'cancel': {AppLanguage.en: 'Cancel', AppLanguage.hi: 'रद्द करें'},
    'close': {AppLanguage.en: 'Close', AppLanguage.hi: 'बंद करें'},
    'search': {AppLanguage.en: 'Search', AppLanguage.hi: 'खोजें'},
    'edit': {AppLanguage.en: 'Edit', AppLanguage.hi: 'संपादित करें'},
    'delete': {AppLanguage.en: 'Delete', AppLanguage.hi: 'हटाएं'},
    'confirm': {AppLanguage.en: 'Confirm', AppLanguage.hi: 'पुष्टि करें'},
    'view_all': {AppLanguage.en: 'View All', AppLanguage.hi: 'सभी देखें'},
    'refresh': {AppLanguage.en: 'Refresh', AppLanguage.hi: 'ताज़ा करें'},

    // Language
    'language': {AppLanguage.en: 'App Language', AppLanguage.hi: 'ऐप की भाषा'},
    'select_language': {AppLanguage.en: 'Select Language / भाषा चुनें', AppLanguage.hi: 'भाषा चुनें / Select Language'},
    'lang_english': {AppLanguage.en: 'English', AppLanguage.hi: 'अंग्रेज़ी (English)'},
    'lang_hindi': {AppLanguage.en: 'Hindi (हिंदी)', AppLanguage.hi: 'हिंदी (Hindi)'},
    'switched_to_english': {AppLanguage.en: 'Switched to English', AppLanguage.hi: 'भाषा बदलकर English कर दी गई'},
    'switched_to_hindi': {AppLanguage.en: 'Switched to Hindi (हिंदी)', AppLanguage.hi: 'भाषा बदलकर हिंदी कर दी गई'},

    // Seats Screen
    'seats_title': {AppLanguage.en: 'Library Seats', AppLanguage.hi: 'लाइब्रेरी सीटें'},
    'seat': {AppLanguage.en: 'Seat', AppLanguage.hi: 'सीट'},
    'available': {AppLanguage.en: 'Available', AppLanguage.hi: 'उपलब्ध'},
    'occupied': {AppLanguage.en: 'Occupied', AppLanguage.hi: 'आरक्षित / भरी हुई'},
    'due': {AppLanguage.en: 'Due', AppLanguage.hi: 'बकाया'},
    'expired': {AppLanguage.en: 'Expired', AppLanguage.hi: 'अवधि समाप्त'},
    'days_left': {AppLanguage.en: 'days left', AppLanguage.hi: 'दिन शेष'},
    'day_left': {AppLanguage.en: 'day left', AppLanguage.hi: 'दिन शेष'},
    'days_overdue': {AppLanguage.en: 'days overdue', AppLanguage.hi: 'दिन बकाया'},
    'expires_today': {AppLanguage.en: 'Expires today', AppLanguage.hi: 'आज समाप्त हो रही है'},
    'vacant_seat': {AppLanguage.en: 'Vacant Seat', AppLanguage.hi: 'खाली सीट'},
    'assign_seat': {AppLanguage.en: 'Assign Seat', AppLanguage.hi: 'सीट आवंटित करें'},
    'vacate_seat': {AppLanguage.en: 'Vacate Seat', AppLanguage.hi: 'सीट खाली करें'},
    'all_shifts': {AppLanguage.en: 'All Shifts', AppLanguage.hi: 'सभी शिफ्ट'},
    'morning_shift': {AppLanguage.en: 'Morning', AppLanguage.hi: 'सुबह (Morning)'},
    'evening_shift': {AppLanguage.en: 'Evening', AppLanguage.hi: 'शाम (Evening)'},
    'night_shift': {AppLanguage.en: 'Night', AppLanguage.hi: 'रात (Night)'},
    'full_day_shift': {AppLanguage.en: 'Full Day', AppLanguage.hi: 'पूरा दिन (Full Day)'},

    // Students
    'students_title': {AppLanguage.en: 'Student Directory', AppLanguage.hi: 'छात्र सूची'},
    'add_student': {AppLanguage.en: 'Add Student', AppLanguage.hi: 'नया छात्र जोड़ें'},
    'active_students': {AppLanguage.en: 'Active Students', AppLanguage.hi: 'सक्रिय छात्र'},
    'all_students': {AppLanguage.en: 'All Students', AppLanguage.hi: 'सभी छात्र'},
    'student_name': {AppLanguage.en: 'Student Name', AppLanguage.hi: 'छात्र का नाम'},
    'phone_number': {AppLanguage.en: 'Phone Number', AppLanguage.hi: 'मोबाइल नंबर'},
    'admission_date': {AppLanguage.en: 'Joined Date', AppLanguage.hi: 'प्रवेश तिथि'},
    'validity_until': {AppLanguage.en: 'Valid Until', AppLanguage.hi: 'वैधता समाप्त'},

    // Payments & Fees
    'collect_payment': {AppLanguage.en: 'Collect Payment', AppLanguage.hi: 'फीस जमा करें'},
    'clear_due_only': {AppLanguage.en: 'Clear Due Only', AppLanguage.hi: 'केवल बकाया जमा करें'},
    'renew_one_month': {AppLanguage.en: '1 Month Renewal', AppLanguage.hi: '1 माह नवीनीकरण'},
    'renew_and_due': {AppLanguage.en: '1 Mo + Due', AppLanguage.hi: '1 माह + बकाया'},
    'monthly_fee': {AppLanguage.en: 'Monthly Fee', AppLanguage.hi: 'मासिक शुल्क'},
    'due_amount': {AppLanguage.en: 'Due Amount', AppLanguage.hi: 'बकाया राशि'},
    'advance_amount': {AppLanguage.en: 'Advance Balance', AppLanguage.hi: 'अग्रिम राशि (Advance)'},
    'payment_mode': {AppLanguage.en: 'Payment Mode', AppLanguage.hi: 'भुगतान माध्यम'},
    'payment_success': {AppLanguage.en: 'Payment Recorded Successfully', AppLanguage.hi: 'भुगतान सफलतापूर्वक दर्ज किया गया'},
    'cash': {AppLanguage.en: 'Cash', AppLanguage.hi: 'नकद (Cash)'},
    'upi': {AppLanguage.en: 'UPI', AppLanguage.hi: 'यूपीआई (UPI)'},
    'card': {AppLanguage.en: 'Card', AppLanguage.hi: 'कार्ड (Card)'},
    'online': {AppLanguage.en: 'Online', AppLanguage.hi: 'ऑनलाइन (Online)'},

    // Settings
    'settings_title': {AppLanguage.en: 'Settings', AppLanguage.hi: 'सेटिंग्स'},
    'settings_subtitle': {AppLanguage.en: 'Manage your account and preferences', AppLanguage.hi: 'अपने खाते और प्राथमिकताएं प्रबंधित करें'},
    'appearance': {AppLanguage.en: 'APPEARANCE & LANGUAGE', AppLanguage.hi: 'दिखावट और भाषा (APPEARANCE & LANGUAGE)'},
    'theme_mode': {AppLanguage.en: 'Theme Mode', AppLanguage.hi: 'थीम मोड'},
    'branch_switcher': {AppLanguage.en: 'Branch Switcher', AppLanguage.hi: 'ब्रांच बदलें'},
    'backup_restore': {AppLanguage.en: 'Backup & Restore', AppLanguage.hi: 'बैकअप और रीस्टोर'},
    'logout': {AppLanguage.en: 'Logout', AppLanguage.hi: 'लॉग आउट'},

    // Dashboard / Home
    'quick_stats': {AppLanguage.en: 'Quick Overview', AppLanguage.hi: 'संक्षिप्त विवरण'},
    'total_seats': {AppLanguage.en: 'Total Seats', AppLanguage.hi: 'कुल सीटें'},
    'occupied_seats': {AppLanguage.en: 'Occupied', AppLanguage.hi: 'भरी हुई सीटें'},
    'vacant_seats': {AppLanguage.en: 'Vacant', AppLanguage.hi: 'खाली सीटें'},
    'total_revenue': {AppLanguage.en: 'Total Revenue', AppLanguage.hi: 'कुल आय'},
    'pending_dues': {AppLanguage.en: 'Pending Dues', AppLanguage.hi: 'कुल बकाया'},
  };

  /// Translate a given key using explicit language or English default
  static String get(String key, AppLanguage lang, {String? fallback}) {
    final map = _strings[key];
    if (map != null) {
      return map[lang] ?? map[AppLanguage.en] ?? fallback ?? key;
    }
    return fallback ?? key;
  }
}
