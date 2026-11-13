class AdminQueueProfile {
  const AdminQueueProfile({
    required this.id,
    required this.userId,
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.profession,
    required this.education,
    required this.cityName,
    required this.approvalStatus,
    required this.createdAtUtc,
  });

  final String id;
  final String userId;
  final String userName;
  final String firstName;
  final String? lastName;
  final String? email;
  final String gender;
  final DateTime? dateOfBirth;
  final String? profession;
  final String? education;
  final String? cityName;
  final String approvalStatus;
  final DateTime? createdAtUtc;

  String get fullName => [firstName, lastName].where((value) => value != null && value.trim().isNotEmpty).join(' ');

  int? get age {
    final birth = dateOfBirth;
    if (birth == null) return null;
    final today = DateTime.now();
    var years = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      years--;
    }
    return years;
  }

  bool get canReview => approvalStatus.toLowerCase() == 'submittedforreview';

  factory AdminQueueProfile.fromJson(Map<String, dynamic> json) => AdminQueueProfile(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString(),
        email: json['email']?.toString(),
        gender: json['gender']?.toString() ?? '',
        dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
        profession: json['profession']?.toString(),
        education: json['education']?.toString(),
        cityName: json['cityName']?.toString(),
        approvalStatus: json['approvalStatus']?.toString() ?? 'Pending',
        createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
      );
}

class AdminReviewPhoto {
  const AdminReviewPhoto({required this.id, required this.isPrimary});
  final String id;
  final bool isPrimary;

  factory AdminReviewPhoto.fromJson(Map<String, dynamic> json) => AdminReviewPhoto(
        id: json['id']?.toString() ?? '',
        isPrimary: json['isPrimary'] == true,
      );
}

class AdminReviewContact {
  const AdminReviewContact({
    required this.referenceId,
    required this.name,
    required this.phoneNumber,
    required this.cityName,
    required this.relationshipWithUser,
  });

  final String referenceId;
  final String name;
  final String phoneNumber;
  final String cityName;
  final String relationshipWithUser;

  factory AdminReviewContact.fromJson(Map<String, dynamic> json) => AdminReviewContact(
        referenceId: json['referenceId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        cityName: json['cityName']?.toString() ?? '',
        relationshipWithUser: json['relationshipWithUser']?.toString() ?? '',
      );
}

class AdminProfileReviewDetail {
  const AdminProfileReviewDetail({
    required this.profile,
    required this.photos,
    required this.contacts,
  });

  final Map<String, dynamic> profile;
  final List<AdminReviewPhoto> photos;
  final List<AdminReviewContact> contacts;

  factory AdminProfileReviewDetail.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    final rawPhotos = json['photos'];
    final rawContacts = json['relativeContacts'];
    return AdminProfileReviewDetail(
      profile: rawProfile is Map ? Map<String, dynamic>.from(rawProfile) : const {},
      photos: rawPhotos is List
          ? rawPhotos.whereType<Map>().map((item) => AdminReviewPhoto.fromJson(Map<String, dynamic>.from(item))).toList()
          : const [],
      contacts: rawContacts is List
          ? rawContacts.whereType<Map>().map((item) => AdminReviewContact.fromJson(Map<String, dynamic>.from(item))).toList()
          : const [],
    );
  }
}
