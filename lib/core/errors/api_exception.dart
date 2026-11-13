class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode = 0,
    this.validationErrors = const {},
  });

  final String message;
  final int statusCode;
  final Map<String, List<String>> validationErrors;

  @override
  String toString() => message;
}
