import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/calculator_models.dart';

class CalculatorService {
  final String baseUrl;   // ex: https://xxxx.ngrok-free.app  (sans /api)
  final http.Client client;
  CalculatorService(this.baseUrl, this.client);

  /// Construit une URI en préfixant /api/ exactement UNE fois.
  Uri _buildUri(String path) {
    final b = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // normalise le path demandé par l'appelant (on passe 'dimensionnements/calculate/')
    final normalized = path.startsWith('/') ? path : '/$path';

    // ajoute /api seulement s’il n’est pas déjà là
    final withApi = normalized.startsWith('/api/')
        ? normalized
        : '/api$normalized';

    return Uri.parse('$b$withApi');
  }

  Future<CalculationResult> publicCalculate(CalculationInput input) async {
    final uri = _buildUri('dimensionnements/calculate/'); // <- pas de /api ici
    final started = DateTime.now();
    // ignore: avoid_print
    print('[HTTP] POST $uri');

    http.Response res;
    try {
      res = await client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: jsonEncode(input.toJson()),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Timeout réseau (>15s) vers $uri');
    }

    final dur = DateTime.now().difference(started).inMilliseconds;
    // ignore: avoid_print
    print('[HTTP] ${res.statusCode} en ${dur}ms');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Map<String, dynamic> data =
          jsonDecode(res.body) as Map<String, dynamic>;
      return CalculationResult.fromJson(data);
    }

    // message propre (évite les dumps HTML géants)
    final raw = res.body;
    final noHtml = raw.replaceAll(RegExp(r'<[^>]+>'), '');
    final short = noHtml.length > 500 ? '${noHtml.substring(0, 500)}…' : noHtml;
    throw Exception('HTTP ${res.statusCode}: ${short.isEmpty ? 'No details' : short}');
  }
}
