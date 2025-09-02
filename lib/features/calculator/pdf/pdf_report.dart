// lib/features/calculator/pdf/pdf_report.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PDFData {
  final Map<String, dynamic> result;
  final Map<String, dynamic> inputData;

  PDFData({required this.result, required this.inputData});
}

Future<pw.Document> buildSolarReport({
  required PDFData data,
  String title = "Rapport de Dimensionnement Photovoltaïque",
}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      header: (context) => _buildHeader(data),
      footer: (context) => _buildFooter(context),
      build: (context) => [
        pw.SizedBox(height: 20),
        
        // 1. Données d'entrée
        _buildInputDataSection(data),
        pw.SizedBox(height: 20),
        
        // 2. Résultats du dimensionnement
        _buildResultsSection(data),
        pw.SizedBox(height: 20),
        
        // 3. Équipements recommandés
        _buildEquipmentsSection(data),
        pw.SizedBox(height: 20),
        
        // 4. Topologies
        _buildTopologiesSection(data),
      ],
    ),
  );

  return doc;
}

// Header avec style identique au TypeScript
pw.Widget _buildHeader(PDFData data) {
  final now = DateTime.now();
  final location = data.inputData['localisation'] ?? 'Non spécifiée';
  
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Ligne colorée en haut
      pw.Container(
        width: double.infinity,
        height: 5,
        color: const PdfColor.fromInt(0x2980B9), // Bleu
      ),
      pw.SizedBox(height: 15),
      
      // Titre principal
      pw.Text(
        'Rapport de Dimensionnement Photovoltaïque',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0x2980B9),
        ),
      ),
      pw.SizedBox(height: 5),
      
      // Sous-titre
      pw.Text(
        'Système solaire autonome',
        style: pw.TextStyle(
          fontSize: 12,
          color: const PdfColor.fromInt(0x646464),
        ),
      ),
      pw.SizedBox(height: 8),
      
      // Ligne de séparation
      pw.Container(
        width: double.infinity,
        height: 1,
        color: const PdfColor.fromInt(0xC8C8C8),
      ),
      pw.SizedBox(height: 8),
      
      // Informations générales
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Date du rapport: ${_formatDate(now)}',
            style: pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Localisation: $location',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
    ],
  );
}

// 1. Données d'entrée
pw.Widget _buildInputDataSection(PDFData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '1. Données d\'entrée',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0x3498DB), // Bleu
        ),
      ),
      pw.SizedBox(height: 8),
      
      pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0x969696)),
        columnWidths: {
          0: const pw.FixedColumnWidth(80),
          1: const pw.FixedColumnWidth(50),
          2: const pw.FixedColumnWidth(40),
        },
        children: [
          // Header
          _buildTableRow(
            ['Paramètre', 'Valeur', 'Unité'],
            isHeader: true,
            backgroundColor: const PdfColor.fromInt(0x2980B9),
            textColor: PdfColors.white,
          ),
          
          // Data rows
          _buildTableRow([
            'Consommation journalière',
            '${data.inputData['E_jour'] ?? 0}',
            'Wh'
          ]),
          _buildTableRow([
            'Puissance maximale',
            '${data.inputData['P_max'] ?? 0}',
            'W'
          ], isAlternate: true),
          _buildTableRow([
            'Jours d\'autonomie',
            '${data.inputData['N_autonomie'] ?? 0}',
            'jours'
          ]),
          _buildTableRow([
            'Tension batterie',
            '${data.inputData['V_batterie'] ?? 0}',
            'V'
          ], isAlternate: true),
          _buildTableRow([
            'Irradiation solaire',
            '${data.inputData['H_solaire'] ?? 0}',
            'kWh/m²/j'
          ]),
          _buildTableRow([
            'Hauteur vers le toit',
            '${data.inputData['H_vers_toit'] ?? "—"}',
            'm'
          ], isAlternate: true),
          _buildTableRow([
            'Stratégie de sélection',
            _getPriorityLabel(data.inputData['priorite_selection']),
            '—'
          ]),
        ],
      ),
    ],
  );
}

// 2. Résultats du dimensionnement
pw.Widget _buildResultsSection(PDFData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '2. Résultats du dimensionnement',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0x2ECC71), // Vert
        ),
      ),
      pw.SizedBox(height: 8),
      
      pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0x969696)),
        columnWidths: {
          0: const pw.FixedColumnWidth(80),
          1: const pw.FixedColumnWidth(50),
          2: const pw.FixedColumnWidth(40),
        },
        children: [
          // Header
          _buildTableRow(
            ['Élément', 'Valeur', 'Unité'],
            isHeader: true,
            backgroundColor: const PdfColor.fromInt(0x2ECC71),
            textColor: PdfColors.white,
          ),
          
          // Data rows
          _buildTableRow([
            'Puissance totale',
            '${(data.result['puissance_totale'] ?? 0).toStringAsFixed(1)}',
            'W'
          ]),
          _buildTableRow([
            'Capacité batterie',
            '${(data.result['capacite_batterie'] ?? 0).toStringAsFixed(1)}',
            'Ah'
          ], isAlternate: true),
          _buildTableRow([
            'Bilan énergétique annuel',
            _formatEnergy(data.result['bilan_energetique_annuel'] ?? 0),
            ''
          ]),
          _buildTableRow([
            'Coût total estimé',
            _formatPrice(data.result['cout_total'] ?? 0),
            'Ar'
          ], isAlternate: true),
          _buildTableRow([
            'Nombre de panneaux',
            '${data.result['nombre_panneaux'] ?? 0}',
            'unités'
          ]),
          _buildTableRow([
            'Nombre de batteries',
            '${data.result['nombre_batteries'] ?? 0}',
            'unités'
          ], isAlternate: true),
        ],
      ),
    ],
  );
}

// 3. Équipements recommandés
pw.Widget _buildEquipmentsSection(PDFData data) {
  final equipments = data.result['equipements_recommandes'];
  if (equipments == null) return pw.SizedBox();
  
  // Calculs pour les câbles (comme dans le TypeScript)
  final lCable = _calculateCableLength(data);
  final prixCableTotal = _calculateCablePrice(data, equipments, lCable);
  
  final equipmentData = <List<String>>[];
  
  // Panneau
  if (equipments['panneau'] != null) {
    final panneau = equipments['panneau'];
    equipmentData.add([
      'Panneau',
      panneau['modele'] ?? 'N/A',
      panneau['reference'] ?? 'N/A',
      panneau['puissance_W'] != null ? '${panneau['puissance_W']} W' : 'N/A',
      _formatPrice(panneau['prix_unitaire'] ?? 0),
      '${data.result['nombre_panneaux'] ?? 0}',
    ]);
  }
  
  // Batterie
  if (equipments['batterie'] != null) {
    final batterie = equipments['batterie'];
    equipmentData.add([
      'Batterie',
      batterie['modele'] ?? 'N/A',
      batterie['reference'] ?? 'N/A',
      batterie['capacite_Ah'] != null ? '${batterie['capacite_Ah']} Ah' : 'N/A',
      _formatPrice(batterie['prix_unitaire'] ?? 0),
      '${data.result['nombre_batteries'] ?? 0}',
    ]);
  }
  
  // Régulateur
  if (equipments['regulateur'] != null) {
    final regulateur = equipments['regulateur'];
    equipmentData.add([
      'Régulateur',
      regulateur['modele'] ?? 'N/A',
      regulateur['reference'] ?? 'N/A',
      regulateur['puissance_W'] != null ? '${regulateur['puissance_W']} W' : 'MPPT / PWM',
      _formatPrice(regulateur['prix_unitaire'] ?? 0),
      '1',
    ]);
  }
  
  // Onduleur
  if (equipments['onduleur'] != null) {
    final onduleur = equipments['onduleur'];
    equipmentData.add([
      'Onduleur',
      onduleur['modele'] ?? 'N/A',
      onduleur['reference'] ?? 'N/A',
      onduleur['puissance_W'] != null ? '${onduleur['puissance_W']} W' : 'N/A',
      _formatPrice(onduleur['prix_unitaire'] ?? 0),
      '1',
    ]);
  }
  
  // Câble
  if (equipments['cable'] != null) {
    equipmentData.add([
      'Câble',
      equipments['cable']['modele'] ?? 'N/A',
      equipments['cable']['reference'] ?? 'N/A',
      lCable > 0 ? '${lCable} m' : '—',
      _formatPrice(prixCableTotal),
      lCable > 0 ? '${lCable} m' : '—',
    ]);
  }
  
  if (equipmentData.isEmpty) return pw.SizedBox();
  
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '3. Équipements recommandés',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xE67E22), // Orange
        ),
      ),
      pw.SizedBox(height: 8),
      
      pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0x969696)),
        columnWidths: {
          0: const pw.FixedColumnWidth(25),
          1: const pw.FixedColumnWidth(35),
          2: const pw.FixedColumnWidth(30),
          3: const pw.FixedColumnWidth(25),
          4: const pw.FixedColumnWidth(30),
          5: const pw.FixedColumnWidth(25),
        },
        children: [
          // Header
          _buildTableRow(
            ['Type', 'Modèle', 'Référence', 'Specs', 'Prix', 'Qté'],
            isHeader: true,
            backgroundColor: const PdfColor.fromInt(0xE67E22),
            textColor: PdfColors.white,
          ),
          
          // Data rows
          ...equipmentData.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return _buildTableRow(row, isAlternate: index % 2 == 1);
          }),
        ],
      ),
    ],
  );
}

// 4. Topologies (tableau unifié comme dans le TypeScript)
pw.Widget _buildTopologiesSection(PDFData data) {
  final hasPV = data.result['topologie_pv'] != null ||
      (data.result['nb_pv_serie'] != null && data.result['nb_pv_parallele'] != null);
  final hasBatt = data.result['topologie_batterie'] != null ||
      (data.result['nb_batt_serie'] != null && data.result['nb_batt_parallele'] != null);
  
  if (!hasPV && !hasBatt) return pw.SizedBox();
  
  final topologyData = <List<String>>[];
  
  // Données PV
  if (hasPV) {
    final configPV = data.result['topologie_pv'] ?? 
        '${data.result['nb_pv_serie'] ?? "—"}S${data.result['nb_pv_parallele'] ?? "—"}P';
    
    topologyData.add([
      'Panneaux PV',
      configPV,
      '${data.result['nb_pv_serie'] ?? "—"}',
      '${data.result['nb_pv_parallele'] ?? "—"}',
      '${data.result['nombre_panneaux'] ?? "—"}',
    ]);
  }
  
  // Données batteries
  if (hasBatt) {
    final configBatt = data.result['topologie_batterie'] ?? 
        '${data.result['nb_batt_serie'] ?? "—"}S${data.result['nb_batt_parallele'] ?? "—"}P';
    
    topologyData.add([
      'Batteries',
      configBatt,
      '${data.result['nb_batt_serie'] ?? "—"}',
      '${data.result['nb_batt_parallele'] ?? "—"}',
      '${data.result['nombre_batteries'] ?? "—"}',
    ]);
  }
  
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '4. Topologies',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0x2980B9), // Bleu
        ),
      ),
      pw.SizedBox(height: 8),
      
      pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0x969696)),
        columnWidths: {
          0: const pw.FixedColumnWidth(35),
          1: const pw.FixedColumnWidth(45),
          2: const pw.FixedColumnWidth(25),
          3: const pw.FixedColumnWidth(25),
          4: const pw.FixedColumnWidth(25),
        },
        children: [
          // Header
          _buildTableRow(
            ['Type', 'Configuration', 'Série', 'Parallèle', 'Total'],
            isHeader: true,
            backgroundColor: const PdfColor.fromInt(0x2980B9),
            textColor: PdfColors.white,
          ),
          
          // Data rows
          ...topologyData.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return _buildTableRow(row, isAlternate: index % 2 == 1);
          }),
        ],
      ),
    ],
  );
}

// Helper pour créer les lignes de tableau
pw.TableRow _buildTableRow(
  List<String> cells, {
  bool isHeader = false,
  bool isAlternate = false,
  PdfColor? backgroundColor,
  PdfColor? textColor,
}) {
  PdfColor? bgColor = backgroundColor;
  if (!isHeader && bgColor == null) {
    bgColor = isAlternate ? const PdfColor.fromInt(0xF5F5F5) : null;
  }
  
  return pw.TableRow(
    decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
    children: cells.map((cell) {
      // Truncate le texte si trop long
      final displayText = cell.length > 15 ? '${cell.substring(0, 12)}...' : cell;
      
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          displayText,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor ?? (isHeader ? PdfColors.white : PdfColors.black),
          ),
        ),
      );
    }).toList(),
  );
}

// Footer identique au TypeScript
pw.Widget _buildFooter(pw.Context context) {
  final now = DateTime.now();
  return pw.Column(
    children: [
      pw.Container(
        width: double.infinity,
        height: 1,
        color: const PdfColor.fromInt(0xC8C8C8),
      ),
      pw.SizedBox(height: 5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Rapport généré automatiquement par le Calculateur Solaire',
            style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0x808080)),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Date de génération: ${_formatDate(now)} à ${_formatTime(now)}',
            style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0x808080)),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: const PdfColor.fromInt(0x808080)),
          ),
        ],
      ),
    ],
  );
}

// Utilitaires de formatage
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatPrice(dynamic price) {
  if (price == null) return '0 Ar';
  final priceNum = price is String ? double.tryParse(price) ?? 0 : price.toDouble();
  return '${priceNum.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} Ar';
}

String _formatEnergy(dynamic energy) {
  if (energy == null) return '0 Wh';
  final energyNum = energy is String ? double.tryParse(energy) ?? 0 : energy.toDouble();
  if (energyNum >= 1000) {
    return '${(energyNum / 1000).toStringAsFixed(1)} kWh';
  }
  return '${energyNum.toStringAsFixed(1)} Wh';
}

String _getPriorityLabel(String? priority) {
  return priority == 'quantite' ? 'Nombre minimal' : 'Coût minimal';
}

int _calculateCableLength(PDFData data) {
  if (data.result['longueur_cable_global_m'] != null) {
    return (data.result['longueur_cable_global_m'] as num).toInt();
  }
  
  final hauteur = data.inputData['H_vers_toit'];
  if (hauteur != null && hauteur > 0) {
    return (hauteur * 2 * 1.2).round();
  }
  
  return 0;
}

double _calculateCablePrice(PDFData data, Map<String, dynamic> equipments, int lCable) {
  if (data.result['prix_cable_global'] != null) {
    return (data.result['prix_cable_global'] as num).toDouble();
  }
  
  final cableUnit = equipments['cable']?['prix_unitaire'];
  if (cableUnit != null && lCable > 0) {
    return cableUnit * lCable;
  }
  
  return 0.0;
}