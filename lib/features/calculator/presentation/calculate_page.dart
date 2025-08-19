import 'package:flutter/material.dart';
import '../../../core/ui/smart_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calculator/providers.dart';
import '../../calculator/domain/calculator_models.dart';
import 'package:printing/printing.dart';
import '../pdf/pdf_report.dart';

class CalculatePage extends ConsumerStatefulWidget {
  const CalculatePage({super.key});
  @override
  ConsumerState<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends ConsumerState<CalculatePage> {
  final _form = GlobalKey<FormState>();
  final _ejour = TextEditingController(text: '1520');
  final _pmax = TextEditingController(text: '400');
  final _nauto = TextEditingController(text: '1');
  final _vbat = ValueNotifier<num>(24);
  final _loc = TextEditingController(text: 'Antananarivo');
  double _hSolaire = 4.5;

  bool _busy = false;
  List<Map<String, String>> _sugs = [];
  Map<String, dynamic>? _resultJson;

  @override
  void dispose() {
    _ejour.dispose();
    _pmax.dispose();
    _nauto.dispose();
    _loc.dispose();
    _vbat.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _sugs = []);
      return;
    }
    final geo = ref.read(geoServiceProvider);
    final items = await geo.search(q);
    setState(() {
      _sugs = items.map((e) => {'name': e.displayName, 'lat': e.lat, 'lon': e.lon}).toList();
    });
  }

  Future<void> _pickLocation(Map<String, String> m) async {
    _loc.text = m['name']!;
    setState(() => _sugs = []);
    final lat = double.tryParse(m['lat']!) ?? 0;
    final lon = double.tryParse(m['lon']!) ?? 0;
    final nasa = ref.read(nasaServiceProvider);
    final avg = await nasa.avgIrradiation(lat, lon);
    setState(() => _hSolaire = avg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Irradiation moyenne: $_hSolaire kWh/m²/j')),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final svc = ref.read(calculatorServiceProvider);
      final input = CalculationInput(
        E_jour: num.parse(_ejour.text),
        P_max: num.parse(_pmax.text),
        N_autonomie: num.parse(_nauto.text),
        H_solaire: _hSolaire,
        V_batterie: _vbat.value,
        localisation: _loc.text,
      );
      final res = await svc.publicCalculate(input);
      ref.read(lastResultProvider.notifier).state = res;
      setState(() => _resultJson = {
        'puissance_totale (W)': res.puissance_totale,
        'capacite_batterie (Wh)': res.capacite_batterie,
        'bilan_energetique_annuel (kWh)': res.bilan_energetique_annuel,
        'cout_total (Ar)': res.cout_total,
        'nombre_panneaux': res.nombre_panneaux,
        'nombre_batteries': res.nombre_batteries,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf() async {
    final res = ref.read(lastResultProvider);
    if (res == null) return;
    final doc = await buildReport(
      title: 'Rapport de dimensionnement',
      results: _resultJson ?? {},
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'dimensionnement.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final inputStyle = const InputDecoration(border: OutlineInputBorder(), isDense: true);
    return Scaffold(
      appBar: buildSmartAppBar(context, 'Calculateur'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ligne 1
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ejour,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle.copyWith(label: const Text('Consommation journalière (Wh)')),
                    validator: (v) => (num.tryParse(v ?? '') ?? 0) > 0 ? null : 'Valeur > 0 requise',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pmax,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle.copyWith(label: const Text('Puissance max (W)')),
                    validator: (v) => (num.tryParse(v ?? '') ?? 0) > 0 ? null : 'Valeur > 0 requise',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ligne 2
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nauto,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle.copyWith(label: const Text('Jours d’autonomie')),
                    validator: (v) => (num.tryParse(v ?? '') ?? 0) > 0 ? null : 'Valeur > 0 requise',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<num>(
                    valueListenable: _vbat,
                    builder: (_, v, __) => DropdownButtonFormField<num>(
                      value: v,
                      items: const [12, 24, 48]
                          .map((e) => DropdownMenuItem(value: e, child: Text('$e V')))
                          .toList(),
                      onChanged: (x) => _vbat.value = x ?? 24,
                      decoration: inputStyle.copyWith(label: const Text('Tension batterie')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Localisation + suggestions
            TextFormField(
              controller: _loc,
              decoration: inputStyle.copyWith(
                label: const Text('Localisation'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchLocation(_loc.text),
                ),
              ),
              validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Requis',
              onChanged: (v) {
                if (v.length >= 3) _searchLocation(v);
              },
            ),
            if (_sugs.isNotEmpty) ...[
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sugs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = _sugs[i];
                    return ListTile(
                      dense: true,
                      title: Text(s['name']!),
                      onTap: () => _pickLocation(s),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Irradiation
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _hSolaire.toString(),
                    key: ValueKey(_hSolaire), // reflète l’auto-update
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputStyle.copyWith(label: const Text('Irradiation (kWh/m²/j)')),
                    onChanged: (v) => _hSolaire = double.tryParse(v) ?? _hSolaire,
                    validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : 'Valeur > 0 requise',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _searchLocation(_loc.text),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Rechercher lieu'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.calculate),
              label: const Text('Calculer'),
            ),

            const SizedBox(height: 20),
            if (_resultJson != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _resultJson!.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${e.key}: ${e.value}'),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Télécharger PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
