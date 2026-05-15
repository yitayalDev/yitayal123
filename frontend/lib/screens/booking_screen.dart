import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../services/appointment_service.dart';
import '../providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class BookingScreen extends StatefulWidget {
  final ServiceModel service;

  BookingScreen({required this.service});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  String _selectedTime = "09:00 AM";
  
  final _reasonController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _majorController = TextEditingController();
  final _orgController = TextEditingController();
  final _guestIdController = TextEditingController();
  String _appointmentType = 'physical';

  final List<String> _timeSlots = [
    "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM",
    "11:00 AM", "11:30 AM", "02:00 PM", "02:30 PM",
    "03:00 PM", "03:30 PM", "04:00 PM"
  ];

  List<PlatformFile> _attachments = [];

  void _book(String userType) async {
    final result = await _appointmentService.bookAppointment(
      widget.service.id,
      DateFormat('yyyy-MM-dd').format(_selectedDate),
      _selectedTime,
      _reasonController.text,
      studentId: userType == 'student' ? _studentIdController.text : null,
      major: userType == 'student' ? _majorController.text : null,
      organization: (userType == 'other' || userType == 'staff' || userType == 'researcher') ? _orgController.text : null,
      guestId: (userType == 'other' || userType == 'staff' || userType == 'researcher') ? _guestIdController.text : null,
      attachments: [],
      appointmentType: _appointmentType,
    );

    if (result['success']) {
      final String appointmentId = result['appointment'].id;

      if (_attachments.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Uploading documents...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )),
        );

        for (var file in _attachments) {
          if (kIsWeb) {
            await _appointmentService.uploadFile(appointmentId, file.bytes, fileName: file.name);
          } else {
            await _appointmentService.uploadFile(appointmentId, File(file.path!));
          }
        }
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Color(0xFF065F46),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any, // Changed to 'any' for maximum compatibility
        withData: kIsWeb,
      );
      
      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      print("File picking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file picker. Please check app permissions.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isGuest = authProvider.isGuest;
    final String userType = user?.userType ?? 'student';
    final bool isEmergencyToday = !widget.service.providerIsAvailable && _isDateToday(_selectedDate);

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmergencyToday) _buildEmergencyWarning(),
                  
                  _buildSectionHeader('Personal Information', Icons.person_pin_rounded),
                  SizedBox(height: 16),
                  if (userType == 'student') ...[
                    _buildField(_studentIdController, 'Student ID', 'Enter your ID number', Icons.badge_rounded),
                    SizedBox(height: 16),
                    _buildField(_majorController, 'Major/Department', 'e.g. Computer Science', Icons.school_rounded),
                  ] else ...[
                    _buildField(_orgController, 'Organization', 'Your affiliation', Icons.business_rounded),
                    SizedBox(height: 16),
                    _buildField(_guestIdController, 'ID/Passport', 'Identification number', Icons.credit_card_rounded),
                  ],
                  
                  SizedBox(height: 32),
                  _buildSectionHeader('Appointment Details', Icons.event_available_rounded),
                  SizedBox(height: 16),
                  _buildTypeSelector(),
                  SizedBox(height: 20),
                  _buildDatePicker(),
                  SizedBox(height: 24),
                  Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 13)),
                  SizedBox(height: 12),
                  _buildTimeSlots(),
                  SizedBox(height: 24),
                  _buildField(_reasonController, 'Reason for Visit', 'Briefly describe your request', Icons.notes_rounded, maxLines: 3),
                  
                  SizedBox(height: 32),
                  _buildSectionHeader('Attachments (Optional)', Icons.attach_file_rounded),
                  SizedBox(height: 16),
                  _buildFilePicker(),
                  
                  SizedBox(height: 48),
                  _buildSubmitButton(userType, isGuest, isEmergencyToday),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFF0F172A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, bottom: 16, right: 24),
        title: Text(
          widget.service.name, 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.calendar_month_rounded, size: 120, color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyWarning() {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Provider is unavailable today. Please select a future date.',
              style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF1E3C72)),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Color(0xFF94A3B8), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          floatingLabelStyle: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeCard('physical', 'In-Person', Icons.location_on_rounded),
        SizedBox(width: 16),
        _buildTypeCard('virtual', 'Video Call', Icons.videocam_rounded),
      ],
    );
  }

  Widget _buildTypeCard(String type, String label, IconData icon) {
    final bool isSelected = _appointmentType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _appointmentType = type),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : Color(0xFFE2E8F0)),
            boxShadow: isSelected ? [BoxShadow(color: Color(0xFF0F172A).withOpacity(0.2), blurRadius: 12, offset: Offset(0, 6))] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Color(0xFF64748B), size: 24),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF1E293B),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Color(0xFF1E3C72)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: Color(0xFF1E3C72), size: 20),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate), style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
            Spacer(),
            Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timeSlots.map((time) {
        final isSelected = _selectedTime == time;
        return InkWell(
          onTap: () => setState(() => _selectedTime = time),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF1E3C72) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.transparent : Color(0xFFE2E8F0)),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      children: [
        InkWell(
          onTap: _pickFiles,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1E3C72).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF1E3C72).withOpacity(0.1), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded, color: Color(0xFF1E3C72)),
                SizedBox(width: 12),
                Text('Add Supporting Documents', style: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        if (_attachments.isNotEmpty) ...[
          SizedBox(height: 16),
          ..._attachments.map((file) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file_rounded, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 12),
                Expanded(child: Text(file.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                IconButton(
                  icon: Icon(Icons.cancel_rounded, size: 20, color: Colors.red[300]),
                  onPressed: () => setState(() => _attachments.remove(file)),
                ),
              ],
            ),
          )).toList(),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(String userType, bool isGuest, bool isEmergencyToday) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isEmergencyToday ? null : LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3C72)]),
        color: isEmergencyToday ? Colors.grey : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEmergencyToday ? null : [BoxShadow(color: Color(0xFF1E3C72).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: !isEmergencyToday 
            ? (isGuest ? _showLoginRequiredDialog : () => _book(userType)) 
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          !isEmergencyToday ? (isGuest ? 'LOGIN TO BOOK' : 'CONFIRM BOOKING') : 'UNAVAILABLE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Login Required', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Please log in to your student account to book appointments and access video calls.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E3C72),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Login / Register'),
          ),
        ],
      ),
    );
  }
}
