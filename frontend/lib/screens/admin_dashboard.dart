import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'admin/user_management_screen.dart';
import 'admin/provider_management_screen.dart';
import 'admin/all_appointments_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/language_provider.dart';
import '../config/api_config.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {'users': 0, 'providers': 0, 'appointments': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isDemo) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _stats = {
          'users': 245,
          'providers': 18,
          'appointments': 1240,
          'statusBreakdown': {
            'pending': 15,
            'approved': 85,
            'rejected': 10
          }
        };
        _isLoading = false;
      });
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("${ApiConfig.adminUrl}/stats"),
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
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, lang),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  _buildSectionTitle('System Overview', Icons.analytics_rounded),
                  SizedBox(height: 16),
                  _buildStatGrid(lang),
                  SizedBox(height: 32),
                  _buildSectionTitle('Booking Metrics', Icons.bar_chart_rounded),
                  SizedBox(height: 16),
                  _buildAnalyticsCard(lang),
                  SizedBox(height: 32),
                  _buildSectionTitle('Control Center', Icons.settings_input_component_rounded),
                  SizedBox(height: 16),
                  _buildActionModule(
                    context,
                    'Student Management',
                    'View and manage all registered students',
                    Icons.people_alt_rounded,
                    Color(0xFF6366F1),
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserManagementScreen())),
                  ),
                  _buildActionModule(
                    context,
                    'Service Departments',
                    'Manage university offices and staff accounts',
                    Icons.verified_user_rounded,
                    Color(0xFF10B981),
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderManagementScreen())),
                  ),
                  _buildActionModule(
                    context,
                    'Global Appointments',
                    'Monitor all bookings across the university',
                    Icons.event_note_rounded,
                    Color(0xFFF59E0B),
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllAppointmentsScreen())),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, LanguageProvider lang) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.zoomBackground],
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
              Positioned(
                right: -40,
                top: -40,
                child: Icon(Icons.admin_panel_settings_rounded, size: 220, color: Colors.white.withOpacity(0.04)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        lang.translate('admin').toUpperCase(),
                        style: TextStyle(color: Colors.indigoAccent[100], fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      lang.translate('control_panel'),
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildHeaderAction(context, 'Refresh Data', Icons.refresh_rounded, _fetchStats),
                          SizedBox(width: 12),
                          _buildNotificationAction(context),
                          SizedBox(width: 12),
                          _buildHeaderAction(context, 'My Profile', Icons.person_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()))),
                          SizedBox(width: 12),
                          _buildHeaderAction(context, 'Logout', Icons.logout_rounded, () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                label, 
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAction(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          _buildHeaderAction(context, 'Alerts', Icons.notifications_none_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()))),
          if (provider.unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: Color(0xFF0F172A), width: 2)
                ),
                constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    provider.unreadCount.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF64748B)),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: Color(0xFF1E293B), 
            letterSpacing: -0.5
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(LanguageProvider lang) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Total Users', _stats['users'].toString(), Icons.people_rounded, Color(0xFF6366F1)),
            SizedBox(width: 16),
            _buildStatCard('Departments', _stats['providers'].toString(), Icons.account_balance_rounded, Color(0xFF10B981)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard('Bookings', _stats['appointments'].toString(), Icons.confirmation_number_rounded, Color(0xFFF59E0B)),
            SizedBox(width: 16),
            _buildStatCard('System Health', 'Stable', Icons.verified_user_rounded, Color(0xFFEC4899)),
          ],
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
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 16),
            Text(
              value, 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)
            ),
            Text(
              label, 
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(LanguageProvider lang) {
    if (_stats['statusBreakdown'] == null) return SizedBox();

    final breakdown = _stats['statusBreakdown'];
    final pending = (breakdown['pending'] as num).toDouble();
    final approved = (breakdown['approved'] as num).toDouble();
    final rejected = (breakdown['rejected'] as num).toDouble();

    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: [pending, approved, rejected].reduce((a, b) => a > b ? a : b) + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Color(0xFF0F172A),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 10);
                        switch (value.toInt()) {
                          case 0: return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('PENDING', style: style));
                          case 1: return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('APPROVED', style: style));
                          case 2: return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('REJECTED', style: style));
                          default: return Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pending, color: Color(0xFFF59E0B), width: 32, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: approved, color: Color(0xFF10B981), width: 32, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: rejected, color: Color(0xFFEF4444), width: 32, borderRadius: BorderRadius.circular(8))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionModule(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(20),
        leading: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 17)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
