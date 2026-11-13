class AppConfig {
  AppConfig._();

  /// Production API root, matching the VedicVivah MAUI app.
  /// Can be overridden at build time with --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vedicvivah.co.in/api',
  );

  static Uri endpoint(String path) {
    if (apiBaseUrl.trim().isEmpty) {
      throw const ApiConfigurationException(
        'The API address is not configured. Build with --dart-define=API_BASE_URL=https://vedicvivah.co.in/api.',
      );
    }

    final base = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException(this.message);
  final String message;

  @override
  String toString() => message;
}
