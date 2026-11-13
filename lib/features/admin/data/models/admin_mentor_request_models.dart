class AdminMentorUserRequest {
  const AdminMentorUserRequest({
    required this.id,
    required this.mentorUserId,
    required this.requestedName,
    required this.requestedMobileNumber,
    required this.status,
    required this.createdAtUtc,
    required this.mentorName,
  });

  final String id;
  final String mentorUserId;
  final String requestedName;
  final String requestedMobileNumber;
  final String status;
  final DateTime? createdAtUtc;
  final String mentorName;

  factory AdminMentorUserRequest.fromJson(Map<String, dynamic> json) => AdminMentorUserRequest(
        id: json['id']?.toString() ?? '',
        mentorUserId: json['mentorUserId']?.toString() ?? '',
        requestedName: json['requestedName']?.toString() ?? '',
        requestedMobileNumber: json['requestedMobileNumber']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Pending',
        createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
        mentorName: json['mentorName']?.toString() ?? 'Unknown mentor',
      );
}

class AdminMentorStat {
  const AdminMentorStat({
    required this.mentorUserId,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.memberCount,
  });

  final String mentorUserId;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final int memberCount;

  String get displayName => [firstName, lastName].where((value) => value.trim().isNotEmpty).join(' ');

  factory AdminMentorStat.fromJson(Map<String, dynamic> json) => AdminMentorStat(
        mentorUserId: json['mentorUserId']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        mobileNumber: json['mobileNumber']?.toString() ?? '',
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      );
}
