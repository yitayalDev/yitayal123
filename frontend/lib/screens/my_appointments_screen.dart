import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import '../widgets/rating_dialog.dart';
import 'chat_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<AppointmentResponse> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAppointments();
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
    });
  }

  void _joinMeeting(AppointmentModel appointment) async {
    if (appointment.meetingRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting room not generated yet.')),
      );
      return;
    }

    if (kIsWeb) {
      final url = Uri.parse('https://meet.jit.si/${appointment.meetingRoom}');
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch video call: $e')),
        );
      }
      return;
    }

    var jitsiMeet = JitsiMeet();
    var options = JitsiMeetConferenceOptions(
      room: appointment.meetingRoom!,
      configOverrides: {
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
        "subject" : appointment.serviceName,
      },
      featureFlags: {
        "unsecureMeetingIdReminder": false,
        "ios.screensharing.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(
          displayName: appointment.userName ?? "Student",
          email: "",
          avatar: ""
      ),
    );
    await jitsiMeet.join(options);
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

  void _showQRDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titlePadding: EdgeInsets.only(top: 24),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Color(0xFF0F172A).withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0F172A), size: 32),
            ),
            SizedBox(height: 16),
            Text('Check-in Code', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appointment.serviceName, textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, 10))],
                border: Border.all(color: Color(0xFFF1F5F9)),
              ),
              child: QrImageView(
                data: appointment.id,
                version: QrVersions.auto,
                size: 180.0,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF0F172A)),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF0F172A)),
              ),
            ),
            SizedBox(height: 24),
            Text('Present this code to the provider upon arrival.', 
                 textAlign: TextAlign.center, 
                 style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3C72))),
            ),
          ),
        ],
      ),
    );
  }

  void _pickAndUpload(String appointmentId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      withData: kIsWeb,
    );

    if (result != null) {
      dynamic fileToUpload;
      String? fileName;

      if (kIsWeb) {
        fileToUpload = result.files.single.bytes;
        fileName = result.files.single.name;
      } else {
        fileToUpload = File(result.files.single.path!);
      }
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      final uploadResult = await _appointmentService.uploadFile(
        appointmentId, 
        fileToUpload,
        fileName: fileName,
      );
      
      Navigator.pop(context);

      if (uploadResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.indigo[700])
        );
        _refreshAppointments();
      }
    }
  }

  final List<String> _timeSlots = [
    "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM",
    "11:00 AM", "11:30 AM", "02:00 PM", "02:30 PM",
    "03:00 PM", "03:30 PM", "04:00 PM"
  ];

  void _showRescheduleDialog(AppointmentModel appointment) {
    DateTime tempDate = appointment.date;
    String tempTime = appointment.timeSlot;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13)),
                SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempDate.isBefore(DateTime.now()) ? DateTime.now().add(Duration(days: 1)) : tempDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                    );
                    if (picked != null) {
                      setDialogState(() => tempDate = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM d, yyyy').format(tempDate), style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Icon(Icons.calendar_today_rounded, color: Color(0xFF1E3C72), size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('New Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13)),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((time) {
                    final isSelected = tempTime == time;
                    return InkWell(
                      onTap: () => setDialogState(() => tempTime = time),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.transparent : Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await _appointmentService.rescheduleAppointment(
                  appointment.id,
                  DateFormat('yyyy-MM-dd').format(tempDate),
                  tempTime,
                );
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reschedule request sent!'), behavior: SnackBarBehavior.floating));
                  _refreshAppointments();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3C72),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Request Change', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(AppointmentModel appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Supporting Documents', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF475569))),
            IconButton(
              onPressed: () => _pickAndUpload(appointment.id),
              icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF1E3C72)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (appointment.attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('No files attached', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ...appointment.attachments.map((file) => Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.insert_drive_file_rounded, size: 18, color: Color(0xFF64748B)),
            title: Text(file.split('-').last, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF1E3C72)),
              onPressed: () async {
                final url = _appointmentService.getAttachmentUrl(file);
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        )).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        title: Text('My Appointments', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<AppointmentResponse>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF1E3C72)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_rounded, size: 80, color: Colors.grey[200]),
                  SizedBox(height: 16),
                  Text('No appointments found', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final response = snapshot.data!;
          final appointments = response.appointments;

          return Column(
            children: [
              if (response.isFromCache)
                Container(
                  color: Colors.amber[50],
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt_rounded, size: 18, color: Colors.amber[900]),
                      SizedBox(width: 10),
                      Text(
                        'Viewing Offline Mode',
                        style: TextStyle(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshAppointments(),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final statusColor = _getStatusColor(appointment.status);
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            appointment.appointmentType == 'virtual' ? Icons.videocam_rounded : Icons.person_pin_rounded, 
                                            color: statusColor,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                appointment.serviceName,
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A), letterSpacing: -0.5),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                appointment.providerName,
                                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  _buildInfoTag(Icons.calendar_today_rounded, DateFormat('MMM d').format(appointment.date)),
                                                  SizedBox(width: 12),
                                                  _buildInfoTag(Icons.access_time_rounded, appointment.timeSlot),
                                                ],
                                              ),
                                              if (appointment.queuePosition != null) ...[
                                                SizedBox(height: 12),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.indigo[100]!),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.people_alt_rounded, size: 14, color: Colors.indigo[700]),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Position in Line: ',
                                                        style: TextStyle(color: Colors.indigo[900], fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                      Text(
                                                        '${appointment.queuePosition}${_getOrdinal(appointment.queuePosition!)}',
                                                        style: TextStyle(color: Colors.indigo[700], fontSize: 13, fontWeight: FontWeight.w900),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(appointment.status, statusColor),
                                      ],
                                    ),
                                    if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Color(0xFFF1F5F9)),
                                        ),
                                        child: Text(
                                          appointment.reason!,
                                          style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 20),
                                    _buildDocumentsSection(appointment),
                                  ],
                                ),
                              ),
                              _buildActionFooter(appointment),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
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

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionFooter(AppointmentModel appointment) {
    if (appointment.status == 'rejected' || appointment.status == 'cancelled') return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (appointment.status == 'approved') ...[
            _buildIconButton(Icons.qr_code_rounded, 'QR', () => _showQRDialog(context, appointment), Colors.indigo),
            SizedBox(width: 12),
            _buildIconButton(Icons.message_rounded, 'Chat', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(appointmentId: appointment.id, otherPartyName: appointment.providerName))), Colors.teal),
            SizedBox(width: 12),
          ],
          if (appointment.status == 'approved' && appointment.appointmentType == 'virtual') ...[
            _buildActionButton('JOIN CALL', Icons.videocam_rounded, () => _joinMeeting(appointment), Color(0xFF10B981)),
            SizedBox(width: 12),
          ],
          if (appointment.status == 'pending' || appointment.status == 'approved') ...[
            _buildIconButton(Icons.edit_calendar_rounded, 'Reschedule', () => _showRescheduleDialog(appointment), Colors.blue),
            SizedBox(width: 12),
            _buildIconButton(Icons.cancel_rounded, 'Cancel', () => _cancelAppointment(appointment.id), Color(0xFFF43F5E)),
          ],
          if (appointment.status == 'completed')
            _buildActionButton('RATE SERVICE', Icons.star_rounded, () async {
              final result = await showDialog(
                context: context,
                builder: (context) => RatingDialog(
                  appointmentId: appointment.id,
                  serviceName: appointment.serviceName,
                ),
              );
              if (result == true) _refreshAppointments();
            }, Colors.amber[800]!),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onTap, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF43F5E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _appointmentService.updateStatus(id, 'cancelled');
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment cancelled'), behavior: SnackBarBehavior.floating));
        _refreshAppointments();
      }
    }
  }
}
