import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/notification_model.dart';

class NotificationService {
  final String baseUrl = ApiConfig.notificationsUrl;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: ApiConfig.getHeaders(token),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch Notifications Error: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse("$baseUrl/$id/read"),
        headers: ApiConfig.getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark Read Error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse("$baseUrl/read-all"),
        headers: ApiConfig.getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Mark All Read Error: $e');
      return false;
    }
  }
}
