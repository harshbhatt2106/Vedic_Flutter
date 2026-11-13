class AdminReport {
  const AdminReport({
    required this.id,
    required this.reportedByUserId,
    required this.reportedByName,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reason,
    required this.createdAtUtc,
  });

  final String id;
  final String reportedByUserId;
  final String reportedByName;
  final String reportedUserId;
  final String reportedUserName;
  final String reason;
  final DateTime? createdAtUtc;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: json['id']?.toString() ?? '',
        reportedByUserId: json['reportedByUserId']?.toString() ?? '',
        reportedByName: json['reportedByName']?.toString() ?? '',
        reportedUserId: json['reportedUserId']?.toString() ?? '',
        reportedUserName: json['reportedUserName']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
        createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
      );
}
