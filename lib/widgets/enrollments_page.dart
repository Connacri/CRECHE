import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../services/pdf_dossier_service.dart';
import 'glass_card.dart';
import 'child_profile_dialog.dart';

class EnrollmentsPage extends StatefulWidget {
  const EnrollmentsPage({super.key});

  @override
  State<EnrollmentsPage> createState() => _EnrollmentsPageState();
}

class _EnrollmentsPageState extends State<EnrollmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProviderV2>();
      if (auth.currentUser != null) {
        context.read<ChildEnrollmentProvider>().loadOwnerEnrollments(auth.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Inscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showScanner(context),
            tooltip: 'Scanner un paiement',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Demandes'),
            Tab(text: 'Inscrits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _EnrollmentList(status: EnrollmentStatus.pending),
          const _EnrollmentList(status: EnrollmentStatus.approved),
        ],
      ),
    );
  }

  void _showScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              title: const Text('Scanner le QR Enfant', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      _handleScannedData(context, barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Placez le QR code de l\'enfant dans le cadre pour valider son paiement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScannedData(BuildContext context, String data) {
    try {
      // 1. Essayer le format JSON (format recommandé)
      if (data.startsWith('{')) {
        final decoded = jsonDecode(data);
        if (decoded['type'] == 'enrollment_payment') {
          final enrollmentId = decoded['id'];
          final childName = decoded['child_name'];
          final amount = (decoded['amount'] as num).toDouble();
          
          _showValidationDialog(context, enrollmentId, childName, amount);
          return;
        }
      }
      
      // 2. Si ce n'est pas du JSON, essayer de trouver l'ID dans la liste locale
      final provider = context.read<ChildEnrollmentProvider>();
      final item = provider.ownerEnrollmentsDetailed.firstWhere(
        (e) => e['enrollment']?['id'] == data,
        orElse: () => {},
      );

      if (item.isNotEmpty) {
        final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);
        final child = ChildModel.fromSupabase(item['child']);
        _showValidationDialog(context, enrollment.id, child.firstName, enrollment.totalAmount ?? 0.0);
      } else {
        throw Exception('Inscription non trouvée');
      }
    } catch (e) {
      debugPrint('❌ [EnrollmentsPage] Error handling scanned data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format de QR Code invalide ou inscription introuvable : $e')),
      );
    }
  }

  void _showValidationDialog(BuildContext context, String enrollmentId, String childName, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le paiement'),
        content: Text('Voulez-vous confirmer le paiement de $amount DA pour $childName ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<ChildEnrollmentProvider>().validatePayment(enrollmentId, amount);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Paiement validé !' : 'Erreur lors de la validation')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentList extends StatelessWidget {
  final EnrollmentStatus status;
  const _EnrollmentList({required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChildEnrollmentProvider>();
    final enrollments = provider.ownerEnrollmentsDetailed.where((e) {
      if (e['enrollment'] == null) return false;
      try {
        final enrollment = EnrollmentModel.fromSupabase(e['enrollment']);
        return enrollment.status == status;
      } catch (err) {
        debugPrint('❌ [EnrollmentsPage] Error parsing enrollment: $err');
        return false;
      }
    }).toList();

    if (provider.isLoading && enrollments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (enrollments.isEmpty) {
      return Center(child: Text(status == EnrollmentStatus.pending ? 'Aucune demande en attente.' : 'Aucun inscrit pour le moment.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final item = enrollments[index];
        if (item['enrollment'] == null || item['child'] == null || item['course'] == null) {
          return const SizedBox.shrink();
        }
        
        try {
          final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);
          final child = ChildModel.fromSupabase(item['child']);
          final course = CourseModel.fromSupabase(item['course']);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null,
                        child: child.photoUrl == null ? Text(child.firstName[0]) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${child.firstName} ${child.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(course.title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(enrollment.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Inscrit le: ${enrollment.enrolledAt.day}/${enrollment.enrolledAt.month}/${enrollment.enrolledAt.year}', style: const TextStyle(fontSize: 11)),
                      if (status == EnrollmentStatus.pending)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => provider.updateEnrollment(enrollmentId: enrollment.id, status: EnrollmentStatus.approved),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => provider.updateEnrollment(enrollmentId: enrollment.id, status: EnrollmentStatus.rejected),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            if (enrollment.paymentStatus != PaymentStatus.paid)
                              IconButton(
                                icon: const Icon(Icons.payments_outlined, color: Colors.orange),
                                onPressed: () => _showPaymentValidation(context, enrollment, child),
                                tooltip: 'Valider le paiement',
                              ),
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: Colors.blue),
                              onPressed: () => _showQR(context, enrollment, child, course),
                              tooltip: 'Voir QR Code',
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showDetails(context, child, enrollment, course),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChildProfileDialog(childId: child.id)),
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _showQR(BuildContext context, EnrollmentModel enrollment, ChildModel child, CourseModel course) {
    final qrData = jsonEncode({
      'type': 'enrollment_payment',
      'id': enrollment.id,
      'child_name': child.fullName,
      'amount': enrollment.totalAmount ?? 0.0,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${child.firstName}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text('Cours: ${course.title}', style: const TextStyle(fontSize: 12)),
              Text('Montant: ${enrollment.totalAmount ?? 0} DA', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showPaymentValidation(BuildContext context, EnrollmentModel enrollment, ChildModel child) {
    final controller = TextEditingController(text: (enrollment.totalAmount ?? 0).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Validation manuelle pour ${child.fullName}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Montant reçu (DA)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              final success = await context.read<ChildEnrollmentProvider>().validatePayment(enrollment.id, amount);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Paiement validé !' : 'Erreur lors de la validation')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, ChildModel child, EnrollmentModel enrollment, CourseModel course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Détails de l\'inscription', style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 16),
             Text('Enfant: ${child.fullName}'),
             Text('Cours: ${course.title}'),
             Text('Statut: ${enrollment.status.displayName}'),
             Text('Paiement: ${enrollment.paymentStatus.displayName}'),
             Text('Montant: ${enrollment.totalAmount} DA'),
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: () async {
                    final auth = context.read<AuthProviderV2>();
                    // Si on est admin/school, on veut peut-être le parent de l'inscription, 
                    // sinon on prend l'utilisateur actuel (si c'est le parent lui-même)
                    UserModel? parent;
                    if (auth.currentUser?.uid == enrollment.parentId) {
                      parent = auth.user;
                    } else {
                      // Optionnel: On pourrait charger le profil du parent ici via l'API
                      final data = await auth.getUserData(enrollment.parentId);
                      if (data != null) parent = UserModel.fromSupabase(data);
                    }

                    // Fetch club/school name
                    String? clubName;
                    if (course.clubId != null) {
                      final clubData = await auth.getUserData(course.clubId!);
                      if (clubData != null) clubName = clubData['name'];
                    } else {
                      final ownerData = await auth.getUserData(course.createdBy);
                      if (ownerData != null) clubName = ownerData['name'];
                    }

                    await PdfDossierService.generateAndPrintDossier(
                      child: child,
                      enrollment: enrollment,
                      course: course,
                      parent: parent,
                      clubName: clubName,
                    );
                 },
                 icon: const Icon(Icons.picture_as_pdf),
                 label: const Text('Générer Dossier PDF'),
               ),
             ),
             const SizedBox(height: 8),
             SizedBox(
               width: double.infinity,
               child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EnrollmentStatus status) {
    Color color = Colors.grey;
    if (status == EnrollmentStatus.approved) color = Colors.green;
    if (status == EnrollmentStatus.pending) color = Colors.orange;
    if (status == EnrollmentStatus.rejected) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}