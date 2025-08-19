import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_api.dart';

class AuthRepository {
  final _storage = SecureAuthStorage.instance;
  final _api = AuthApi();
  final _controller = StreamController<void>.broadcast();
  final Dio _dio = DioClient.instance.dio;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;
  Stream<void> get changes => _controller.stream;

  Future<bool> login(String email, String password) async {
    try {
      // 1) Login email/password (une seule requête)
      final data = await _api.loginWithEmail(email, password);

      // 2) Récupère les tokens quel que soit le format
      final access = _extractAccess(data);
      final refresh = _extractRefresh(data);
      if (access == null || access.isEmpty) {
        throw Exception('Token d’accès manquant');
      }

      // 3) Stocke
      await _storage.setAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await _storage.setRefreshToken(refresh);
      }

      // 4) Déduis isAdmin depuis le JWT si possible…
      _isAdmin = _extractIsAdminFromJwt(access);

      // …sinon, vérifie via une route protégée
      if (!_isAdmin) {
        _isAdmin = await _probeAdminViaApi();
      }

      _controller.add(null);
      return true;
    } on DioException catch (e) {
      // Nettoyage en cas d’échec
      await _storage.clearTokens();
      _isAdmin = false;
      _controller.add(null);

      // Propage un message propre pour la UI
      final msg = e.response?.data is Map && (e.response!.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Erreur réseau');
      throw Exception(msg);
    } catch (e) {
      await _storage.clearTokens();
      _isAdmin = false;
      _controller.add(null);
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    _isAdmin = false;
    _controller.add(null);
  }

  // ---------- helpers ----------

  String? _extractAccess(Map<String, dynamic> data) {
    // Formats fréquents
    if (data['access'] is String) return data['access'] as String;
    if (data['token'] is String) return data['token'] as String;
    final t = data['tokens'];
    if (t is Map && t['access'] is String) return t['access'] as String;
    return null;
  }

  String? _extractRefresh(Map<String, dynamic> data) {
    if (data['refresh'] is String) return data['refresh'] as String;
    final t = data['tokens'];
    if (t is Map && t['refresh'] is String) return t['refresh'] as String;
    return null;
  }

  bool _extractIsAdminFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = json.decode(payload) as Map<String, dynamic>;

      if (map['is_staff'] == true) return true;
      if (map['is_superuser'] == true) return true;

      final role = map['role']?.toString().toLowerCase();
      if (role == 'admin' || role == 'staff') return true;

      final scope = map['scope']?.toString().toLowerCase() ?? '';
      if (scope.contains('admin')) return true;

      final groups = map['groups'];
      if (groups is List && groups.map((e) => '$e'.toLowerCase())
          .any((g) => g.contains('admin') || g.contains('staff'))) return true;

      final roles = map['roles'];
      if (roles is List && roles.map((e) => '$e'.toLowerCase())
          .any((g) => g.contains('admin') || g.contains('staff'))) return true;
    } catch (_) {}
    return false;
  }

  /// Teste l’accès à une route admin-only.
  /// 200 => admin ; 403 => non-admin ; 401 => token invalide
  Future<bool> _probeAdminViaApi() async {
    try {
      final res = await _dio.get(
        '/dimensionnements/',
        options: Options(extra: {'requiresAuth': true}),
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 403) return false;
      return false; // 401 ou autre -> non admin (ou problème token)
    } catch (_) {
      return false;
    }
  }
}
