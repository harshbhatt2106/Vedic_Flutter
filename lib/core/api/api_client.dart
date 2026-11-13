import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/session_store.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final SessionStore _sessionStore = SessionStore.instance;
  static const _timeout = Duration(seconds: 25);

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = _sessionStore.current?.accessToken;
    if (authenticated && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client
          .post(
            AppConfig.endpoint(path),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          message: 'The server returned an unexpected response.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['message']?.toString().trim();
        throw ApiException(
          message: (message == null || message.isEmpty)
              ? _fallbackMessage(response.statusCode)
              : message,
          statusCode: response.statusCode,
          validationErrors: _readValidationErrors(decoded['errors']),
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on ApiConfigurationException catch (error) {
      throw ApiException(message: error.message);
    } on TimeoutException {
      throw const ApiException(
        message: 'The request timed out. Check your connection and try again.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'The server returned an unreadable response.',
      );
    } catch (_) {
      throw const ApiException(
        message: 'Unable to connect to VedicVivah. Check your internet connection and API address.',
      );
    }
  }

  Map<String, List<String>> _readValidationErrors(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List) {
        result[entry.key.toString()] =
            value.map((item) => item.toString()).toList(growable: false);
      } else if (value != null) {
        result[entry.key.toString()] = [value.toString()];
      }
    }
    return result;
  }

  String _fallbackMessage(int status) {
    if (status == 401) return 'Invalid credentials or an expired session.';
    if (status == 409) return 'This request conflicts with existing account data. Please review and try again.';
    if (status == 429) return 'Too many attempts. Please wait and try again.';
    if (status >= 500) return 'Something went wrong on the server. Please try again.';
    return 'Request failed ($status). Please try again.';
  }

  void close() => _client.close();
}
