import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class AuthApi {
  final Dio _dio = DioClient.instance.dio;

  /// Backend EmailBackend: attend { "email", "password" }
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    final res = await _dio.post(
      '/token/',
      data: {'email': email, 'password': password},
      options: Options(extra: {'requiresAuth': false}),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
