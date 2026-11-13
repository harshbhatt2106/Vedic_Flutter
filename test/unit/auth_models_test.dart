import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/auth/data/models/auth_models.dart';

void main() {
  test('parses the backend login token response', () {
    final session = AuthSession.fromResponse({
      'success': true,
      'message': 'Login successful.',
      'data': {
        'userId': 'd7d1a6de-14a5-4d15-a8b1-33d8d4ccaa11',
        'userName': 'sample_user',
        'role': 'User',
        'accessToken': 'access-token',
        'expiresAtUtc': '2026-11-13T12:30:00Z',
        'refreshToken': 'refresh-token',
        'refreshTokenExpiresAtUtc': '2026-11-20T12:00:00Z',
      },
    });
    expect(session.userName, 'sample_user');
    expect(session.role, 'User');
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
  });

  test('parses registration request identifier', () {
    final result = RegistrationResult.fromJson({
      'success': true,
      'message': 'OTP queued.',
      'data': {'registrationId': '9e3b1ef3-35f8-43fb-87b8-9a6b23aef101'},
    });
    expect(result.registrationId, '9e3b1ef3-35f8-43fb-87b8-9a6b23aef101');
  });

  test('parses password reset request identifier', () {
    final result = ResetRequestResult.fromJson({
      'success': true,
      'message': 'OTP sent if account exists.',
      'data': {'resetRequestId': 'a5f45f21-9f6a-4a82-8a61-4eaaea3d8b65'},
    });
    expect(result.resetRequestId, 'a5f45f21-9f6a-4a82-8a61-4eaaea3d8b65');
  });
}
