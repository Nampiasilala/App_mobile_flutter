import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../constants/api_url.dart'; // const API_BASE_URL
import '../domain/calculator_models.dart';

class HelpService {
  final http.Client _client;
  HelpService({http.Client? client}) : _client = client ?? http.Client();

  // ------------------------- Public API -------------------------

  Future<Map<String, HelpItem>> fetchHelpByKeys(List<String> uiKeys) async {
    if (uiKeys.isEmpty) return {};

    // 1) normaliser les clés pour l’API (snake_case minuscule)
    final apiKeys = uiKeys.map(_toApiKey).toList();

    // 2) batch d’abord
    final batchUri = _buildBatchUri(apiKeys);
    final batchMap = await _fetchBatch(batchUri);

    // 3) compléter les manquants par endpoint unitaire
    final missing = <String>[];
    for (final k in apiKeys) {
      if (!batchMap.containsKey(k)) missing.add(k);
    }

    if (missing.isNotEmpty) {
      if (kDebugMode) {
        print('HELP missing after batch: $missing — fetching individually…');
      }
      final singles = await _fetchSingles(missing);
      batchMap.addAll(singles);
    }

    // 4) aligner: retourner sous les clés EXACTES UI (E_jour, P_max, …)
    final aligned = _alignToUiKeys(batchMap, uiKeys);

    if (kDebugMode) {
      print('HELP final keys for UI: ${aligned.keys.toList()}');
    }
    return aligned;
  }

  // ------------------------- HTTP helpers -------------------------

  Uri _buildBatchUri(List<String> apiKeys) {
    final base = Uri.parse(API_BASE_URL);
    // sur Next tu fais `${BASE}/contenus/public/help-by-key/?keys=...`
    // Ici on suppose BASE sans /api ; si ton BASE inclut déjà /api, c’est ok:
    // resolve() gère bien les chemins absolus.
    final endpoint = base.resolve('/api/contenus/public/help-by-key/');
    return endpoint.replace(
      queryParameters: {
        'keys': apiKeys.join(','), // CSV
      },
    );
  }

  Uri _buildSingleUri(String apiKey) {
    final base = Uri.parse(API_BASE_URL);
    // même logique que Next: /contenus/public/by-key/<key>/
    final encoded = Uri.encodeComponent(apiKey);
    return base.resolve('/api/contenus/public/by-key/$encoded/');
  }

  Future<Map<String, _RawHelp>> _fetchBatch(Uri uri) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (kIsWeb) 'ngrok-skip-browser-warning': 'true',
    };

    final res = await _client.get(uri, headers: headers);
    if (res.statusCode != 200) {
      if (kDebugMode) {
        print('HELP batch HTTP ${res.statusCode}: ${res.body}');
      }
      return {};
    }

    final dynamic jsonData = await compute(_decodeJsonBytes, res.bodyBytes);
    return _parseBatch(jsonData);
  }

  Future<Map<String, _RawHelp>> _fetchSingles(List<String> apiKeys) async {
    final out = <String, _RawHelp>{};

    // Appels séquentiels (simplicité). Si tu veux, tu peux paralléliser.
    for (final key in apiKeys) {
      final uri = _buildSingleUri(key);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (kIsWeb) 'ngrok-skip-browser-warning': 'true',
      };
      try {
        final res = await _client.get(uri, headers: headers);
        if (res.statusCode != 200) continue;

        final dynamic data = await compute(_decodeJsonBytes, res.bodyBytes);
        final item = _parseSingle(data);
        if (item != null) out[key] = item;
      } catch (_) {
        // silencieux
      }
    }
    return out;
  }

  // ------------------------- Parsing -------------------------

  // Format batch: peut être un Map {key: {...}} ou une List d’objets
  Map<String, _RawHelp> _parseBatch(dynamic data) {
    final out = <String, _RawHelp>{};

    if (data is Map<String, dynamic>) {
      // wrappers typiques
      for (final k in ['results', 'data', 'payload', 'items', 'objects']) {
        if (data[k] != null) return _parseBatch(data[k]);
      }
      // map clé -> objet
      data.forEach((k, v) {
        final rh = _toRawHelp(v);
        if (rh != null) out[_toApiKey(k)] = rh;
      });
    } else if (data is List) {
      for (final item in data) {
        final key = _extractKey(item);
        final rh = _toRawHelp(item);
        if (key != null && rh != null) out[_toApiKey(key)] = rh;
      }
    }

    return out;
  }

  // Format single: objet direct (avec key/title/body_html) ou wrappers
  _RawHelp? _parseSingle(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final k in ['result', 'data', 'payload', 'item', 'object']) {
        if (data[k] != null) return _parseSingle(data[k]);
      }
      final key = _extractKey(data);
      final rh = _toRawHelp(data);
      if (key != null && rh != null) {
        return rh;
      }
    }
    return _toRawHelp(data);
  }

  String? _extractKey(dynamic v) {
    if (v is! Map) return null;
    final cands = [v['key'], v['help_key'], v['slug'], v['code'], v['name']];
    for (final c in cands) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    // parfois dans fields/attributes
    final f = (v['fields'] is Map)
        ? v['fields'] as Map
        : (v['attributes'] is Map)
        ? v['attributes'] as Map
        : null;
    if (f != null) {
      for (final k in ['key', 'help_key', 'slug', 'code', 'name']) {
        final s = f[k]?.toString().trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  _RawHelp? _toRawHelp(dynamic v) {
    if (v is! Map) return null;

    final m = (v['fields'] is Map)
        ? v['fields'] as Map
        : (v['attributes'] is Map)
        ? v['attributes'] as Map
        : v;

    String pick(Map mm, List<String> keys) {
      for (final k in keys) {
        final s = mm[k]?.toString();
        if (s != null && s.trim().isNotEmpty) return s;
      }
      return '';
    }

    final title = pick(m, ['title', 'titre', 'name', 'label']);
    final body = pick(m, [
      'body_html',
      'bodyHtml',
      'html',
      'content',
      'contenu',
      'description',
      'texte_html',
      'texte',
      'body',
      'markdown',
    ]);

    // (optionnel) si tu veux respecter is_active quand présent :
    // final isActive = (m['is_active'] == true);

    return _RawHelp(title: title, bodyHtml: body);
  }

  Map<String, HelpItem> _alignToUiKeys(
    Map<String, _RawHelp> apiMap, // clés en snake_case minuscule
    List<String> uiKeys, // 'E_jour', 'P_max', ...
  ) {
    // index des données batch par clé normalisée
    final byNorm = <String, _RawHelp>{};
    apiMap.forEach((k, v) => byNorm[_normKey(k)] = v);

    final out = <String, HelpItem>{};
    for (final key in uiKeys) {
      final norm = _normKey(key); // ex: 'E_jour' -> 'e_jour'
      final rh = byNorm[norm];
      if (rh != null) {
        out[key] = HelpItem(title: rh.title, bodyHtml: rh.bodyHtml);
      }
    }

    // bonus: on ajoute aussi les clés API brutes (utile pour debug)
    apiMap.forEach((k, v) {
      out.putIfAbsent(k, () => HelpItem(title: v.title, bodyHtml: v.bodyHtml));
    });

    return out;
  }

  // ------------------------- Normalisation clés -------------------------

  String _toApiKey(String s) => _normKey(s);

  String _normKey(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[ \-\/]+'), '_')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ç', 'c');
  }
}

// ===== Helpers pour compute() =====
dynamic _decodeJsonBytes(Uint8List bytes) {
  final raw = utf8.decode(bytes);
  return json.decode(raw);
}

// ===== Modèle interne (brut) =====
class _RawHelp {
  final String title;
  final String bodyHtml;
  _RawHelp({required this.title, required this.bodyHtml});
}
