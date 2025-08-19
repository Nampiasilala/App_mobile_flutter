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
    return HelpContent(
      id: j['id'] as int?,
      key: j['key']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      bodyHtml: j['body_html']?.toString() ?? '',
      isActive: j['is_active'] == true,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
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

const _predefs = <_PredefField>[
  _PredefField(
    key: 'e_jour',
    title: 'Consommation journalière',
    description: 'Énergie consommée par jour',
    unit: 'Wh',
    icon: Icons.bolt_outlined,
    color: Color(0xFFF59E0B), // amber/orange
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
    color: Color(0xFFFB923C), // orange
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
    color: Color(0xFFA78BFA), // purple
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
    color: Color(0xFF60A5FA), // blue
    category: 'Configuration',
    placeholder: '12V, 24V ou 48V',
    defaultHelp:
        "Tension nominale du parc de batteries.\n\nOptions :\n• 12V : Petites installations (camping-car, abri)\n• 24V : Installations moyennes (maison secondaire)\n• 48V : Grandes installations (maison principale)\n\nAvantage 48V : Moins de pertes, câbles plus fins, meilleur rendement.",
  ),
  _PredefField(
    key: 'localisation',
    title: 'Localisation',
    description: 'Position géographique',
    unit: '',
    icon: Icons.public_outlined,
    color: Color(0xFF34D399), // green
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
    color: Color(0xFFFBBF24), // amber
    category: 'Environnement',
    placeholder: 'Ex: 4.5',
    defaultHelp:
        "Énergie solaire reçue par m² et par jour.\n\nValeurs typiques : 2.5 à 5.5 kWh/m²/j selon la région.\n\nNote : Cette valeur peut être remplie automatiquement selon la localisation.",
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

    return Scaffold(
      appBar: buildSmartAppBar(context, 'Aide / Contenus'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

              for (final entry in byCat.entries) ...[
                _CategoryHeader(entry.key),
                const SizedBox(height: 8),
                _Grid(
                  children: [
                    for (final f in entry.value)
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
                                final c =
                                    st.items.firstWhere((e) => e.key == f.key);
                                _openPreviewDialog(context, c, f);
                              }
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),

          if (st.loading)
            const Positioned.fill(
              child: _FullScreenLoader(label: 'Chargement des contenus…'),
            ),
          if (st.saving)
            const Positioned.fill(
              child: _FullScreenLoader(label: 'Sauvegarde…'),
            ),
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
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${ex.id == null ? 'Configurer' : 'Modifier'} : ${field.title}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Clé : ${field.key}'),
                    trailing: IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    minLines: 8,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      labelText: 'Explication (texte simple)',
                      helperText:
                          'Les sauts de ligne seront convertis automatiquement en HTML.',
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
                      const Text('Contenu actif (visible)'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final bodyText = bodyCtrl.text.trim();
                        if (title.isEmpty || bodyText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Titre et texte requis')),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ex.id == null
                                  ? 'Contenu créé'
                                  : 'Contenu mis à jour'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Échec: $e')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
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
            'Aperçu : ${field.title}${field.unit.isNotEmpty ? ' (${field.unit})' : ''}'),
        content: SingleChildScrollView(
          child: SelectableText(
            _htmlToText(c.bodyHtml).isEmpty
                ? field.defaultHelp
                : _htmlToText(c.bodyHtml),
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
        Icon(Icons.description_outlined, color: Color(0xFF2563EB)),
        SizedBox(width: 8),
        Text(
          'Gestion des notices',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(this.title, {super.key});
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
        if (icon != null) Icon(icon, color: color),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 1100
          ? 3
          : w >= 820
              ? 2
              : 1;
      if (cols == 1) {
        return Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      }
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        children: children,
      );
    });
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ évite les hauteurs infinies
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: field.color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(field.icon, color: field.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    field.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  configured ? Icons.check_circle : Icons.error_outline,
                  color: chipColor,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              field.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569), height: 1.3),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: Text(configured ? 'Modifier' : 'Configurer'),
                  ),
                ),
                const SizedBox(width: 8),
                if (onPreview != null)
                  IconButton.filledTonal(
                    onPressed: onPreview,
                    tooltip: 'Aperçu',
                    icon: const Icon(Icons.visibility),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Clé : ${field.key}${field.unit.isNotEmpty ? '   •   ${field.unit}' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
        title: const Text('Échec du chargement'),
        subtitle: Text(message),
        trailing: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.12),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
