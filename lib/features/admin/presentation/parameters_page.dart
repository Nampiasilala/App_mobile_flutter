// lib/features/admin/presentation/parameters_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/smart_app_bar.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers.dart';

class ParametersPage extends ConsumerStatefulWidget {
  const ParametersPage({super.key});

  @override
  ConsumerState<ParametersPage> createState() => _ParametersPageState();
}

/* ---------------------------------- MODEL --------------------------------- */

class Parameters {
  final double nGlobal;
  final double kSecurite;
  final double dod;
  final double kDimensionnement;
  final double sMax;
  final double iSec;

  const Parameters({
    required this.nGlobal,
    required this.kSecurite,
    required this.dod,
    required this.kDimensionnement,
    required this.sMax,
    required this.iSec,
  });

  Parameters copyWith({
    double? nGlobal,
    double? kSecurite,
    double? dod,
    double? kDimensionnement,
    double? sMax,
    double? iSec,
  }) {
    return Parameters(
      nGlobal: nGlobal ?? this.nGlobal,
      kSecurite: kSecurite ?? this.kSecurite,
      dod: dod ?? this.dod,
      kDimensionnement: kDimensionnement ?? this.kDimensionnement,
      sMax: sMax ?? this.sMax,
      iSec: iSec ?? this.iSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'n_global': nGlobal,
        'k_securite': kSecurite,
        'dod': dod,
        'k_dimensionnement': kDimensionnement,
        's_max': sMax,
        'i_sec': iSec,
      };

  factory Parameters.fromJson(Map<String, dynamic> m) => Parameters(
        nGlobal: (m['n_global'] as num).toDouble(),
        kSecurite: (m['k_securite'] as num).toDouble(),
        dod: (m['dod'] as num).toDouble(),
        kDimensionnement: (m['k_dimensionnement'] as num).toDouble(),
        sMax: (m['s_max'] as num).toDouble(),
        iSec: (m['i_sec'] as num).toDouble(),
      );
}

/* --------------------------------- SERVICE -------------------------------- */

class _ParametersService {
  final Dio _dio = DioClient.instance.dio;

  Future<Parameters> fetch() async {
    final res = await _dio.get(
      '/parametres/effective/',
      // public: pas besoin d'auth
      options: Options(extra: {'requiresAuth': false}),
    );
    return Parameters.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> save(Parameters p) async {
    await _dio.put(
      '/parametres/effective/',
      data: p.toJson(),
      options: Options(extra: {'requiresAuth': true}), // protégé
    );
  }
}

/* ------------------------------- PAGE STATE ------------------------------- */

class _ParametersPageState extends ConsumerState<ParametersPage> {
  final _svc = _ParametersService();

  Parameters? _params;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  /// clé actuellement en édition
  _ParamKey? _editing;

  // map des contrôleurs pour édition
  final Map<_ParamKey, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _svc.fetch();
      _params = p;
      _seedControllers(p);
    } on DioException catch (e) {
      _error = _prettyError(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _seedControllers(Parameters p) {
    String _fmt(double v, _ParamKey k) =>
        (k == _ParamKey.dod || k == _ParamKey.sMax) ? v.toStringAsFixed(2) : v.toString();
    _controllers[_ParamKey.nGlobal] = TextEditingController(text: _fmt(p.nGlobal, _ParamKey.nGlobal));
    _controllers[_ParamKey.kSecurite] = TextEditingController(text: _fmt(p.kSecurite, _ParamKey.kSecurite));
    _controllers[_ParamKey.dod] = TextEditingController(text: _fmt(p.dod, _ParamKey.dod));
    _controllers[_ParamKey.kDimensionnement] =
        TextEditingController(text: _fmt(p.kDimensionnement, _ParamKey.kDimensionnement));
    _controllers[_ParamKey.sMax] = TextEditingController(text: _fmt(p.sMax, _ParamKey.sMax));
    _controllers[_ParamKey.iSec] = TextEditingController(text: _fmt(p.iSec, _ParamKey.iSec));
  }


    void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : null,
      ),
    );
  }





  Future<void> _save() async {
    if (_params == null) return;
    final updated = _readFromControllers();
    if (updated == null) return;

    setState(() => _saving = true);
    try {
      await _svc.save(updated);
      setState(() {
        _params = updated;
        _editing = null;
      });
      _showSnack('Paramètres sauvegardés avec succès', success: true);
    } on DioException catch (e) {
      _showSnack(_prettyError(e));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Parameters? _readFromControllers() {
    double _parse(_ParamKey k) {
      final raw = _controllers[k]!.text.replaceAll(',', '.');
      return double.tryParse(raw) ?? double.nan;
    }

    final nGlobal = _parse(_ParamKey.nGlobal);
    final kSecurite = _parse(_ParamKey.kSecurite);
    final dod = _parse(_ParamKey.dod);
    final kDim = _parse(_ParamKey.kDimensionnement);
    final sMax = _parse(_ParamKey.sMax);
    final iSec = _parse(_ParamKey.iSec);

    final vals = [nGlobal, kSecurite, dod, kDim, sMax, iSec];
    if (vals.any((v) => v.isNaN)) {
      _showSnack('Valeurs invalides. Vérifiez les champs.');
      return null;
    }

    return _params!.copyWith(
      nGlobal: nGlobal,
      kSecurite: kSecurite,
      dod: dod,
      kDimensionnement: kDim,
      sMax: sMax,
      iSec: iSec,
    );
  }

  void _cancelEdit() {
    if (_params == null) return;
    _seedControllers(_params!);
    setState(() => _editing = null);
  }

  String _prettyError(DioException e) {
    final code = e.response?.statusCode;
    if (e.response?.data is Map) {
      final m = e.response!.data as Map;
      if (m['detail'] != null) return '${m['detail']}';
    }
    return 'Erreur${code != null ? ' $code' : ''}: ${e.message ?? 'réseau'}';
  }

  @override
  Widget build(BuildContext context) {
    // garde admin
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/admin-login');
      });
    }

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Paramètres système'),
      body: _loading
          ? const _CenteredLoader(label: 'Chargement des paramètres…')
          : _error != null
              ? _ErrorCard(
                  message: _error!,
                  onRetry: _load,
                )
              : _params == null
                  ? const SizedBox.shrink()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final cards = <_ParamCardData>[
      _ParamCardData(
        keyName: _ParamKey.nGlobal,
        title: 'Rendement global',
        hint: 'Typ. 0.70 – 0.80',
        range: '0.60–0.90',
        step: '0.01',
        controller: _controllers[_ParamKey.nGlobal]!,
      ),
      _ParamCardData(
        keyName: _ParamKey.kSecurite,
        title: 'Coefficient de sécurité',
        hint: 'Typ. 1.20 – 1.40',
        range: '1.10–1.50',
        step: '0.01',
        controller: _controllers[_ParamKey.kSecurite]!,
      ),
      _ParamCardData(
        keyName: _ParamKey.dod,
        title: 'Profondeur de décharge (DoD)',
        hint: '0.50 = 50%',
        range: '0.30–0.80',
        step: '0.01',
        controller: _controllers[_ParamKey.dod]!,
        fractionDisplay: true,
      ),
      _ParamCardData(
        keyName: _ParamKey.kDimensionnement,
        title: 'Coeff. dimensionnement onduleur',
        hint: 'Typ. 1.20 – 1.40',
        range: '1.10–1.50',
        step: '0.01',
        controller: _controllers[_ParamKey.kDimensionnement]!,
      ),
      _ParamCardData(
        keyName: _ParamKey.sMax,
        title: 'Seuil de surdimensionnement (Smax)',
        hint: '0.25 = 25%',
        range: '0.00–0.50',
        step: '0.01',
        controller: _controllers[_ParamKey.sMax]!,
        fractionDisplay: true,
      ),
      _ParamCardData(
        keyName: _ParamKey.iSec,
        title: 'Marge courant régulateur (Isec)',
        hint: 'ex. 1.25',
        range: '1.00–1.50',
        step: '0.01',
        controller: _controllers[_ParamKey.iSec]!,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 1200 ? 3 : w >= 820 ? 2 : 1;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => _ParamCard(
              data: cards[i],
              isEditing: _editing == cards[i].keyName,
              onEdit: () => setState(() => _editing = cards[i].keyName),
              onCancel: _cancelEdit,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: (_editing == null || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Enregistrement…' : 'Enregistrer les modifications'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _editing == null ? null : _cancelEdit,
                icon: const Icon(Icons.close),
                label: const Text('Annuler'),
              ),
            ],
          ),
        ],
      );
    });
  }
}

/* --------------------------------- UI bits -------------------------------- */

enum _ParamKey { nGlobal, kSecurite, dod, kDimensionnement, sMax, iSec }

class _ParamCardData {
  final _ParamKey keyName;
  final String title;
  final String hint;
  final String range;
  final String step;
  final bool fractionDisplay;
  final TextEditingController controller;

  _ParamCardData({
    required this.keyName,
    required this.title,
    required this.hint,
    required this.range,
    required this.step,
    required this.controller,
    this.fractionDisplay = false,
  });
}

class _ParamCard extends StatelessWidget {
  const _ParamCard({
    required this.data,
    required this.isEditing,
    required this.onEdit,
    required this.onCancel,
  });

  final _ParamCardData data;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    String displayValue(String v) {
      final parsed = double.tryParse(v.replaceAll(',', '.'));
      if (parsed == null) return v;
      return data.fractionDisplay ? parsed.toStringAsFixed(2) : parsed.toString();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            if (isEditing)
              TextField(
                controller: data.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: data.hint,
                ),
              )
            else
              Text(
                displayValue(data.controller.text),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            const SizedBox(height: 6),
            Text('Plage conseillée : ${data.range}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: isEditing
                  ? OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler'),
                    )
                  : TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 10),
        Text(label),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        color: const Color(0xFFFFE4E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFB91C1C)),
            const SizedBox(height: 8),
            const Text('Erreur de chargement',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF7F1D1D))),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ]),
        ),
      ),
    );
  }
}
