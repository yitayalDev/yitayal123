import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/service_model.dart';

class ServiceService {
  final String baseUrl = ApiConfig.servicesUrl;

  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: ApiConfig.getHeaders(null),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ServiceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch Services Error: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> serviceData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode(serviceData),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'service': ServiceModel.fromJson(responseData)};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      print('Create Service Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
