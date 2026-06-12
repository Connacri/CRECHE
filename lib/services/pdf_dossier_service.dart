import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';

class PdfDossierService {
  // Brand Colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF52634A);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF9DB093);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF8D4D36);
  static const PdfColor lightBgColor = PdfColor.fromInt(0xFFF9F9F7);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor textMainColor = PdfColor.fromInt(0xFF212121);
  static const PdfColor textSubColor = PdfColor.fromInt(0xFF757575);

  static Future<void> generateAndPrintDossier({
    required ChildModel child,
    EnrollmentModel? enrollment,
    CourseModel? course,
    UserModel? parent,
    String? clubName,
  }) async {
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();

    // Symbols font for gender icons
    final symbolsFont = await PdfGoogleFonts.notoSansSymbols2Regular();
    final materialIcons = await PdfGoogleFonts.materialIcons();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: robotoRegular,
        bold: robotoBold,
        italic: robotoItalic,
        fontFallback: [symbolsFont],
      ),
    );

    // 1. Fetch images (Logo, Child Photo, and Documents)
    final photoProvider =
        child.photoUrl != null ? await _fetchImage(child.photoUrl!) : null;
    
    if (child.birthCertificateUrl != null) {
      debugPrint('📄 [PdfDossierService] Fetching Birth Certificate: ${child.birthCertificateUrl}');
    }
    final birthCertProvider = child.birthCertificateUrl != null
        ? await _fetchImage(child.birthCertificateUrl!)
        : null;
    if (birthCertProvider != null) {
      debugPrint('✅ [PdfDossierService] Birth Certificate loaded');
    }

    if (child.medicalCertificateUrl != null) {
      debugPrint('📄 [PdfDossierService] Fetching Medical Certificate: ${child.medicalCertificateUrl}');
    }
    final medicalCertProvider = child.medicalCertificateUrl != null
        ? await _fetchImage(child.medicalCertificateUrl!)
        : null;
    if (medicalCertProvider != null) {
      debugPrint('✅ [PdfDossierService] Medical Certificate loaded');
    }

    pw.ImageProvider? logoProvider;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon.jpg');
      logoProvider = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // PAGE 1: Designer Dossier
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoProvider, child.id, clubName),
              pw.SizedBox(height: 30),

              // PHOTO & IDENTITY
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildProfilePhoto(photoProvider, child.firstName[0]),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            '${child.firstName} ${child.lastName}'
                                .toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: textMainColor)),
                        pw.SizedBox(height: 8),
                        _buildBadge(
                          child.gender.name == 'male' ? 'GARÇON' : 'FILLE',
                          child.gender.name == 'male'
                              ? PdfColors.blue700
                              : PdfColors.pink700,
                          child.gender.name == 'male'
                              ? pw.Icon(pw.IconData(Icons.male.codePoint),
                                  font: materialIcons)
                              : pw.Icon(pw.IconData(Icons.male.codePoint),
                                  font: materialIcons),
                          materialIcons,
                        ),
                        pw.SizedBox(height: 15),
                        _buildAttribute(
                            'Né(e) le', _formatDate(child.dateOfBirth)),
                        _buildAttribute('Âge',
                            '${DateTime.now().year - child.dateOfBirth.year} ans'),
                        _buildAttribute(
                            'Classe', child.schoolGrade ?? 'Non spécifié'),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // ENROLLMENT & FINANCE
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (enrollment != null && course != null)
                    pw.Expanded(
                      child: _buildDesignerCard(
                        title: 'INSCRIPTION',
                        iconColor: accentColor,
                        content: [
                          _buildDetailRow('Cours', course.title),
                          _buildDetailRow(
                              'Date', _formatDate(enrollment.enrolledAt)),
                          _buildDetailRow(
                              'Statut', enrollment.status.displayName),
                        ],
                      ),
                    ),
                  if (enrollment != null && course != null)
                    pw.SizedBox(width: 20),
                  if (enrollment != null)
                    pw.Expanded(
                      child: _buildDesignerCard(
                        title: 'FINANCE',
                        iconColor: PdfColors.green700,
                        content: [
                          _buildDetailRow('Montant Total',
                              '${enrollment.totalAmount ?? 0} DA'),
                          _buildDetailRow('Reste à payer',
                              '${(enrollment.totalAmount ?? 0) - (enrollment.paidAmount ?? 0)} DA'),
                          _buildDetailRow(
                              'Paiement', enrollment.paymentStatus.displayName),
                        ],
                      ),
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // PARENT / GUARDIAN
              if (parent != null)
                _buildDesignerCard(
                  title: 'CONTACT PARENT / TUTEUR',
                  iconColor: primaryColor,
                  content: [
                    _buildDetailRow('Responsable', parent.name),
                    pw.Row(
                      children: [
                        pw.Expanded(
                            child: _buildDetailRow(
                                'Téléphone', parent.phoneNumber ?? '-')),
                        pw.SizedBox(width: 100),
                        pw.Expanded(
                            child: _buildDetailRow('Email', parent.email)),
                      ],
                    ),
                    _buildDetailRow('Adresse',
                        parent.location?.address ?? 'Non renseignée'),
                  ],
                ),

              pw.SizedBox(height: 20),

              // MEDICAL INFO
              _buildDesignerCard(
                title: 'DOSSIER MÉDICAL',
                iconColor: PdfColors.red700,
                content: [
                  pw.Text(
                      child.medicalInfo.additionalNotes ??
                          'Aucune mention médicale particulière.',
                      style: const pw.TextStyle(
                          fontSize: 10, color: textMainColor, lineSpacing: 2)),
                ],
              ),

              pw.Spacer(),
              _buildFooter(clubName),
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoProvider, child.id, clubName),
                pw.SizedBox(height: 20),
                _buildSectionTitle('EXTRAIT DE NAISSANCE'),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child:
                          pw.Image(birthCertProvider, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildFooter(clubName),
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoProvider, child.id, clubName),
                pw.SizedBox(height: 20),
                _buildSectionTitle('CERTIFICAT MÉDICAL'),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child:
                          pw.Image(medicalCertProvider, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildFooter(clubName),
              ],
            );
          },
        ),
      );
    }

    // Saving and Opening logic
    await _saveAndOpenFile(pdf, child);
  }

  // --- UI COMPONENTS ---

  static pw.Widget _buildHeader(
      pw.ImageProvider? logoProvider, String childId, String? clubName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoProvider != null)
              pw.Container(
                width: 40,
                height: 40,
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Image(logoProvider),
              ),
            if (clubName != null)
              pw.Text(clubName.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textSubColor)),
            pw.Text('DOSSIER INDIVIDUEL',
                style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2)),
            pw.Text('Réf: ${childId.substring(0, 8).toUpperCase()}',
                style: const pw.TextStyle(fontSize: 9, color: textSubColor)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: lightBgColor,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text('ANNÉE SCOLAIRE',
                  style: const pw.TextStyle(fontSize: 7, color: textSubColor)),
              pw.Text('${DateTime.now().year} - ${DateTime.now().year + 1}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildProfilePhoto(
      pw.ImageProvider? photoProvider, String initial) {
    return pw.Container(
      width: 120,
      height: 140,
      decoration: pw.BoxDecoration(
        color: lightBgColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: photoProvider != null
          ? pw.ClipRRect(
              horizontalRadius: 12,
              verticalRadius: 12,
              child: pw.Image(photoProvider, fit: pw.BoxFit.cover),
            )
          : pw.Center(
              child: pw.Text(initial,
                  style: pw.TextStyle(
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor)),
            ),
    );
  }

  static pw.Widget _buildFooter(String? clubName) {
    return pw.Column(
      children: [
        pw.Divider(color: borderColor),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    clubName != null
                        ? '$clubName - L\'Avenir de la Petite Enfance'
                        : 'Crèche Application LAB- L\'Avenir de la Petite Enfance',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: textMainColor)),
                pw.Text('Document certifié conforme',
                    style: pw.TextStyle(
                        fontSize: 7,
                        color: textSubColor,
                        fontStyle: pw.FontStyle.italic)),
              ],
            ),
            pw.Text('Généré le ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: textSubColor)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDesignerCard(
      {required String title,
      required List<pw.Widget> content,
      required PdfColor iconColor}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 4, height: 12, color: iconColor),
              pw.SizedBox(width: 8),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5)),
            ],
          ),
          pw.SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: textSubColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textMainColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildAttribute(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
                text: '$label : ',
                style: const pw.TextStyle(fontSize: 10, color: textSubColor)),
            pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: textMainColor)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBadge(
    String text,
    PdfColor color,
    pw.Icon symbol,
    pw.Font symbolFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color.withAlpha(0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          symbol,
          pw.SizedBox(width: 4),
          pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 1.5)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor)),
    );
  }

  // --- LOGIC HELPER METHODS ---

  static Future<void> _saveAndOpenFile(
      pw.Document pdf, ChildModel child) async {
    try {
      final bytes = await pdf.save();
      // Sanitize names for filename
      final safeLastName = child.lastName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final safeFirstName = child.firstName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final fileName =
          'Dossier_${safeLastName}_${safeFirstName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (_) => pdf.save());
        return;
      }

      Directory? directory;
      if (Platform.isWindows) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid || Platform.isIOS) {
        directory = await getDownloadsDirectory();
        directory ??= await getExternalStorageDirectory();
      }

      // Fallback to temporary directory if specifically requested folders are not accessible
      directory ??= await getTemporaryDirectory();

      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      debugPrint('✅ PDF saved and opening directly: $path');

      // Open the file directly with system default viewer
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint('❌ Error in PDF Generation/Opening: $e');
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static Future<pw.ImageProvider?> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Error fetching image for PDF: $e');
    }
    return null;
  }
}
