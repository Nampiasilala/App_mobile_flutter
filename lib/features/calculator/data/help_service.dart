// lib/features/calculator/data/help_service.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/calculator_models.dart'; // contient HelpItem (+ fromJson)

class HelpService {
  final Dio _dio = DioClient.instance.dio; // baseUrl doit inclure /api

  /// GET api/contenus/public/help-by-key/?keys=k1,k2
  Future<Map<String, HelpItem>> fetchHelpByKeys(List<String> keys) async {
    final qs = keys.join(',');
    final res = await _dio.get(
      // ⚠️ PAS de slash initial, sinon /api est écrasé
      'contenus/public/help-by-key/',
      queryParameters: {'keys': qs},
      options: Options(extra: {'requiresAuth': false}),
    );

    final data = res.data;
    final out = <String, HelpItem>{};

    if (data is List) {
      for (final item in data) {
        final key = item['key'];
        if (key != null) {
          out['$key'] = HelpItem.fromJson(Map<String, dynamic>.from(item));
        }
      }
    } else if (data is Map) {
      data.forEach((k, v) {
        if (v is Map) {
          out['$k'] = HelpItem.fromJson(Map<String, dynamic>.from(v));
        } else {
          out['$k'] = HelpItem(title: '', bodyHtml: '');
        }
      });
    }

    return out;
  }
}
