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
}

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

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is String) {
      try {
        return DateTime.parse(v).toLocal();
      } catch (_) {}
    }
    return null;
  }
}
