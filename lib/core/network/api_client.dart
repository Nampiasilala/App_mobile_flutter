import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_url.dart'; // => contient API_BASE_URL
import '../auth/token_storage.dart';

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  // -------- Helpers
  Uri _u(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) return Uri.parse(pathOrUrl);
    // accepte "/dimensionnements/" ou "dimensionnements/"
    final p = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return Uri.parse('$API_BASE_URL/api$p');
  }

  Map<String, String> _baseHeaders({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  Future<http.Response> _do(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    switch (method) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: body);
      case 'PATCH':
        return http.patch(url, headers: headers, body: body);
      case 'DELETE':
        return http.delete(url, headers: headers);
      default:
        throw UnsupportedError('HTTP $method non supporté');
    }
  }

  // -------- Refresh
  bool _isRefreshing = false;

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // petit “wait” simple si plusieurs requêtes tombent en 401 en même temps
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      return (await TokenStorage.instance.readAccess()) != null;
    }

    _isRefreshing = true;
    try {
      final refresh = await TokenStorage.instance.readRefresh();
      if (refresh == null || refresh.isEmpty) return false;

      final url = Uri.parse('$API_BASE_URL/api/token/refresh/');
      final res = await http.post(
        url,
        headers: _baseHeaders(),
        body: jsonEncode({'refresh': refresh}),
      );

      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = data['access'] as String?;
      if (access == null || access.isEmpty) return false;

      await TokenStorage.instance.save(access: access);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // -------- Requête protégée avec retry si 401
  Future<http.Response> request(
    String method,
    String pathOrUrl, {
    Map<String, String>? headers,
    Object? body,
    bool requiresAuth = true,
  }) async {
    final url = _u(pathOrUrl);
    final h = {..._baseHeaders(), ...?headers};

    if (requiresAuth) {
      final access = await TokenStorage.instance.readAccess();
      if (access != null && access.isNotEmpty) {
        h['Authorization'] = 'Bearer $access';
      }
    }

    http.Response res = await _do(method, url, headers: h, body: body);

    if (requiresAuth && res.statusCode == 401) {
      final ok = await _refreshToken();
      if (!ok) return res;

      final access = await TokenStorage.instance.readAccess();
      final retryHeaders = {..._baseHeaders(), ...?headers};
      if (access != null && access.isNotEmpty) {
        retryHeaders['Authorization'] = 'Bearer $access';
      }
      res = await _do(method, url, headers: retryHeaders, body: body);
    }
    return res;
  }

  // -------- Helpers JSON
  Future<List<dynamic>> getJsonList(String path, {bool requiresAuth = true}) async {
    final r = await request('GET', path, requiresAuth: requiresAuth);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} ${r.reasonPhrase}');
    }
    final body = r.body.isEmpty ? '[]' : r.body;
    final json = jsonDecode(body);
    if (json is List) return json;
    throw Exception('Réponse inattendue (attendu: liste)');
  }

  Future<Map<String, dynamic>> getJson(String path, {bool requiresAuth = true}) async {
    final r = await request('GET', path, requiresAuth: requiresAuth);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} ${r.reasonPhrase}');
    }
    final body = r.body.isEmpty ? '{}' : r.body;
    final json = jsonDecode(body);
    if (json is Map<String, dynamic>) return json;
    throw Exception('Réponse inattendue (attendu: objet)');
  }

  Future<void> delete(String path, {bool requiresAuth = true}) async {
    final r = await request('DELETE', path, requiresAuth: requiresAuth);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode} ${r.reasonPhrase}');
    }
  }
}
