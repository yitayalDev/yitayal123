import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/api_config.dart';
import '../../providers/language_provider.dart';

class ProviderAnalyticsScreen extends StatefulWidget {
  @override
  _ProviderAnalyticsScreenState createState() => _ProviderAnalyticsScreenState();
}

class _ProviderAnalyticsScreenState extends State<ProviderAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("${ApiConfig.appointmentsUrl}/analytics"),
        headers: {'x-auth-token': token ?? ''},
      );

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang.translate('analytics') == 'analytics' ? 'Business Analytics' : lang.translate('analytics')),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAnalytics();
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text('Failed to load analytics'))
              : RefreshIndicator(
                  onRefresh: _fetchAnalytics,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(lang),
                      SizedBox(height: 32),
                      _buildSectionTitle('Booking Trends (Last 7 Days)'),
                      SizedBox(height: 16),
                      _buildLineChart(),
                      SizedBox(height: 32),
                      _buildSectionTitle('Popular Services'),
                      SizedBox(height: 16),
                      _buildPieChart(),
                      SizedBox(height: 32),
                      _buildSectionTitle('Status Breakdown'),
                      SizedBox(height: 16),
                      _buildStatusList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
    );
  }

  Widget _buildSummaryCards(LanguageProvider lang) {
    final status = _data!['statusBreakdown'] as List;
    final totalBookings = status.fold(0, (sum, item) => sum + (item['count'] as int));
    
    return Row(
      children: [
        _buildSimpleStatCard('Total Customers', _data!['totalCustomers'].toString(), Icons.group_rounded, Color(0xFF6366F1)),
        SizedBox(width: 16),
        _buildSimpleStatCard('Total Bookings', totalBookings.toString(), Icons.event_available_rounded, Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildSimpleStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final trends = _data!['bookingTrends'] as List;
    return Container(
      height: 250,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= trends.length) return Text('');
                  return Text(trends[value.toInt()]['date'], style: TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trends.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['count'].toDouble())).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final services = _data!['popularServices'] as List;
    if (services.isEmpty) return Center(child: Text('No data yet'));

    final totalCount = services.fold(0, (sum, item) => sum + (item['count'] as int));
    final colors = [Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)];

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: services.asMap().entries.map((e) {
                  final double percentage = (e.value['count'] / totalCount) * 100;
                  return PieChartSectionData(
                    color: colors[e.key % colors.length],
                    value: e.value['count'].toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12, 
                      height: 12, 
                      decoration: BoxDecoration(color: colors[index % colors.length], borderRadius: BorderRadius.circular(4))
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service['name'], 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${service['count']}', 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF64748B))
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusList() {
    final status = _data!['statusBreakdown'] as List;
    return Column(
      children: status.map((s) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s['_id'].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _getStatusColor(s['_id']))),
              Text('${s['count']} Bookings', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Color(0xFF10B981);
      case 'pending': return Color(0xFFF59E0B);
      case 'rejected': return Color(0xFFF43F5E);
      default: return Color(0xFF6366F1);
    }
  }
}
