class ApiConfig {
  // Change this to your current ngrok URL or your local IP (e.g., http://10.0.2.2:5000)
  static const String baseUrl = "https://university-appointment-backend.onrender.com/api";
  
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
