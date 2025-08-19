import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/calculator_models.dart';

class CalculatorService {
  final Dio _dio = DioClient.instance.dio;

  // ---------- API publique ----------
  Future<CalculationResult> publicCalculate(CalculationInput input) async {
    final res = await _dio.post(
      '/dimensionnements/calculate/',
      data: input.toJson(),
      options: Options(extra: {'requiresAuth': false}),
    );
    return CalculationResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ---------- API protégée ----------
  Future<List<CalculationResult>> getAll() async {
    final res = await _dio.get(
      '/dimensionnements/',
      options: Options(extra: {'requiresAuth': true}),
    );
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(CalculationResult.fromJson).toList();
  }

  Future<CalculationResult> getById(int id) async {
    final res = await _dio.get(
      '/dimensionnements/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
    return CalculationResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteById(int id) async {
    await _dio.delete(
      '/dimensionnements/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
  }

  Future<CalculationResult> calculateProtected(CalculationInput input) async {
    final res = await _dio.post(
      '/dimensionnements/calculate/',
      data: input.toJson(),
      options: Options(extra: {'requiresAuth': true}),
    );
    return CalculationResult.fromJson(res.data as Map<String, dynamic>);
  }
}
