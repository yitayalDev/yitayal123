import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _saveLastRoute();
    Future.microtask(() =>
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications());
  }

  void _saveLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', 'notifications');
    } catch (e) {
      print("Error saving last route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: EdgeInsetsDirectional.only(start: 56, bottom: 16),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.notifications_active_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
                        ),
                      ],
                    ),
                  ),
                ),
                iconTheme: IconThemeData(color: Colors.white),
                actions: [
                  if (provider.notifications.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.done_all_rounded, color: Colors.white),
                      onPressed: () => provider.markAllAsRead(),
                      tooltip: 'Mark all as read',
                    ),
                ],
              ),
              if (provider.isLoading && provider.notifications.isEmpty)
                SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                
              if (!provider.isLoading && provider.notifications.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Color(0xFF1A237E).withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFF1A237E).withOpacity(0.3)),
                        ),
                        SizedBox(height: 24),
                        Text('No notifications yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('We will notify you when something happens.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                
              if (provider.notifications.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.only(top: 16, bottom: 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notification = provider.notifications[index];
                        return _buildNotificationTile(context, notification, provider);
                      },
                      childCount: provider.notifications.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, notification, NotificationProvider provider) {
    Color typeColor;
    IconData typeIcon;

    switch (notification.type) {
      case 'success': typeColor = Color(0xFF10B981); typeIcon = Icons.check_circle_rounded; break;
      case 'error': typeColor = Color(0xFFF43F5E); typeIcon = Icons.error_rounded; break;
      case 'warning': typeColor = Color(0xFFF59E0B); typeIcon = Icons.warning_rounded; break;
      default: typeColor = Color(0xFF6366F1); typeIcon = Icons.info_rounded;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(notification.isRead ? 0.02 : 0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
        border: notification.isRead ? null : Border.all(color: typeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!notification.isRead) provider.markAsRead(notification.id);
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
                      ),
                      SizedBox(height: 12),
                      Text(
                        DateFormat('MMM d, h:mm a').format(notification.createdAt),
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
