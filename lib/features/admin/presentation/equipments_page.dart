import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers.dart';

import '../widgets/edit_equipment_dialog.dart';

// ----------------- Modèles & helpers -----------------
enum EquipmentCategory {
  panneau_solaire,
  batterie,
  regulateur,
  onduleur,
  cable,
  disjoncteur,
  parafoudre,
  support,
  boitier_jonction,
  connecteur,
  monitoring,
  autre,
}

extension EquipmentCategoryX on EquipmentCategory {
  String get label {
    switch (this) {
      case EquipmentCategory.panneau_solaire:
        return 'Panneau solaire';
      case EquipmentCategory.batterie:
        return 'Batterie';
      case EquipmentCategory.regulateur:
        return 'Régulateur';
      case EquipmentCategory.onduleur:
        return 'Onduleur';
      case EquipmentCategory.cable:
        return 'Câble';
      case EquipmentCategory.disjoncteur:
        return 'Disjoncteur';
      case EquipmentCategory.parafoudre:
        return 'Parafoudre';
      case EquipmentCategory.support:
        return 'Support';
      case EquipmentCategory.boitier_jonction:
        return 'Boîtier de jonction';
      case EquipmentCategory.connecteur:
        return 'Connecteur';
      case EquipmentCategory.monitoring:
        return 'Monitoring';
      case EquipmentCategory.autre:
        return 'Autre';
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
  final num? courantA,
      pvVocMaxV,
      mpptVMinV,
      mpptVMaxV,
      puissanceSurgebW,
      sectionMm2,
      ampaciteA;
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
    num? n(Object? v) {
      if (v == null) return null;
      if (v is num) return v;
      final s = '$v'.trim().replaceAll('\u00A0', '').replaceAll(' ', '');
      // Remplacer la virgule par un point pour parser "150,5"
      final s2 = s.replaceAll(',', '.');
      return num.tryParse(s2);
    }

    int i(Object? v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = '$v'.trim().replaceAll('\u00A0', '').replaceAll(' ', '');
      final s2 = s.replaceAll(',', '.');
      final parsed = num.tryParse(s2);
      if (parsed != null) return parsed.toInt();

      // Dernier recours : retirer tout sauf chiffres et signes
      final digits = RegExp(r'[-+]?\d+');
      final match = digits.firstMatch(s);
      return match != null ? int.parse(match.group(0)!) : 0;
    }

    return Equipment(
      id: i(m['id']),
      categorie:
          EquipmentCategoryX.fromString(m['categorie']) ??
          EquipmentCategory.autre,
      reference: (m['reference'] ?? '') as String,
      // Accepte plusieurs variantes de clé
      prixUnitaire: i(
        m['prix_unitaire'] ?? m['prixUnitaire'] ?? m['prix'] ?? m['price'],
      ),
      devise: m['devise'] as String?,
      marque: m['marque'] as String?,
      modele: m['modele'] as String?,
      nomCommercial: m['nom_commercial'] as String?,
      puissanceW: n(m['puissance_W']),
      capaciteAh: n(m['capacite_Ah']),
      tensionNominaleV: n(m['tension_nominale_V']),
      vmpV: n(m['vmp_V']),
      vocV: n(m['voc_V']),
      typeRegulateur: m['type_regulateur'] as String?,
      courantA: n(m['courant_A']),
      pvVocMaxV: n(m['pv_voc_max_V']),
      mpptVMinV: n(m['mppt_v_min_V']),
      mpptVMaxV: n(m['mppt_v_max_V']),
      puissanceSurgebW: n(m['puissance_surgeb_W']),
      entreeDcV: m['entree_dc_V'] as String?,
      sectionMm2: n(m['section_mm2']),
      ampaciteA: n(m['ampacite_A']),
    );
  }
}

// ----------------- Page -----------------
class AdminEquipmentsPage extends ConsumerStatefulWidget {
  const AdminEquipmentsPage({super.key});
  @override
  ConsumerState<AdminEquipmentsPage> createState() =>
      _AdminEquipmentsPageState();
}

class _AdminEquipmentsPageState extends ConsumerState<AdminEquipmentsPage> {
  final Dio _dio = DioClient.instance.dio;

  List<Equipment> _items = <Equipment>[];
  bool _loading = true;

  String _search = '';
  String _filter = 'Tous';

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

      final List<dynamic> raw = res.data as List<dynamic>;
      final List<Equipment> data = raw
          .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() => _items = data);
    } on DioException catch (e) {
      _snack(
        'Erreur de chargement: ${e.response?.statusCode ?? ''} ${e.message ?? ''}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: ok ? Colors.green.shade700 : null,
      ),
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
          setState(
            () => _items = _items
                .map((x) => x.id == result.item!.id ? result.item! : x)
                .toList(),
          );
          _snack('Équipement modifié', ok: true);
        }
        break;
      case EditEquipmentAction.delete:
        if (result.deletedId != null) {
          setState(
            () =>
                _items = _items.where((x) => x.id != result.deletedId).toList(),
          );
          _snack('Équipement supprimé', ok: true);
        }
        break;
      case EditEquipmentAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Équipements'),
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Barre de recherche et filtre (layout vertical pour mobile)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Recherche
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Rechercher…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.search,
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 8),
                        // Filtre catégorie
                        DropdownButtonFormField<String>(
                          value: _filter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.filter_list),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              <String>[
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (v) =>
                              setState(() => _filter = v ?? 'Tous'),
                        ),
                      ],
                    ),
                  ),

                  // Liste des équipements
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Aucun équipement à afficher'),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final e = _filtered.elementAt(i);
                                final titre =
                                    e.modele ?? e.nomCommercial ?? e.reference;

                                return ListTile(
                                  onTap: () => _openEdit(equipment: e),
                                  dense: true,
                                  isThreeLine: e.reference.isNotEmpty,
                                  title: Text(
                                    e.modele ?? e.nomCommercial ?? e.reference,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${e.categorie.label} • ${_fmtMGA(e.prixUnitaire)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (e.reference.isNotEmpty)
                                        Text(
                                          'Réf. ${e.reference}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
