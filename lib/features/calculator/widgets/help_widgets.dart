// ============================================================================
// 1) lib/features/calculator/widgets/help_widgets.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/calculator_models.dart';
import '../providers/help_providers.dart';

/// Petite icône d’aide qui lit calculatorHelpProvider.
/// - Affiche l’aide si la clé existe.
/// - Sinon, icône grisée + message "Aide indisponible" (fallback).
class SimpleHelpIcon extends ConsumerWidget {
  final String helpKey;
  final double size;
  final Color? color;
  final bool showWhenMissing;

  const SimpleHelpIcon({
    super.key,
    required this.helpKey,
    this.size = 18,
    this.color,
    this.showWhenMissing = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpAsync = ref.watch(calculatorHelpProvider);

    return helpAsync.when(
      data: (helpData) {
        final helpItem = helpData[helpKey];

        // Fallback si l'aide n'existe pas
        if (helpItem == null || helpItem.title.trim().isEmpty) {
          if (!showWhenMissing) return const SizedBox.shrink();
          return IconButton(
            icon: Icon(Icons.help_outline, size: size, color: Colors.grey[400]),
            tooltip: 'Aide indisponible',
            onPressed: () => _showHelpDialogFromStrings(
              context,
              'Aide indisponible',
              'Aucune aide définie pour « $helpKey ». Réessaie plus tard.',
            ),
          );
        }

        // Aide trouvée
        return IconButton(
          icon: Icon(Icons.help_outline, size: size, color: color ?? Colors.blue[600]),
          tooltip: helpItem.title,
          onPressed: () => _showHelpDialog(context, helpItem),
        );
      },
      loading: () => Icon(Icons.help_outline, size: size, color: Colors.grey[400]),
      error: (_, __) => showWhenMissing
          ? Icon(Icons.help_outline, size: size, color: Colors.grey[400])
          : const SizedBox.shrink(),
    );
  }

  // --- Dialog helpers -------------------------------------------------------

  void _showHelpDialog(BuildContext context, HelpItem helpItem) {
    _showHelpDialogFromStrings(context, helpItem.title, _htmlToPlain(helpItem.bodyHtml));
  }

  void _showHelpDialogFromStrings(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _htmlToPlain(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
