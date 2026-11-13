import '../../../../core/errors/api_exception.dart';
import '../../../../core/storage/session_store.dart';
import '../models/auth_models.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  AuthRepository(this._api, this._sessions);
  final AuthApiService _api;
  final SessionStore _sessions;

  Future<AuthSession> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final session = await _api.login(identifier: identifier, password: password);
    _validateRole(session.role);
    await _sessions.save(session, rememberMe: rememberMe);
    return session;
  }

  Future<void> register({
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    await _api.register(
      userName: userName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  Future<RegistrationResult> beginRegistration({
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
  }) =>
      _api.register(
        userName: userName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );

  Future<String> verifyEmail({
    required String registrationId,
    required String otp,
  }) =>
      _api.verifyEmail(registrationId: registrationId, otp: otp);

  Future<String> resendEmailOtp(String registrationId) =>
      _api.resendEmailOtp(registrationId);

  Future<ResetRequestResult> forgotPassword(String email) =>
      _api.forgotPassword(email);

  Future<void> verifyPasswordResetOtp({
    required String resetRequestId,
    required String otp,
  }) =>
      _api.verifyPasswordResetOtp(resetRequestId: resetRequestId, otp: otp);

  Future<String> resendPasswordResetOtp(String resetRequestId) =>
      _api.resendPasswordResetOtp(resetRequestId);

  Future<void> resetPassword({
    required String resetRequestId,
    required String newPassword,
  }) =>
      _api.resetPassword(resetRequestId: resetRequestId, newPassword: newPassword);

  Future<AuthSession?> restoreSession() async {
    final session = await _sessions.readPersistent();
    if (session == null) return null;

    try {
      if (session.expiresAtUtc.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 30)))) {
        _validateRole(session.role);
        return session;
      }
      if (session.refreshTokenExpiresAtUtc.isBefore(DateTime.now().toUtc())) {
        await _sessions.clear();
        return null;
      }
      final refreshed = await _api.refresh(session.refreshToken);
      _validateRole(refreshed.role);
      await _sessions.update(refreshed);
      return refreshed;
    } on ApiException catch (error) {
      if (error.statusCode == 0) {
        // Preserve a persistent session during temporary connectivity loss.
        return session;
      }
      await _sessions.clear();
      return null;
    } catch (_) {
      await _sessions.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final session = _sessions.current;
    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } catch (_) {
        // Local credentials must be removed even if the server cannot be reached.
      }
    }
    await _sessions.clear();
  }

  void _validateRole(String role) {
    if (!const {'Admin', 'User', 'Mentor'}.contains(role)) {
      throw const ApiException(
        message: 'Your account role is not configured correctly.',
      );
    }
  }
}
