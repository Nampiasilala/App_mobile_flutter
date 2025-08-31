// lib/features/calculator/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../constants/api_url.dart';
import 'data/calculator_service.dart';
import 'data/help_service.dart';
import 'data/geo_service.dart'; // ✅ contient GeoService + NasaPowerService
import 'domain/calculator_models.dart';

// Client HTTP partagé
final _httpClientProvider = Provider.autoDispose<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final calculatorServiceProvider = Provider<CalculatorService>((ref) {
  final client = ref.watch(_httpClientProvider);
  return CalculatorService(API_BASE_URL, client);
});

final helpServiceProvider = Provider((_) => HelpService());
final geoServiceProvider = Provider((_) => GeoService());
final nasaServiceProvider = Provider((_) => NasaPowerService());

final helpMapProvider =
    FutureProvider.family<Map<String, HelpItem>, List<String>>((ref, keys) async {
  final s = ref.read(helpServiceProvider);
  return s.fetchHelpByKeys(keys);
});

final lastResultProvider = StateProvider<CalculationResult?>((_) => null);
