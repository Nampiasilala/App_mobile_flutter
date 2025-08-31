import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AdminUsersService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<AdminUser>> fetchUsers() async {
    final res = await _dio.get(
      '/users/',
      options: Options(extra: {'requiresAuth': true}),
    );
    final data = res.data;
    if (data is List) {
      return data.map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return <AdminUser>[];
  }

  Future<void> deleteUser(int id) async {
    await _dio.delete(
      '/users/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  /// 🔎 Détails utilisateur (miroir du modal web)
  /// GET /users/{id}/
  Future<UserDetails> fetchUserDetails(int id) async {
    final res = await _dio.get(
      '/users/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );

    final d = Map<String, dynamic>.from(res.data as Map);

    String _roleFrom(Map<String, dynamic> m) {
      final raw = m['role']?.toString();
      final isSuper = m['is_superuser'] == true;
      final isStaff = m['is_staff'] == true;
      // Même logique que le web : si pas de role, Admin si superuser/staff, sinon Entreprise
      return raw ?? ((isSuper || isStaff) ? 'Admin' : 'Entreprise');
    }

    DateTime? _parseDate(Object? v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return UserDetails(
      id: _asInt(d['id']),
      username: (d['username'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      role: _roleFrom(d),
      dateJoined: _parseDate(d['date_joined']),
      lastLogin: _parseDate(d['last_login']),
      phone: d['phone']?.toString(),
      address: d['address']?.toString(),
      website: d['website']?.toString(),
      description: d['description']?.toString(),
      isStaff: d['is_staff'] == true,
      isSuperuser: d['is_superuser'] == true,
    );
  }
}

/* ------------------------------- Modèles ------------------------------- */

class AdminUser {
  final int id;
  final String username;
  final String email;
  final String role;       // "Admin" | "Modérateur" | "Utilisateur" | "Invité" | autre
  final DateTime joinDate;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.joinDate,
  });

  factory AdminUser.fromJson(Map<String, dynamic> m) {
    final isSuper = m['is_superuser'] == true;
    final isStaff = m['is_staff'] == true;
    final rawRole = m['role']?.toString();
    final role = rawRole ??
        (isSuper
            ? 'Admin'
            : isStaff
                ? 'Modérateur'
                : 'Utilisateur');

    final joined = _parseDate(m['date_joined'] ?? m['created_at']) ?? DateTime.now();

    return AdminUser(
      id: _asInt(m['id']),
      username: (m['username'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      role: role,
      joinDate: joined,
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class UserDetails {
  final int id;
  final String username;
  final String email;
  final String role; // 'Admin' | 'Entreprise' | autre
  final DateTime? dateJoined;
  final DateTime? lastLogin;
  final String? phone;
  final String? address;
  final String? website;
  final String? description;
  final bool? isStaff;
  final bool? isSuperuser;

  UserDetails({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.dateJoined,
    this.lastLogin,
    this.phone,
    this.address,
    this.website,
    this.description,
    this.isStaff,
    this.isSuperuser,
  });
}

/* ------------------------------- Helpers ------------------------------- */

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return null;
  }
}
