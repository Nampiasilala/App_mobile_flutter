import 'package:flutter/material.dart';
import '../../../core/ui/smart_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calculator/providers.dart';
import '../../calculator/domain/calculator_models.dart';
import 'package:printing/printing.dart';
import '../pdf/pdf_report.dart';
import 'dart:async';

class CalculatePage extends ConsumerStatefulWidget {
  const CalculatePage({super.key});
  @override
  ConsumerState<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends ConsumerState<CalculatePage> {
  final _form = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers - vides par défaut
  final _ejour = TextEditingController();
  final _pmax = TextEditingController();
  final _nauto = TextEditingController();
  final _loc = TextEditingController();
  final _hSolaire = TextEditingController();
  
  // État du formulaire
  final _vbat = ValueNotifier<num>(24);
  final _selectedLocation = ValueNotifier<Map<String, String>?>(null);
  
  // États de l'interface
  bool _isCalculating = false;
  bool _isLoadingIrradiation = false;
  List<Map<String, String>> _suggestions = [];
  Map<String, dynamic>? _resultJson;
  CalculationResult? _fullResult;
  List<String> _errors = [];
  
  // Debouncing
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loc.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _ejour.dispose();
    _pmax.dispose();
    _nauto.dispose();
    _loc.dispose();
    _hSolaire.dispose();
    _vbat.dispose();
    _selectedLocation.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

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
      if (mounted) {
        setState(() {
          _suggestions = items.map((e) => {
            'name': e.displayName,
            'lat': e.lat,
            'lon': e.lon
          }).toList();
        });
      }
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
    
    final lat = double.tryParse(location['lat']!) ?? 0;
    final lon = double.tryParse(location['lon']!) ?? 0;
    
    await _fetchIrradiation(lat, lon);
  }

  Future<void> _fetchIrradiation(double lat, double lon) async {
    setState(() => _isLoadingIrradiation = true);
    
    try {
      final nasa = ref.read(nasaServiceProvider);
      final avgIrradiation = await nasa.avgIrradiation(lat, lon);
      
      if (mounted) {
        _hSolaire.text = avgIrradiation.toStringAsFixed(2);
        _showSnackBar(
          'Irradiation mise à jour: ${avgIrradiation.toStringAsFixed(2)} kWh/m²/j',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Impossible de récupérer l\'irradiation: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingIrradiation = false);
      }
    }
  }

  List<String> _validateForm() {
    final errors = <String>[];
    
    final ejour = double.tryParse(_ejour.text) ?? 0;
    if (ejour <= 0) errors.add('La consommation journalière doit être > 0');
    
    final pmax = double.tryParse(_pmax.text) ?? 0;
    if (pmax <= 0) errors.add('La puissance max doit être > 0');
    
    final nauto = double.tryParse(_nauto.text) ?? 0;
    if (nauto <= 0) errors.add('Le nombre de jours d\'autonomie doit être > 0');
    
    final hsolaire = double.tryParse(_hSolaire.text) ?? 0;
    if (hsolaire <= 0) errors.add('L\'irradiation doit être > 0');
    
    if (![12, 24, 48].contains(_vbat.value)) {
      errors.add('La tension doit être 12V, 24V ou 48V');
    }
    
    if (_loc.text.trim().isEmpty) {
      errors.add('La localisation est requise');
    }
    
    return errors;
  }

  Future<void> _submit() async {
    // Validation
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
      );

      final result = await svc.publicCalculate(input);
      ref.read(lastResultProvider.notifier).state = result;
      
      setState(() {
        _fullResult = result; // Stocker le résultat complet
        _resultJson = {
          'Puissance totale (W)': result.puissance_totale.toStringAsFixed(0),
          'Capacité batterie (Wh)': result.capacite_batterie.toStringAsFixed(0),
          'Bilan énergétique annuel (kWh)': result.bilan_energetique_annuel.toStringAsFixed(2),
          'Coût total (Ar)': _formatPrice(result.cout_total),
          'Nombre de panneaux': result.nombre_panneaux.toString(),
          'Nombre de batteries': result.nombre_batteries.toString(),
        };
      });

      _showSnackBar('Calcul effectué avec succès!', isError: false);
      
    } catch (e) {
      String errorMessage = 'Erreur lors du calcul';
      
      if (e.toString().contains('400')) {
        errorMessage = 'Données invalides. Vérifiez vos saisies.';
        setState(() => _errors = ['Veuillez vérifier les données saisies']);
      } else if (e.toString().contains('429')) {
        errorMessage = 'Trop de requêtes. Veuillez patienter.';
        setState(() => _errors = ['Limite de calculs atteinte. Veuillez patienter.']);
      } else {
        setState(() => _errors = [e.toString()]);
      }
      
      _showSnackBar(errorMessage, isError: true);
      _scrollToTop();
      
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _downloadPdf() async {
    final res = ref.read(lastResultProvider);
    if (res == null) return;

    try {
      // Organiser les données de manière structurée pour un meilleur affichage PDF
      final pdfResults = <String, dynamic>{
        // Section Paramètres d'entrée
        '=== PARAMÈTRES D\'ENTRÉE ===': '',
        'Consommation journalière': '${_ejour.text} Wh',
        'Puissance max': '${_pmax.text} W',
        'Jours d\'autonomie': _nauto.text,
        'Tension batterie': '${_vbat.value} V',
        'Localisation': _loc.text,
        'Irradiation': '${_hSolaire.text} kWh/m²/j',
        '': '', // Espacement
        
        // Section Résultats
        '=== RÉSULTATS DU DIMENSIONNEMENT ===': '',
        'Puissance totale': '${res.puissance_totale.toStringAsFixed(0)} W',
        'Capacité batterie': '${res.capacite_batterie.toStringAsFixed(0)} Wh',
        'Bilan énergétique annuel': '${res.bilan_energetique_annuel.toStringAsFixed(2)} kWh',
        'Coût total estimé': _formatPrice(res.cout_total),
        'Nombre de panneaux': res.nombre_panneaux.toString(),
        'Nombre de batteries': res.nombre_batteries.toString(),
        ' ': '', // Espacement
      };

      // Ajouter les équipements si disponibles
      if (res.equipements_recommandes != null) {
        pdfResults['=== ÉQUIPEMENTS RECOMMANDÉS ==='] = '';
        
        final equips = res.equipements_recommandes!;
        
        if (equips.panneau != null) {
          final p = equips.panneau!;
          pdfResults['--- Panneau solaire ---'] = '';
          pdfResults['Modèle panneau'] = p.modele ?? 'N/A';
          if (p.reference != null) pdfResults['Référence panneau'] = p.reference!;
          if (p.puissance_W != null) pdfResults['Puissance panneau'] = '${p.puissance_W} W';
          if (p.prix_unitaire != null) pdfResults['Prix unitaire panneau'] = '${p.prix_unitaire!.toStringAsFixed(0)} ${p.devise ?? 'Ar'}';
          pdfResults['Quantité panneaux'] = '${res.nombre_panneaux}';
        }
        
        if (equips.batterie != null) {
          final b = equips.batterie!;
          pdfResults['--- Batterie ---'] = '';
          pdfResults['Modèle batterie'] = b.modele ?? 'N/A';
          if (b.reference != null) pdfResults['Référence batterie'] = b.reference!;
          if (b.capacite_Ah != null) pdfResults['Capacité batterie'] = '${b.capacite_Ah} Ah';
          if (b.tension_nominale_V != null) pdfResults['Tension batterie'] = '${b.tension_nominale_V} V';
          if (b.prix_unitaire != null) pdfResults['Prix unitaire batterie'] = '${b.prix_unitaire!.toStringAsFixed(0)} ${b.devise ?? 'Ar'}';
          pdfResults['Quantité batteries'] = '${res.nombre_batteries}';
        }
        
        if (equips.regulateur != null) {
          final r = equips.regulateur!;
          pdfResults['--- Régulateur ---'] = '';
          pdfResults['Modèle régulateur'] = r.modele ?? 'N/A';
          if (r.reference != null) pdfResults['Référence régulateur'] = r.reference!;
          if (r.puissance_W != null) pdfResults['Puissance régulateur'] = '${r.puissance_W} W';
          if (r.prix_unitaire != null) pdfResults['Prix unitaire régulateur'] = '${r.prix_unitaire!.toStringAsFixed(0)} ${r.devise ?? 'Ar'}';
          pdfResults['Quantité régulateur'] = '1';
        }
        
        if (equips.onduleur != null) {
          final o = equips.onduleur!;
          pdfResults['--- Onduleur ---'] = '';
          pdfResults['Modèle onduleur'] = o.modele ?? 'N/A';
          if (o.reference != null) pdfResults['Référence onduleur'] = o.reference!;
          if (o.puissance_W != null) pdfResults['Puissance onduleur'] = '${o.puissance_W} W';
          if (o.prix_unitaire != null) pdfResults['Prix unitaire onduleur'] = '${o.prix_unitaire!.toStringAsFixed(0)} ${o.devise ?? 'Ar'}';
          pdfResults['Quantité onduleur'] = '1';
        }
        
        if (equips.cable != null) {
          final c = equips.cable!;
          pdfResults['--- Câble ---'] = '';
          pdfResults['Modèle câble'] = c.modele ?? 'N/A';
          if (c.reference != null) pdfResults['Référence câble'] = c.reference!;
          if (c.prix_unitaire != null) pdfResults['Prix unitaire câble'] = '${c.prix_unitaire!.toStringAsFixed(0)} ${c.devise ?? 'Ar'}';
          pdfResults['Quantité câble'] = 'Selon installation';
        }
      }
      
      final doc = await buildReport(
        title: 'Rapport de dimensionnement',
        results: pdfResults,
      );
      
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'dimensionnement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      _showSnackBar('Erreur lors de la génération du PDF: $e', isError: true);
    }
  }

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
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildEquipmentSection() {
    final equipments = _fullResult?.equipements_recommandes;
    if (equipments == null) return const SizedBox();

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Équipements recommandés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grille d'équipements
          if (equipments.panneau != null)
            _buildEquipmentCard(
              'Panneau solaire',
              Icons.wb_sunny,
              Colors.orange,
              equipments.panneau!,
              _fullResult!.nombre_panneaux,
            ),
          
          if (equipments.batterie != null) ...[
            const SizedBox(height: 12),
            _buildEquipmentCard(
              'Batterie',
              Icons.battery_charging_full,
              Colors.green,
              equipments.batterie!,
              _fullResult!.nombre_batteries,
            ),
          ],
          
          if (equipments.regulateur != null) ...[
            const SizedBox(height: 12),
            _buildEquipmentCard(
              'Régulateur',
              Icons.settings_input_component,
              Colors.purple,
              equipments.regulateur!,
              1,
            ),
          ],
          
          if (equipments.onduleur != null) ...[
            const SizedBox(height: 12),
            _buildEquipmentCard(
              'Onduleur',
              Icons.power,
              Colors.blue,
              equipments.onduleur!,
              1,
            ),
          ],
          
          if (equipments.cable != null) ...[
            const SizedBox(height: 12),
            _buildEquipmentCard(
              'Câble',
              Icons.cable,
              Colors.grey,
              equipments.cable!,
              null, // Quantité selon installation
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(
    String title,
    IconData icon,
    Color color,
    dynamic equipment,
    int? quantity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (equipment.modele != null) ...[
            _buildEquipmentRow('Modèle', equipment.modele),
            const SizedBox(height: 4),
          ],
          
          if (equipment.reference != null) ...[
            _buildEquipmentRow('Référence', equipment.reference),
            const SizedBox(height: 4),
          ],
          
          if (equipment.puissance_W != null) ...[
            _buildEquipmentRow('Puissance', '${equipment.puissance_W} W'),
            const SizedBox(height: 4),
          ],
          
          if (equipment.capacite_Ah != null) ...[
            _buildEquipmentRow('Capacité', '${equipment.capacite_Ah} Ah'),
            const SizedBox(height: 4),
          ],
          
          if (equipment.tension_nominale_V != null) ...[
            _buildEquipmentRow('Tension', '${equipment.tension_nominale_V} V'),
            const SizedBox(height: 4),
          ],
          
          if (equipment.prix_unitaire != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prix unitaire'),
                  Text(
                    '${equipment.prix_unitaire?.toStringAsFixed(0)} ${equipment.devise ?? 'Ar'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (quantity != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantité'),
                Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantité'),
                Text(
                  'Selon installation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
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
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} Ar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Erreurs de validation
            if (_errors.isNotEmpty) ...[
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
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Erreurs de validation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._errors.map((error) => Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text('• $error', style: TextStyle(color: Colors.red[700])),
                    )),
                  ],
                ),
              ),
            ],

            // Section Consommation
            _buildSection(
              title: 'Consommation',
              icon: Icons.flash_on,
              color: Colors.amber,
              children: [
                _buildNumberField(
                  controller: _ejour,
                  label: 'Consommation journalière (Wh)',
                  decoration: inputDecoration,
                  helpText: 'Somme de l\'énergie consommée sur 24h',
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _pmax,
                  label: 'Puissance max (W)',
                  decoration: inputDecoration,
                  helpText: 'Pic de puissance utilisé simultanément',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section Configuration
            _buildSection(
              title: 'Configuration',
              icon: Icons.settings,
              color: Colors.purple,
              children: [
                _buildNumberField(
                  controller: _nauto,
                  label: 'Jours d\'autonomie',
                  decoration: inputDecoration,
                  helpText: 'Jours sans soleil couverts par les batteries',
                ),
                const SizedBox(height: 16),
                Text(
                  'Tension batterie',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<num>(
                  valueListenable: _vbat,
                  builder: (_, voltage, __) => Row(
                    children: [12, 24, 48].map((v) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: v == 48 ? 0 : 8,
                        ),
                        child: Material(
                          color: voltage == v ? theme.primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _vbat.value = v,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                '${v}V',
                                style: TextStyle(
                                  color: voltage == v ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section Environnement
            _buildSection(
              title: 'Environnement',
              icon: Icons.location_on,
              color: Colors.green,
              children: [
                // Localisation avec suggestions
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, size: 18),
                              title: Text(
                                suggestion['name']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () => _pickLocation(suggestion),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Irradiation
                ValueListenableBuilder<Map<String, String>?>(
                  valueListenable: _selectedLocation,
                  builder: (_, selectedLoc, __) => TextFormField(
                    controller: _hSolaire,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: selectedLoc == null,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Irradiation (kWh/m²/j)',
                      helperText: selectedLoc != null 
                          ? 'Calculée automatiquement' 
                          : 'Énergie solaire moyenne reçue par m² et par jour',
                      helperStyle: TextStyle(
                        color: selectedLoc != null ? Colors.green[600] : null,
                      ),
                    ),
                  ),
                ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.calculate),
                label: Text(
                  _isCalculating ? 'Calcul en cours...' : 'Calculer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Résultats
            if (_resultJson != null) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
              
              // Équipements recommandés
              if (_fullResult?.equipements_recommandes != null) ...[
                const SizedBox(height: 20),
                _buildEquipmentSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required InputDecoration decoration,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: decoration.copyWith(labelText: label),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Résultats du Dimensionnement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green[50],
                  foregroundColor: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._resultJson!.entries.map((entry) => Container(
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
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _downloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text(
                'Télécharger le rapport PDF',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}