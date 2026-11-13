import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/admin/data/models/admin_report.dart';

void main() {
  test('parses the read-only Admin report DTO', () {
    final report = AdminReport.fromJson({
      'id': 'report-1',
      'reportedByUserId': 'user-1',
      'reportedByName': 'Aarav Patel',
      'reportedUserId': 'user-2',
      'reportedUserName': 'Rohan Shah',
      'reason': 'The profile contains misleading information.',
      'createdAtUtc': '2026-11-13T08:00:00Z',
    });

    expect(report.id, 'report-1');
    expect(report.reportedByName, 'Aarav Patel');
    expect(report.reportedUserName, 'Rohan Shah');
    expect(report.reason, contains('misleading'));
    expect(report.createdAtUtc, isNotNull);
  });
}
