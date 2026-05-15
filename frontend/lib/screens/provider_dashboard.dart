import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'manage_appointments_screen.dart';
import 'provider/manage_services_screen.dart';
import 'provider/work_hours_screen.dart';
import 'provider/calendar_screen.dart';
import 'provider/qr_scanner_screen.dart';
import 'provider/absence_screen.dart';
import 'provider/analytics_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../config/api_config.dart';

class ProviderDashboard extends StatefulWidget {
  @override
  _ProviderDashboardState createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  Map<String, dynamic> _stats = {'pending': 0, 'approved': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("${ApiConfig.appointmentsUrl}/stats"),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9), // Light Slate background
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(user, lang),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user?.isAvailable == false) _buildEmergencyBanner(lang),
                  SizedBox(height: 24),
                  _buildSectionHeader(lang.translate('stats') == 'stats' ? 'Overview' : lang.translate('stats'), Icons.insights_rounded),
                  SizedBox(height: 16),
                  _buildStatGrid(lang),
                  SizedBox(height: 32),
                  _buildSectionHeader(lang.translate('quick_actions') == 'quick_actions' ? 'Quick Actions' : lang.translate('quick_actions'), Icons.grid_view_rounded),
                  SizedBox(height: 16),
                  _buildActionGrid(context, lang),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(user, LanguageProvider lang) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      stretch: true,
      centerTitle: false,
      backgroundColor: Color(0xFF1E293B),
      leading: Navigator.canPop(context) 
        ? IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          )
        : null,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                right: -60,
                top: -60,
                child: CircleAvatar(radius: 120, backgroundColor: Colors.blueAccent.withOpacity(0.05)),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: CircleAvatar(radius: 80, backgroundColor: Colors.indigoAccent.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())),
                          borderRadius: BorderRadius.circular(32),
                          child: Hero(
                            tag: 'profile-avatar',
                            child: Container(
                              padding: EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent]),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Color(0xFF1E293B),
                                child: Text(
                                  user?.name[0] ?? 'P', 
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${lang.translate('welcome')},',
                                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                user?.name ?? 'Provider',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusToggle(user, lang),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 22, color: Colors.white),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen())),
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.logout_rounded, size: 22, color: Colors.white),
          ),
          onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusToggle(user, LanguageProvider lang) {
    final bool isOnline = user?.isAvailable ?? true;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOnline ? lang.translate('online').toUpperCase() : lang.translate('absent').toUpperCase(),
            style: TextStyle(
              color: isOnline ? Colors.greenAccent : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 2),
          SizedBox(
            height: 24,
            child: Switch(
              value: isOnline,
              activeColor: Colors.greenAccent,
              activeTrackColor: Colors.greenAccent.withOpacity(0.3),
              inactiveThumbColor: Colors.redAccent,
              inactiveTrackColor: Colors.redAccent.withOpacity(0.3),
              onChanged: (val) async {
                final result = await Provider.of<AuthProvider>(context, listen: false).toggleEmergencyMode();
                if (result['success']) {
                  _showHapticFeedback();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHapticFeedback() {
    // Simple feedback for status change
  }

  Widget _buildEmergencyBanner(LanguageProvider lang) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('emergency_mode') == 'emergency_mode' ? 'Emergency Mode Active' : lang.translate('emergency_mode'), 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
                Text(
                  lang.translate('emergency_desc') == 'emergency_desc' ? 'New bookings for today are disabled.' : lang.translate('emergency_desc'), 
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF64748B)),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF1E293B), 
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(LanguageProvider lang) {
    return Row(
      children: [
        _buildStatCard(
          lang.translate('pending') == 'pending' ? 'Pending' : lang.translate('pending'), 
          _stats['pending'].toString(), 
          Icons.hourglass_bottom_rounded, 
          Colors.orange,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          lang.translate('approved') == 'approved' ? 'Approved' : lang.translate('approved'), 
          _stats['approved'].toString(), 
          Icons.check_circle_rounded, 
          Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.trending_up_rounded, color: color.withOpacity(0.3), size: 16),
              ],
            ),
            SizedBox(height: 20),
            Text(
              value, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
            ),
            Text(
              label, 
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, LanguageProvider lang) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildActionCard(
          context,
          lang.translate('my_appointments'),
          Icons.calendar_month_rounded,
          Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAppointmentsScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('scan_qr'),
          Icons.qr_code_scanner_rounded,
          Colors.orangeAccent,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => QRScannerScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('services'),
          Icons.layers_rounded,
          Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageServicesScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('absence') == 'absence' ? 'Absence' : lang.translate('absence'),
          Icons.event_busy_rounded,
          Color(0xFFF43F5E),
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => AbsenceScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('calendar'),
          Icons.date_range_rounded,
          Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderCalendarScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('work_hours') == 'work_hours' ? 'Work Hours' : lang.translate('work_hours'),
          Icons.schedule_rounded,
          Color(0xFF64748B),
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorkHoursScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('profile') == 'profile' ? 'My Profile' : lang.translate('profile'),
          Icons.person_outline_rounded,
          Color(0xFF6366F1),
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())),
        ),
        _buildActionCard(
          context,
          lang.translate('analytics') == 'analytics' ? 'Analytics' : lang.translate('analytics'),
          Icons.analytics_rounded,
          Colors.pinkAccent,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderAnalyticsScreen())),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 15, 
                          color: Color(0xFF334155),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
