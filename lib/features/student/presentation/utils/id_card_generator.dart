import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/student_detail.dart';

class IdCardGenerator {
  static Future<Uint8List> generate({
    required StudentDetail student,
    required String institutionName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          53.98 * PdfPageFormat.mm,
          85.60 * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey700, width: 1.5),
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header (Banner)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  color: PdfColors.blue900,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        institutionName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'STUDENT ID CARD',
                        style: pw.TextStyle(
                          color: PdfColors.amber,
                          fontSize: 5.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Avatar
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: PdfColors.grey300,
                    border: pw.Border.all(color: PdfColors.blue900, width: 1),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    student.profile.name.isNotEmpty ? student.profile.name[0] : 'S',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),

                // Student Name
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  child: pw.Text(
                    student.profile.name,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                pw.Text(
                  'ID: ${student.profile.id.length > 8 ? student.profile.id.substring(0, 8).toUpperCase() : student.profile.id.toUpperCase()}',
                  style: const pw.TextStyle(
                    fontSize: 5.5,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),

                // Info Rows
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Column(
                    children: [
                      _buildRow('Email', student.profile.email),
                      _buildRow('Phone', student.profile.phone ?? 'N/A'),
                      if (student.guardian != null)
                        _buildRow('Guardian', student.guardian!.guardianName),
                    ],
                  ),
                ),

                pw.Spacer(),

                // QR Code
                pw.Container(
                  width: 32,
                  height: 32,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'eduzio://student/${student.profile.id}',
                    drawText: false,
                  ),
                ),
                pw.SizedBox(height: 6),

                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  color: PdfColors.grey200,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Powered by Eduzio',
                    style: const pw.TextStyle(
                      fontSize: 5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 28,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 5.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 5.5,
                color: PdfColors.black,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}
