import 'package:dio/dio.dart';

class LocationSuggestion {
  final String displayName;
  final String lat;
  final String lon;
  LocationSuggestion({required this.displayName, required this.lat, required this.lon});

  factory LocationSuggestion.fromJson(Map<String, dynamic> j) => LocationSuggestion(
    displayName: j['display_name'] ?? '',
    lat: '${j['lat']}',
    lon: '${j['lon']}',
  );
}

class GeoService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'calculateur-solaire-app'},
  ));

  Future<List<LocationSuggestion>> search(String q, {int limit = 5}) async {
    final res = await _dio.get('/search', queryParameters: {
      'q': q,
      'format': 'json',
      'limit': limit,
    });
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(LocationSuggestion.fromJson).toList();
  }
}

class NasaPowerService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://power.larc.nasa.gov'));

  /// Retourne ALLSKY_SFC_SW_DWN moyen (kWh/m²/j)
  Future<double> avgIrradiation(double lat, double lon) async {
    final now = DateTime.now();
    final startYear = now.year - 1;
    final endYear = now.year;
    final res = await _dio.get('/api/temporal/daily/point', queryParameters: {
      'parameters': 'ALLSKY_SFC_SW_DWN',
      'community': 'RE',
      'longitude': lon,
      'latitude': lat,
      'start': startYear,
      'end': endYear,
      'format': 'json',
    });

    final map = (res.data['properties']['parameter']['ALLSKY_SFC_SW_DWN'] as Map)
        .cast<String, num>();
    final values = map.values.where((v) => v != -999);
    if (values.isEmpty) return 0;
    final sum = values.fold<double>(0, (a, b) => a + b.toDouble());
    return double.parse((sum / values.length).toStringAsFixed(2));
  }
}
