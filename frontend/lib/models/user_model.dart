class BusySlot {
  final String date;
  final String startTime;
  final String endTime;
  final String reason;

  BusySlot({required this.date, required this.startTime, required this.endTime, this.reason = ""});

  factory BusySlot.fromJson(Map<String, dynamic> json) {
    return BusySlot(
      date: json['date'] ?? "",
      startTime: json['startTime'] ?? "",
      endTime: json['endTime'] ?? "",
      reason: json['reason'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }
}

class RecurringSlot {
  final String startTime;
  final String endTime;
  final String reason;
  final bool active;

  RecurringSlot({required this.startTime, required this.endTime, this.reason = "", this.active = true});

  factory RecurringSlot.fromJson(Map<String, dynamic> json) {
    return RecurringSlot(
      startTime: json['startTime'] ?? "",
      endTime: json['endTime'] ?? "",
      reason: json['reason'] ?? "",
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'active': active,
    };
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? userType;
  final String category;
  final String phone;
  final String bio;
  final bool isAvailable;
  final List<String> unavailableDates;
  final List<BusySlot> busySlots;
  final List<RecurringSlot> recurringBusySlots;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.userType,
    this.category = "General",
    this.phone = "",
    this.bio = "",
    this.isAvailable = true,
    this.unavailableDates = const [],
    this.busySlots = const [],
    this.recurringBusySlots = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? "",
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      userType: json['userType'],
      category: json['category'] ?? "General",
      phone: json['phone'] ?? "",
      bio: json['bio'] ?? "",
      isAvailable: json['isAvailable'] ?? true,
      unavailableDates: List<String>.from(json['unavailableDates'] ?? []),
      busySlots: (json['busySlots'] as List? ?? []).map((s) => BusySlot.fromJson(s)).toList(),
      recurringBusySlots: (json['recurringBusySlots'] as List? ?? []).map((s) => RecurringSlot.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'userType': userType,
      'category': category,
      'phone': phone,
      'bio': bio,
      'isAvailable': isAvailable,
      'unavailableDates': unavailableDates,
      'busySlots': busySlots.map((s) => s.toJson()).toList(),
      'recurringBusySlots': recurringBusySlots.map((s) => s.toJson()).toList(),
    };
  }
}
