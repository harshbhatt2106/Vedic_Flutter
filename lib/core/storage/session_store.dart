import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/auth_models.dart';

class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionKey = 'vedicvivah.auth.session.v1';

  AuthSession? _memorySession;

  AuthSession? get current => _memorySession;

  Future<void> save(AuthSession session, {required bool rememberMe}) async {
    _memorySession = session;
    if (rememberMe) {
      await _storage.write(key: _sessionKey, value: session.toJsonString());
    } else {
      await _storage.delete(key: _sessionKey);
    }
  }

  Future<AuthSession?> readPersistent() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = AuthSession.fromJsonString(raw);
      _memorySession = session;
      return session;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> update(AuthSession session) async {
    _memorySession = session;
    final persisted = await _storage.read(key: _sessionKey);
    if (persisted != null) {
      await _storage.write(key: _sessionKey, value: session.toJsonString());
    }
  }

  Future<void> clear() async {
    _memorySession = null;
    await _storage.delete(key: _sessionKey);
  }
}
