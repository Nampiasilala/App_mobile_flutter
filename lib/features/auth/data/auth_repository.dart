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

  bool _isEntreprise = false;
  bool get isEntreprise => _isEntreprise;

  Stream<void> get changes => _controller.stream;

  Future<bool> login(String email, String password) async {
    try {
      // 1) Login email/password
      final data = await _api.loginWithEmail(email, password);

      print('DEBUG - Réponse login complète: $data');

      // 2) Récupère les tokens
      final access = _extractAccess(data);
      final refresh = _extractRefresh(data);
      if (access == null || access.isEmpty) {
        throw Exception('Token d\'accès manquant');
      }

      print('DEBUG - Token access: $access');

      // 3) Stocke les tokens
      await _storage.setAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await _storage.setRefreshToken(refresh);
      }

      // 4) NOUVEAU - Récupère le profil utilisateur via API
      try {
        final userProfile = await _getUserProfile();
        print('DEBUG - Profil utilisateur: $userProfile');

        _isAdmin = _extractIsAdminFromProfile(userProfile);
        _isEntreprise = _extractIsEntrepriseFromProfile(userProfile);

        print(
          'DEBUG - Rôles depuis profil - isAdmin: $_isAdmin, isEntreprise: $_isEntreprise',
        );
      } catch (profileError) {
        print('DEBUG - Erreur récupération profil: $profileError');

        // Fallback: essaie avec le JWT (même si on sait qu'il n'y a pas de rôle)
        _isAdmin = _extractIsAdminFromJwt(access);
        _isEntreprise = _extractIsEntrepriseFromJwt(access);
        print(
          'DEBUG - Fallback JWT - isAdmin: $_isAdmin, isEntreprise: $_isEntreprise',
        );
      }

      // 5) Si toujours pas admin, teste via probe API
      if (!_isAdmin) {
        _isAdmin = await _probeAdminViaApi();
        print('DEBUG - isAdmin après probe: $_isAdmin');
      }

      _controller.add(null);
      return true;
    } on DioException catch (e) {
      print('DEBUG - Erreur DioException: ${e.response?.data}');
      await _storage.clearTokens();
      _isAdmin = false;
      _isEntreprise = false;
      _controller.add(null);

      final msg =
          e.response?.data is Map && (e.response!.data['detail'] != null)
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Erreur réseau');
      throw Exception(msg);
    } catch (e) {
      print('DEBUG - Erreur générale: $e');
      await _storage.clearTokens();
      _isAdmin = false;
      _isEntreprise = false;
      _controller.add(null);
      throw Exception(e.toString());
    }
  }

  // NOUVELLE méthode - Récupération du profil utilisateur
  Future<Map<String, dynamic>> _getUserProfile() async {
    print('DEBUG - Tentative récupération profil...');

    // Essaie différents endpoints possibles
    final endpoints = [
      '/auth/user/', // Endpoint le plus courant
      '/user/profile/', // Alternative
      '/users/me/', // Autre alternative
      '/me/', // Plus simple
      '/api/user/', // Avec préfixe api
    ];

    for (final endpoint in endpoints) {
      try {
        print('DEBUG - Essai endpoint: $endpoint');
        final response = await _dio.get(
          endpoint,
          options: Options(extra: {'requiresAuth': true}),
        );

        if (response.statusCode == 200) {
          print('DEBUG - Succès avec endpoint: $endpoint');
          return Map<String, dynamic>.from(response.data as Map);
        }
      } catch (e) {
        print('DEBUG - Échec endpoint $endpoint: ${e.toString()}');
        continue; // Essaie le suivant
      }
    }

    throw Exception('Aucun endpoint de profil utilisateur trouvé');
  }

  bool _extractIsAdminFromProfile(Map<String, dynamic> profile) {
    print('DEBUG - Recherche admin dans profil: $profile');

    // Teste différents champs possibles pour admin
    if (profile['is_staff'] == true) {
      print('DEBUG - Admin détecté via is_staff');
      return true;
    }
    if (profile['is_superuser'] == true) {
      print('DEBUG - Admin détecté via is_superuser');
      return true;
    }
    if (profile['is_admin'] == true) {
      print('DEBUG - Admin détecté via is_admin');
      return true;
    }

    final role = profile['role']?.toString().toLowerCase();
    if (role == 'admin' || role == 'staff') {
      print('DEBUG - Admin détecté via role: $role');
      return true;
    }

    final userType = profile['user_type']?.toString().toLowerCase();
    if (userType == 'admin') {
      print('DEBUG - Admin détecté via user_type: $userType');
      return true;
    }

    // Cherche dans un objet user nested
    final user = profile['user'];
    if (user is Map) {
      if (user['is_staff'] == true || user['is_admin'] == true) {
        print('DEBUG - Admin détecté via user nested');
        return true;
      }
      if (user['role']?.toString().toLowerCase() == 'admin') {
        print('DEBUG - Admin détecté via user.role');
        return true;
      }
    }

    return false;
  }

  bool _extractIsEntrepriseFromProfile(Map<String, dynamic> profile) {
    print('DEBUG - Recherche entreprise dans profil: $profile');

    // Teste différents champs possibles pour entreprise
    final role = profile['role']?.toString().toLowerCase();
    if (role == 'entreprise' || role == 'enterprise') {
      print('DEBUG - Entreprise détectée via role: $role');
      return true;
    }

    final userType = profile['user_type']?.toString().toLowerCase();
    if (userType == 'entreprise' || userType == 'enterprise') {
      print('DEBUG - Entreprise détectée via user_type: $userType');
      return true;
    }

    if (profile['is_enterprise'] == true) {
      print('DEBUG - Entreprise détectée via is_enterprise');
      return true;
    }

    if (profile['is_company'] == true) {
      print('DEBUG - Entreprise détectée via is_company');
      return true;
    }

    // Cherche dans un objet user nested
    final user = profile['user'];
    if (user is Map) {
      final nestedRole = user['role']?.toString().toLowerCase();
      if (nestedRole == 'entreprise' || nestedRole == 'enterprise') {
        print('DEBUG - Entreprise détectée via user.role: $nestedRole');
        return true;
      }
    }

    // Cherche dans les groupes
    final groups = profile['groups'];
    if (groups is List) {
      for (final group in groups) {
        final groupName = group.toString().toLowerCase();
        if (groupName.contains('entreprise') ||
            groupName.contains('enterprise')) {
          print('DEBUG - Entreprise détectée via groups: $groups');
          return true;
        }
      }
    }

    return false;
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    _isAdmin = false;
    _isEntreprise = false;
    _controller.add(null);
  }

  // ---------- helpers ----------
  String? _extractAccess(Map<String, dynamic> data) {
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
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;

      if (map['is_staff'] == true || map['is_superuser'] == true) return true;
      return map['role']?.toString().toLowerCase() == 'admin';
    } catch (_) {}
    return false;
  }

  bool _extractIsEntrepriseFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return false;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;

      final role = map['role']?.toString().toLowerCase();
      return role == 'entreprise' || role == 'enterprise';
    } catch (_) {}
    return false;
  }

  Future<bool> _probeAdminViaApi() async {
    try {
      final res = await _dio.get(
        '/dimensionnements/',
        options: Options(extra: {'requiresAuth': true}),
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      return code != 403;
    } catch (_) {
      return false;
    }
  }
}
