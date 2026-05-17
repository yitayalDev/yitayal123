import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Dynamically detect active host on web (localhost or Render) to make testing seamless
  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      // Handles cases where hot reload or stubs return empty origin
      if (origin.isNotEmpty && origin.startsWith('http')) {
        return "$origin/api";
      }
    }
    // Mobile or absolute fallback
    return "https://university-appointment-backend.onrender.com/api";
  }
  
  static String get authUrl => "$baseUrl/auth";
  static String get servicesUrl => "$baseUrl/services";
  static String get appointmentsUrl => "$baseUrl/appointments";
  static String get adminUrl => "$baseUrl/admin";
  static String get notificationsUrl => "$baseUrl/notifications";
  static String get reviewsUrl => "$baseUrl/reviews";

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
    };
  }
}

