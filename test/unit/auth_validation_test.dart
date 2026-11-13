import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/auth/domain/auth_validation.dart';

void main() {
  group('AuthValidation', () {
    test('validates username using web registration rules', () {
      expect(AuthValidation.userName('harsh_2106'), isNull);
      expect(AuthValidation.userName('ab'), isNotNull);
      expect(AuthValidation.userName('bad name'), isNotNull);
    });
    test('validates email', () {
      expect(AuthValidation.email('person@example.com'), isNull);
      expect(AuthValidation.email('not-an-email'), isNotNull);
    });
    test('uses the web ten-digit mobile rule', () {
      expect(AuthValidation.mobile('9876543210'), isNull);
      expect(AuthValidation.mobile('98765'), isNotNull);
    });
    test('requires eight password characters', () {
      expect(AuthValidation.password('12345678'), isNull);
      expect(AuthValidation.password('1234567'), isNotNull);
    });
    test('requires exactly six numeric OTP digits', () {
      expect(AuthValidation.otp('123456'), isNull);
      expect(AuthValidation.otp('12345'), isNotNull);
      expect(AuthValidation.otp('12a456'), isNotNull);
    });
    test('checks confirm-password equality in recovery flow', () {
      expect(AuthValidation.confirmPassword('samepass', 'samepass'), isNull);
      expect(AuthValidation.confirmPassword('different', 'samepass'), isNotNull);
    });
  });
}
