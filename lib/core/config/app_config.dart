class AppConfig {
  AppConfig._();

  /// Pass the backend API root at build time, including the /api suffix.
  /// Example: --dart-define=API_BASE_URL=https://api.example.com/api
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri endpoint(String path) {
    if (apiBaseUrl.trim().isEmpty) {
      throw const ApiConfigurationException(
        'The API address is not configured. Build with --dart-define=API_BASE_URL=https://your-host/api.',
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
