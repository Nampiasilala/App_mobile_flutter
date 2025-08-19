// lib/features/calculator/pdf/pdf_report.dart
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> buildReport({
  required String title,
  required Map<String, dynamic> results,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 16),
          ...results.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
        ],
      ),
    ),
  );
  return doc;
}
