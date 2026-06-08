import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import 'glass_card.dart';

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
      } catch (_) {
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
                         IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showDetails(context, child, enrollment, course),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
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
             Text('Paiement: ${enrollment.paymentStatus.name}'),
             Text('Montant: ${enrollment.totalAmount} DA'),
             const SizedBox(height: 24),
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
