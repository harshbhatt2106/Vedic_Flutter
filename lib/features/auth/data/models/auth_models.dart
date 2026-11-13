import 'dart:convert';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.userName,
    required this.role,
    required this.accessToken,
    required this.expiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
  });

  final String userId;
  final String userName;
  final String role;
  final String accessToken;
  final DateTime expiresAtUtc;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        userId: json['userId'].toString(),
        userName: json['userName'].toString(),
        role: json['role'].toString(),
        accessToken: json['accessToken'].toString(),
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'].toString()).toUtc(),
        refreshToken: json['refreshToken'].toString(),
        refreshTokenExpiresAtUtc:
            DateTime.parse(json['refreshTokenExpiresAtUtc'].toString()).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'role': role,
        'accessToken': accessToken,
        'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
        'refreshToken': refreshToken,
        'refreshTokenExpiresAtUtc':
            refreshTokenExpiresAtUtc.toUtc().toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());
  factory AuthSession.fromJsonString(String value) =>
      AuthSession.fromJson(jsonDecode(value) as Map<String, dynamic>);

  factory AuthSession.fromResponse(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Authentication response has no data object.');
    }
    return AuthSession.fromJson(data);
  }
}

class AuthResult {
  const AuthResult({required this.success, required this.message, this.session});
  final bool success;
  final String message;
  final AuthSession? session;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        success: json['success'] == true,
        message: json['message']?.toString() ?? '',
        session: json['data'] is Map<String, dynamic>
            ? AuthSession.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

class RegistrationResult {
  const RegistrationResult({required this.registrationId, required this.message});
  final String registrationId;
  final String message;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic> || data['registrationId'] == null) {
      throw const FormatException('Registration response is missing registrationId.');
    }
    return RegistrationResult(
      registrationId: data['registrationId'].toString(),
      message: json['message']?.toString() ?? 'Verification code request accepted.',
    );
  }
}

class ResetRequestResult {
  const ResetRequestResult({required this.resetRequestId, required this.message});
  final String resetRequestId;
  final String message;

  factory ResetRequestResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic> || data['resetRequestId'] == null) {
      throw const FormatException('Password reset response is missing resetRequestId.');
    }
    return ResetRequestResult(
      resetRequestId: data['resetRequestId'].toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}
