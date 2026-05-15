import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = Locale('en');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _currentLocale = Locale(langCode);
      notifyListeners();
    }
  }

  void setLanguage(String langCode) async {
    _currentLocale = Locale(langCode);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    notifyListeners();
  }

  // Translation Map
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_title': 'University Appointments',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email Address',
      'password': 'Password',
      'name': 'Full Name',
      'welcome': 'Welcome',
      'book_now': 'Book Now',
      'my_appointments': 'My Appointments',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'logout': 'Logout',
      'scan_qr': 'Scan QR',
      'calendar': 'Calendar',
      'services': 'Services',
      'stats': 'Statistics',
      'save': 'Save Changes',
      'explore_services': 'Explore Services',
      'search_hint': 'Search for services or departments...',
      'no_departments': 'No departments found',
      'online': 'ONLINE',
      'absent': 'ABSENT',
      'documents': 'Documents',
      'upload': 'Upload',
      'no_docs': 'No documents uploaded yet.',
      'reason': 'Reason',
      'status': 'Status',
      'date': 'Date',
      'time': 'Time',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'phone_number': 'Phone Number',
      'bio': 'Bio / Description',
      'app_lang': 'Application Language',
      'admin': 'Administrator',
      'control_panel': 'Control Panel',
      'system_vitals': 'System Vitals',
      'booking_dist': 'Booking Distribution',
      'modules': 'Management Modules',
      'master_schedule': 'Master Schedule',
      'total_users': 'Total Users',
      'total_bookings': 'Total Bookings',
      'system_health': 'System Health',
      'emergency_mode': 'Emergency Mode Active',
      'emergency_desc': 'New bookings for today are disabled.',
      'pending': 'Pending',
      'approved': 'Approved',
      'absence': 'Absence',
      'work_hours': 'Work Hours',
      'quick_actions': 'Quick Actions',
    },
    'am': {
      'app_title': 'የዩኒቨርሲቲ ቀጠሮዎች',
      'login': 'ግባ',
      'register': 'ተመዝገብ',
      'email': 'የኢሜል አድራሻ',
      'password': 'የይለፍ ቃል',
      'name': 'ሙሉ ስም',
      'welcome': 'እንኳን ደህና መጡ',
      'book_now': 'አሁን ይያዙ',
      'my_appointments': 'የእኔ ቀጠሮዎች',
      'profile': 'መገለጫ',
      'notifications': 'ማሳወቂያዎች',
      'logout': 'ውጣ',
      'scan_qr': 'QR ስካን',
      'calendar': 'ቀን መቁጠሪያ',
      'services': 'አገልግሎቶች',
      'stats': 'ስታትስቲክስ',
      'save': 'ለውጦችን አስቀምጥ',
      'explore_services': 'አገልግሎቶችን ያስሱ',
      'search_hint': 'አገልግሎቶችን ወይም መምሪያዎችን ይፈልጉ...',
      'no_departments': 'ምንም መምሪያዎች አልተገኙም',
      'online': 'ክፍት',
      'absent': 'ዝግ',
      'documents': 'ሰነዶች',
      'upload': 'ጫን',
      'no_docs': 'ምንም ሰነዶች አልተጫኑም።',
      'reason': 'ምክንያት',
      'status': 'ሁኔታ',
      'date': 'ቀን',
      'time': 'ሰዓት',
      'confirm': 'አረጋግጥ',
      'cancel': 'ሰርዝ',
      'rejection_reason': 'ምክንያት ይጥቀሱ',
      'phone_number': 'የስልክ ቁጥር',
      'bio': 'ስለ እኔ',
      'app_lang': 'የመተግበሪያ ቋንቋ',
      'admin': 'አስተዳዳሪ',
      'control_panel': 'መቆጣጠሪያ ሰሌዳ',
      'system_vitals': 'የስርዓት ሁኔታ',
      'booking_dist': 'የቀጠሮ ስርጭት',
      'modules': 'የአስተዳደር ሞጁሎች',
      'master_schedule': 'ጠቅላላ የጊዜ ሰሌዳ',
      'total_users': 'ጠቅላላ ተጠቃሚዎች',
      'total_bookings': 'ጠቅላላ ቀጠሮዎች',
      'system_health': 'የስርዓት ጤና',
      'emergency_mode': 'የአደጋ ጊዜ ሁነታ በርቷል',
      'emergency_desc': 'ለዛሬ አዲስ ቀጠሮ መያዝ አይቻልም።',
      'pending': 'በመጠባበቅ ላይ',
      'approved': 'የጸደቀ',
      'absence': 'ዕረፍት/ዝግ',
      'work_hours': 'የሥራ ሰዓት',
      'quick_actions': 'ፈጣን ተግባራት',
    }
  };

  String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }
}
