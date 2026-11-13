class AdminLocationItem {
  const AdminLocationItem({
    required this.id,
    required this.name,
    required this.isActive,
    this.parentId,
  });

  final int id;
  final String name;
  final bool isActive;
  final int? parentId;

  factory AdminLocationItem.country(Map<String, dynamic> json) => AdminLocationItem(
        id: (json['countryId'] as num?)?.toInt() ?? 0,
        name: json['countryName']?.toString() ?? '',
        isActive: json['isActive'] == true,
      );

  factory AdminLocationItem.state(Map<String, dynamic> json) => AdminLocationItem(
        id: (json['stateId'] as num?)?.toInt() ?? 0,
        parentId: (json['countryId'] as num?)?.toInt(),
        name: json['stateName']?.toString() ?? '',
        isActive: json['isActive'] == true,
      );

  factory AdminLocationItem.city(Map<String, dynamic> json) => AdminLocationItem(
        id: (json['cityId'] as num?)?.toInt() ?? 0,
        parentId: (json['stateId'] as num?)?.toInt(),
        name: json['cityName']?.toString() ?? '',
        isActive: json['isActive'] == true,
      );
}
