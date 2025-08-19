// lib/features/admin/widgets/edit_equipment_dialog.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/dio_client.dart';
import '../presentation/equipments_page.dart';

enum EditEquipmentAction { add, update, delete, none }

class EditEquipmentResult {
  final EditEquipmentAction action;
  final Equipment? item;
  final int? deletedId;
  const EditEquipmentResult._(this.action, {this.item, this.deletedId});

  factory EditEquipmentResult.add(Equipment e) =>
      EditEquipmentResult._(EditEquipmentAction.add, item: e);
  factory EditEquipmentResult.update(Equipment e) =>
      EditEquipmentResult._(EditEquipmentAction.update, item: e);
  factory EditEquipmentResult.deleted(int id) =>
      EditEquipmentResult._(EditEquipmentAction.delete, deletedId: id);
  factory EditEquipmentResult.none() => const EditEquipmentResult._(EditEquipmentAction.none);
}

class EditEquipmentDialog extends StatefulWidget {
  const EditEquipmentDialog({super.key, this.item});
  final Equipment? item;

  @override
  State<EditEquipmentDialog> createState() => _EditEquipmentDialogState();
}

class _EditEquipmentDialogState extends State<EditEquipmentDialog> {
  final Dio _dio = DioClient.instance.dio;

  // Form state
  late EquipmentCategory _type;
  final _ref = TextEditingController();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _nom = TextEditingController();
  final _prix = TextEditingController(text: '0');
  final _devise = TextEditingController(text: 'MGA');

  // champs numériques
  final _puissanceW = TextEditingController();
  final _capaciteAh = TextEditingController();
  final _tensionV = TextEditingController();
  final _vmpV = TextEditingController();
  final _vocV = TextEditingController();
  final _typeReg = ValueNotifier<String>('MPPT');
  final _courantA = TextEditingController();
  final _pvVocMax = TextEditingController();
  final _mpptVMin = TextEditingController();
  final _mpptVMax = TextEditingController();
  final _surgeW = TextEditingController();
  final _entreeDcV = TextEditingController();
  final _section = TextEditingController();
  final _ampacite = TextEditingController();

  bool _saving = false;
  bool _deleting = false;
  bool _editMode = true; // si item != null, on commence en "vue" -> _editMode=false

  @override
  void initState() {
    super.initState();
    if (widget.item == null) {
      _type = EquipmentCategory.panneau_solaire;
      _editMode = true;
    } else {
      final e = widget.item!;
      _type = e.categorie;
      _ref.text = e.reference;
      _marque.text = e.marque ?? '';
      _modele.text = e.modele ?? '';
      _nom.text = e.nomCommercial ?? '';
      _prix.text = e.prixUnitaire.toString();
      _devise.text = e.devise ?? 'MGA';
      _puissanceW.text = _numOrEmpty(e.puissanceW);
      _capaciteAh.text = _numOrEmpty(e.capaciteAh);
      _tensionV.text = _numOrEmpty(e.tensionNominaleV);
      _vmpV.text = _numOrEmpty(e.vmpV);
      _vocV.text = _numOrEmpty(e.vocV);
      _typeReg.value = e.typeRegulateur ?? 'MPPT';
      _courantA.text = _numOrEmpty(e.courantA);
      _pvVocMax.text = _numOrEmpty(e.pvVocMaxV);
      _mpptVMin.text = _numOrEmpty(e.mpptVMinV);
      _mpptVMax.text = _numOrEmpty(e.mpptVMaxV);
      _surgeW.text = _numOrEmpty(e.puissanceSurgebW);
      _entreeDcV.text = e.entreeDcV ?? '';
      _section.text = _numOrEmpty(e.sectionMm2);
      _ampacite.text = _numOrEmpty(e.ampaciteA);
      _editMode = false;
    }
  }

  @override
  void dispose() {
    _ref.dispose();
    _marque.dispose();
    _modele.dispose();
    _nom.dispose();
    _prix.dispose();
    _devise.dispose();
    _puissanceW.dispose();
    _capaciteAh.dispose();
    _tensionV.dispose();
    _vmpV.dispose();
    _vocV.dispose();
    _courantA.dispose();
    _pvVocMax.dispose();
    _mpptVMin.dispose();
    _mpptVMax.dispose();
    _surgeW.dispose();
    _entreeDcV.dispose();
    _section.dispose();
    _ampacite.dispose();
    _typeReg.dispose();
    super.dispose();
  }

  String _numOrEmpty(num? v) => v == null ? '' : v.toString();

  num? _toNum(String s) => s.trim().isEmpty ? null : num.tryParse(s.trim());

  bool get _isPanel => _type == EquipmentCategory.panneau_solaire;
  bool get _isBattery => _type == EquipmentCategory.batterie;
  bool get _isReg => _type == EquipmentCategory.regulateur;
  bool get _isInv => _type == EquipmentCategory.onduleur;
  bool get _isCable => _type == EquipmentCategory.cable;

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? Colors.green.shade700 : null),
    );
    }

  Map<String, dynamic> _buildPayload() {
    final p = <String, dynamic>{
      'categorie': _type.name,
      'reference': _ref.text.trim(),
      'marque': _marque.text.trim().isEmpty ? null : _marque.text.trim(),
      'modele': _modele.text.trim(),
      'nom_commercial': _nom.text.trim().isEmpty ? null : _nom.text.trim(),
      'prix_unitaire': int.tryParse(_prix.text.trim()) ?? 0,
      'devise': _devise.text.trim().isEmpty ? 'MGA' : _devise.text.trim(),
      'disponible': true,
    };

    if (_isPanel) {
      p['puissance_W'] = _toNum(_puissanceW.text);
      final tv = _toNum(_tensionV.text);
      if (tv != null) p['tension_nominale_V'] = tv;
      final vmp = _toNum(_vmpV.text);
      if (vmp != null) p['vmp_V'] = vmp;
      final voc = _toNum(_vocV.text);
      if (voc != null) p['voc_V'] = voc;
    }
    if (_isBattery) {
      p['capacite_Ah'] = _toNum(_capaciteAh.text);
      p['tension_nominale_V'] = _toNum(_tensionV.text);
    }
    if (_isReg) {
      p['type_regulateur'] = _typeReg.value;
      p['courant_A'] = _toNum(_courantA.text);
      final pv = _toNum(_pvVocMax.text);
      if (pv != null) p['pv_voc_max_V'] = pv;
      final mn = _toNum(_mpptVMin.text);
      if (mn != null) p['mppt_v_min_V'] = mn;
      final mx = _toNum(_mpptVMax.text);
      if (mx != null) p['mppt_v_max_V'] = mx;
    }
    if (_isInv) {
      p['puissance_W'] = _toNum(_puissanceW.text);
      final sg = _toNum(_surgeW.text);
      if (sg != null) p['puissance_surgeb_W'] = sg;
      if (_entreeDcV.text.trim().isNotEmpty) p['entree_dc_V'] = _entreeDcV.text.trim();
    }
    if (_isCable) {
      p['section_mm2'] = _toNum(_section.text);
      p['ampacite_A'] = _toNum(_ampacite.text);
    }

    // nettoie null/vides
    p.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
    return p;
  }

  bool _validate() {
    if (_ref.text.trim().isEmpty) {
      _snack('La référence est requise.');
      return false;
    }
    if (_modele.text.trim().isEmpty && _nom.text.trim().isEmpty) {
      _snack('Renseignez au moins Modèle ou Nom commercial.');
      return false;
    }
    final prix = int.tryParse(_prix.text.trim()) ?? 0;
    if (prix <= 0) {
      _snack('Prix unitaire (MGA) invalide.');
      return false;
    }
    if (_isPanel && (_puissanceW.text.trim().isEmpty)) {
      _snack('Puissance (W) requise pour un panneau.');
      return false;
    }
    if (_isBattery &&
        (_capaciteAh.text.trim().isEmpty || _tensionV.text.trim().isEmpty)) {
      _snack('Capacité (Ah) et Tension (V) requises pour une batterie.');
      return false;
    }
    if (_isReg && _courantA.text.trim().isEmpty) {
      _snack('Courant (A) requis pour un régulateur.');
      return false;
    }
    if (_isInv && _puissanceW.text.trim().isEmpty) {
      _snack('Puissance (W) requise pour un onduleur.');
      return false;
    }
    if (_isCable &&
        (_section.text.trim().isEmpty || _ampacite.text.trim().isEmpty)) {
      _snack('Section (mm²) et Ampacité (A) requises pour un câble.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final payload = _buildPayload();
      Response res;
      if (widget.item == null) {
        res = await _dio.post('/equipements/',
            data: payload, options: Options(extra: {'requiresAuth': true}));
      } else {
        res = await _dio.patch('/equipements/${widget.item!.id}/',
            data: payload, options: Options(extra: {'requiresAuth': true}));
      }
      final data = Equipment.fromJson(Map<String, dynamic>.from(res.data as Map));
      if (!mounted) return;
      Navigator.of(context).pop(
        widget.item == null
            ? EditEquipmentResult.add(data)
            : EditEquipmentResult.update(data),
      );
    } on DioException catch (e) {
      _snack('Erreur ${e.response?.statusCode ?? ''} ${e.message ?? ''}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.item == null) return;
    setState(() => _deleting = true);
    try {
      await _dio.delete('/equipements/${widget.item!.id}/',
          options: Options(extra: {'requiresAuth': true}));
      if (!mounted) return;
      Navigator.of(context).pop(EditEquipmentResult.deleted(widget.item!.id));
    } on DioException catch (e) {
      _snack('Erreur ${e.response?.statusCode ?? ''} ${e.message ?? ''}');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ⬇️⬇️⬇️ LA MÉTHODE DEMANDÉE : _grid(...) existe bien ici
  Widget _grid(List<Widget> children) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 900 ? 2 : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.2,
        children: children,
      );
    });
  }
  // ⬆️⬆️⬆️

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item == null
                            ? 'Ajouter un équipement'
                            : _editMode
                                ? 'Modifier l’équipement'
                                : 'Détails de l’équipement',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(EditEquipmentResult.none()),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // Mode vue
                if (widget.item != null && !_editMode) ...[
                  _readRow('Type', widget.item!.categorie.label),
                  _readRow('Référence', widget.item!.reference),
                  _readRow('Modèle / Nom',
                      widget.item!.modele ?? widget.item!.nomCommercial ?? '—'),
                  _readRow('Prix', '${widget.item!.prixUnitaire} Ar'),
                  const Divider(),
                ],

                // Formulaire (édition/ajout)
                if (widget.item == null || _editMode) ...[
                  _grid([
                    // Type
                    DropdownButtonFormField<EquipmentCategory>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type d’équipement',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: EquipmentCategory.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.label),
                              ))
                          .toList(),
                      onChanged: widget.item == null
                          ? (v) => setState(() => _type = v ?? _type)
                          : null, // type non modifiable en édition
                    ),
                    // Référence
                    TextFormField(
                      controller: _ref,
                      decoration: const InputDecoration(
                        labelText: 'Référence (SKU)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    // Modèle
                    TextFormField(
                      controller: _modele,
                      decoration: const InputDecoration(
                        labelText: 'Modèle*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    // Nom commercial
                    TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(
                        labelText: 'Nom commercial',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    // Marque
                    TextFormField(
                      controller: _marque,
                      decoration: const InputDecoration(
                        labelText: 'Marque',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    // Prix
                    TextFormField(
                      controller: _prix,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire (MGA)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Champs spécifiques
                  if (_isPanel) _grid([
                    TextFormField(
                      controller: _puissanceW,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puissance (W)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _tensionV,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tension nominale (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _vmpV,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vmp (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _vocV,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Voc (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ]),

                  if (_isBattery) _grid([
                    TextFormField(
                      controller: _capaciteAh,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité (Ah)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _tensionV,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tension nominale (V)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ]),

                  if (_isReg) _grid([
                    ValueListenableBuilder<String>(
                      valueListenable: _typeReg,
                      builder: (_, v, __) => DropdownButtonFormField<String>(
                        value: v,
                        items: const [
                          DropdownMenuItem(value: 'MPPT', child: Text('MPPT')),
                          DropdownMenuItem(value: 'PWM', child: Text('PWM')),
                        ],
                        onChanged: (x) => _typeReg.value = x ?? 'MPPT',
                        decoration: const InputDecoration(
                          labelText: 'Type régulateur*',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _courantA,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Courant (A)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _pvVocMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PV Voc max (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _mpptVMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'MPPT V min (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _mpptVMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'MPPT V max (V)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ]),

                  if (_isInv) _grid([
                    TextFormField(
                      controller: _puissanceW,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puissance (W)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _surgeW,
                      keyboardType: TextInputType.number,
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
                  ]),

                  if (_isCable) _grid([
                    TextFormField(
                      controller: _section,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Section (mm²)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    TextFormField(
                      controller: _ampacite,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ampacité (A)*',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.item != null && !_editMode)
                      OutlinedButton(
                        onPressed: () => setState(() => _editMode = true),
                        child: const Text('Modifier'),
                      ),
                    const Spacer(),
                    if (widget.item != null && !_editMode)
                      OutlinedButton(
                        onPressed: _deleting ? null : _delete,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: _deleting
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Supprimer'),
                      ),
                    if (widget.item == null || _editMode) ...[
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(EditEquipmentResult.none()),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving
                            ? 'Enregistrement…'
                            : (widget.item == null ? 'Ajouter' : 'Enregistrer')),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF475569), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
