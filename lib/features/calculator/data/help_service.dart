import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/calculator_models.dart';

class HelpService {
  final Dio _dio = DioClient.instance.dio;

  /// GET /contenus/public/help-by-key/?keys=k1,k2
  Future<Map<String, HelpItem>> fetchHelpByKeys(List<String> keys) async {
    final qs = keys.join(',');
    final res = await _dio.get(
      '/contenus/public/help-by-key/',
      queryParameters: {'keys': qs},
      options: Options(extra: {'requiresAuth': false}),
    );
    final data = res.data;

    final out = <String, HelpItem>{};
    if (data is List) {
      for (final item in data) {
        final k = item['key'];
        if (k != null) {
          out[k] = HelpItem(
            title: item['title'] ?? '',
            bodyHtml: item['body_html'] ?? item['bodyHtml'] ?? item['body'] ?? '',
          );
        }
      }
    } else if (data is Map) {
      data.forEach((k, v) {
        out['$k'] = HelpItem(
          title: v['title'] ?? '',
          bodyHtml: v['body_html'] ?? v['bodyHtml'] ?? v['body'] ?? '',
        );
      });
    }
    return out;
  }
}
