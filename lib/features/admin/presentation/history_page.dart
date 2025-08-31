// lib/features/admin/presentation/history_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../constants/api_url.dart'; // => const String API_BASE_URL

/* -------------------------------------------------------------------------- */
/*                                   MODELS                                   */
/* -------------------------------------------------------------------------- */

class EquipmentDetail {
  final int? id;
  final String modele;
  final String? reference;
  final String? marque;
  final String? nomCommercial;
  final String? categorie;

  final num? puissanceW;
  final num? capaciteAh;
  final num? tensionV;

  // PV / câble / régulateur
  final num? sectionMm2;
  final num? ampaciteA;
  final num? vmpV;
  final num? vocV;
  final num? courantA;

  final num prixUnitaire;
  final String? devise;

  EquipmentDetail({
    this.id,
    required this.modele,
    this.reference,
    this.marque,
    this.nomCommercial,
    this.categorie,
    this.puissanceW,
    this.capaciteAh,
    this.tensionV,
    this.sectionMm2,
    this.ampaciteA,
    this.vmpV,
    this.vocV,
    this.courantA,
    required this.prixUnitaire,
    this.devise,
  });

  factory EquipmentDetail.fromJson(Map<String, dynamic> j) => EquipmentDetail(
        id: (j['id'] as num?)?.toInt(),
        modele: (j['modele'] ?? j['model'] ?? '').toString(),
        reference: j['reference']?.toString(),
        marque: j['marque']?.toString(),
        nomCommercial: (j['nom_commercial'] ?? j['nomCommercial'])?.toString(),
        categorie: j['categorie']?.toString(),
        puissanceW: j['puissance_W'] ?? j['puissanceW'],
        capaciteAh: j['capacite_Ah'] ?? j['capaciteAh'],
        tensionV: j['tension_nominale_V'] ?? j['tensionV'],
        sectionMm2: j['section_mm2'] ?? j['sectionMm2'],
        ampaciteA: j['ampacite_A'] ?? j['ampaciteA'],
        vmpV: j['vmp_V'] ?? j['vmpV'],
        vocV: j['voc_V'] ?? j['vocV'],
        courantA: j['courant_A'] ?? j['courantA'],
        prixUnitaire: (j['prix_unitaire'] ?? j['prix'] ?? 0) as num,
        devise: j['devise']?.toString(),
      );
}

class EquipementsRecommandes {
  final EquipmentDetail? panneau;
  final EquipmentDetail? batterie;
  final EquipmentDetail? regulateur;
  final EquipmentDetail? onduleur;
  final EquipmentDetail? cable;

  EquipementsRecommandes({
    this.panneau,
    this.batterie,
    this.regulateur,
    this.onduleur,
    this.cable,
  });

  factory EquipementsRecommandes.fromJson(Map<String, dynamic> j) =>
      EquipementsRecommandes(
        panneau:
            j['panneau'] != null ? EquipmentDetail.fromJson(j['panneau']) : null,
        batterie:
            j['batterie'] != null ? EquipmentDetail.fromJson(j['batterie']) : null,
        regulateur: j['regulateur'] != null
            ? EquipmentDetail.fromJson(j['regulateur'])
            : null,
        onduleur:
            j['onduleur'] != null ? EquipmentDetail.fromJson(j['onduleur']) : null,
        cable: j['cable'] != null ? EquipmentDetail.fromJson(j['cable']) : null,
      );
}

class InputDetails {
  final num eJour;
  final num pMax;
  final int nAutonomie;
  final int vBatterie;
  final String localisation;

  // Champs supplémentaires
  final num? hSolaire; // kWh/m²/j
  final num? hVersToit; // m
  final String? prioriteSelection; // "quantite" | "cout"

  InputDetails({
    required this.eJour,
    required this.pMax,
    required this.nAutonomie,
    required this.vBatterie,
    required this.localisation,
    this.hSolaire,
    this.hVersToit,
    this.prioriteSelection,
  });

  factory InputDetails.fromJson(Map<String, dynamic> j) => InputDetails(
        eJour: (j['e_jour'] ?? 0) as num,
        pMax: (j['p_max'] ?? 0) as num,
        nAutonomie: (j['n_autonomie'] ?? 0) as int,
        vBatterie: (j['v_batterie'] ?? 0) as int,
        localisation: (j['localisation'] ?? '').toString(),
        hSolaire: j['h_solaire'] as num?,
        hVersToit: j['h_vers_toit'] as num?,
        prioriteSelection: j['priorite_selection']?.toString(),
      );
}

class ResultData {
  final int id;
  final DateTime dateCalcul;
  final num puissanceTotale;
  final num capaciteBatterie;
  final num nombrePanneaux;
  final num nombreBatteries;
  final num bilanEnergetiqueAnnuel;
  final num coutTotal;
  final InputDetails? entree;
  final EquipementsRecommandes? equipements;

  // Topologies & câble
  final int? nbBattSerie;
  final int? nbBattParallele;
  final String? topologieBatterie;
  final int? nbPvSerie;
  final int? nbPvParallele;
  final String? topologiePv;
  final num? longueurCableGlobalM; // m
  final num? prixCableGlobal; // Ar

  ResultData({
    required this.id,
    required this.dateCalcul,
    required this.puissanceTotale,
    required this.capaciteBatterie,
    required this.nombrePanneaux,
    required this.nombreBatteries,
    required this.bilanEnergetiqueAnnuel,
    required this.coutTotal,
    this.entree,
    this.equipements,
    this.nbBattSerie,
    this.nbBattParallele,
    this.topologieBatterie,
    this.nbPvSerie,
    this.nbPvParallele,
    this.topologiePv,
    this.longueurCableGlobalM,
    this.prixCableGlobal,
  });

  factory ResultData.fromJson(Map<String, dynamic> j) => ResultData(
        id: j['id'] as int,
        dateCalcul: DateTime.tryParse(j['date_calcul']?.toString() ?? '') ??
            DateTime.now(),
        puissanceTotale: (j['puissance_totale'] ?? 0) as num,
        capaciteBatterie: (j['capacite_batterie'] ?? 0) as num,
        nombrePanneaux: (j['nombre_panneaux'] ?? 0) as num,
        nombreBatteries: (j['nombre_batteries'] ?? 0) as num,
        bilanEnergetiqueAnnuel:
            (j['bilan_energetique_annuel'] ?? 0) as num,
        coutTotal: (j['cout_total'] ?? 0) as num,
        entree: j['entree_details'] != null
            ? InputDetails.fromJson(j['entree_details'])
            : null,
        equipements: j['equipements_recommandes'] != null
            ? EquipementsRecommandes.fromJson(j['equipements_recommandes'])
            : null,
        nbBattSerie: (j['nb_batt_serie'] as num?)?.toInt(),
        nbBattParallele: (j['nb_batt_parallele'] as num?)?.toInt(),
        topologieBatterie: j['topologie_batterie']?.toString(),
        nbPvSerie: (j['nb_pv_serie'] as num?)?.toInt(),
        nbPvParallele: (j['nb_pv_parallele'] as num?)?.toInt(),
        topologiePv: j['topologie_pv']?.toString(),
        longueurCableGlobalM: j['longueur_cable_global_m'] as num?,
        prixCableGlobal: j['prix_cable_global'] as num?,
      );
}

/* -------------------------------------------------------------------------- */
/*                                   HELPERS                                  */
/* -------------------------------------------------------------------------- */

final _nf = NumberFormat.decimalPattern(); // locale par défaut
String _fmtDate(DateTime d) {
  try {
    // essaie fr_FR si initialisée
    return DateFormat.yMMMMd('fr_FR').format(d);
  } catch (_) {
    // fallback safe si initializeDateFormatting n'a pas encore tourné
    return DateFormat.yMMMd().format(d);
  }
}

String formatNumber(num n) => _nf.format(n);
String formatPower(num w) =>
    w >= 1000 ? '${(w / 1000).toStringAsFixed(2)} kW' : '${_nf.format(w)} W';
String formatEnergy(num wh, {bool preferKWh = false}) =>
    preferKWh || wh >= 1000
        ? '${(wh / 1000).toStringAsFixed(2)} kWh'
        : '${_nf.format(wh)} Wh';
String formatVoltage(num v) => '${_nf.format(v)} V';
String formatPrice(num n, {String currency = 'Ar'}) =>
    '${_nf.format(n)} $currency';
String formatCurrent(num a) => '${_nf.format(a)} A';
String formatLength(num m) => '${_nf.format(m)} m';

String humanStrategy(String? s) {
  switch (s) {
    case 'quantite':
      return 'Nombre minimal';
    case 'cout':
    case 'prix': // par compat
      return 'Coût minimal';
    default:
      return '—';
  }
}

/* -------------------------------------------------------------------------- */
/*                                   PAGE UI                                  */
/* -------------------------------------------------------------------------- */

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _storage = const FlutterSecureStorage();
  final _expanded = <int>{};
  final _showInputs = <int>{};
  final _showEquip = <int>{};

  List<ResultData> _items = [];
  bool _loading = true;
  String? _error;
  int? _deletingId;

  String get _api => '$API_BASE_URL/api';

  // helpers sûrs
  bool get _isActive => mounted && context.mounted;
  void _safeSnack(String msg) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getAccessToken() async {
    // essaie les deux clés pour compatibilité
    final a1 = await _storage.read(key: 'adminAccessToken');
    if (a1 != null && a1.isNotEmpty) return a1;
    final a2 = await _storage.read(key: 'accessToken');
    return a2;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getAccessToken();
      final res = await http.get(
        Uri.parse('$_api/dimensionnements/'),
        headers: _headers(token),
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      final list =
          data.map((e) => ResultData.fromJson(e as Map<String, dynamic>)).toList()
            ..sort((a, b) => b.dateCalcul.compareTo(a.dateCalcul));
      if (!_isActive) return;
      setState(() => _items = list);
    } catch (e) {
      if (!_isActive) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    setState(() => _deletingId = id);
    String? lastErr;

    Future<http.Response> _try(String url, String? token) {
      final uri = Uri.parse(url);
      debugPrint('[DELETE] $uri');
      return http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
    }

    try {
      final token = await _getAccessToken();
      final base = '$_api/dimensionnements/$id';
      final candidates = <String>[
        '$base/', // DRF le plus courant
        base, // certain routers
      ];

      for (final url in candidates) {
        try {
          final res = await _try(url, token);
          debugPrint('[DELETE ${res.statusCode}] $url body="${res.body}"');

          if (res.statusCode == 204 || res.statusCode == 200) {
            if (!_isActive) return;
            setState(() => _items.removeWhere((e) => e.id == id));
            _safeSnack('Calcul supprimé');
            return;
          }
          lastErr = 'HTTP ${res.statusCode}: ${res.body}';
        } on TimeoutException {
          lastErr = 'Timeout au serveur sur $url';
        } on Object catch (e) {
          lastErr = e.toString();
        }
      }

      throw Exception(lastErr ?? 'Suppression impossible (raison inconnue)');
    } catch (e) {
      if (_isActive) _safeSnack('Erreur suppression: $e');
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _expandAll() {
    setState(() {
      _expanded
        ..clear()
        ..addAll(_items.map((e) => e.id));
      _showInputs
        ..clear()
        ..addAll(_items.map((e) => e.id));
      _showEquip
        ..clear()
        ..addAll(_items.map((e) => e.id));
    });
  }

  void _collapseAll() {
    setState(() {
      _expanded.clear();
      _showInputs.clear();
      _showEquip.clear();
    });
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ce calcul ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                  onPressed: () =>
                      Navigator.of(ctx, rootNavigator: true).pop(false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () =>
                      Navigator.of(ctx, rootNavigator: true).pop(true),
                  child: const Text('Supprimer')),
            ],
          ),
        ) ??
        false;

    if (!_isActive) return;
    if (ok) await _delete(id);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          if (mounted) context.go('/'); // fallback si pile vide
        }
      },
      child: Scaffold(
        appBar: buildSmartAppBar(
          context,
          'Admin',
          actions: [
            IconButton(
              tooltip: 'Tout développer',
              onPressed: _items.isEmpty ? null : _expandAll,
              icon: const Icon(Icons.unfold_more),
            ),
            IconButton(
              tooltip: 'Tout réduire',
              onPressed: _items.isEmpty ? null : _collapseAll,
              icon: const Icon(Icons.unfold_less),
            ),
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur de chargement : $_error',
                    style: const TextStyle(color: Color(0xFF991B1B)),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return _EmptyState(onNew: () => context.go('/calculate'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final calc = _items[i];
        final expanded = _expanded.contains(calc.id);
        final showInputs = _showInputs.contains(calc.id);
        final showEquip = _showEquip.contains(calc.id);

        return _HistoryItem(
          data: calc,
          expanded: expanded,
          deleting: _deletingId == calc.id,
          onToggle: () {
            setState(() {
              expanded ? _expanded.remove(calc.id) : _expanded.add(calc.id);
            });
          },
          onDelete: () => _confirmDelete(calc.id),
          showInputs: showInputs,
          onToggleInputs: () {
            setState(() {
              showInputs
                  ? _showInputs.remove(calc.id)
                  : _showInputs.add(calc.id);
            });
          },
          showEquip: showEquip,
          onToggleEquip: () {
            setState(() {
              showEquip ? _showEquip.remove(calc.id) : _showEquip.add(calc.id);
            });
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  WIDGETS                                   */
/* -------------------------------------------------------------------------- */

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.data,
    required this.expanded,
    required this.deleting,
    required this.onToggle,
    required this.onDelete,
    required this.showInputs,
    required this.onToggleInputs,
    required this.showEquip,
    required this.onToggleEquip,
  });

  final ResultData data;
  final bool expanded;
  final bool deleting;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  final bool showInputs;
  final VoidCallback onToggleInputs;
  final bool showEquip;
  final VoidCallback onToggleEquip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isNarrow = c.maxWidth < 380;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // HEADER
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.chevron_right_rounded,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calcul du ${_fmtDate(data.dateCalcul)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data.entree?.localisation ?? "—"} • ${formatPrice(data.coutTotal)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Supprimer',
                          onPressed: deleting ? null : onDelete,
                          icon: deleting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),

                    // Indicateurs rapides
                    if (!expanded)
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 34, right: 6, top: 6),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          alignment: isNarrow
                              ? WrapAlignment.start
                              : WrapAlignment.end,
                          children: [
                            _Mini(
                                icon: Icons.sunny,
                                text: '${data.nombrePanneaux} panneaux'),
                            _Mini(
                                icon: Icons.battery_charging_full,
                                text: '${data.nombreBatteries} batt.'),
                            _Mini(
                                icon: Icons.attach_money,
                                text: formatPrice(data.coutTotal)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // CONTENU
            if (expanded) const Divider(height: 1),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 160),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    _Section(
                      title: 'Résultats du dimensionnement',
                      icon: Icons.assignment_turned_in_outlined,
                      child: GridView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 1.25, // <- plus haut (anti-overflow)
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        children: [
                          _MetricCard(
                            label: 'Puissance totale',
                            value: formatPower(data.puissanceTotale),
                            color: const Color(0xFF2563EB),
                            icon: Icons.solar_power_outlined,
                          ),
                          _MetricCard(
                            label: 'Capacité batterie',
                            value: formatEnergy(data.capaciteBatterie),
                            color: const Color(0xFF16A34A),
                            icon: Icons.battery_charging_full_outlined,
                          ),
                          _MetricCard(
                            label: 'Bilan annuel',
                            value: formatEnergy(
                              data.bilanEnergetiqueAnnuel,
                              preferKWh: true,
                            ),
                            color: const Color(0xFF7C3AED),
                            icon: Icons.fact_check_outlined,
                          ),
                          _MetricCard(
                            label: 'Coût total',
                            value: formatPrice(data.coutTotal),
                            color: const Color(0xFFF59E0B),
                            icon: Icons.attach_money,
                          ),
                          _MetricCard(
                            label: 'Panneaux',
                            value: formatNumber(data.nombrePanneaux),
                            color: const Color(0xFFFB923C),
                            icon: Icons.sunny,
                          ),
                          _MetricCard(
                            label: 'Batteries',
                            value: formatNumber(data.nombreBatteries),
                            color: const Color(0xFF22C55E),
                            icon: Icons.battery_charging_full,
                          ),

                          // Ajouts alignés sur page.tsx
                          if (data.equipements?.onduleur != null)
                            _MetricCard(
                              label: 'Onduleur',
                              value: (data.equipements!.onduleur!.puissanceW !=
                                      null)
                                  ? formatPower(
                                      data.equipements!.onduleur!.puissanceW!)
                                  : data.equipements!.onduleur!.modele,
                              color: const Color(0xFFFFA000),
                              icon: Icons.bolt_outlined,
                            ),
                          if (data.equipements?.regulateur != null)
                            _MetricCard(
                              label: 'Régulateur',
                              value: (data.equipements!.regulateur!.courantA !=
                                      null)
                                  ? formatCurrent(
                                      data.equipements!.regulateur!.courantA!)
                                  : data.equipements!.regulateur!.modele,
                              color: const Color(0xFF8B5CF6),
                              icon: Icons.settings_input_component,
                            ),
                          if (data.topologiePv != null || data.nbPvSerie != null)
                            _MetricCard(
                              label: 'Topologie PV',
                              value: data.topologiePv ??
                                  '${data.nbPvSerie ?? "?"}S${data.nbPvParallele ?? "?"}P',
                              color: const Color(0xFF3B82F6),
                              icon: Icons.sunny,
                            ),
                          if (data.topologieBatterie != null ||
                              data.nbBattSerie != null)
                            _MetricCard(
                              label: 'Topologie Batteries',
                              value: data.topologieBatterie ??
                                  '${data.nbBattSerie ?? "?"}S${data.nbBattParallele ?? "?"}P',
                              color: const Color(0xFF10B981),
                              icon: Icons.battery_charging_full_outlined,
                            ),
                          if (data.longueurCableGlobalM != null ||
                              data.prixCableGlobal != null)
                            _MetricCard(
                              label: 'Câblage',
                              value: [
                                if (data.longueurCableGlobalM != null)
                                  formatLength(data.longueurCableGlobalM!),
                                if (data.prixCableGlobal != null)
                                  formatPrice(data.prixCableGlobal!)
                              ].join('\n'),
                              color: const Color(0xFF9CA3AF),
                              icon: Icons.cable_outlined,
                            ),
                        ],
                      ),
                    ),

                    if (data.entree != null) ...[
                      const SizedBox(height: 12),
                      _TogglerTile(
                        isOpen: showInputs,
                        title: 'Données d’entrée',
                        icon: Icons.info_outline,
                        onToggle: onToggleInputs,
                      ),
                      if (showInputs)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _InputsGrid(entree: data.entree!),
                        ),
                    ],

                    if (data.equipements != null) ...[
                      const SizedBox(height: 8),
                      _TogglerTile(
                        isOpen: showEquip,
                        title: 'Équipements recommandés',
                        icon: Icons.settings_outlined,
                        onToggle: onToggleEquip,
                      ),
                      if (showEquip)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _EquipmentsGrid(eq: data.equipements!),
                        ),
                    ],
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: Colors.grey.shade700)),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 10),
      child,
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.22),
        ]),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TogglerTile extends StatelessWidget {
  const _TogglerTile({
    required this.isOpen,
    required this.title,
    required this.icon,
    required this.onToggle,
  });

  final bool isOpen;
  final String title;
  final IconData icon;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class _InputsGrid extends StatelessWidget {
  const _InputsGrid({required this.entree});
  final InputDetails entree;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InputTile(
          icon: Icons.bolt,
          label: 'Énergie journalière',
          value: formatEnergy(entree.eJour),
          bg: const Color(0xFFFFF7ED)),
      _InputTile(
          icon: Icons.flash_on,
          label: 'Puissance max',
          value: formatPower(entree.pMax),
          bg: const Color(0xFFFFEBEE)),
      _InputTile(
          icon: Icons.calendar_today,
          label: 'Autonomie',
          value: '${formatNumber(entree.nAutonomie)} jours',
          bg: const Color(0xFFF3E8FF)),
      _InputTile(
          icon: Icons.battery_charging_full,
          label: 'Tension batterie',
          value: formatVoltage(entree.vBatterie),
          bg: const Color(0xFFE8F5E9)),
      _InputTile(
          icon: Icons.place,
          label: 'Localisation',
          value: entree.localisation,
          bg: const Color(0xFFEFF6FF)),
    ];

    // Champs optionnels (alignés Next.js)
    if (entree.hSolaire != null) {
      tiles.add(_InputTile(
        icon: Icons.wb_sunny_outlined,
        label: 'Irradiation',
        value: '${entree.hSolaire!.toStringAsFixed(2)} kWh/m²/j',
        bg: const Color(0xFFFFF7ED),
      ));
    }
    if (entree.hVersToit != null) {
      tiles.add(_InputTile(
        icon: Icons.height,
        label: 'Hauteur vers le toit',
        value: '${_nf.format(entree.hVersToit)} m',
        bg: const Color(0xFFEFF6FF),
        hint:
            'Longueur câble estimée ≈ ${((entree.hVersToit! * 2) * 1.2).toStringAsFixed(1)} m',
      ));
    }
    if (entree.prioriteSelection != null) {
      tiles.add(_InputTile(
        icon: Icons.tune,
        label: 'Stratégie de sélection',
        value: humanStrategy(entree.prioriteSelection),
        bg: const Color(0xFFF3E8FF),
      ));
    }

    return GridView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        childAspectRatio: 3.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      children: tiles,
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: const Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ]),
          ),
        ],
      ),
    );
  }
}

class _EquipmentsGrid extends StatelessWidget {
  const _EquipmentsGrid({required this.eq});
  final EquipementsRecommandes eq;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (eq.panneau != null)
        _EquipCard(
            title: 'Panneau solaire',
            color: const Color(0xFF2563EB),
            detail: eq.panneau!,
            extra: '—'),
      if (eq.batterie != null)
        _EquipCard(
            title: 'Batterie',
            color: const Color(0xFF16A34A),
            detail: eq.batterie!,
            extra: '—'),
      if (eq.regulateur != null)
        _EquipCard(
            title: 'Régulateur',
            color: const Color(0xFF7C3AED),
            detail: eq.regulateur!,
            extra: '—'),
      if (eq.onduleur != null)
        _EquipCard(
            title: 'Onduleur',
            color: const Color(0xFFF59E0B),
            detail: eq.onduleur!,
            extra: '—'),
      if (eq.cable != null)
        _EquipCard(
            title: 'Câble',
            color: const Color(0xFF6B7280),
            detail: eq.cable!,
            extra: 'Selon installation'),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 0.95, // <- beaucoup plus haut (anti-overflow)
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) => cards[i],
    );
  }
}

class _EquipCard extends StatelessWidget {
  const _EquipCard(
      {required this.title,
      required this.color,
      required this.detail,
      required this.extra});
  final String title;
  final Color color;
  final EquipmentDetail detail;
  final String extra;

  @override
  Widget build(BuildContext context) {
    String price =
        formatPrice(detail.prixUnitaire, currency: detail.devise ?? 'Ar');
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.16),
        ]),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          _kv('Modèle', detail.modele),
          if (detail.reference != null)
            _kv('Référence', detail.reference!, mono: true),
          if (detail.puissanceW != null)
            _kv('Puissance', formatPower(detail.puissanceW!)),
          if (detail.capaciteAh != null)
            _kv('Capacité', '${_nf.format(detail.capaciteAh)} Ah'),
          if (detail.tensionV != null)
            _kv('Tension', formatVoltage(detail.tensionV!)),

          // Nouveaux champs
          if (detail.marque != null) _kv('Marque', detail.marque!),
          if (detail.nomCommercial != null)
            _kv('Nom commercial', detail.nomCommercial!),
          if (detail.courantA != null)
            _kv('Courant', formatCurrent(detail.courantA!)),
          if (detail.sectionMm2 != null || detail.ampaciteA != null)
            _kv(
              'Section / Ampacité',
              '${detail.sectionMm2 != null ? '${_nf.format(detail.sectionMm2)} mm²' : '—'} · '
              '${detail.ampaciteA != null ? formatCurrent(detail.ampaciteA!) : '—'}',
            ),
          if (detail.vmpV != null) _kv('Vmp', formatVoltage(detail.vmpV!)),
          if (detail.vocV != null) _kv('Voc', formatVoltage(detail.vocV!)),

          _kv('Prix unitaire', price, strong: true),
          const Spacer(),
          Text(
            extra,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
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
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 8),
        Text(
          v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            fontFamily: mono ? 'monospace' : null,
            color: const Color(0xFF111827),
          ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFFF3F4F6),
            child:
                Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 36),
          ),
          const SizedBox(height: 12),
          const Text('Aucun calcul enregistré',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            "Effectue un premier calcul pour voir l'historique ici.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Nouveau calcul'),
          ),
        ]),
      ),
    );
  }
}
