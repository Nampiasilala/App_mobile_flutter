import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../calculator/domain/calculator_models.dart';
import '../../calculator/providers.dart';
import '../pdf/pdf_report.dart';

class CalculatePage extends ConsumerStatefulWidget {
  const CalculatePage({super.key});
  @override
  ConsumerState<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends ConsumerState<CalculatePage> {
  final _form = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _ejour = TextEditingController();
  final _pmax = TextEditingController();
  final _nauto = TextEditingController(text: '1');
  final _loc = TextEditingController();
  final _hSolaire = TextEditingController(); // rempli auto
  final _hVersToit = TextEditingController(text: '10'); // défaut 10 m

  // Notifiers
  final _vbat = ValueNotifier<num>(24);
  final _selectedLocation = ValueNotifier<Map<String, String>?>(null);
  final _priorite = ValueNotifier<String>('cout'); // 'cout' | 'quantite'

  // UI state
  bool _isCalculating = false;
  bool _isLoadingIrradiation = false;
  List<Map<String, String>> _suggestions = [];
  Map<String, dynamic>? _resultJson;
  CalculationResult? _fullResult;
  List<String> _errors = [];

  // Auto/manuel pour la tension batterie
  bool _manualBattery = false;

  // Debounce
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loc.addListener(_onLocationChanged);
    _pmax.addListener(_onPmaxChanged); // 👉 met à jour V_batterie en mode auto
    // Première suggestion au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPmaxChanged());
  }

  @override
  void dispose() {
    _ejour.dispose();
    _pmax.removeListener(_onPmaxChanged);
    _pmax.dispose();
    _nauto.dispose();
    _loc.dispose();
    _hSolaire.dispose();
    _hVersToit.dispose();
    _vbat.dispose();
    _priorite.dispose();
    _selectedLocation.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /* --------------------------- Suggestion V_batterie --------------------------- */

  int _suggestBatteryVoltage(num pmax) {
    final v = pmax.toDouble();
    if (!v.isFinite || v <= 0) return 24; // neutre par défaut
    if (v <= 800) return 12;
    if (v <= 2000) return 24;
    return 48;
  }

  void _onPmaxChanged() {
    if (_manualBattery) return; // l'utilisateur a forcé
    final p = double.tryParse(_pmax.text) ?? 0;
    final suggested = _suggestBatteryVoltage(p);
    if (_vbat.value != suggested) _vbat.value = suggested;
  }

  /* ------------------------------ GEO & NASA ------------------------------ */

  void _onLocationChanged() {
    _debounceTimer?.cancel();
    if (_selectedLocation.value != null) {
      _selectedLocation.value = null;
    }
    _debounceTimer = Timer(_debounceDuration, () {
      if (_loc.text.trim().length >= 3) {
        _searchLocation(_loc.text);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final geo = ref.read(geoServiceProvider);
      final items = await geo.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = items
            .map((e) => {'name': e.displayName, 'lat': e.lat, 'lon': e.lon})
            .toList();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la recherche: $e', isError: true);
      }
    }
  }

  Future<void> _pickLocation(Map<String, String> location) async {
    _loc.text = location['name']!;
    _selectedLocation.value = location;
    setState(() => _suggestions = []);
    final lat = double.tryParse(location['lat'] ?? '') ?? 0;
    final lon = double.tryParse(location['lon'] ?? '') ?? 0;
    await _fetchIrradiation(lat, lon);
  }

  Future<void> _fetchIrradiation(double lat, double lon) async {
    setState(() => _isLoadingIrradiation = true);
    try {
      final nasa = ref.read(nasaServiceProvider);
      final avg = await nasa.avgIrradiation(lat, lon);
      if (!mounted) return;
      _hSolaire.text = avg.toStringAsFixed(2);
      _showSnackBar(
        'Irradiation mise à jour: ${avg.toStringAsFixed(2)} kWh/m²/j',
        isError: false,
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar("Impossible de récupérer l'irradiation: $e",
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoadingIrradiation = false);
    }
  }

  /* ------------------------------ Validation ----------------------------- */

  List<String> _validateForm() {
    final errors = <String>[];

    final ejour = double.tryParse(_ejour.text) ?? 0;
    if (ejour <= 0) errors.add('La consommation journalière doit être > 0');

    final pmax = double.tryParse(_pmax.text) ?? 0;
    if (pmax <= 0) errors.add('La puissance max doit être > 0');

    final nauto = double.tryParse(_nauto.text) ?? 0;
    if (nauto <= 0) errors.add("Le nombre de jours d'autonomie doit être > 0");

    final hsolaire = double.tryParse(_hSolaire.text) ?? 0;
    if (hsolaire <= 0) errors.add("L'irradiation doit être > 0");

    final htoit = double.tryParse(_hVersToit.text) ?? 0;
    if (htoit <= 0) errors.add('La hauteur vers le toit doit être > 0');

    if (![12, 24, 48].contains(_vbat.value)) {
      errors.add('La tension doit être 12V, 24V ou 48V');
    }

    final prio = _priorite.value;
    if (prio != 'cout' && prio != 'quantite') {
      errors.add('Stratégie de sélection invalide');
    }

    if (_loc.text.trim().isEmpty) {
      errors.add('La localisation est requise');
    }

    return errors;
  }

  /* -------------------------------- Submit ------------------------------- */

  Future<void> _submit() async {
    final validationErrors = _validateForm();
    if (validationErrors.isNotEmpty) {
      setState(() => _errors = validationErrors);
      _scrollToTop();
      return;
    }

    setState(() {
      _isCalculating = true;
      _errors = [];
    });

    try {
      final svc = ref.read(calculatorServiceProvider);
      final input = CalculationInput(
        E_jour: num.parse(_ejour.text),
        P_max: num.parse(_pmax.text),
        N_autonomie: num.parse(_nauto.text),
        H_solaire: double.parse(_hSolaire.text),
        V_batterie: _vbat.value,
        localisation: _loc.text,
        H_vers_toit: double.parse(_hVersToit.text),
        priorite_selection: _priorite.value,
      );

      final result = await svc.publicCalculate(input);
      ref.read(lastResultProvider.notifier).state = result;

      setState(() {
        _fullResult = result;
        _resultJson = {
          'Puissance totale (W)':
              result.puissance_totale.toDouble().toStringAsFixed(0),
          'Capacité batterie (Wh)':
              result.capacite_batterie.toDouble().toStringAsFixed(0),
          'Bilan énergétique annuel (kWh)':
              result.bilan_energetique_annuel.toDouble().toStringAsFixed(2),
          'Coût total (Ar)': _formatPrice(result.cout_total),
          'Nombre de panneaux': result.nombre_panneaux.toString(),
          'Nombre de batteries': result.nombre_batteries.toString(),
        };
      });

      _showSnackBar('Calcul effectué avec succès!', isError: false);
    } catch (e) {
      setState(() => _errors = [e.toString()]);
      _showSnackBar('Erreur lors du calcul', isError: true);
      _scrollToTop();
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  /* ------------------------------ PDF export ----------------------------- */

  Future<void> _downloadPdf() async {
    final res = ref.read(lastResultProvider);
    if (res == null) return;

    try {
      final pdfResults = <String, dynamic>{
        "=== PARAMÈTRES D'ENTRÉE ===": '',
        'Consommation journalière': '${_ejour.text} Wh',
        'Puissance max': '${_pmax.text} W',
        "Jours d'autonomie": _nauto.text,
        'Tension batterie': '${_vbat.value} V',
        'Localisation': _loc.text,
        'Irradiation': '${_hSolaire.text} kWh/m²/j',
        'Hauteur vers le toit': '${_hVersToit.text} m',
        'Stratégie de sélection':
            _priorite.value == 'cout' ? 'Coût minimal' : 'Nombre minimal',
        '': '',
        '=== RÉSULTATS DU DIMENSIONNEMENT ===': '',
        'Puissance totale': '${res.puissance_totale.toStringAsFixed(0)} W',
        'Capacité batterie': '${res.capacite_batterie.toStringAsFixed(0)} Wh',
        'Bilan énergétique annuel':
            '${res.bilan_energetique_annuel.toStringAsFixed(2)} kWh',
        'Coût total estimé': _formatPrice(res.cout_total),
        'Nombre de panneaux': res.nombre_panneaux.toString(),
        'Nombre de batteries': res.nombre_batteries.toString(),
        ' ': '',
      };

      final eq = res.equipements_recommandes;
      if (eq != null) {
        pdfResults['=== ÉQUIPEMENTS RECOMMANDÉS ==='] = '';

        final p = eq.panneau;
        if (p != null) {
          pdfResults['--- Panneau solaire ---'] = '';
          if (p.modele != null) pdfResults['Modèle panneau'] = p.modele!;
          if (p.reference != null) pdfResults['Référence panneau'] = p.reference!;
          if (p.puissance_W != null) {
            pdfResults['Puissance panneau'] = '${p.puissance_W} W';
          }
          pdfResults['Prix unitaire panneau'] =
              '${p.prix_unitaire.toStringAsFixed(0)} ${p.devise ?? 'Ar'}';
          pdfResults['Quantité panneaux'] = '${res.nombre_panneaux}';
        }

        final b = eq.batterie;
        if (b != null) {
          pdfResults['--- Batterie ---'] = '';
          if (b.modele != null) pdfResults['Modèle batterie'] = b.modele!;
          if (b.reference != null) pdfResults['Référence batterie'] = b.reference!;
          if (b.capacite_Ah != null) {
            pdfResults['Capacité batterie (Ah)'] = '${b.capacite_Ah} Ah';
          }
          if (b.tension_nominale_V != null) {
            pdfResults['Tension batterie (V)'] = '${b.tension_nominale_V} V';
          }
          pdfResults['Prix unitaire batterie'] =
              '${b.prix_unitaire.toStringAsFixed(0)} ${b.devise ?? 'Ar'}';
          pdfResults['Quantité batteries'] = '${res.nombre_batteries}';
        }

        final r = eq.regulateur;
        if (r != null) {
          pdfResults['--- Régulateur ---'] = '';
          if (r.modele != null) pdfResults['Modèle régulateur'] = r.modele!;
          if (r.reference != null) pdfResults['Référence régulateur'] = r.reference!;
          if (r.puissance_W != null) {
            pdfResults['Puissance régulateur'] = '${r.puissance_W} W';
          }
          if (r.courant_A != null) {
            pdfResults['Courant nominal'] = '${r.courant_A} A';
          }
          pdfResults['Prix unitaire régulateur'] =
              '${r.prix_unitaire.toStringAsFixed(0)} ${r.devise ?? 'Ar'}';
          pdfResults['Quantité régulateur'] = '1';
        }

        final o = eq.onduleur;
        if (o != null) {
          pdfResults['--- Onduleur ---'] = '';
          if (o.modele != null) pdfResults['Modèle onduleur'] = o.modele!;
          if (o.reference != null) pdfResults['Référence onduleur'] = o.reference!;
          if (o.puissance_W != null) {
            pdfResults['Puissance onduleur'] = '${o.puissance_W} W';
          }
          pdfResults['Prix unitaire onduleur'] =
              '${o.prix_unitaire.toStringAsFixed(0)} ${o.devise ?? 'Ar'}';
          pdfResults['Quantité onduleur'] = '1';
        }

        final c = eq.cable;
        if (c != null) {
          pdfResults['--- Câble ---'] = '';
          if (c.modele != null) pdfResults['Modèle câble'] = c.modele!;
          if (c.reference != null) pdfResults['Référence câble'] = c.reference!;
          pdfResults['Prix unitaire câble'] =
              '${c.prix_unitaire.toStringAsFixed(0)} ${c.devise ?? 'Ar'}';
          pdfResults['Quantité câble'] = 'Selon installation';
        }
      }

      if (res.topologie_pv != null ||
          res.nb_pv_serie != null ||
          res.nb_pv_parallele != null) {
        pdfResults['Topologie PV'] =
            res.topologie_pv ??
                '${res.nb_pv_serie ?? "?"}S${res.nb_pv_parallele ?? "?"}P';
      }
      if (res.topologie_batterie != null ||
          res.nb_batt_serie != null ||
          res.nb_batt_parallele != null) {
        pdfResults['Topologie Batteries'] =
            res.topologie_batterie ??
                '${res.nb_batt_serie ?? "?"}S${res.nb_batt_parallele ?? "?"}P';
      }
      if (res.longueur_cable_global_m != null) {
        pdfResults['Longueur câble globale'] =
            '${res.longueur_cable_global_m} m';
      }
      if (res.prix_cable_global != null) {
        pdfResults['Prix total câble'] = _formatPrice(res.prix_cable_global!);
      }

      final doc = await buildReport(
        title: 'Rapport de dimensionnement',
        results: pdfResults,
      );
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename:
            'dimensionnement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      _showSnackBar('Erreur lors de la génération du PDF: $e', isError: true);
    }
  }

  /* ------------------------------ UI helpers ----------------------------- */

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatPrice(num price) {
    final s = price.toStringAsFixed(0);
    final withSpaces =
        s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ');
    return '$withSpaces Ar';
  }

  /* --------------------------------- BUILD -------------------------------- */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.grey[50],
    );

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Calculateur Solaire'),
      body: Form(
        key: _form,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (_errors.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Erreurs de validation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700])),
                    ]),
                    const SizedBox(height: 8),
                    ..._errors.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text('• $e',
                              style: TextStyle(color: Colors.red[700])),
                        )),
                  ],
                ),
              ),

            /* -------------------------- Section Consommation ------------------------- */
            _section(
              title: 'Consommation',
              icon: Icons.flash_on,
              color: Colors.amber,
              children: [
                _numField(_ejour, 'Consommation journalière (Wh)',
                    inputDecoration,
                    help:
                        "Somme de l'énergie consommée sur 24h"),
                const SizedBox(height: 16),
                _numField(_pmax, 'Puissance max (W)', inputDecoration,
                    help: 'Pic de puissance simultané'),
              ],
            ),
            const SizedBox(height: 20),

            /* --------------------------- Section Configuration ---------------------- */
            _section(
              title: 'Configuration',
              icon: Icons.settings,
              color: Colors.purple,
              children: [
                _numField(_nauto, "Jours d'autonomie", inputDecoration,
                    help: 'Jours sans soleil couverts'),
                const SizedBox(height: 16),

                // --- Tension batterie (auto + manuel)
                Text('Tension batterie',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ValueListenableBuilder<num>(
                  valueListenable: _vbat,
                  builder: (_, v, __) {
                    final p = double.tryParse(_pmax.text) ?? 0;
                    final suggested = _suggestBatteryVoltage(p);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [12, 24, 48].map((e) {
                            final selected = v == e;
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: e == 48 ? 0 : 8),
                                child: Material(
                                  color: selected
                                      ? theme.primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() => _manualBattery = true);
                                      _vbat.value = e;
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        '${e}V',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mode : ${_manualBattery ? 'manuel' : 'auto'}'
                          '${(!_manualBattery && p > 0) ? ' — suggestion : ${suggested}V' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        if (_manualBattery)
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            onPressed: () {
                              setState(() => _manualBattery = false);
                              _onPmaxChanged(); // applique la suggestion
                            },
                            child: const Text(
                              'Revenir au choix automatique (basé sur P_max)',
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Stratégie de sélection
                Text('Stratégie de sélection',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ValueListenableBuilder<String>(
                  valueListenable: _priorite,
                  builder: (_, value, __) => Row(children: [
                    Expanded(
                      child: _choice(
                        selected: value == 'cout',
                        label: 'Coût minimal',
                        onTap: () => _priorite.value = 'cout',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choice(
                        selected: value == 'quantite',
                        label: 'Nombre minimal',
                        onTap: () => _priorite.value = 'quantite',
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /* ----------------------------- Section Environnement -------------------- */
            _section(
              title: 'Environnement',
              icon: Icons.location_on,
              color: Colors.green,
              children: [
                // Localisation + suggestions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _loc,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Localisation',
                        suffixIcon: _isLoadingIrradiation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => _searchLocation(_loc.text),
                              ),
                      ),
                    ),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = _suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, size: 18),
                              title: Text(s['name']!, style: const TextStyle(fontSize: 14)),
                              onTap: () => _pickLocation(s),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Irradiation (disabled)
                TextFormField(
                  controller: _hSolaire,
                  enabled: false,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Irradiation (kWh/m²/j)',
                    helperText:
                        'Calculée automatiquement à partir de la localisation',
                    helperStyle: TextStyle(color: Colors.green[600]),
                  ),
                ),
                const SizedBox(height: 16),

                // Hauteur vers toit
                _numField(_hVersToit, 'Hauteur vers le toit (m)',
                    inputDecoration,
                    help:
                        'Estimation longueur câble ≈ H × 2 × 1,2 (aller/retour + 20%)'),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton Calculer
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isCalculating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isCalculating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.calculate),
                label: Text(
                  _isCalculating ? 'Calcul en cours...' : 'Calculer',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Résultats
            if (_resultJson != null) ...[
              const SizedBox(height: 24),
              _resultsSection(),
              if (_fullResult?.equipements_recommandes != null) ...[
                const SizedBox(height: 20),
                _equipmentSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /* ----------------------------- Small widgets ---------------------------- */

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _numField(TextEditingController c, String label,
      InputDecoration deco, {String? help}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: deco.copyWith(labelText: label),
        onChanged: (val) {
          // si l'utilisateur modifie P_max via ce champ, on applique la logique auto
          if (c == _pmax) _onPmaxChanged();
        },
      ),
      if (help != null) ...[
        const SizedBox(height: 4),
        Text(help, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]
    ]);
  }

  Widget _choice({required bool selected, required String label, required VoidCallback onTap}) {
    return Material(
      color: selected ? Colors.blue : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Résultats du Dimensionnement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.picture_as_pdf),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green[50],
              foregroundColor: Colors.green[700],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        ..._resultJson!.entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(e.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.grey)),
                  ),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),

        // --- KPI affichés 2 par ligne
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final itemWidth = (constraints.maxWidth - gap) / 2;

            final kpis = <Widget>[
              if (_fullResult?.equipements_recommandes?.onduleur != null)
                _kpi('Onduleur',
                    _fullResult!.equipements_recommandes!.onduleur!.puissance_W !=
                            null
                        ? '${_fullResult!.equipements_recommandes!.onduleur!.puissance_W} W'
                        : (_fullResult!.equipements_recommandes!.onduleur!.modele ?? '—')),
              if (_fullResult?.equipements_recommandes?.regulateur != null)
                _kpi(
                    'Régulateur',
                    _fullResult!.equipements_recommandes!.regulateur!.courant_A !=
                            null
                        ? '${_fullResult!.equipements_recommandes!.regulateur!.courant_A} A'
                        : (_fullResult!.equipements_recommandes!.regulateur!.modele ?? '—')),
              if (_fullResult?.topologie_pv != null ||
                  _fullResult?.nb_pv_serie != null ||
                  _fullResult?.nb_pv_parallele != null)
                _kpi(
                    'Topologie PV',
                    _fullResult!.topologie_pv ??
                        '${_fullResult!.nb_pv_serie ?? "?"}S${_fullResult!.nb_pv_parallele ?? "?"}P'),
              if (_fullResult?.topologie_batterie != null ||
                  _fullResult?.nb_batt_serie != null ||
                  _fullResult?.nb_batt_parallele != null)
                _kpi(
                    'Topologie Batteries',
                    _fullResult!.topologie_batterie ??
                        '${_fullResult!.nb_batt_serie ?? "?"}S${_fullResult!.nb_batt_parallele ?? "?"}P'),
              if (_fullResult?.longueur_cable_global_m != null ||
                  _fullResult?.prix_cable_global != null)
                _kpi(
                    'Câblage',
                    [
                      if (_fullResult?.longueur_cable_global_m != null)
                        '${_fullResult!.longueur_cable_global_m} m',
                      if (_fullResult?.prix_cable_global != null)
                        _formatPrice(_fullResult!.prix_cable_global!)
                    ].join(' · ')),
            ];

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: kpis
                  .map((w) => SizedBox(width: itemWidth, child: w))
                  .toList(),
            );
          },
        ),
      ]),
    );
  }

  Widget _kpi(String label, String value) {
    return Container(
      // width: 160,  // ❌ supprimé pour laisser le LayoutBuilder gérer la largeur
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF111827))),
      ]),
    );
  }

  Widget _equipmentSection() {
    final eq = _fullResult!.equipements_recommandes!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Équipements recommandés',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Column(children: [
          if (eq.panneau != null)
            _equipCard('Panneau solaire', Colors.blue, eq.panneau!,
                trailing: 'Quantité: ${_fullResult!.nombre_panneaux}'),
          if (eq.batterie != null) ...[
            const SizedBox(height: 12),
            _equipCard('Batterie', Colors.green, eq.batterie!,
                trailing: 'Quantité: ${_fullResult!.nombre_batteries}'),
          ],
          if (eq.regulateur != null) ...[
            const SizedBox(height: 12),
            _equipCard('Régulateur', Colors.purple, eq.regulateur!,
                trailing: 'Quantité: 1'),
          ],
          if (eq.onduleur != null) ...[
            const SizedBox(height: 12),
            _equipCard('Onduleur', Colors.orange, eq.onduleur!,
                trailing: 'Quantité: 1'),
          ],
          if (eq.cable != null) ...[
            const SizedBox(height: 12),
            _equipCard('Câble', Colors.grey, eq.cable!,
                trailing: (_fullResult?.longueur_cable_global_m != null ||
                        _fullResult?.prix_cable_global != null)
                    ? [
                        if (_fullResult?.longueur_cable_global_m != null)
                          'Longueur: ${_fullResult!.longueur_cable_global_m} m',
                        if (_fullResult?.prix_cable_global != null)
                          'Prix total: ${_formatPrice(_fullResult!.prix_cable_global!)}',
                      ].join(' · ')
                    : 'Selon installation'),
          ],
        ]),
      ]),
    );
  }

  Widget _equipCard(
      String title, Color color, dynamic d, {required String trailing}) {
    String price = _formatPrice(d.prix_unitaire);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(.08), color.withOpacity(.16)]),
        border: Border.all(color: color.withOpacity(.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.settings, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          _kv('Modèle', d.modele ?? '—'),
          if (d.reference != null) _kv('Référence', d.reference, mono: true),
          if (d.puissance_W != null) _kv('Puissance', '${d.puissance_W} W'),
          if (d.capacite_Ah != null) _kv('Capacité', '${d.capacite_Ah} Ah'),
          if (d.tension_nominale_V != null)
            _kv('Tension', '${d.tension_nominale_V} V'),
          _kv('Prix unitaire', price, strong: true),
          const SizedBox(height: 6),
          Text(trailing,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v, {bool strong = false, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(
          child: Text(k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 8),
        Text(v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
                color: const Color(0xFF111827))),
      ]),
    );
  }
}
