import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../providers/child_enrollment_provider.dart';
import 'glass_card.dart';

class EnrollmentsPage extends StatelessWidget {
  const EnrollmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    final provider = context.read<ChildEnrollmentProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Inscriptions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _openScanner(context, provider),
                tooltip: "Scanner un QR Code de paiement",
              ),
            ],
          ),
        ),
        if (enrollments.isEmpty)
          const Expanded(child: Center(child: Text("Aucune inscription.")))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: enrollments.length,
              itemBuilder: (context, index) {
                final item = enrollments[index];
                final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);
                final child = ChildModel.fromSupabase(item['child']);
                final course = CourseModel.fromSupabase(item['course']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(course.title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            _buildStatusChip(enrollment.status),
                          ],
                        ),
                        if (enrollment.status == EnrollmentStatus.pending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(context, provider, enrollment.id, 'approved'),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approuver', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _rejectDialog(context, provider, enrollment.id),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Refuser', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (enrollment.status == EnrollmentStatus.approved && enrollment.paymentStatus != PaymentStatus.paid) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("En attente de paiement", style: TextStyle(fontSize: 12, color: Colors.orange)),
                              ElevatedButton(
                                onPressed: () => _confirmPaymentFromQR(context, provider, enrollment.id),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(0, 32)),
                                child: const Text("Valider manuellement", style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openScanner(BuildContext context, ChildEnrollmentProvider provider) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(title: const Text("Scanner Paiement")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              Navigator.pop(context);
              _confirmPaymentFromQR(context, provider, code);
            }
          }
        },
      ),
    )));
  }

  void _confirmPaymentFromQR(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId) async {
    final success = await provider.updateEnrollment(
      enrollmentId: enrollmentId,
      paymentStatus: PaymentStatus.paid,
      paidAmount: 0 // Mock amount for now
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Paiement validé avec succès" : "Erreur lors de la validation"))
      );
    }
  }

  void _updateStatus(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId, String status) async {
    final enrollmentStatus = status == 'approved'
        ? EnrollmentStatus.approved
        : status == 'rejected'
            ? EnrollmentStatus.rejected
            : EnrollmentStatus.cancelled;
    try {
      await provider.updateEnrollment(enrollmentId: enrollmentId, status: enrollmentStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'approved' ? 'Inscription approuvée' : 'Inscription mise à jour')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _rejectDialog(BuildContext context, ChildEnrollmentProvider provider, String enrollmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser l\'inscription'),
        content: const Text('Êtes-vous sûr de vouloir refuser cette inscription ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(context, provider, enrollmentId, 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(EnrollmentStatus status) {
    Color color;
    String text;
    switch (status) {
      case EnrollmentStatus.approved: color = Colors.green; text = 'Approuvé'; break;
      case EnrollmentStatus.pending: color = Colors.orange; text = 'En attente'; break;
      case EnrollmentStatus.rejected: color = Colors.red; text = 'Refusé'; break;
      case EnrollmentStatus.cancelled: color = Colors.grey; text = 'Annulé'; break;
      case EnrollmentStatus.completed: color = Colors.blue; text = 'Terminé'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10))
    );
  }
}
