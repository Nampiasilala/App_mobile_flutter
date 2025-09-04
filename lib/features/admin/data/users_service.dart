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
      return data
          .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <AdminUser>[];
  }

  Future<void> deleteUser(int id) async {
    await _dio.delete(
      '/users/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  /// GET /users/{id}/ (détails)
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
      // même logique que web : flags > role texte
      if (isSuper || isStaff) return 'Admin';
      return (raw?.isNotEmpty == true) ? raw! : 'Entreprise';
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
      isActive: d['is_active'] == true,
    );
  }

  /// PATCH /users/{id}/toggle-active/  { "is_active": true|false }
  Future<bool> setActive(int id, bool value) async {
    final res = await _dio.patch(
      '/users/$id/toggle-active/',
      data: {'is_active': value},
      options: Options(extra: {'requiresAuth': true}),
    );
    final m = Map<String, dynamic>.from(res.data as Map);
    return m['is_active'] == true;
  }
}

/* ------------------------------- Modèles ------------------------------- */

class AdminUser {
  final int id;
  final String username;
  final String email;
  final String role;       // "Admin" | "Entreprise" | autre
  final DateTime joinDate;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.isActive,
  });

  factory AdminUser.fromJson(Map<String, dynamic> m) {
    final isSuper = m['is_superuser'] == true;
    final isStaff = m['is_staff'] == true;
    final rawRole = m['role']?.toString();
    final role = (isSuper || isStaff)
        ? 'Admin'
        : (rawRole?.isNotEmpty == true ? rawRole! : 'Entreprise');

    final joined =
        _parseDate(m['date_joined'] ?? m['created_at']) ?? DateTime.now();

    return AdminUser(
      id: _asInt(m['id']),
      username: (m['username'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      role: role,
      joinDate: joined,
      isActive: m['is_active'] == true,
    );
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
  final bool? isActive;

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
    this.isActive,
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
