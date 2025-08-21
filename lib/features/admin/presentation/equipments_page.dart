import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers.dart';

// ⬇️ IMPORTANT : importe le dialog ici
import '../widgets/edit_equipment_dialog.dart';

// ----------------- Modèles & helpers -----------------
enum EquipmentCategory {
  panneau_solaire, batterie, regulateur, onduleur, cable,
  disjoncteur, parafoudre, support, boitier_jonction, connecteur, monitoring, autre,
}

extension EquipmentCategoryX on EquipmentCategory {
  String get label {
    switch (this) {
      case EquipmentCategory.panneau_solaire: return 'Panneau solaire';
      case EquipmentCategory.batterie:        return 'Batterie';
      case EquipmentCategory.regulateur:      return 'Régulateur';
      case EquipmentCategory.onduleur:        return 'Onduleur';
      case EquipmentCategory.cable:           return 'Câble';
      case EquipmentCategory.disjoncteur:     return 'Disjoncteur';
      case EquipmentCategory.parafoudre:      return 'Parafoudre';
      case EquipmentCategory.support:         return 'Support';
      case EquipmentCategory.boitier_jonction:return 'Boîtier de jonction';
      case EquipmentCategory.connecteur:      return 'Connecteur';
      case EquipmentCategory.monitoring:      return 'Monitoring';
      case EquipmentCategory.autre:           return 'Autre';
    }
  }

  static EquipmentCategory? fromString(String? v) {
    if (v == null) return null;
    return EquipmentCategory.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EquipmentCategory.autre,
    );
  }
}

class Equipment {
  final int id;
  final EquipmentCategory categorie;
  final String reference;
  final String? marque;
  final String? modele;
  final String? nomCommercial;
  final int prixUnitaire;
  final String? devise;
  final num? puissanceW, capaciteAh, tensionNominaleV, vmpV, vocV;
  final String? typeRegulateur;
  final num? courantA, pvVocMaxV, mpptVMinV, mpptVMaxV, puissanceSurgebW, sectionMm2, ampaciteA;
  final String? entreeDcV;

  Equipment({
    required this.id,
    required this.categorie,
    required this.reference,
    required this.prixUnitaire,
    this.devise,
    this.marque,
    this.modele,
    this.nomCommercial,
    this.puissanceW,
    this.capaciteAh,
    this.tensionNominaleV,
    this.vmpV,
    this.vocV,
    this.typeRegulateur,
    this.courantA,
    this.pvVocMaxV,
    this.mpptVMinV,
    this.mpptVMaxV,
    this.puissanceSurgebW,
    this.entreeDcV,
    this.sectionMm2,
    this.ampaciteA,
  });

  factory Equipment.fromJson(Map<String, dynamic> m) {
    num? _n(Object? v) => v == null ? null : (v is num ? v : num.tryParse('$v'));
    int _i(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;

    return Equipment(
      id: _i(m['id']),
      categorie: EquipmentCategoryX.fromString(m['categorie']) ?? EquipmentCategory.autre,
      reference: (m['reference'] ?? '') as String,
      prixUnitaire: _i(m['prix_unitaire']),
      devise: m['devise'] as String?,
      marque: m['marque'] as String?,
      modele: m['modele'] as String?,
      nomCommercial: m['nom_commercial'] as String?,
      puissanceW: _n(m['puissance_W']),
      capaciteAh: _n(m['capacite_Ah']),
      tensionNominaleV: _n(m['tension_nominale_V']),
      vmpV: _n(m['vmp_V']),
      vocV: _n(m['voc_V']),
      typeRegulateur: m['type_regulateur'] as String?,
      courantA: _n(m['courant_A']),
      pvVocMaxV: _n(m['pv_voc_max_V']),
      mpptVMinV: _n(m['mppt_v_min_V']),
      mpptVMaxV: _n(m['mppt_v_max_V']),
      puissanceSurgebW: _n(m['puissance_surgeb_W']),
      entreeDcV: m['entree_dc_V'] as String?,
      sectionMm2: _n(m['section_mm2']),
      ampaciteA: _n(m['ampacite_A']),
    );
  }
}

// ----------------- Page -----------------
class AdminEquipmentsPage extends ConsumerStatefulWidget {
  const AdminEquipmentsPage({super.key});
  @override
  ConsumerState<AdminEquipmentsPage> createState() => _AdminEquipmentsPageState();
}

class _AdminEquipmentsPageState extends ConsumerState<AdminEquipmentsPage> {
  final Dio _dio = DioClient.instance.dio;

  List<Equipment> _items = <Equipment>[];
  bool _loading = true;

  String _search = '';
  String _filter = 'Tous'; // 'Tous' ou EquipmentCategory.name

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _dio.get(
        '/equipements/',
        options: Options(extra: {'requiresAuth': true}),
      );

      // ⬇️ Corrige le typage: List<dynamic> -> List<Equipment>
      final List<dynamic> raw = res.data as List<dynamic>;
      final List<Equipment> data = raw
          .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() => _items = data);
    } on DioException catch (e) {
      _snack('Erreur de chargement: ${e.response?.statusCode ?? ''} ${e.message ?? ''}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? Colors.green.shade700 : null),
    );
  }

  String _fmtMGA(num n) {
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - 1 - i;
      buf.write(s[idx]);
      if ((i + 1) % 3 == 0 && i < s.length - 1) buf.write(' ');
    }
    final rev = buf.toString().split('').reversed.join();
    return '$rev Ar';
  }

  Iterable<Equipment> get _filtered {
    final term = _search.trim().toLowerCase();
    return _items.where((e) {
      final matchCat = _filter == 'Tous' ? true : e.categorie.name == _filter;
      final inText = [
        e.reference,
        e.modele ?? '',
        e.nomCommercial ?? '',
        e.categorie.label,
      ].any((t) => t.toLowerCase().contains(term));
      return matchCat && (term.isEmpty || inText);
    });
  }

  Future<void> _openEdit({Equipment? equipment}) async {
    // ⬇️ Le bon type générique est EditEquipmentResult (pas EditResult)
    final result = await showDialog<EditEquipmentResult>(
      context: context,
      builder: (_) => EditEquipmentDialog(item: equipment),
    );
    if (result == null) return;

    switch (result.action) {
      case EditEquipmentAction.add:
        if (result.item != null) {
          setState(() => _items = [result.item!, ..._items]);
          _snack('Équipement ajouté', ok: true);
        }
        break;
      case EditEquipmentAction.update:
        if (result.item != null) {
          setState(() => _items =
              _items.map((x) => x.id == result.item!.id ? result.item! : x).toList());
          _snack('Équipement modifié', ok: true);
        }
        break;
      case EditEquipmentAction.delete:
        if (result.deletedId != null) {
          setState(() => _items = _items.where((x) => x.id != result.deletedId).toList());
          _snack('Équipement supprimé', ok: true);
        }
        break;
      case EditEquipmentAction.none:
        break;
    }
  }

  // ----------------- UI mobile-first sans débordements -----------------
  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    // Basculer le FAB en "mini" si la largeur est très petite
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Scaffold(
          appBar: buildSmartAppBar(context, 'Gestion des équipements'),
          // Évite que le clavier pousse le FAB hors écran
          resizeToAvoidBottomInset: true,

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEdit(),
            icon: const Icon(Icons.add),
            label: isNarrow ? const SizedBox.shrink() : const Text('Ajouter'),
            isExtended: !isNarrow,
          ),

          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Barre de recherche + filtre
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Référence / Modèle / Catégorie…',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.search,
                                onChanged: (v) => setState(() => _search = v),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Le Dropdown ne déborde plus et ellipsera le libellé
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isDense: true,
                                  isExpanded: true,
                                  value: _filter,
                                  items: <String>[
                                    'Tous',
                                    ...EquipmentCategory.values.map((e) => e.name),
                                  ].map((v) {
                                    final label = v == 'Tous'
                                        ? 'Tous'
                                        : EquipmentCategoryX.fromString(v)!.label;
                                    return DropdownMenuItem<String>(
                                      value: v,
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  // Évite l’overflow du "selected item" dans la zone fermée
                                  selectedItemBuilder: (ctx) {
                                    return <String>[
                                      'Tous',
                                      ...EquipmentCategory.values.map((e) => e.name),
                                    ].map((v) {
                                      final label = v == 'Tous'
                                          ? 'Tous'
                                          : EquipmentCategoryX.fromString(v)!.label;
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onChanged: (v) => setState(() => _filter = v ?? 'Tous'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Liste + Pull-to-refresh
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('Aucun équipement à afficher'))
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 0),
                                  itemBuilder: (_, i) {
                                    final e = _filtered.elementAt(i);

                                    // Compose un titre compact et non‑cassant
                                    final titre = [
                                      e.reference,
                                      (e.modele ?? e.nomCommercial ?? '—'),
                                    ].where((s) => (s).trim().isNotEmpty).join(' — ');

                                    return ListTile(
                                      onTap: () => _openEdit(equipment: e),

                                      // Rend la liste plus “dense” pour mobile
                                      dense: true,
                                      visualDensity: const VisualDensity(vertical: -2),

                                      // Évite les overflows
                                      title: Text(
                                        titre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${e.categorie.label} • ${_fmtMGA(e.prixUnitaire)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Trailing compact + contrainte de largeur
                                      trailing: const Icon(Icons.chevron_right, size: 20),
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
