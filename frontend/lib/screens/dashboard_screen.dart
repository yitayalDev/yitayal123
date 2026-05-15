import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'user_dashboard.dart';
import 'provider_dashboard.dart';
import 'admin_dashboard.dart';

import '../services/push_notification_service.dart';
import '../providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (authProvider.isGuest) {
      return UserDashboard(); // Guests use the same discovery dashboard as students
    }

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (user.role) {
      case 'admin':
        return AdminDashboard();
      case 'provider':
        return ProviderDashboard();
      case 'user':
      default:
        return UserDashboard();
    }
  }
}
