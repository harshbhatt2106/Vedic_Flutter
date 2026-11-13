class AdminMember {
  const AdminMember({
    required this.userId,
    required this.userName,
    required this.mobileNumber,
    required this.email,
    required this.roleName,
    required this.isMobileVerified,
    required this.isEmailVerified,
    required this.isActive,
    required this.isDeleted,
    required this.createdAtUtc,
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.profession,
    required this.education,
    required this.approvalStatus,
    required this.visibilityStatus,
    required this.isProfileComplete,
    required this.dateOfBirth,
    required this.cityName,
    required this.religionName,
    required this.mentorName,
    required this.mentorUserId,
  });

  final String userId;
  final String userName;
  final String mobileNumber;
  final String? email;
  final String roleName;
  final bool isMobileVerified;
  final bool isEmailVerified;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAtUtc;
  final String? profileId;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? profession;
  final String? education;
  final String? approvalStatus;
  final String? visibilityStatus;
  final bool isProfileComplete;
  final DateTime? dateOfBirth;
  final String? cityName;
  final String? religionName;
  final String? mentorName;
  final String? mentorUserId;

  String get displayName {
    final name = [firstName, lastName].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    return name.isEmpty ? userName : name;
  }

  factory AdminMember.fromJson(Map<String, dynamic> json) => AdminMember(
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        mobileNumber: json['mobileNumber']?.toString() ?? '',
        email: json['email']?.toString(),
        roleName: json['roleName']?.toString() ?? '',
        isMobileVerified: json['isMobileVerified'] == true,
        isEmailVerified: json['isEmailVerified'] == true,
        isActive: json['isActive'] == true,
        isDeleted: json['isDeleted'] == true,
        createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
        profileId: json['profileId']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        gender: json['gender']?.toString(),
        profession: json['profession']?.toString(),
        education: json['education']?.toString(),
        approvalStatus: json['approvalStatus']?.toString(),
        visibilityStatus: json['visibilityStatus']?.toString(),
        isProfileComplete: json['isProfileComplete'] == true,
        dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
        cityName: json['cityName']?.toString(),
        religionName: json['religionName']?.toString(),
        mentorName: json['mentorName']?.toString(),
        mentorUserId: json['mentorUserId']?.toString(),
      );
}
