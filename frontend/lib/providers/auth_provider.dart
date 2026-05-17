import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isGuest = false;
  String? _demoRole;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null || _isGuest || _demoRole != null;
  bool get isGuest => _isGuest;
  bool get isDemo => _demoRole != null;
  String? get demoRole => _demoRole;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  void loginAsGuest() {
    _isGuest = true;
    _user = null;
    _demoRole = null;
    notifyListeners();
  }

  void loginAsDemo(String role) {
    _isGuest = false;
    _demoRole = role;
    _user = UserModel(
      id: 'demo_user',
      name: 'Demo ${role[0].toUpperCase()}${role.substring(1)}',
      email: 'demo@university.edu',
      role: role,
      category: role == 'provider' ? 'Information Technology' : 'General',
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      _user = result['user'];
      _isGuest = false;
      _demoRole = null;
      _syncFcmToken();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role, String? userType) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.register(name, email, password, role, userType);

    if (result['success']) {
      _user = result['user'];
      _isGuest = false;
      _demoRole = null;
      _syncFcmToken();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _user = null;
    _isGuest = false;
    _demoRole = null;
    await _authService.logout();
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.updateProfile(data);

    if (result['success']) {
      _user = result['user'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> toggleEmergencyMode({List<String>? dates}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.toggleEmergencyMode(dates: dates);

    if (result['success']) {
      _user = result['user'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> blockTime({
    required String date,
    required String startTime,
    required String endTime,
    String reason = "",
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.blockTime(
      date: date,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
    );

    if (result['success']) {
      _user = result['user'];
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> _syncFcmToken() async {
    final token = await PushNotificationService.getToken();
    if (token != null) {
      await _authService.updateFcmToken(token);
    }
  }
}
