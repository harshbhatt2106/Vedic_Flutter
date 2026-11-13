class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorUserName,
    required this.activityType,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.detailsJson,
    required this.ipAddress,
    required this.createdAtUtc,
  });

  final int id;
  final String? actorUserId;
  final String? actorUserName;
  final String activityType;
  final String action;
  final String entityType;
  final String? entityId;
  final String? entityName;
  final String? detailsJson;
  final String? ipAddress;
  final DateTime? createdAtUtc;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) => AdminAuditLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        actorUserId: json['actorUserId']?.toString(),
        actorUserName: json['actorUserName']?.toString(),
        activityType: json['activityType']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        entityType: json['entityType']?.toString() ?? '',
        entityId: json['entityId']?.toString(),
        entityName: json['entityName']?.toString(),
        detailsJson: json['detailsJson']?.toString(),
        ipAddress: json['ipAddress']?.toString(),
        createdAtUtc: DateTime.tryParse(json['createdAtUtc']?.toString() ?? ''),
      );
}
