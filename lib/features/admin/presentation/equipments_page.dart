// lib/features/admin/presentation/admin_equipments_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/ui/smart_app_bar.dart';
import '../../auth/providers.dart';
import '../widgets/edit_equipment_dialog.dart';

/* ========================== Modèles & helpers ========================== */

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

  IconData get icon {
    switch (this) {
      case EquipmentCategory.panneau_solaire:
        return Icons.wb_sunny_outlined;
      case EquipmentCategory.batterie:
        return Icons.battery_full;
      case EquipmentCategory.regulateur:
        return Icons.tune;
      case EquipmentCategory.onduleur:
        return Icons.power;
      case EquipmentCategory.cable:
        return Icons.cable;
      case EquipmentCategory.disjoncteur:
        return Icons.electric_bolt;
      case EquipmentCategory.parafoudre:
        return Icons.thunderstorm_outlined;
      case EquipmentCategory.support:
        return Icons.construction;
      case EquipmentCategory.boitier_jonction:
        return Icons.settings_input_component;
      case EquipmentCategory.connecteur:
        return Icons.settings_ethernet;
      case EquipmentCategory.monitoring:
        return Icons.insights;
      case EquipmentCategory.autre:
        return Icons.category_outlined;
    }
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

  // Specs
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

  // Flags / métadonnées web-aligned
  final bool disponible;
  final bool approuveDimensionnement;
  final String? createdByEmail;

  const Equipment({
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
    this.disponible = true,
    this.approuveDimensionnement = false,
    this.createdByEmail,
  });

  Equipment copyWith({
    int? id,
    EquipmentCategory? categorie,
    String? reference,
    String? marque,
    String? modele,
    String? nomCommercial,
    int? prixUnitaire,
    String? devise,
    num? puissanceW,
    num? capaciteAh,
    num? tensionNominaleV,
    num? vmpV,
    num? vocV,
    String? typeRegulateur,
    num? courantA,
    num? pvVocMaxV,
    num? mpptVMinV,
    num? mpptVMaxV,
    num? puissanceSurgebW,
    String? entreeDcV,
    num? sectionMm2,
    num? ampaciteA,
    bool? disponible,
    bool? approuveDimensionnement,
    String? createdByEmail,
  }) {
    return Equipment(
      id: id ?? this.id,
      categorie: categorie ?? this.categorie,
      reference: reference ?? this.reference,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      devise: devise ?? this.devise,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      puissanceW: puissanceW ?? this.puissanceW,
      capaciteAh: capaciteAh ?? this.capaciteAh,
      tensionNominaleV: tensionNominaleV ?? this.tensionNominaleV,
      vmpV: vmpV ?? this.vmpV,
      vocV: vocV ?? this.vocV,
      typeRegulateur: typeRegulateur ?? this.typeRegulateur,
      courantA: courantA ?? this.courantA,
      pvVocMaxV: pvVocMaxV ?? this.pvVocMaxV,
      mpptVMinV: mpptVMinV ?? this.mpptVMinV,
      mpptVMaxV: mpptVMaxV ?? this.mpptVMaxV,
      puissanceSurgebW: puissanceSurgebW ?? this.puissanceSurgebW,
      entreeDcV: entreeDcV ?? this.entreeDcV,
      sectionMm2: sectionMm2 ?? this.sectionMm2,
      ampaciteA: ampaciteA ?? this.ampaciteA,
      disponible: disponible ?? this.disponible,
      approuveDimensionnement:
          approuveDimensionnement ?? this.approuveDimensionnement,
      createdByEmail: createdByEmail ?? this.createdByEmail,
    );
  }

  factory Equipment.fromJson(Map<String, dynamic> m) {
    num? n(Object? v) {
      if (v == null) return null;
      if (v is num) return v;
      final s = '$v'.trim().replaceAll('\u00A0', '').replaceAll(' ', '');
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
      final digits = RegExp(r'[-+]?\d+');
      final match = digits.firstMatch(s);
      return match != null ? int.parse(match.group(0)!) : 0;
    }

    bool b(Object? v, {bool def = true}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes' || s == 'oui') return true;
        if (s == 'false' || s == '0' || s == 'no' || s == 'non') return false;
      }
      return def;
    }

    return Equipment(
      id: i(m['id']),
      categorie:
          EquipmentCategoryX.fromString(m['categorie']) ?? EquipmentCategory.autre,
      reference: (m['reference'] ?? '') as String,
      prixUnitaire:
          i(m['prix_unitaire'] ?? m['prixUnitaire'] ?? m['prix'] ?? m['price']),
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
      disponible: b(m['disponible'], def: true),
      approuveDimensionnement: b(m['approuve_dimensionnement'], def: false),
      createdByEmail: m['created_by_email'] as String?,
    );
  }
}

/* ================================ Page ================================ */

enum _ViewMode { tous, approuves, nonApprouves, entreprises }

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
  EquipmentCategory? _filterCat; // null => "Toutes catégories"
  _ViewMode _viewMode = _ViewMode.tous;

  // Catégories “principales” (tout le reste = Autres)
  static const Set<EquipmentCategory> _mainCats = {
    EquipmentCategory.panneau_solaire,
    EquipmentCategory.batterie,
    EquipmentCategory.regulateur,
    EquipmentCategory.onduleur,
    EquipmentCategory.cable,
  };

  String _filterLabel(EquipmentCategory? c) {
    if (c == null) return 'Toutes catégories';
    return c == EquipmentCategory.autre ? 'Autres' : c.label;
  }

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
      if (!mounted) return;
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
      // Mode de vue
      switch (_viewMode) {
        case _ViewMode.approuves:
          if (!e.approuveDimensionnement) return false;
          break;
        case _ViewMode.nonApprouves:
          if (e.approuveDimensionnement) return false;
          break;
        case _ViewMode.entreprises:
          final fromEntreprise =
              e.createdByEmail != null && !e.createdByEmail!.contains('admin');
          if (!fromEntreprise) return false;
          break;
        case _ViewMode.tous:
          break;
      }

      // Catégorie (Autres regroupe tout ce qui n’est pas _mainCats)
      final matchCat = _filterCat == null
          ? true
          : (_filterCat == EquipmentCategory.autre
              ? !_mainCats.contains(e.categorie)
              : e.categorie == _filterCat);

      // Recherche
      final inText = [
        e.reference,
        e.modele ?? '',
        e.nomCommercial ?? '',
        e.marque ?? '',
        e.createdByEmail ?? '',
        e.categorie.label,
      ].any((t) => t.toLowerCase().contains(term));

      return matchCat && (term.isEmpty || inText);
    });
  }

  /* -------------------- Actions CRUD / toggle -------------------- */

  Future<void> _openEdit({Equipment? equipment}) async {
    final result = await showDialog<EditEquipmentResult>(
      context: context,
      builder: (dialogCtx) => EditEquipmentDialog(item: equipment),
    );
    if (!mounted || result == null) return;

    switch (result.action) {
      case EditEquipmentAction.add:
        if (result.item != null) {
          setState(() => _items = [result.item!, ..._items]);
          _snack('Équipement ajouté', ok: true);
        }
        break;
      case EditEquipmentAction.update:
        if (result.item != null) {
          setState(() => _items = _items
              .map((x) => x.id == result.item!.id ? result.item! : x)
              .toList());
          _snack('Équipement modifié', ok: true);
        }
        break;
      case EditEquipmentAction.delete:
        if (result.deletedId != null) {
          setState(
            () => _items = _items.where((x) => x.id != result.deletedId).toList(),
          );
          _snack('Équipement supprimé', ok: true);
        }
        break;
      case EditEquipmentAction.none:
        break;
    }
  }

  Future<void> _toggleAvailability(Equipment e) async {
    final newStatus = !(e.disponible);
    try {
      await _dio.patch(
        '/equipements/${e.id}/',
        data: {'disponible': newStatus},
        options: Options(extra: {'requiresAuth': true}),
      );
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x.id == e.id ? x.copyWith(disponible: newStatus) : x)
            .toList();
      });
      _snack(
        newStatus
            ? 'Équipement marqué comme disponible'
            : 'Équipement marqué comme indisponible',
        ok: true,
      );
    } on DioException catch (_) {
      _snack('Erreur lors de la mise à jour de la disponibilité');
    }
  }

  Future<void> _toggleApproval(Equipment e) async {
    final newStatus = !(e.approuveDimensionnement);
    try {
      await _dio.patch(
        '/equipements/${e.id}/approve/',
        data: {'approuve_dimensionnement': newStatus},
        options: Options(extra: {'requiresAuth': true}),
      );
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) =>
                x.id == e.id ? x.copyWith(approuveDimensionnement: newStatus) : x)
            .toList();
      });
      _snack(
        newStatus
            ? 'Équipement approuvé pour le dimensionnement'
            : 'Équipement retiré du dimensionnement',
        ok: true,
      );
    } on DioException catch (_) {
      _snack('Erreur lors de la mise à jour de l’approbation');
    }
  }

  /* ------------------------------ Stats ------------------------------ */
  ({int total, int approuves, int disponibles, int entrepriseEquips}) get _stats {
    final total = _items.length;
    final approuves =
        _items.where((e) => e.approuveDimensionnement).length;
    final disponibles = _items.where((e) => e.disponible).length;
    final entrepriseEquips = _items
        .where((e) => e.createdByEmail != null && !e.createdByEmail!.contains('admin'))
        .length;
    return (total: total, approuves: approuves, disponibles: disponibles, entrepriseEquips: entrepriseEquips);
  }

  /* ------------------------------ UI ------------------------------ */

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    final stats = _stats;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Équipements'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // KPIs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _KpiPill(color: cs.primary, value: stats.total, label: 'Total'),
                            const SizedBox(width: 10),
                            _KpiPill(color: Colors.green, value: stats.approuves, label: 'Approuvés'),
                            const SizedBox(width: 10),
                            _KpiPill(color: Colors.orange, value: stats.disponibles, label: 'Disponibles'),
                            const SizedBox(width: 10),
                            _KpiPill(color: Colors.purple, value: stats.entrepriseEquips, label: 'Entreprises'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filtres
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _ViewSegmented(
                            value: _viewMode,
                            onChanged: (m) => setState(() => _viewMode = m),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher…',
                                    prefixIcon: const Icon(Icons.search),
                                    isDense: true,
                                    filled: true,
                                    fillColor: cs.surfaceVariant.withOpacity(.35),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  textInputAction: TextInputAction.search,
                                  onChanged: (v) => setState(() => _search = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterButton(
                                label: _filterLabel(_filterCat),
                                onTap: () async {
                                  final picked =
                                      await showModalBottomSheet<EquipmentCategory?>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    showDragHandle: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (_) => _CategoryPicker(
                                      selected: _filterCat,
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (picked == null && _filterCat == null) return;
                                  setState(() => _filterCat = picked);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Liste
                  if (_filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Aucun équipement à afficher')),
                    )
                  else
                    SliverList.separated(
                      itemBuilder: (_, i) {
                        final e = _filtered.elementAt(i);
                        return _EquipmentCard(
                          e: e,
                          price: _fmtMGA(e.prixUnitaire),
                          onTap: () => _openEdit(equipment: e),
                          onToggleAvailable: () => _toggleAvailability(e),
                          onToggleApproved: () => _toggleApproval(e),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: _filtered.length,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
      ),
    );
  }
}

/* =============================== Widgets =============================== */

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.color, required this.value, required this.label});
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = color.withOpacity(.12);
    final fg = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: fg.withOpacity(.9), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ViewSegmented extends StatelessWidget {
  const _ViewSegmented({required this.value, required this.onChanged});
  final _ViewMode value;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _ViewMode.values.map((m) {
          final selected = value == m;
          final label = switch (m) {
            _ViewMode.tous => 'Tous',
            _ViewMode.approuves => 'Approuvés',
            _ViewMode.nonApprouves => 'Non approuvés',
            _ViewMode.entreprises => 'Entreprises',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withOpacity(.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? cs.primary : null,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceVariant.withOpacity(.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 18),
              const SizedBox(width: 8),
              Text(label, overflow: TextOverflow.ellipsis),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picker compact SANS icônes, limité à 6 entrées + "Toutes catégories".
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected});
  final EquipmentCategory? selected;

  // Ordre voulu : Toutes + 5 principales + Autres
  static const List<EquipmentCategory?> _options = <EquipmentCategory?>[
    null,
    EquipmentCategory.panneau_solaire,
    EquipmentCategory.batterie,
    EquipmentCategory.regulateur,
    EquipmentCategory.onduleur,
    EquipmentCategory.cable,
    EquipmentCategory.autre,
  ];

  String _labelOf(EquipmentCategory? c) {
    if (c == null) return 'Toutes catégories';
    return c == EquipmentCategory.autre ? 'Autres' : c.label;
    }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.6; // évite débordement
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final opt = _options[i];
                  final isSel = opt == selected ||
                      (opt == EquipmentCategory.autre &&
                          selected == EquipmentCategory.autre);
                  return ListTile(
                    // ❌ pas d’icône
                    title: Text(_labelOf(opt)),
                    trailing: isSel ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () => Navigator.of(ctx).pop<EquipmentCategory?>(opt),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.e,
    required this.price,
    required this.onTap,
    required this.onToggleAvailable,
    required this.onToggleApproved,
  });

  final Equipment e;
  final String price;
  final VoidCallback onTap;
  final VoidCallback onToggleAvailable;
  final VoidCallback onToggleApproved;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Leading
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(e.categorie.icon, color: cs.primary),
                ),
                const SizedBox(width: 12),

                // Center
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.modele ?? e.nomCommercial ?? e.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.categorie.label} • $price',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _statusPill(
                            label: e.disponible ? 'Disponible' : 'Indispo',
                            fg: e.disponible ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                            bg: e.disponible ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          ),
                          _statusPill(
                            label: e.approuveDimensionnement ? 'Approuvé' : 'En attente',
                            fg: e.approuveDimensionnement
                                ? const Color(0xFF166534)
                                : const Color(0xFF374151),
                            bg: e.approuveDimensionnement
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFE5E7EB),
                          ),
                          if (e.createdByEmail != null)
                            _statusPill(
                              label: e.createdByEmail!.contains('admin')
                                  ? 'Admin'
                                  : e.createdByEmail!,
                              fg: e.createdByEmail!.contains('admin')
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFF334155),
                              bg: e.createdByEmail!.contains('admin')
                                  ? const Color(0xFFEDE9FE)
                                  : const Color(0xFFF1F5F9),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing actions
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: e.approuveDimensionnement
                          ? 'Retirer du dimensionnement'
                          : 'Approuver pour dimensionnement',
                      onPressed: onToggleApproved,
                      icon: Icon(
                        e.approuveDimensionnement
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color:
                            e.approuveDimensionnement ? Colors.green : cs.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: e.disponible ? 'Marquer indisponible' : 'Marquer disponible',
                      onPressed: onToggleAvailable,
                      icon: Icon(
                        e.disponible ? Icons.toggle_on : Icons.toggle_off,
                        color: e.disponible ? Colors.green : cs.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill({required String label, required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11)),
    );
  }
}
