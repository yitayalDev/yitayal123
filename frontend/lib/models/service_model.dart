class ServiceModel {
  final String id;
  final String name;
  final String providerId;
  final String providerName;
  final String? description;
  final int duration;
  final String? category;
  final String? providerCategory;
  final bool providerIsAvailable;

  ServiceModel({
    required this.id,
    required this.name,
    required this.providerId,
    required this.providerName,
    this.description,
    required this.duration,
    this.category,
    this.providerCategory,
    this.providerIsAvailable = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle providerId which could be a String or a Map (populated)
    String pId = "";
    String pName = 'Unknown Provider';
    bool pAvailable = true;
    String? pCat;

    if (json['providerId'] is Map) {
      pId = json['providerId']['_id'] ?? json['providerId']['id'] ?? "";
      pName = json['providerId']['name'] ?? 'Unknown Provider';
      pAvailable = json['providerId']['isAvailable'] ?? true;
      pCat = json['providerId']['category'];
    } else {
      pId = json['providerId']?.toString() ?? "";
    }

    return ServiceModel(
      id: json['_id'] ?? json['id'] ?? "",
      name: json['name'] ?? "",
      providerId: pId,
      providerName: pName,
      providerIsAvailable: pAvailable,
      description: json['description'],
      duration: json['duration'] ?? 30,
      category: json['category'],
      providerCategory: pCat,
    );
  }
}
