import 'package:dio/dio.dart';
import '../env/env.dart';
import '../storage/secure_storage.dart';

class DioClient {
  DioClient._() {
    dio = Dio(BaseOptions(
      baseUrl: Env.apiBase,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // <-- important pour ngrok
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Toujours injecter l’entête ngrok (au cas où BaseOptions ait été copiée)
        options.headers['ngrok-skip-browser-warning'] = 'true';

        final requiresAuth = options.extra['requiresAuth'] == true;
        if (requiresAuth) {
          final token = await SecureAuthStorage.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final req = e.requestOptions;
        final requiresAuth = req.extra['requiresAuth'] == true;
        final alreadyRetried = req.extra['__ret'] == true;

        if (e.response?.statusCode == 401 && requiresAuth && !alreadyRetried) {
          try {
            final newAccess = await _refreshAccessToken();
            final opts = Options(
              method: req.method,
              headers: {
                ...req.headers,
                'Authorization': 'Bearer $newAccess',
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
              responseType: req.responseType,
              followRedirects: req.followRedirects,
              receiveDataWhenStatusError: req.receiveDataWhenStatusError,
              extra: {...req.extra, '__ret': true},
            );
            final clone = await dio.request<dynamic>(
              req.path,
              data: req.data,
              queryParameters: req.queryParameters,
              options: opts,
            );
            return handler.resolve(clone);
          } catch (_) {
            await SecureAuthStorage.instance.clearTokens();
            return handler.reject(e);
          }
        }
        handler.next(e);
      },
    ));
  }

  late final Dio dio;
  static final DioClient instance = DioClient._();

  Future<String> _refreshAccessToken() async {
    final refresh = await SecureAuthStorage.instance.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '${Env.apiBase}/token/refresh/'),
        error: 'No refresh token',
      );
    }

    final res = await dio.post(
      '/token/refresh/',
      data: {'refresh': refresh},
      options: Options(extra: {'requiresAuth': false}),
    );
    final access = (res.data['access'] as String?) ?? '';
    if (access.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '${Env.apiBase}/token/refresh/'),
        error: 'Refresh failed',
      );
    }
    await SecureAuthStorage.instance.setAccessToken(access);
    return access;
  }
}
