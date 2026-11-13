import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/admin/data/models/admin_mentor_request_models.dart';

void main() {
  test('parses mentor request with status and requested member details', () {
    final request = AdminMentorUserRequest.fromJson({
      'id': 'request-1',
      'mentorUserId': 'mentor-1',
      'requestedName': 'Ravi Patel',
      'requestedMobileNumber': '9876543210',
      'status': 'Pending',
      'createdAtUtc': '2026-11-13T08:00:00Z',
      'mentorName': 'Mentor One',
    });
    expect(request.requestedName, 'Ravi Patel');
    expect(request.status, 'Pending');
    expect(request.mentorName, 'Mentor One');
    expect(request.createdAtUtc, isNotNull);
  });

  test('parses mentor direct assignment count', () {
    final stat = AdminMentorStat.fromJson({
      'mentorUserId': 'mentor-1',
      'firstName': 'Nisha',
      'lastName': 'Shah',
      'mobileNumber': '9000000000',
      'memberCount': 8,
    });
    expect(stat.displayName, 'Nisha Shah');
    expect(stat.memberCount, 8);
  });
}
