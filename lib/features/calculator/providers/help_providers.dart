import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/help_service.dart';
import '../domain/calculator_models.dart';

final helpServiceProvider = Provider<HelpService>((ref) => HelpService());

final calculatorHelpKeysProvider = Provider<List<String>>((ref) => const [
  'E_jour',
  'P_max',
  'N_autonomie',
  'V_batterie',
  'H_solaire',
  'H_vers_toit',
  'localisation',
  'priorite_selection',
]);

/// Provider principal – SANS autoDispose pour éviter tout mismatch.
/// On peut recharger à la demande avec `ref.refresh(calculatorHelpProvider)`.
final calculatorHelpProvider = FutureProvider<Map<String, HelpItem>>((ref) async {
  final service = ref.read(helpServiceProvider);
  final keys = ref.read(calculatorHelpKeysProvider);

  // Fallback minimal (s'affiche si l'API n'a rien/erreur)
  final defaults = <String, HelpItem>{
    'E_jour': HelpItem(title: 'Consommation journalière (Wh)', bodyHtml: '...'),
    'P_max': HelpItem(title: 'Puissance max (W)', bodyHtml: '...'),
    'N_autonomie': HelpItem(title: "Jours d'autonomie", bodyHtml: '...'),
    'V_batterie': HelpItem(title: 'Tension batterie', bodyHtml: '...'),
    'H_solaire': HelpItem(title: 'Irradiation (kWh/m²/j)', bodyHtml: '...'),
    'H_vers_toit': HelpItem(title: 'Hauteur vers le toit (m)', bodyHtml: '...'),
    'localisation': HelpItem(title: 'Localisation', bodyHtml: '...'),
    'priorite_selection': HelpItem(title: 'Stratégie de sélection', bodyHtml: '...'),
  };

  Map<String, HelpItem> remote = const {};
  try {
    remote = await service.fetchHelpByKeys(keys);
    if (kDebugMode) {
      print('HELP REMOTE count: ${remote.length}  keys: ${remote.keys}');
    }
  } catch (e) {
    if (kDebugMode) print('HELP ERROR: $e');
    // on laisse le fallback s'afficher si l’API échoue
  }

  // Les données API (si présentes) remplacent le fallback
  return {...defaults, ...remote};
});
