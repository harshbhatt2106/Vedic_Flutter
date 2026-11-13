import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/admin/data/models/admin_audit_log.dart';

void main() {
  test('parses audit record fields including nullable actor and entity metadata', () {
    final log = AdminAuditLog.fromJson({
      'id': 42,
      'actorUserId': null,
      'actorUserName': null,
      'activityType': 'Administration',
      'action': 'ProfileApproved',
      'entityType': 'UserProfile',
      'entityId': 'profile-1',
      'entityName': null,
      'detailsJson': '{"profileId":"profile-1"}',
      'ipAddress': '127.0.0.1',
      'createdAtUtc': '2026-11-13T07:00:00Z',
    });

    expect(log.id, 42);
    expect(log.actorUserId, isNull);
    expect(log.actorUserName, isNull);
    expect(log.action, 'ProfileApproved');
    expect(log.entityType, 'UserProfile');
    expect(log.createdAtUtc, isNotNull);
  });
}
