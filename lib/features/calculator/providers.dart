import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/calculator_service.dart';
import 'data/help_service.dart';
import 'data/geo_service.dart';
import 'domain/calculator_models.dart';

final calculatorServiceProvider = Provider((_) => CalculatorService());
final helpServiceProvider = Provider((_) => HelpService());
final geoServiceProvider = Provider((_) => GeoService());
final nasaServiceProvider = Provider((_) => NasaPowerService());

final helpMapProvider = FutureProvider.family<Map<String, HelpItem>, List<String>>((ref, keys) async {
  final s = ref.read(helpServiceProvider);
  return s.fetchHelpByKeys(keys);
});

final lastResultProvider = StateProvider<CalculationResult?>((_) => null);
