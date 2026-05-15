import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserService {
  final String authUrl = ApiConfig.authUrl;
  final String appointmentsUrl = ApiConfig.appointmentsUrl;

  Future<Map<String, dynamic>> getUserProfile(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$authUrl/user/$id'),
        headers: ApiConfig.getHeaders(null),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> toggleEmergencyAbsence() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$appointmentsUrl/emergency-cancel'),
        headers: ApiConfig.getHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
