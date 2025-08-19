import 'package:calculateur_solaire/constants/api_url.dart' as gen;

/// Ordre de priorité :
/// 1) --dart-define=API_BASE_URL=...  (utile si tu veux override à la volée)
/// 2) lib/constants/api_url.dart       (généré par start_dev.sh depuis ngrok)
/// 3) fallback local (émulateur Android)
class Env {
  static const _fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static String get apiBase {
    if (_fromDefine.isNotEmpty) return _normalize(_fromDefine);
    if (gen.API_BASE_URL.isNotEmpty) return _normalize(gen.API_BASE_URL);
    return 'http://10.0.2.2:8001/api'; // fallback émulateur
  }

  static String _normalize(String s) {
    // Garantir suffixe /api si tu fournis juste le host
    // (si ton start_dev.sh écrit déjà .../api, laissons comme tel)
    return s.endsWith('/api') ? s : (s.endsWith('/') ? '${s}api' : '$s/api');
  }
}
