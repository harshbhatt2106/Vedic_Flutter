class AuthValidation {
  AuthValidation._();

  static String? loginIdentifier(String value) =>
      value.trim().isEmpty ? 'Enter your email or mobile number.' : null;

  static String? loginPassword(String value) =>
      value.isEmpty ? 'Enter your password.' : null;

  static String? userName(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(normalized)) {
      return 'Username must be 3–30 characters using letters, numbers, dots, or underscores.';
    }
    return null;
  }

  static String? email(String value) {
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? mobile(String value) =>
      RegExp(r'^\d{10}$').hasMatch(value)
          ? null
          : 'Enter a valid 10-digit mobile number.';

  static String? password(String value) =>
      value.length < 8 ? 'Password must be at least 8 characters.' : null;

  static String? otp(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value) ? null : 'Enter the complete 6-digit OTP.';

  static String? confirmPassword(String value, String password) =>
      value != password ? 'Passwords do not match.' : null;
}
