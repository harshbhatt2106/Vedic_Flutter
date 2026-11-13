import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/session_store.dart';
import '../../features/auth/data/models/auth_models.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final SessionStore _sessionStore = SessionStore.instance;
  static const _timeout = Duration(seconds: 25);
  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) =>
      _request('GET', path, authenticated: authenticated);
  Future<Map<String, dynamic>> post(String path, {required Map<String, dynamic> body, bool authenticated = false}) =>
      _request('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> _request(String method, String path, {
    Map<String, dynamic>? body, required bool authenticated, bool retryAfterRefresh = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json', if (body != null) 'Content-Type': 'application/json'};
    final token = _sessionStore.current?.accessToken;
    if (authenticated && token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    try {
      final request = http.Request(method, AppConfig.endpoint(path))..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await _client.send(request).then(http.Response.fromStream).timeout(_timeout);
      if (response.statusCode == 401 && authenticated && retryAfterRefresh && !path.startsWith('/auth/')) {
        if (await _refreshSession()) return _request(method, path, body: body, authenticated: true, retryAfterRefresh: false);
        await _sessionStore.clear();
        throw const ApiException(message: 'Your session has expired. Please sign in again.', statusCode: 401);
      }
      final dynamic decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw ApiException(message: 'The server returned an unexpected response.', statusCode: response.statusCode);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['message']?.toString().trim();
        throw ApiException(message: message?.isNotEmpty == true ? message! : _fallbackMessage(response.statusCode),
          statusCode: response.statusCode, validationErrors: _readValidationErrors(decoded['errors']));
      }
      return decoded;
    } on ApiException { rethrow; }
    on ApiConfigurationException catch (e) { throw ApiException(message: e.message); }
    on TimeoutException { throw const ApiException(message: 'The request timed out. Check your connection and try again.'); }
    on FormatException { throw const ApiException(message: 'The server returned an unreadable response.'); }
    catch (_) { throw const ApiException(message: 'Unable to connect to VedicVivah. Check your internet connection and API address.'); }
  }

  Future<bool> _refreshSession() {
    final active = _refreshInFlight;
    if (active != null) return active;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }
  Future<bool> _performRefresh() async {
    final session = _sessionStore.current;
    if (session == null || !session.refreshTokenExpiresAtUtc.isAfter(DateTime.now().toUtc())) return false;
    try {
      final response = await _client.post(AppConfig.endpoint('/auth/refresh'),
        headers: const {'Accept':'application/json','Content-Type':'application/json'},
        body: jsonEncode({'refreshToken':session.refreshToken})).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final payload = jsonDecode(response.body);
      if (payload is! Map<String,dynamic> || payload['success'] != true) return false;
      await _sessionStore.update(AuthSession.fromResponse(payload));
      return true;
    } catch (_) { return false; }
  }
  Map<String,List<String>> _readValidationErrors(dynamic raw) {
    if (raw is! Map) return const {};
    final result=<String,List<String>>{};
    for (final e in raw.entries) {
      if (e.value is List) { result[e.key.toString()] = (e.value as List).map((v)=>v.toString()).toList(); }
      else if (e.value != null) { result[e.key.toString()] = [e.value.toString()]; }
    }
    return result;
  }
  String _fallbackMessage(int status) {
    if(status==401) return 'Invalid credentials or an expired session.';
    if(status==409) return 'This request conflicts with existing account data. Please review and try again.';
    if(status==429) return 'Too many attempts. Please wait and try again.';
    if(status>=500) return 'Something went wrong on the server. Please try again.';
    return 'Request failed ($status). Please try again.';
  }
  void close() => _client.close();
}