import '../../../../core/api/api_client.dart';
import '../models/auth_models.dart';

class AuthApiService {
  AuthApiService(this._api);
  final ApiClient _api;

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final payload = await _api.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    final result = AuthResult.fromJson(payload);
    if (!result.success || result.session == null) {
      throw FormatException(
        result.message.isEmpty ? 'Unable to sign in.' : result.message,
      );
    }
    return result.session!;
  }

  Future<RegistrationResult> register({
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final payload = await _api.post(
      '/auth/register',
      body: {
        'userName': userName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Registration failed.');
    }
    return RegistrationResult.fromJson(payload);
  }

  Future<String> verifyEmail({
    required String registrationId,
    required String otp,
  }) async {
    final payload = await _api.post(
      '/auth/verify-email',
      body: {'registrationId': registrationId, 'otp': otp},
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'OTP verification failed.');
    }
    return payload['data'] is Map
        ? (payload['data']['userId']?.toString() ?? '')
        : '';
  }

  Future<String> resendEmailOtp(String registrationId) async {
    final payload = await _api.post(
      '/auth/resend-email-otp',
      body: {'registrationId': registrationId},
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Unable to resend OTP.');
    }
    return payload['message']?.toString() ?? 'A new OTP has been requested.';
  }

  Future<ResetRequestResult> forgotPassword(String email) async {
    final payload = await _api.post('/auth/forgot-password', body: {'email': email});
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Unable to start password reset.');
    }
    return ResetRequestResult.fromJson(payload);
  }

  Future<void> verifyPasswordResetOtp({
    required String resetRequestId,
    required String otp,
  }) async {
    final payload = await _api.post(
      '/auth/verify-password-reset-otp',
      body: {'resetRequestId': resetRequestId, 'otp': otp},
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Invalid or expired OTP.');
    }
  }

  Future<String> resendPasswordResetOtp(String resetRequestId) async {
    final payload = await _api.post(
      '/auth/resend-password-reset-otp',
      body: {'resetRequestId': resetRequestId},
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Unable to resend OTP.');
    }
    return payload['message']?.toString() ?? 'A new OTP has been requested.';
  }

  Future<void> resetPassword({
    required String resetRequestId,
    required String newPassword,
  }) async {
    final payload = await _api.post(
      '/auth/reset-password',
      body: {'resetRequestId': resetRequestId, 'newPassword': newPassword},
    );
    if (payload['success'] != true) {
      throw FormatException(payload['message']?.toString() ?? 'Unable to reset password.');
    }
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final payload = await _api.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    final result = AuthResult.fromJson(payload);
    if (!result.success || result.session == null) {
      throw FormatException(result.message.isEmpty ? 'Session refresh failed.' : result.message);
    }
    return result.session!;
  }

  Future<void> logout(String refreshToken) async {
    await _api.post('/auth/logout', body: {'refreshToken': refreshToken});
  }
}
