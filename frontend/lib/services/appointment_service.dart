import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_config.dart';
import '../models/appointment_model.dart';

class AppointmentResponse {
  final List<AppointmentModel> appointments;
  final bool isFromCache;
  AppointmentResponse({required this.appointments, required this.isFromCache});
}

class AppointmentService {
  final String baseUrl = ApiConfig.appointmentsUrl;

  String getAttachmentUrl(String filename) {
    // Assuming backend URL is same as baseUrl but without /api/appointments
    final rootUrl = baseUrl.split('/api/')[0];
    return '$rootUrl/uploads/appointments/$filename';
  }

  Future<Map<String, dynamic>> uploadFile(String appointmentId, dynamic file, {String? fileName}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$appointmentId/upload'));
      Map<String, String> headers = ApiConfig.getHeaders(token);
      headers.remove('Content-Type'); // Remove JSON content type for multipart upload
      request.headers.addAll(headers);

      if (kIsWeb) {
        // file is Uint8List on web
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file,
          filename: fileName ?? 'upload.dat',
        ));
      } else {
        // file is File object on mobile/desktop
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'appointment': AppointmentModel.fromJson(responseData)};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Upload failed'};
      }
    } catch (e) {
      print('Upload Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> rescheduleAppointment(String id, String date, String timeSlot) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/$id/reschedule'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'date': date,
          'timeSlot': timeSlot,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'appointment': AppointmentModel.fromJson(responseData)};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      print('Reschedule Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<AppointmentResponse> getMyAppointments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/my'),
        headers: ApiConfig.getHeaders(token),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Save to cache
        await prefs.setString('cached_appointments', response.body);
        return AppointmentResponse(
          appointments: data.map((json) => AppointmentModel.fromJson(json)).toList(),
          isFromCache: false,
        );
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch Error: $e. Attempting to load from cache...');
      
      // Load from cache if network fails
      String? cachedData = prefs.getString('cached_appointments');
      if (cachedData != null) {
        List<dynamic> data = jsonDecode(cachedData);
        return AppointmentResponse(
          appointments: data.map((json) => AppointmentModel.fromJson(json)).toList(),
          isFromCache: true,
        );
      }
      
      throw Exception('No internet connection and no cached data available.');
    }
  }

  Future<Map<String, dynamic>> bookAppointment(
    String serviceId, 
    String date, 
    String timeSlot, 
    String reason,
    {String? studentId, String? major, String? organization, String? guestId, List<String>? attachments, String appointmentType = 'physical'}
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/book'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'serviceId': serviceId,
          'date': date,
          'timeSlot': timeSlot,
          'reason': reason,
          'studentId': studentId,
          'major': major,
          'organization': organization,
          'guestId': guestId,
          'attachments': attachments,
          'appointmentType': appointmentType
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'appointment': AppointmentModel.fromJson(responseData)};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      print('Booking Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateStatus(String appointmentId, String status, {String? reason}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/$appointmentId/status'),
        headers: ApiConfig.getHeaders(token),
        body: jsonEncode({
          'status': status,
          'reason': reason,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': responseData['msg'] ?? 'Server error ${response.statusCode}'};
      }
    } catch (e) {
      print('Update Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
