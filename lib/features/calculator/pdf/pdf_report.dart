// lib/features/calculator/pdf/pdf_report.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

Future<pw.Document> buildReport({
  required String title,
  required Map<String, dynamic> results,
}) async {
  final doc = pw.Document();

  // Organiser les données en sections
  final sections = _organizeDataIntoSections(results);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // En-tête du rapport
        _buildHeader(title),
        pw.SizedBox(height: 24),

        // Table des paramètres d'entrée
        if (sections['parameters'].isNotEmpty) ...[
          _buildSectionTitle('Paramètres d\'entrée'),
          pw.SizedBox(height: 8),
          _buildParametersTable(sections['parameters']),
          pw.SizedBox(height: 20),
        ],

        // Table des résultats
        if (sections['results'].isNotEmpty) ...[
          _buildSectionTitle('Résultats du dimensionnement'),
          pw.SizedBox(height: 8),
          _buildResultsTable(sections['results']),
          pw.SizedBox(height: 20),
        ],

        // Tableaux des équipements
        ...sections['equipments'].map((equipment) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(equipment['title']),
            pw.SizedBox(height: 8),
            _buildEquipmentTable(equipment['data']),
            pw.SizedBox(height: 16),
          ],
        )),

        // Pied de page
        pw.SizedBox(height: 20),
        _buildFooter(),
      ],
    ),
  );

  return doc;
}

Map<String, dynamic> _organizeDataIntoSections(Map<String, dynamic> results) {
  final parameters = <String, dynamic>{};
  final mainResults = <String, dynamic>{};
  final equipments = <Map<String, dynamic>>[];

  String? currentEquipmentTitle;
  Map<String, dynamic>? currentEquipmentData;

  for (final entry in results.entries) {
    final key = entry.key;
    final value = entry.value;

    // Ignorer les clés vides (espacement)
    if (key.isEmpty || key == ' ') continue;

    // Section principale
    if (key.startsWith('=== PARAMÈTRES')) {
      continue; // Header, on skip
    } else if (key.startsWith('=== RÉSULTATS')) {
      continue; // Header, on skip
    } else if (key.startsWith('=== ÉQUIPEMENTS')) {
      continue; // Header, on skip
    }
    // Sous-section équipement
    else if (key.startsWith('---')) {
      // Sauvegarder l'équipement précédent si il existe
      if (currentEquipmentTitle != null && currentEquipmentData != null) {
        equipments.add({
          'title': currentEquipmentTitle,
          'data': Map<String, dynamic>.from(currentEquipmentData),
        });
      }
      // Commencer un nouvel équipement
      currentEquipmentTitle = key.replaceAll('---', '').trim();
      currentEquipmentData = <String, dynamic>{};
    }
    // Données d'équipement
    else if (currentEquipmentData != null) {
      currentEquipmentData[key] = value;
    }
    // Paramètres d'entrée (avant la première section résultats)
    else if (!key.toLowerCase().contains('puissance totale') &&
             !key.toLowerCase().contains('capacité batterie') &&
             !key.toLowerCase().contains('bilan énergétique') &&
             !key.toLowerCase().contains('coût total') &&
             !key.toLowerCase().contains('nombre de')) {
      parameters[key] = value;
    }
    // Résultats principaux
    else {
      mainResults[key] = value;
    }
  }

  // Ajouter le dernier équipement
  if (currentEquipmentTitle != null && currentEquipmentData != null) {
    equipments.add({
      'title': currentEquipmentTitle,
      'data': Map<String, dynamic>.from(currentEquipmentData),
    });
  }

  return {
    'parameters': parameters,
    'results': mainResults,
    'equipments': equipments,
  };
}

pw.Widget _buildHeader(String title) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
      pw.Container(
        width: double.infinity,
        height: 2,
        color: PdfColors.blue800,
        margin: const pw.EdgeInsets.only(top: 8),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        style: pw.TextStyle(
          fontSize: 12,
          color: PdfColors.grey600,
        ),
      ),
    ],
  );
}

pw.Widget _buildSectionTitle(String title) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey200,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey800,
      ),
    ),
  );
}

pw.Widget _buildParametersTable(Map<String, dynamic> parameters) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(3),
    },
    children: [
      // En-tête
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue100),
        children: [
          _buildTableCell('Paramètre', isHeader: true),
          _buildTableCell('Valeur', isHeader: true),
        ],
      ),
      // Données
      ...parameters.entries.map((entry) => pw.TableRow(
        children: [
          _buildTableCell(entry.key),
          _buildTableCell(entry.value.toString()),
        ],
      )),
    ],
  );
}

pw.Widget _buildResultsTable(Map<String, dynamic> results) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(3),
    },
    children: [
      // En-tête
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.green100),
        children: [
          _buildTableCell('Résultat', isHeader: true),
          _buildTableCell('Valeur', isHeader: true),
        ],
      ),
      // Données
      ...results.entries.map((entry) => pw.TableRow(
        children: [
          _buildTableCell(entry.key),
          _buildTableCell(entry.value.toString()),
        ],
      )),
    ],
  );
}

pw.Widget _buildEquipmentTable(Map<String, dynamic> equipment) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400),
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(3),
    },
    children: [
      // En-tête
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.orange100),
        children: [
          _buildTableCell('Caractéristique', isHeader: true),
          _buildTableCell('Valeur', isHeader: true),
        ],
      ),
      // Données
      ...equipment.entries.map((entry) => pw.TableRow(
        children: [
          _buildTableCell(entry.key),
          _buildTableCell(entry.value.toString()),
        ],
      )),
    ],
  );
}

pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: isHeader ? 12 : 10,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader ? PdfColors.grey800 : PdfColors.grey700,
      ),
    ),
  );
}

pw.Widget _buildFooter() {
  return pw.Column(
    children: [
      pw.Container(
        width: double.infinity,
        height: 1,
        color: PdfColors.grey400,
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Rapport généré automatiquement par le calculateur solaire',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    ],
  );
}