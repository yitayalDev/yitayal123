import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ChatService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getMessages(String appointmentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$appointmentId'),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Chat Error: $e');
      return [];
    }
  }

  Future<bool> sendMessage(String appointmentId, String text) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? ''
        },
        body: jsonEncode({
          'appointmentId': appointmentId,
          'text': text
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Send Message Error: $e');
      return false;
    }
  }
}
