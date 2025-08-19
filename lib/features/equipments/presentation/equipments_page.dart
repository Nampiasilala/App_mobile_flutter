// lib/features/equipments/presentation/equipments_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers.dart';

// Dialog & types de retour (ADD / UPDATE / DELETE)
import '../../admin/presentation/edit_equipment_dialog.dart'
    show EditEquipmentDialog, EditEquipmentResult, EditEquipmentAction;

// Modèle unique (enum Categorie, map kCategoryLabel, class Equipment)
import '../domain/equipment_model.dart' as models;

/* --------------------------------- Service -------------------------------- */

class EquipmentsService {
  final Dio _dio = DioClient.instance.dio;

  Future<List<models.Equipment>> fetchAll() async {
    final res = await _dio.get(
      '/equipements/',
      options: Options(extra: {'requiresAuth': true}),
    );
    // Sécuriser le typage
    final list = (res.data as List).map((e) {
      return models.Equipment.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
    return list;
  }

  Future<models.Equipment> create(Map<String, dynamic> payload) async {
    final res = await _dio.post(
      '/equipements/',
      data: payload,
      options: Options(extra: {'requiresAuth': true}),
    );
    return models.Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<models.Equipment> update(int id, Map<String, dynamic> payload) async {
    final res = await _dio.patch(
      '/equipements/$id/',
      data: payload,
      options: Options(extra: {'requiresAuth': true}),
    );
    return models.Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> delete(int id) async {
    await _dio.delete(
      '/equipements/$id/',
      options: Options(extra: {'requiresAuth': true}),
    );
  }
}

/* ---------------------------------- Page ---------------------------------- */

class AdminEquipmentsPage extends ConsumerStatefulWidget {
  const AdminEquipmentsPage({super.key});
  @override
  ConsumerState<AdminEquipmentsPage> createState() => _AdminEquipmentsPageState();
}

class _AdminEquipmentsPageState extends ConsumerState<AdminEquipmentsPage> {
  final _svc = EquipmentsService();
  final _search = TextEditingController();

  bool _loading = true;
  List<models.Equipment> _equipments = [];
  String _searchTerm = '';
  models.Categorie? _filterCategory; // null = Tous

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() {
      setState(() => _searchTerm = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final isAdmin = ref.read(authStateProvider).isAdmin;
      if (!isAdmin) {
        if (mounted) context.go('/admin-login');
        return;
      }
      final data = await _svc.fetchAll();
      if (mounted) setState(() => _equipments = data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (!mounted) return;
        context.go('/admin-login');
      } else {
        _snack('Erreur ${e.response?.statusCode ?? ''} : ${e.message}');
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green.shade700 : null),
    );
  }

  String _formatMGA(num n) {
    final s = n
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
    return '$s MGA';
  }

  List<models.Equipment> get _filtered {
    final term = _searchTerm;
    return _equipments.where((e) {
      final matchesSearch = term.isEmpty ||
          e.reference.toLowerCase().contains(term) ||
          (e.modele ?? '').toLowerCase().contains(term) ||
          (e.nomCommercial ?? '').toLowerCase().contains(term) ||
          models.kCategoryLabel[e.categorie]!.toLowerCase().contains(term);
      final matchesCat =
          _filterCategory == null || e.categorie == _filterCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  Future<void> _openAdd() async {
    final res = await showDialog<EditEquipmentResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EditEquipmentDialog.add(),
    );
    if (res == null) return;
    if (res.action == EditEquipmentAction.add && res.item != null) {
      setState(() => _equipments = [res.item!, ..._equipments]);
      _snack('Équipement ajouté', ok: true);
    }
  }

  Future<void> _openEdit(models.Equipment e) async {
    final res = await showDialog<EditEquipmentResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditEquipmentDialog.edit(e),
    );
    if (res == null) return;

    switch (res.action) {
      case EditEquipmentAction.update:
        final updated = res.item!;
        setState(() {
          _equipments =
              _equipments.map((x) => x.id == updated.id ? updated : x).toList();
        });
        _snack('Équipement modifié', ok: true);
        break;
      case EditEquipmentAction.delete:
        setState(() {
          _equipments = _equipments.where((x) => x.id != res.deletedId).toList();
        });
        _snack('Équipement supprimé', ok: true);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSmartAppBar(context, 'Gestion des équipements', actions: [
        IconButton(
          tooltip: 'Recharger',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Barre outils
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 320,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Référence / Modèle / Catégorie…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      DropdownButtonFormField<models.Categorie?>(
                        value: _filterCategory,
                        items: [
                          const DropdownMenuItem<models.Categorie?>(
                            value: null,
                            child: Text('Tous'),
                          ),
                          ...models.Categorie.values.map(
                            (c) => DropdownMenuItem<models.Categorie?>(
                              value: c,
                              child: Text(models.kCategoryLabel[c]!),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _filterCategory = v),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_alt_outlined),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _openAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tableau
                  Card(
                    elevation: 0,
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Catégorie')),
                          DataColumn(label: Text('Référence')),
                          DataColumn(label: Text('Modèle / Nom')),
                          DataColumn(label: Text('Puissance (W)')),
                          DataColumn(label: Text('Capacité (Ah)')),
                          DataColumn(label: Text('Tension (V)')),
                          DataColumn(label: Text('Courant (A)')),
                          DataColumn(label: Text('Prix (MGA)')),
                          DataColumn(label: Text('')),
                        ],
                        rows: _filtered.map((e) {
                          return DataRow(
                            cells: [
                              DataCell(_Chip(models.kCategoryLabel[e.categorie]!)),
                              DataCell(Text(e.reference)),
                              DataCell(Text(e.modele ?? e.nomCommercial ?? '—')),
                              DataCell(Text(e.puissanceW?.toString() ?? '—')),
                              DataCell(Text(e.capaciteAh?.toString() ?? '—')),
                              DataCell(Text(e.tensionNominaleV?.toString() ?? '—')),
                              DataCell(Text(e.courantA?.toString() ?? '—')),
                              DataCell(Text(_formatMGA(e.prixUnitaire))),
                              DataCell(
                                IconButton(
                                  tooltip: 'Ouvrir',
                                  onPressed: () => _openEdit(e),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: const [
                          Icon(Icons.bolt_outlined, color: Colors.black38),
                          SizedBox(height: 8),
                          Text(
                            'Aucun équipement à afficher',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
