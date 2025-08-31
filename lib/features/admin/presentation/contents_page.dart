// lib/features/admin/presentation/contents_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/ui/smart_app_bar.dart';

/* =============================== Modèles =============================== */

class HelpContent {
  final int? id;
  final String key;
  final String title;
  final String bodyHtml;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HelpContent({
    this.id,
    required this.key,
    required this.title,
    required this.bodyHtml,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory HelpContent.fromJson(Map<String, dynamic> j) {
    String? _asStr(dynamic v) => v == null ? null : v.toString();
    DateTime? _asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return HelpContent(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
      key: _asStr(j['key']) ?? '',
      title: _asStr(j['title']) ?? '',
      bodyHtml: _asStr(j['body_html']) ?? '',
      isActive: j['is_active'] == true,
      createdAt: _asDate(j['created_at']),
      updatedAt: _asDate(j['updated_at']),
    );
  }
}

/* ========================= Champs prédéfinis ========================= */

class _PredefField {
  final String key;
  final String title;
  final String description;
  final String unit;
  final IconData icon;
  final Color color;
  final String category;
  final String placeholder;
  final String defaultHelp;

  const _PredefField({
    required this.key,
    required this.title,
    required this.description,
    required this.unit,
    required this.icon,
    required this.color,
    required this.category,
    required this.placeholder,
    required this.defaultHelp,
  });
}

// Aligne avec la version Web (ajout priorite_selection & h_vers_toit)
const _predefs = <_PredefField>[
  _PredefField(
    key: 'e_jour',
    title: 'Consommation journalière',
    description: 'Énergie consommée par jour',
    unit: 'Wh',
    icon: Icons.bolt_outlined,
    color: Color(0xFFF59E0B),
    category: 'Consommation',
    placeholder: 'Ex: 1520',
    defaultHelp:
        "Somme de l'énergie consommée par vos appareils sur 24h.\n\nExemple : 2 ampoules de 10W pendant 5h = 2 × 10 × 5 = 100Wh\n\nAstuce : Additionnez chaque appareil (puissance × durée).",
  ),
  _PredefField(
    key: 'p_max',
    title: 'Puissance maximale',
    description: 'Pic de puissance simultané',
    unit: 'W',
    icon: Icons.flash_on_outlined,
    color: Color(0xFFFB923C),
    category: 'Consommation',
    placeholder: 'Ex: 400',
    defaultHelp:
        "Puissance maximale utilisée simultanément.\n\nExemple : fer 1000W + TV 200W en même temps = 1200W\n\nImportant : Identifiez vos appareils les plus gourmands qui peuvent tourner ensemble.",
  ),
  _PredefField(
    key: 'n_autonomie',
    title: "Jours d'autonomie",
    description: 'Jours sans soleil couverts',
    unit: 'jours',
    icon: Icons.settings_outlined,
    color: Color(0xFFA78BFA),
    category: 'Configuration',
    placeholder: 'Ex: 3',
    defaultHelp:
        "Nombre de jours sans soleil pendant lesquels le système doit continuer à fonctionner.\n\nRecommandations :\n• Région ensoleillée : 2-3 jours\n• Région tempérée : 3-5 jours\n• Région peu ensoleillée : 5-7 jours",
  ),
  _PredefField(
    key: 'v_batterie',
    title: 'Tension batterie',
    description: 'Voltage du système',
    unit: 'V',
    icon: Icons.tungsten_outlined,
    color: Color(0xFF60A5FA),
    category: 'Configuration',
    placeholder: '12V, 24V ou 48V',
    defaultHelp:
        "Tension nominale du parc de batteries.\n\nOptions :\n• 12V : Petites installations (camping-car, abri)\n• 24V : Installations moyennes (maison secondaire)\n• 48V : Grandes installations (maison principale)\n\nAvantage 48V : Moins de pertes, câbles plus fins, meilleur rendement.",
  ),
  _PredefField(
    key: 'priorite_selection',
    title: 'Stratégie de sélection',
    description: 'Règle de choix des équipements',
    unit: '',
    icon: Icons.tune, // ✅ remplace l'icône inexistante rule_settings_outlined
    color: Color(0xFF8B5CF6),
    category: 'Configuration',
    placeholder: '',
    defaultHelp:
        "Stratégie appliquée à la sélection des équipements modulaires (panneaux, batteries).\n\n• Coût minimal (défaut) : minimise le coût total.\n• Nombre minimal : minimise le nombre d’unités.\n\nOn respecte d’abord le surdimensionnement maximal. Si aucune option ne respecte ce seuil, on prend la surdimension minimale puis on applique la stratégie.",
  ),
  _PredefField(
    key: 'localisation',
    title: 'Localisation',
    description: 'Position géographique',
    unit: '',
    icon: Icons.public_outlined,
    color: Color(0xFF34D399),
    category: 'Environnement',
    placeholder: 'Ex: Antananarivo',
    defaultHelp:
        "Votre localisation géographique pour estimer l'irradiation solaire.\n\nFacteurs importants :\n• Latitude\n• Climat local (nébulosité)\n• Altitude\n\nSélectionnez la ville la plus proche de votre installation.",
  ),
  _PredefField(
    key: 'h_solaire',
    title: 'Irradiation solaire',
    description: 'Énergie solaire disponible',
    unit: 'kWh/m²/j',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFFFBBF24),
    category: 'Environnement',
    placeholder: 'Ex: 4.5',
    defaultHelp:
        "Énergie solaire reçue par m² et par jour.\n\nValeurs typiques : 2.5 à 5.5 kWh/m²/j selon la région.\n\nNote : Cette valeur peut être remplie automatiquement selon la localisation.",
  ),
  _PredefField(
    key: 'h_vers_toit',
    title: 'Hauteur vers le toit',
    description: 'Distance verticale pour estimer les câbles',
    unit: 'm',
    icon: Icons.straighten_outlined,
    color: Color(0xFFF59E0B),
    category: 'Environnement',
    placeholder: 'Ex: 10',
    defaultHelp:
        "Hauteur verticale (du local technique au toit) utilisée pour estimer la longueur totale de câble.\n\nFormule : H × 2 × 1,2 (aller + retour + 20% de mou).\n\nSaisissez une valeur positive (en mètres).",
  ),
];

/* ============================ Utils simples ============================ */

String _textToHtml(String text) {
  if (text.trim().isEmpty) return '';
  return text
      .split('\n\n')
      .where((p) => p.trim().isNotEmpty)
      .map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>')
      .join();
}

String _htmlToText(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();
}

/* ============================= Controller ============================= */

class _ContentsState {
  final bool loading;
  final bool saving;
  final List<HelpContent> items;
  final String? error;

  const _ContentsState({
    this.loading = false,
    this.saving = false,
    this.items = const [],
    this.error,
  });

  _ContentsState copy({
    bool? loading,
    bool? saving,
    List<HelpContent>? items,
    String? error,
  }) =>
      _ContentsState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        items: items ?? this.items,
        error: error,
      );
}

class _ContentsController extends StateNotifier<_ContentsState> {
  _ContentsController(this._dio) : super(const _ContentsState());
  final Dio _dio;

  Future<void> load() async {
    state = state.copy(loading: true, error: null);
    try {
      final res = await _dio.get(
        '/contenus/admin/',
        options: Options(extra: {'requiresAuth': true}),
      );
      final data = res.data;
      final list = (data as List<dynamic>)
          .map((e) => HelpContent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copy(loading: false, items: list);
    } on DioException catch (e) {
      state = state.copy(
        loading: false,
        error: e.response?.data?.toString() ?? e.message ?? 'Erreur réseau',
      );
    } catch (e) {
      state = state.copy(loading: false, error: e.toString());
    }
  }

  Future<void> save({
    required String key,
    required String title,
    required String bodyText,
    required bool isActive,
  }) async {
    state = state.copy(saving: true, error: null);
    try {
      final existing = state.items.where((c) => c.key == key).toList();
      final bodyHtml = _textToHtml(bodyText);

      if (existing.isEmpty) {
        await _dio.post(
          '/contenus/admin/',
          data: {
            'key': key,
            'title': title,
            'body_html': bodyHtml,
            'is_active': isActive,
          },
          options: Options(
            extra: {'requiresAuth': true},
            headers: {'Content-Type': 'application/json'},
          ),
        );
      } else {
        await _dio.patch(
          '/contenus/admin/${Uri.encodeComponent(key)}/',
          data: {
            'title': title,
            'body_html': bodyHtml,
            'is_active': isActive,
          },
          options: Options(
            extra: {'requiresAuth': true},
            headers: {'Content-Type': 'application/json'},
          ),
        );
      }
      await load();
    } on DioException catch (e) {
      state = state.copy(
        saving: false,
        error: e.response?.data?.toString() ?? e.message ?? 'Erreur réseau',
      );
      rethrow;
    } catch (e) {
      state = state.copy(saving: false, error: e.toString());
      rethrow;
    }
    state = state.copy(saving: false);
  }
}

final _controllerProvider =
    StateNotifierProvider<_ContentsController, _ContentsState>((ref) {
  final dio = DioClient.instance.dio;
  return _ContentsController(dio)..load();
});

/* =============================== UI Page =============================== */

class ContentsPage extends ConsumerStatefulWidget {
  const ContentsPage({super.key});

  @override
  ConsumerState<ContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends ConsumerState<ContentsPage> {
  _PredefField? _editing;
  HelpContent? _editingExisting;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(_controllerProvider);
    final ctrl = ref.read(_controllerProvider.notifier);

    // groupage par catégorie
    final byCat = <String, List<_PredefField>>{};
    for (final f in _predefs) {
      byCat.putIfAbsent(f.category, () => []).add(f);
    }

    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const _TitleRow(),
        const SizedBox(height: 12),

        if (st.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ErrorBanner(
              message: st.error!,
              onRetry: ctrl.load,
            ),
          ),

        // Liste simple des cartes par catégorie
        for (final entry in byCat.entries) ...[
          _CategoryHeader(entry.key),
          const SizedBox(height: 8),
          for (final f in entry.value) ...[
            _FieldCard(
              field: f,
              configured: st.items.any((c) => c.key == f.key),
              onEdit: () {
                setState(() {
                  _editing = f;
                  _editingExisting = st.items.firstWhere(
                    (c) => c.key == f.key,
                    orElse: () => HelpContent(
                      key: f.key,
                      title: f.title,
                      bodyHtml: _textToHtml(f.defaultHelp),
                      isActive: true,
                    ),
                  );
                });
                _openEditSheet(context, ctrl);
              },
              onPreview: st.items.any((c) => c.key == f.key)
                  ? () {
                      final c = st.items.firstWhere((e) => e.key == f.key);
                      _openPreviewDialog(context, c, f);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Aide / Contenus'),
      body: Stack(
        children: [
          RefreshIndicator(onRefresh: ctrl.load, child: list),
          if (st.loading)
            const Positioned.fill(child: _FullScreenLoader(label: 'Chargement…')),
          if (st.saving)
            const Positioned.fill(child: _FullScreenLoader(label: 'Sauvegarde…')),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(
      BuildContext context, _ContentsController ctrl) async {
    if (_editing == null || _editingExisting == null) return;
    final field = _editing!;
    final ex = _editingExisting!;

    final titleCtrl =
        TextEditingController(text: ex.title.isNotEmpty ? ex.title : field.title);
    final bodyCtrl = TextEditingController(
      text: ex.bodyHtml.isNotEmpty ? _htmlToText(ex.bodyHtml) : field.defaultHelp,
    );
    bool isActive = ex.isActive;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final maxHeight = MediaQuery.of(ctx).size.height * 0.9;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                  top: 8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.id == null ? 'Configurer' : 'Modifier',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${field.title} (${field.key})',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Titre affiché',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bodyCtrl,
                        minLines: 6,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: 'Explication',
                          helperText: 'Les sauts de ligne seront convertis en HTML',
                          helperMaxLines: 2,
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (v) => setModalState(() => isActive = v),
                          ),
                          const SizedBox(width: 8),
                          const Text('Contenu actif'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final bodyText = bodyCtrl.text.trim();
                          if (title.isEmpty || bodyText.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Titre et texte requis')),
                            );
                            return;
                          }
                          try {
                            await ctrl.save(
                              key: field.key,
                              title: title,
                              bodyText: bodyText,
                              isActive: isActive,
                            );
                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ex.id == null ? 'Contenu créé' : 'Contenu mis à jour',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Échec: $e')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPreviewDialog(
      BuildContext context, HelpContent c, _PredefField field) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${field.title}${field.unit.isNotEmpty ? ' (${field.unit})' : ''}',
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            _htmlToText(c.bodyHtml).isEmpty ? field.defaultHelp : _htmlToText(c.bodyHtml),
            style: const TextStyle(height: 1.35),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

/* ================================= UI bits ================================ */

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Gestion des notices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color color = const Color(0xFF334155);
    if (title == 'Consommation') {
      icon = Icons.bolt;
      color = const Color(0xFFF59E0B);
    } else if (title == 'Configuration') {
      icon = Icons.settings;
      color = const Color(0xFFA78BFA);
    } else if (title == 'Environnement') {
      icon = Icons.public;
      color = const Color(0xFF34D399);
    }
    return Row(
      children: [
        if (icon != null) Icon(icon, color: color, size: 18),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.configured,
    required this.onEdit,
    this.onPreview,
  });

  final _PredefField field;
  final bool configured;
  final VoidCallback onEdit;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final borderColor = field.color.withOpacity(.35);
    final chipColor = configured ? const Color(0xFF16A34A) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: field.color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(field.icon, color: field.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        field.description,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  configured ? Icons.check_circle : Icons.error_outline,
                  color: chipColor,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Info clé et unité
            Text(
              'Clé : ${field.key}${field.unit.isNotEmpty ? '  •  ${field.unit}' : ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'Modifier',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                if (onPreview != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onPreview,
                    tooltip: 'Aperçu',
                    icon: const Icon(Icons.visibility, color: Color(0xFF3B82F6)),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Échec du chargement',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(.08),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
