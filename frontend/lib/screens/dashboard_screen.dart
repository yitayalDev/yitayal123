import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'user_dashboard.dart';
import 'provider_dashboard.dart';
import 'admin_dashboard.dart';

import '../services/push_notification_service.dart';
import '../providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_appointments_screen.dart';
import 'manage_appointments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _restoreLastRoute();
    
    // Set up foreground notification listener
    PushNotificationService.setOnMessageReceived((message) {
      if (mounted) {
        // Refresh the notification count and list
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        
        // Show a professional top-snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.notification?.title ?? "New Notification",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        message.notification?.body ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF1E3C72),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _restoreLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRoute = prefs.getString('last_route');
      if (lastRoute != null && mounted) {
        // Clear it so it doesn't loop or double-push unexpectedly
        await prefs.remove('last_route');
        final auth = Provider.of<AuthProvider>(context, listen: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (lastRoute == 'my_appointments' && auth.user?.role != 'provider' && auth.user?.role != 'admin') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyAppointmentsScreen()));
          } else if (lastRoute == 'manage_appointments' && auth.user?.role == 'provider') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAppointmentsScreen()));
          } else if (lastRoute == 'notifications') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
          } else if (lastRoute == 'profile') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          }
        });
      }
    } catch (e) {
      print("Error restoring last route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (authProvider.isGuest && !authProvider.isDemo) {
      return UserDashboard(); // Guests use the same discovery dashboard as students
    }

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Role-based routing (works for both real and demo users)
    switch (user.role) {
      case 'admin':
        return AdminDashboard();
      case 'provider':
        return ProviderDashboard();
      case 'user':
      case 'student':
      default:
        return UserDashboard();
    }
  }
}
