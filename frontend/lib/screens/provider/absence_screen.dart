import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';

class AbsenceScreen extends StatefulWidget {
  @override
  _AbsenceScreenState createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  bool _isProcessing = false;

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedStart = start;
      _selectedEnd = end;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _confirmPlannedAbsence() async {
    if (_selectedStart == null || _selectedEnd == null) return;

    List<String> dates = [];
    int days = _selectedEnd!.difference(_selectedStart!).inDays + 1;
    for (int i = 0; i < days; i++) {
      final date = _selectedStart!.add(Duration(days: i));
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Confirm Absence', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('This will cancel all appointments for ${dates.length} days. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700], 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirm Absence', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      final result = await Provider.of<AuthProvider>(context, listen: false).toggleEmergencyMode(dates: dates);
      setState(() => _isProcessing = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']), 
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final bool isEmergencyActive = user?.isAvailable == false;

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text('Absence Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyCard(isEmergencyActive),
            SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.date_range_rounded, color: Color(0xFF64748B), size: 20),
                SizedBox(width: 10),
                Text('Schedule Time Off', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ],
            ),
            SizedBox(height: 8),
            Text('Select a date range for your planned absence.', 
                 style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(height: 20),
            _buildCalendarPicker(),
            SizedBox(height: 32),
            if (_selectedStart != null && _selectedEnd != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red[400]!, Colors.red[700]!]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _confirmPlannedAbsence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing 
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'BLOCK ${DateFormat('MMM d').format(_selectedStart!)} - ${DateFormat('MMM d').format(_selectedEnd!)}', 
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                ),
              ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(bool isActive) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive ? Colors.red[50] : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isActive ? Colors.red[200]! : Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.red : Colors.blueGrey).withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? Icons.emergency_rounded : Icons.flash_on_rounded, 
                  color: isActive ? Colors.red[700] : Colors.blueGrey[400], 
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isActive ? 'ON' : 'OFF', 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: isActive ? Colors.red : Colors.grey[400],
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeColor: Colors.red[700],
                    activeTrackColor: Colors.red[100],
                    onChanged: (val) async {
                      setState(() => _isProcessing = true);
                      await Provider.of<AuthProvider>(context, listen: false).toggleEmergencyMode();
                      setState(() => _isProcessing = false);
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            isActive ? 'Emergency Mode Active' : 'Emergency Absence (Today)',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w900, 
              color: isActive ? Colors.red[900] : Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isActive 
                ? 'Your office is currently closed. All bookings for today have been blocked.' 
                : 'Instantly block all bookings for today if you have a sudden emergency.',
            style: TextStyle(
              color: isActive ? Colors.red[700] : Color(0xFF64748B), 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPicker() {
    return Container(
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
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(Duration(days: 90)),
          focusedDay: _focusedDay,
          rangeStartDay: _selectedStart,
          rangeEndDay: _selectedEnd,
          rangeSelectionMode: RangeSelectionMode.enforced,
          onRangeSelected: _onRangeSelected,
          calendarStyle: CalendarStyle(
            rangeHighlightColor: Colors.red[50]!,
            rangeStartDecoration: BoxDecoration(color: Colors.red[700], shape: BoxShape.circle),
            rangeEndDecoration: BoxDecoration(color: Colors.red[700], shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.blueGrey[50], shape: BoxShape.circle),
            todayTextStyle: TextStyle(color: Colors.blueGrey[900], fontWeight: FontWeight.bold),
            selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: Color(0xFF0F172A)),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}
