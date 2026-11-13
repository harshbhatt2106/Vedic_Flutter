class AdminLocationOption {
  const AdminLocationOption({required this.id, required this.name});
  final int id;
  final String name;

  factory AdminLocationOption.fromJson(Map<String, dynamic> json) => AdminLocationOption(
        id: (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class AdminMentorLocation {
  const AdminMentorLocation({
    required this.countryId,
    required this.countryName,
    required this.stateId,
    required this.stateName,
    required this.cityId,
    required this.cityName,
  });

  final int? countryId;
  final String? countryName;
  final int? stateId;
  final String? stateName;
  final int? cityId;
  final String? cityName;

  factory AdminMentorLocation.fromJson(Map<String, dynamic> json) => AdminMentorLocation(
        countryId: (json['countryId'] as num?)?.toInt(),
        countryName: json['countryName']?.toString(),
        stateId: (json['stateId'] as num?)?.toInt(),
        stateName: json['stateName']?.toString(),
        cityId: (json['cityId'] as num?)?.toInt(),
        cityName: json['cityName']?.toString(),
      );
}

class AdminAssignedMember {
  const AdminAssignedMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.email,
    required this.userName,
    required this.assignedAtUtc,
    required this.isActive,
  });

  final String userId;
  final String firstName;
  final String? lastName;
  final String mobileNumber;
  final String? email;
  final String userName;
  final DateTime? assignedAtUtc;
  final bool isActive;

  String get displayName => [firstName, lastName].where((value) => value != null && value.trim().isNotEmpty).join(' ');

  factory AdminAssignedMember.fromJson(Map<String, dynamic> json) => AdminAssignedMember(
        userId: json['userId']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString(),
        mobileNumber: json['mobileNumber']?.toString() ?? '',
        email: json['email']?.toString(),
        userName: json['userName']?.toString() ?? '',
        assignedAtUtc: DateTime.tryParse(json['assignedAtUtc']?.toString() ?? ''),
        isActive: json['isActive'] == true,
      );
}
