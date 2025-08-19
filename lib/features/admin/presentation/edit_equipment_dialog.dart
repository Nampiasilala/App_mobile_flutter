// lib/features/admin/presentation/edit_equipment_dialog.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../equipments/domain/equipment_model.dart' as models;

enum EditEquipmentAction { none, add, update, delete }

class EditEquipmentResult {
  final EditEquipmentAction action;
  final models.Equipment? item;
  final int? deletedId;

  const EditEquipmentResult._(this.action, {this.item, this.deletedId});

  factory EditEquipmentResult.added(models.Equipment e) =>
      EditEquipmentResult._(EditEquipmentAction.add, item: e);

  factory EditEquipmentResult.updated(models.Equipment e) =>
      EditEquipmentResult._(EditEquipmentAction.update, item: e);

  factory EditEquipmentResult.deleted(int id) =>
      EditEquipmentResult._(EditEquipmentAction.delete, deletedId: id);

  static const none = EditEquipmentResult._(EditEquipmentAction.none);
}

enum _DialogMode { add, edit }

class EditEquipmentDialog extends StatefulWidget {
  const EditEquipmentDialog.add({super.key})
      : mode = _DialogMode.add,
        initial = null;

  const EditEquipmentDialog.edit(this.initial, {super.key})
      : mode = _DialogMode.edit;

  final _DialogMode mode;
  final models.Equipment? initial;

  @override
  State<EditEquipmentDialog> createState() => _EditEquipmentDialogState();
}

class _EditEquipmentDialogState extends State<EditEquipmentDialog> {
  final _dio = DioClient.instance.dio;

  // Champs communs
  models.Categorie _categorie = models.Categorie.panneau_solaire;
  final _reference = TextEditingController();
  final _modele = TextEditingController();
  final _nomCommercial = TextEditingController();
  final _marque = TextEditingController();
  final _prixUnitaire = TextEditingController(text: '0');
  String _devise = 'MGA';

  // Panneau / onduleur
  final _puissanceW = TextEditingController();
  final _tensionNominaleV = TextEditingController();
  final _vmpV = TextEditingController();
  final _vocV = TextEditingController();
  final _puissanceSurgebW = TextEditingController();
  final _entreeDcV = TextEditingController();

  // Batterie
  final _capaciteAh = TextEditingController();

  // Régulateur
  String _typeRegulateur = 'MPPT';
  final _courantA = TextEditingController();
  final _pvVocMaxV = TextEditingController();
  final _mpptVMinV = TextEditingController();
  final _mpptVMaxV = TextEditingController();

  // Câble
  final _sectionMm2 = TextEditingController();
  final _ampaciteA = TextEditingController();

  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == _DialogMode.edit && widget.initial != null) {
      final e = widget.initial!;
      _categorie = e.categorie;
      _reference.text = e.reference;
      _modele.text = e.modele ?? '';
      _nomCommercial.text = e.nomCommercial ?? '';
      _marque.text = e.marque ?? '';
      _prixUnitaire.text = (e.prixUnitaire).toString();
      _devise = e.devise ?? 'MGA';

      _puissanceW.text = e.puissanceW?.toString() ?? '';
      _tensionNominaleV.text = e.tensionNominaleV?.toString() ?? '';
      _vmpV.text = e.vmpV?.toString() ?? '';
      _vocV.text = e.vocV?.toString() ?? '';
      _puissanceSurgebW.text = e.puissanceSurgebW?.toString() ?? '';
      _entreeDcV.text = e.entreeDcV ?? '';

      _capaciteAh.text = e.capaciteAh?.toString() ?? '';

      _typeRegulateur = e.typeRegulateur ?? 'MPPT';
      _courantA.text = e.courantA?.toString() ?? '';
      _pvVocMaxV.text = e.pvVocMaxV?.toString() ?? '';
      _mpptVMinV.text = e.mpptVMinV?.toString() ?? '';
      _mpptVMaxV.text = e.mpptVMaxV?.toString() ?? '';

      _sectionMm2.text = e.sectionMm2?.toString() ?? '';
      _ampaciteA.text = e.ampaciteA?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    _modele.dispose();
    _nomCommercial.dispose();
    _marque.dispose();
    _prixUnitaire.dispose();
    _puissanceW.dispose();
    _tensionNominaleV.dispose();
    _vmpV.dispose();
    _vocV.dispose();
    _puissanceSurgebW.dispose();
    _entreeDcV.dispose();
    _capaciteAh.dispose();
    _courantA.dispose();
    _pvVocMaxV.dispose();
    _mpptVMinV.dispose();
    _mpptVMaxV.dispose();
    _sectionMm2.dispose();
    _ampaciteA.dispose();
    super.dispose();
  }

  num? _numOrNull(String s) => s.trim().isEmpty ? null : num.tryParse(s.trim());

  bool _validate(BuildContext context) {
    if (_reference.text.trim().isEmpty) {
      _toast(context, 'La référence est requise.');
      return false;
    }
    final prix = num.tryParse(_prixUnitaire.text.trim());
    if (prix == null || prix <= 0) {
      _toast(context, 'Prix unitaire invalide.');
      return false;
    }

    switch (_categorie) {
      case models.Categorie.panneau_solaire:
        if (_numOrNull(_puissanceW.text) == null) {
          _toast(context, 'Puissance (W) requise pour un panneau.');
          return false;
        }
        break;
      case models.Categorie.batterie:
        if (_numOrNull(_capaciteAh.text) == null ||
            _numOrNull(_tensionNominaleV.text) == null) {
          _toast(context, 'Capacité (Ah) et Tension (V) requises pour une batterie.');
          return false;
        }
        break;
      case models.Categorie.regulateur:
        if (_numOrNull(_courantA.text) == null) {
          _toast(context, 'Courant (A) requis pour un régulateur.');
          return false;
        }
        if (!['MPPT', 'PWM'].contains(_typeRegulateur)) {
          _toast(context, 'Type régulateur invalide.');
          return false;
        }
        break;
      case models.Categorie.onduleur:
        if (_numOrNull(_puissanceW.text) == null) {
          _toast(context, 'Puissance (W) requise pour un onduleur.');
          return false;
        }
        break;
      case models.Categorie.cable:
        if (_numOrNull(_sectionMm2.text) == null ||
            _numOrNull(_ampaciteA.text) == null) {
          _toast(context, 'Section (mm²) et Ampacité (A) requises pour un câble.');
          return false;
        }
        break;
      default:
        break;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate(context)) return;

    setState(() => _saving = true);
    try {
      final payload = _buildPayload();
      Response res;

      if (widget.mode == _DialogMode.add) {
        res = await _dio.post(
          '/equipements/',
          data: payload,
          options: Options(extra: {'requiresAuth': true}),
        );
      } else {
        final id = widget.initial!.id;
        res = await _dio.patch(
          '/equipements/$id/',
          data: payload,
          options: Options(extra: {'requiresAuth': true}),
        );
      }

      final data = Map<String, dynamic>.from(res.data as Map);
      final saved = models.Equipment.fromJson(data);

      if (!mounted) return;
      Navigator.of(context).pop(
        widget.mode == _DialogMode.add
            ? EditEquipmentResult.added(saved)
            : EditEquipmentResult.updated(saved),
      );
    } on DioException catch (e) {
      _toast(context, 'Erreur ${e.response?.statusCode ?? ''} : ${e.message}');
    } catch (e) {
      _toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.initial == null) return;
    setState(() => _deleting = true);
    try {
      await _dio.delete(
        '/equipements/${widget.initial!.id}/',
        options: Options(extra: {'requiresAuth': true}),
      );
      if (!mounted) return;
      Navigator.of(context).pop(EditEquipmentResult.deleted(widget.initial!.id));
    } on DioException catch (e) {
      _toast(context, 'Erreur ${e.response?.statusCode ?? ''} : ${e.message}');
    } catch (e) {
      _toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final base = <String, dynamic>{
      'categorie': _categorie.toString().split('.').last,
      'reference': _reference.text.trim(),
      'marque': _marque.text.trim().isEmpty ? null : _marque.text.trim(),
      'modele': _modele.text.trim(),
      'nom_commercial':
          _nomCommercial.text.trim().isEmpty ? null : _nomCommercial.text.trim(),
      'prix_unitaire': num.parse(_prixUnitaire.text.trim()),
      'devise': _devise,
      'puissance_W': _numOrNull(_puissanceW.text),
      'capacite_Ah': _numOrNull(_capaciteAh.text),
      'tension_nominale_V': _numOrNull(_tensionNominaleV.text),
      'vmp_V': _numOrNull(_vmpV.text),
      'voc_V': _numOrNull(_vocV.text),
      'type_regulateur':
          _categorie == models.Categorie.regulateur ? _typeRegulateur : null,
      'courant_A': _numOrNull(_courantA.text),
      'pv_voc_max_V': _numOrNull(_pvVocMaxV.text),
      'mppt_v_min_V': _numOrNull(_mpptVMinV.text),
      'mppt_v_max_V': _numOrNull(_mpptVMaxV.text),
      'puissance_surgeb_W': _numOrNull(_puissanceSurgebW.text),
      'entree_dc_V': _entreeDcV.text.trim().isEmpty ? null : _entreeDcV.text.trim(),
      'section_mm2': _numOrNull(_sectionMm2.text),
      'ampacite_A': _numOrNull(_ampaciteA.text),
    };

    base.removeWhere((_, v) => v == null || (v is String && v.isEmpty));
    return base;
  }

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.mode == _DialogMode.add
                ? 'Ajouter un équipement'
                : 'Modifier un équipement'),
            automaticallyImplyLeading: false,
            actions: [
              if (widget.mode == _DialogMode.edit)
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: _deleting ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(EditEquipmentResult.none),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _grid(
                    children: [
                      DropdownButtonFormField<models.Categorie>(
                        value: _categorie,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: models.Categorie.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(models.kCategoryLabel[c]!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _categorie = v!),
                      ),
                      TextFormField(
                        controller: _reference,
                        decoration: const InputDecoration(
                          labelText: 'Référence (SKU) *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      TextFormField(
                        controller: _modele,
                        decoration: const InputDecoration(
                          labelText: 'Modèle',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      TextFormField(
                        controller: _nomCommercial,
                        decoration: const InputDecoration(
                          labelText: 'Nom commercial',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      TextFormField(
                        controller: _marque,
                        decoration: const InputDecoration(
                          labelText: 'Marque',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prixUnitaire,
                              keyboardType:
                                  const TextInputType.numberWithOptions(signed: false, decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Prix unitaire *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _devise,
                              decoration: const InputDecoration(
                                labelText: 'Devise',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'MGA', child: Text('MGA')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                              ],
                              onChanged: (v) => setState(() => _devise = v ?? 'MGA'),
                            ),
                          ),
                        ],
                      ),

                      if (_categorie == models.Categorie.panneau_solaire ||
                          _categorie == models.Categorie.onduleur)
                        TextFormField(
                          controller: _puissanceW,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Puissance (W)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      if (_categorie == models.Categorie.panneau_solaire) ...[
                        TextFormField(
                          controller: _tensionNominaleV,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tension nominale (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _vmpV,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Vmp (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _vocV,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Voc (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      if (_categorie == models.Categorie.onduleur) ...[
                        TextFormField(
                          controller: _puissanceSurgebW,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Surge (W)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _entreeDcV,
                          decoration: const InputDecoration(
                            labelText: 'Entrée DC (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      if (_categorie == models.Categorie.batterie) ...[
                        TextFormField(
                          controller: _capaciteAh,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Capacité (Ah)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _tensionNominaleV,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tension nominale (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      if (_categorie == models.Categorie.regulateur) ...[
                        DropdownButtonFormField<String>(
                          value: _typeRegulateur,
                          decoration: const InputDecoration(
                            labelText: 'Type régulateur',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'MPPT', child: Text('MPPT')),
                            DropdownMenuItem(value: 'PWM', child: Text('PWM')),
                          ],
                          onChanged: (v) => setState(() => _typeRegulateur = v ?? 'MPPT'),
                        ),
                        TextFormField(
                          controller: _courantA,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Courant (A)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _pvVocMaxV,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'PV Voc max (V)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mpptVMinV,
                                keyboardType: const TextInputType.numberWithOptions(
                                    signed: false, decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'MPPT V min (V)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _mpptVMaxV,
                                keyboardType: const TextInputType.numberWithOptions(
                                    signed: false, decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'MPPT V max (V)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_categorie == models.Categorie.cable) ...[
                        TextFormField(
                          controller: _sectionMm2,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Section (mm²)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        TextFormField(
                          controller: _ampaciteA,
                          keyboardType:
                              const TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Ampacité (A)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.of(context).pop(EditEquipmentResult.none),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(widget.mode == _DialogMode.add ? 'Ajouter' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth >= 640 ? 2 : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.0,
          children: children,
        );
      },
    );
  }
}
