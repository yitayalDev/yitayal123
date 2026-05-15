class AppointmentModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String providerName;
  final String? userName;
  final DateTime date;
  final String timeSlot;
  final String status;
  final String? reason;
  final List<String> attachments;
  final String appointmentType;
  final String? meetingRoom;
  final int? queuePosition;

  AppointmentModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.providerName,
    this.userName,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.reason,
    this.attachments = const [],
    this.appointmentType = 'physical',
    this.meetingRoom,
    this.queuePosition,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      serviceId: (json['serviceId'] is Map) ? (json['serviceId']['_id'] ?? '') : (json['serviceId'] ?? ''),
      serviceName: (json['serviceId'] is Map) ? (json['serviceId']['name'] ?? 'Unknown Service') : (json['serviceName'] ?? 'Service Details Pending'),
      providerName: (json['providerId'] is Map) ? (json['providerId']['name'] ?? 'Unknown Provider') : (json['providerName'] ?? 'Provider Details Pending'),
      userName: (json['userId'] is Map) ? (json['userId']['name'] ?? 'User') : (json['userName'] ?? 'User'),
      date: _parseDate(json['date']),
      timeSlot: json['timeSlot'] ?? 'Not set',
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : [],
      appointmentType: json['appointmentType'] ?? 'physical',
      meetingRoom: json['meetingRoom'],
      queuePosition: json['queuePosition'],
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'providerName': providerName,
      'userName': userName,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'reason': reason,
      'attachments': attachments,
      'appointmentType': appointmentType,
      'meetingRoom': meetingRoom,
      'queuePosition': queuePosition,
    };
  }
}
