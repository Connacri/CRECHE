import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/child_model_complete.dart';

class PdfDossierService {
  static Future<void> generateAndPrintDossier(ChildModel child) async {
    final pdf = pw.Document();

    // 1. Fetch child photo and documents
    final photoProvider = child.photoUrl != null 
        ? await _fetchImage(child.photoUrl!) 
        : null;
    final birthCertProvider = child.birthCertificateUrl != null 
        ? await _fetchImage(child.birthCertificateUrl!) 
        : null;
    final medicalCertProvider = child.medicalCertificateUrl != null 
        ? await _fetchImage(child.medicalCertificateUrl!) 
        : null;

    // PAGE 1: Profile Details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DOSSIER DE L\'ENFANT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    if (photoProvider != null)
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(photoProvider, fit: pw.BoxFit.cover),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              _buildInfoSection('IDENTITÉ', [
                'Nom: ${child.lastName}',
                'Prénom: ${child.firstName}',
                'Date de naissance: ${_formatDate(child.dateOfBirth)}',
                'Genre: ${child.gender.name == 'male' ? 'Garçon' : 'Fille'}',
              ]),
              pw.SizedBox(height: 20),
              _buildInfoSection('SCOLARITÉ', [
                'Niveau: ${child.schoolGrade ?? 'Non spécifié'}',
              ]),
              pw.SizedBox(height: 20),
              _buildInfoSection('INFORMATIONS MÉDICALES', [
                'Notes: ${child.medicalInfo.additionalNotes ?? 'Aucune'}',
              ]),
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Généré le: ${_formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: Birth Certificate
    if (birthCertProvider != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(level: 1, text: 'EXTRAIT DE NAISSANCE'),
                pw.Expanded(child: pw.Image(birthCertProvider, fit: pw.BoxFit.contain)),
              ],
            );
          },
        ),
      );
    }

    // PAGE 3: Medical Certificate
    if (medicalCertProvider != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(level: 1, text: 'CERTIFICAT MÉDICAL'),
                pw.Expanded(child: pw.Image(medicalCertProvider, fit: pw.BoxFit.contain)),
              ],
            );
          },
        ),
      );
    }

    // Print the document
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildInfoSection(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
        pw.SizedBox(height: 8),
        ...lines.map((line) => pw.Bullet(text: line)),
      ],
    );
  }

  static String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  static Future<pw.ImageProvider?> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error fetching image for PDF: $e');
    }
    return null;
  }
}
