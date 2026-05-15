import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class AllAppointmentsScreen extends StatefulWidget {
  @override
  _AllAppointmentsScreenState createState() => _AllAppointmentsScreenState();
}

class _AllAppointmentsScreenState extends State<AllAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<AppointmentResponse> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _appointmentService.getMyAppointments(); // API returns all for Admin
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Color(0xFF10B981);
      case 'rejected': return Color(0xFFF43F5E);
      case 'completed': return Colors.indigo;
      case 'cancelled': return Colors.blueGrey;
      default: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 8),
                  Text('Global Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ),
          FutureBuilder<AppointmentResponse>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))));
              } else if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Failed to load system activity')));
              } else if (!snapshot.hasData || snapshot.data!.appointments.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
                        SizedBox(height: 16),
                        Text('No system activity recorded.', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }

              final appointments = snapshot.data!.appointments;

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAppointmentCard(appointments[index]),
                    childCount: appointments.length,
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, bottom: 16),
        title: Text('Master Schedule', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                appointment.appointmentType == 'virtual' ? Icons.videocam_rounded : Icons.person_pin_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            title: Text(
              appointment.serviceName, 
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 15)
            ),
            subtitle: Text(
              'Provider: ${appointment.providerName}', 
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(
                appointment.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
          if (appointment.reason != null && appointment.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Container(
                padding: EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.reason!,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildInfoTag(Icons.calendar_today_rounded, DateFormat('MMM d, yyyy').format(appointment.date)),
                SizedBox(width: 12),
                _buildInfoTag(Icons.access_time_rounded, appointment.timeSlot),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Color(0xFF64748B)),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
