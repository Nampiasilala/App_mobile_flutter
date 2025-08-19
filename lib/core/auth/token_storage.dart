import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final instance = TokenStorage._();

  final _s = const FlutterSecureStorage();

  Future<String?> readAccess()  => _s.read(key: 'accessToken');
  Future<String?> readRefresh() => _s.read(key: 'refreshToken');

  Future<void> save({String? access, String? refresh}) async {
    if (access != null)  await _s.write(key: 'accessToken',  value: access);
    if (refresh != null) await _s.write(key: 'refreshToken', value: refresh);
  }

  Future<void> clear() async {
    await _s.delete(key: 'accessToken');
    await _s.delete(key: 'refreshToken');
  }
}
