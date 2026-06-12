import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/course_model_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider.dart';
import 'glass_card.dart';
import 'child_form_dialog.dart';
import 'course_selection_dialog.dart';

class ChildProfileDialog extends StatelessWidget {
  final String childId;

  const ChildProfileDialog({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        final childIndex = provider.children.indexWhere((c) => c.id == childId);
        if (childIndex == -1) return const SizedBox();
        final child = provider.children[childIndex];
        
        final enrollments = provider.getEnrollmentsForChild(child.id);
        final courses = context.read<CourseProvider>().courses;

        return Dialog.fullscreen(
          child: Scaffold(
            body: SafeArea(child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('${child.firstName} ${child.lastName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
                    background: InkWell(
                      onTap: child.photoUrl != null 
                        ? () => _openFullScreenImage(context, child.photoUrl!, 'child-photo-${child.id}', '${child.firstName} ${child.lastName}')
                        : null,
                      child: Hero(
                        tag: 'child-photo-${child.id}',
                        child: child.photoUrl != null
                            ? CachedNetworkImage(imageUrl: child.photoUrl!, fit: BoxFit.cover)
                            : Container(
                                color: colorScheme.primary,
                                child: Center(child: Text(child.firstName[0],
                                  style: const TextStyle(fontSize: 80, color: Colors.white))),
                              ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditDialog(context, child),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _confirmDelete(context, child),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informations Personnelles',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow(context, Icons.cake, 'Date de naissance', _formatDate(child.dateOfBirth))),
                            Expanded(child: _buildInfoRow(context, Icons.hourglass_empty, 'Âge', '${child.age} ans')),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow(context, child.gender == ChildGender.male ? Icons.male : Icons.female, 'Genre', child.gender == ChildGender.male ? 'Garçon' : child.gender == ChildGender.female ? 'Fille' : 'Autre')),
                            Expanded(child: _buildInfoRow(context, Icons.school, 'Niveau', child.schoolGrade ?? 'Non spécifié')),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow(context, Icons.bloodtype, 'Groupe Sanguin', child.medicalInfo.bloodType ?? 'Non spécifié')),
                            Expanded(child: _buildInfoRow(context, Icons.medical_services, 'Allergies', child.medicalInfo.allergies.isEmpty ? 'Aucune' : child.medicalInfo.allergies.join(", "))),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        const Text('Documents Administratifs',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildDocumentPreview(
                              context, 
                              "Extrait de naissance", 
                              child.birthCertificateUrl, 
                              'child-birth-${child.id}'
                            ),
                            const SizedBox(width: 16),
                            _buildDocumentPreview(
                              context, 
                              "Certificat médical", 
                              child.medicalCertificateUrl, 
                              'child-medical-${child.id}'
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Inscriptions aux Cours',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => _showCourseSelectionDialog(context, child),
                              icon: const Icon(Icons.add),
                              label: const Text('Inscrire'),
                            ),
                          ],
                        ),
                        if (enrollments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('Aucune inscription active')),
                          ),
                      ],
                    ),
                  ),
                ),
                if (enrollments.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final enrollment = enrollments[index];
                        final course = courses.firstWhere((c) => c.id == enrollment.courseId,
                          orElse: () => CourseModel(
                            id: '',
                            title: 'Cours inconnu',
                            description: '',
                            category: CourseCategory.other,
                            season: CourseSeason.yearRound,
                            seasonStartDate: DateTime.now(),
                            seasonEndDate: DateTime.now(),
                            location: CourseLocation(latitude: 0.0, longitude: 0.0, address: ''),
                            images: [],
                            createdBy: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ));

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.class_, color: colorScheme.onPrimaryContainer),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(course.title,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                              _buildBadge(context, enrollment.status.displayName, enrollment.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Inscrit le ${_formatDate(enrollment.enrolledAt)}',
                                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                                  ),
                                                ],
                                              ),
                                              if (enrollment.status == EnrollmentStatus.pending || enrollment.status == EnrollmentStatus.approved)
                                                TextButton(
                                                  onPressed: () => _confirmCancelEnrollment(context, enrollment.id, course.title),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(0, 30),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text("Annuler", style: TextStyle(fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                          if (enrollment.status == EnrollmentStatus.approved) ...[
                                            const Divider(),
                                            const SizedBox(height: 4),
                                            if (enrollment.paymentStatus == PaymentStatus.paid)
                                              const Row(
                                                children: [
                                                  Icon(Icons.verified, color: Colors.green, size: 20),
                                                  SizedBox(width: 8),
                                                  Text("Adhérent confirmé",
                                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              )
                                            else
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Paiement requis",
                                                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 13)),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showPaymentQR(context, enrollment, child),
                                                    icon: const Icon(Icons.qr_code, size: 18),
                                                    label: const Text("Payer", style: TextStyle(fontSize: 12)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.orange,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                      minimumSize: const Size(0, 32),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: enrollments.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            )),
          ),
        );
      },
    );
  }

  void _showPaymentQR(BuildContext context, EnrollmentModel enrollment, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paiement par QR Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Veuillez présenter ce code au club pour valider votre paiement."),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: jsonEncode({
                  'type': 'enrollment_payment',
                  'id': enrollment.id,
                  'child_name': child.firstName,
                  'amount': enrollment.totalAmount ?? 0.0,
                }),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text("${enrollment.totalAmount?.toStringAsFixed(0) ?? "0"} DA",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => ChildFormDialog(child: child, parentId: child.parentId),
    );
  }

  void _confirmDelete(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Supprimer le profil'),
        content: Text('Voulez-vous vraiment supprimer le profil de ${child.firstName} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final provider = confirmContext.read<ChildEnrollmentProvider>();
              await provider.deleteChild(child.id);
              if (confirmContext.mounted) {
                Navigator.pop(confirmContext); // Close alert
                Navigator.pop(context); // Close profile dialog
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelEnrollment(BuildContext context, String enrollmentId, String courseTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler l'inscription"),
        content: Text("Voulez-vous vraiment annuler l'inscription au cours $courseTitle ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          TextButton(
            onPressed: () async {
              await context.read<ChildEnrollmentProvider>().cancelEnrollment(enrollmentId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCourseSelectionDialog(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => CourseSelectionDialog(child: child),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl, String heroTag, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
          title: title,
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context, String title, String? url, String heroTag) {
    return Expanded(
      child: InkWell(
        onTap: url != null ? () => _openFullScreenImage(context, url, heroTag, title) : null,
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Hero(
              tag: heroTag,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner, color: Colors.grey, size: 40),
                            SizedBox(height: 4),
                            Text("Non fourni", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, EnrollmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.approved: return Colors.green;
      case EnrollmentStatus.pending: return Colors.orange;
      case EnrollmentStatus.rejected: return Colors.red;
      case EnrollmentStatus.cancelled: return Colors.grey;
      case EnrollmentStatus.completed: return Colors.blue;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
