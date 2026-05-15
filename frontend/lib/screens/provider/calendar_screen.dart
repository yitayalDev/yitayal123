import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class ProviderCalendarScreen extends StatefulWidget {
  @override
  _ProviderCalendarScreenState createState() => _ProviderCalendarScreenState();
}

class _ProviderCalendarScreenState extends State<ProviderCalendarScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _eventsByDay = {};
  List<RecurringSlot> _recurringSlots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _appointmentService.getMyAppointments();
      final appointments = response.appointments;
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      Map<DateTime, List<dynamic>> data = {};
      
      for (var app in appointments) {
        final date = DateTime(app.date.year, app.date.month, app.date.day);
        if (data[date] == null) data[date] = [];
        data[date]!.add(app);
      }

      if (user != null) {
        _recurringSlots = user.recurringBusySlots;
        for (var slot in user.busySlots) {
          if (slot.date.isEmpty) continue;
          final parts = slot.date.split('-');
          if (parts.length != 3) continue;
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (data[date] == null) data[date] = [];
          data[date]!.add(slot);
        }
      }

      setState(() {
        _eventsByDay = data;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    List<dynamic> events = List.from(_eventsByDay[date] ?? []);
    
    for (var slot in _recurringSlots) {
      if (slot.active) {
        events.add(slot);
      }
    }
    
    events.sort((a, b) {
      String timeA = _getTimeString(a);
      String timeB = _getTimeString(b);
      return timeA.compareTo(timeB);
    });
    
    return events;
  }

  String _getTimeString(dynamic event) {
    if (event is AppointmentModel) return event.timeSlot;
    if (event is BusySlot) return event.startTime;
    if (event is RecurringSlot) return event.startTime;
    return "00:00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: _isLoading 
              ? Container(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))))
              : Column(
                  children: [
                    _buildCalendarCard(),
                    _buildAgendaTitle(),
                    _buildEventList(),
                    SizedBox(height: 40),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), 
        onPressed: () => Navigator.pop(context)
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, bottom: 16),
        title: Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.calendar_today_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
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
            child: Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
          ),
          onPressed: _fetchData,
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(Duration(days: 365)),
          lastDay: DateTime.now().add(Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
            todayTextStyle: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            selectedDecoration: BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
            markersMaxCount: 1,
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: Colors.red[300]),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            formatButtonDecoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Color(0xFF0F172A)),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Color(0xFF0F172A).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF0F172A)),
          ),
          SizedBox(width: 12),
          Text(
            DateFormat('EEEE, MMM d').format(_selectedDay!),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${_getEventsForDay(_selectedDay!).length} Events',
              style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 64, color: Colors.grey[200]),
              SizedBox(height: 16),
              Text('Free day! No events scheduled.', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        if (event is AppointmentModel) {
          return _buildAppointmentCard(event);
        } else if (event is BusySlot) {
          return _buildBusySlotCard(event);
        } else if (event is RecurringSlot) {
          return _buildRecurringSlotCard(event);
        }
        return SizedBox();
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel app) {
    final statusColor = _getStatusColor(app.status);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(app.appointmentType == 'virtual' ? Icons.videocam_rounded : Icons.person_rounded, color: statusColor),
        ),
        title: Text(
          app.serviceName, 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Student: ${app.userName ?? "N/A"}', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                app.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Text(
            app.timeSlot,
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildBusySlotCard(BusySlot slot) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.block_rounded, color: Colors.grey[600]),
        ),
        title: Text(
          'Blocked: ${slot.reason.isEmpty ? "Busy" : slot.reason}', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 15)
        ),
        subtitle: Text('One-time block', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Text(
          '${slot.startTime} - ${slot.endTime}',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF475569), fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRecurringSlotCard(RecurringSlot slot) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.repeat_rounded, color: Colors.orange[700]),
        ),
        title: Text(
          'Break: ${slot.reason.isEmpty ? "Lunch/Break" : slot.reason}', 
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange[900], fontSize: 15)
        ),
        subtitle: Text('Daily recurring break', style: TextStyle(color: Colors.orange[300], fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Text(
          '${slot.startTime} - ${slot.endTime}',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange[700], fontSize: 13),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Color(0xFF10B981);
      case 'rejected': return Color(0xFFEF4444);
      case 'completed': return Color(0xFF6366F1);
      case 'cancelled': return Color(0xFF94A3B8);
      default: return Color(0xFFF59E0B);
    }
  }
}
