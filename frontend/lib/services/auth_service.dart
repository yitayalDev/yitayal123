import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final String baseUrl = ApiConfig.authUrl;
  // For Real Device or Web, use your IP address

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: ApiConfig.getHeaders(null),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString('user', jsonEncode(responseData['user']));
        return {'success': true, 'user': UserModel.fromJson(responseData['user'])};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role, String? userType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: ApiConfig.getHeaders(null),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'userType': userType
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setString('user', jsonEncode(responseData['user']));
        return {'success': true, 'user': UserModel.fromJson(responseData['user'])};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Register Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<UserModel?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user');
    if (userStr != null) {
      return UserModel.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userMap = {
          'id': responseData['_id'],
          'name': responseData['name'],
          'email': responseData['email'],
          'role': responseData['role'],
          'userType': responseData['userType'],
          'phone': responseData['phone'],
          'bio': responseData['bio'],
        };
        await prefs.setString('user', jsonEncode(userMap));
        return {'success': true, 'user': UserModel.fromJson(userMap)};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleEmergencyMode({List<String>? dates}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.appointmentsUrl}/emergency-cancel'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({'dates': dates}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local user data with new availability status
        String? userStr = prefs.getString('user');
        if (userStr != null) {
          Map<String, dynamic> userMap = jsonDecode(userStr);
          userMap['isAvailable'] = responseData['isAvailable'];
          userMap['unavailableDates'] = responseData['unavailableDates'];
          await prefs.setString('user', jsonEncode(userMap));
          return {
            'success': true, 
            'isAvailable': responseData['isAvailable'],
            'unavailableDates': responseData['unavailableDates'],
            'message': responseData['msg'],
            'user': UserModel.fromJson(userMap)
          };
        }
        return {'success': true, 'isAvailable': responseData['isAvailable'], 'message': responseData['msg']};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Operation failed'};
      }
    } catch (e) {
      print('Emergency Mode Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> blockTime({
    required String date,
    required String startTime,
    required String endTime,
    String reason = "",
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.appointmentsUrl}/block-time'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'date': date,
          'startTime': startTime,
          'endTime': endTime,
          'reason': reason,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String? userStr = prefs.getString('user');
        if (userStr != null) {
          Map<String, dynamic> userMap = jsonDecode(userStr);
          userMap['busySlots'] = responseData['busySlots'];
          await prefs.setString('user', jsonEncode(userMap));
          return {'success': true, 'message': responseData['msg'], 'user': UserModel.fromJson(userMap)};
        }
        return {'success': true, 'message': responseData['msg']};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Operation failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/fcm-token'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
