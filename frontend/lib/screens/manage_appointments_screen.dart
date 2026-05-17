import 'dart:io' show File;
import '../services/launcher_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  @override
  _ManageAppointmentsScreenState createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<AppointmentResponse> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _saveLastRoute();
    _refreshAppointments();
  }

  void _saveLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', 'manage_appointments');
    } catch (e) {
      print("Error saving last route: $e");
    }
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
    });
  }

  void _joinMeeting(AppointmentModel appointment) async {
    if (appointment.meetingRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting room not generated yet. Please refresh.')),
      );
      return;
    }

    if (kIsWeb) {
      final url = 'https://meet.jit.si/${appointment.meetingRoom}';
      try {
        openWebUrl(url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch video call: $e')),
        );
      }
      return;
    }

    try {
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
            displayName: appointment.providerName,
            email: "",
            avatar: ""
        ),
      );
      await jitsiMeet.join(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching Jitsi call: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateStatus(String id, String status, {String? reason}) async {
    final result = await _appointmentService.updateStatus(id, status, reason: reason);
    if (result['success']) {
      _refreshAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${status.toUpperCase()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  void _deleteAppointment(String id) async {
    final result = await _appointmentService.deleteAppointment(id);
    if (result['success']) {
      _refreshAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment permanently deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to delete')),
      );
    }
  }

  void _showReasonDialog(String id, String status) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Provide a Reason', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter reason for $status',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, status, reason: controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirm $status'),
          ),
        ],
      ),
    );
  }

  void _pickAndUpload(String appointmentId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
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
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final uploadResult = await _appointmentService.uploadFile(
        appointmentId, 
        fileToUpload,
        fileName: fileName,
      );
      
      Navigator.pop(context);

      if (uploadResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File uploaded successfully')));
        _refreshAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadResult['message'])));
      }
    }
    } catch (e) {
      print("File picking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file picker: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      case 'attended': return Color(0xFF059669);
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Widget _buildDocumentsSection(AppointmentModel appointment) {
    if (appointment.attachments.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attached Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
            TextButton.icon(
              onPressed: () => _pickAndUpload(appointment.id),
              icon: Icon(Icons.add_rounded, size: 16),
              label: Text('Add', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        ...appointment.attachments.map((file) => Container(
          margin: EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.insert_drive_file_rounded, size: 20, color: Colors.blue[700]),
            title: Text(file.split('-').last, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.download_rounded, size: 18, color: Colors.blue[700]),
              onPressed: () async {
                final url = _appointmentService.getAttachmentUrl(file);
                if (kIsWeb) {
                  openWebUrl(url);
                } else if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        )).toList(),
      ],
    );
  }

  void _openScanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text('Scan Student QR', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ),
        content: Container(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? id = barcodes.first.rawValue;
                  if (id != null) {
                    Navigator.pop(context);
                    _confirmCheckIn(id);
                  }
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL')),
        ],
      ),
    );
  }

  void _confirmCheckIn(String appointmentId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Confirm Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Mark this appointment as ATTENDED?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('NO')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(appointmentId, 'attended');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF059669), foregroundColor: Colors.white),
            child: Text('YES, CHECK-IN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        title: Text('Manage Appointments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            onPressed: _openScanner,
            tooltip: 'Scan Student QR',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<AppointmentResponse>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_rounded, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('No appointments found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final appointments = snapshot.data!.appointments;

          return RefreshIndicator(
            onRefresh: () async => _refreshAppointments(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStatusColor(appointment.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                appointment.appointmentType == 'virtual' ? Icons.videocam_rounded : Icons.person_pin_rounded, 
                                color: _getStatusColor(appointment.status),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.serviceName,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Student: ${appointment.userName ?? "N/A"}',
                                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(appointment.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(appointment.status),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              DateFormat('EEEE, MMM d').format(appointment.date),
                              style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              appointment.timeSlot,
                              style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Reason: ${appointment.reason}',
                              style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        _buildDocumentsSection(appointment),
                        if (appointment.status == 'pending' || appointment.status == 'approved') ...[
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (appointment.status == 'pending') ...[
                                TextButton(
                                  onPressed: () => _showReasonDialog(appointment.id, 'rejected'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                                  child: Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _updateStatus(appointment.id, 'approved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                              if (appointment.status == 'approved') ...[
                                OutlinedButton(
                                  onPressed: () => _showReasonDialog(appointment.id, 'cancelled'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red[700],
                                    side: BorderSide(color: Colors.red[100]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Cancel'),
                                ),
                                if (appointment.appointmentType == 'virtual') ...[
                                  SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _joinMeeting(appointment),
                                    icon: Icon(Icons.videocam_rounded, size: 18),
                                    label: Text('Join Call', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo[600],
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                                SizedBox(width: 12),
                                IconButton(
                                  icon: Icon(Icons.message_rounded, color: Colors.teal),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(appointmentId: appointment.id, otherPartyName: appointment.userName ?? "Student"))),
                                  tooltip: 'Chat with Student',
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (appointment.status == 'rejected' || appointment.status == 'cancelled' || appointment.status == 'completed') ...[
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Appointment?'),
                                      content: Text('Are you sure you want to permanently erase this ${appointment.status} appointment from your history?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteAppointment(appointment.id);
                                          },
                                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Icon(Icons.delete_outline_rounded, size: 20),
                                label: Text('Delete Record'),
                                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
