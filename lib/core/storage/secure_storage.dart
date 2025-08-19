import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAuthStorage {
  SecureAuthStorage._();
  static final SecureAuthStorage instance = SecureAuthStorage._();

  final _s = const FlutterSecureStorage();

  // Clés “double nom” pour compat
  static const _kAccess = ['adminAccessToken', 'accessToken'];
  static const _kRefresh = ['adminRefreshToken', 'refreshToken'];

  Future<String?> getAccessToken() async {
    for (final k in _kAccess) {
      final v = await _s.read(key: k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Future<String?> getRefreshToken() async {
    for (final k in _kRefresh) {
      final v = await _s.read(key: k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Future<void> setAccessToken(String token) async {
    for (final k in _kAccess) {
      await _s.write(key: k, value: token);
    }
  }

  Future<void> setRefreshToken(String token) async {
    for (final k in _kRefresh) {
      await _s.write(key: k, value: token);
    }
  }

  Future<void> clearTokens() async {
    for (final k in [..._kAccess, ..._kRefresh]) {
      await _s.delete(key: k);
    }
  }
}
