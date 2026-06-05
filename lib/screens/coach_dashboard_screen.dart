import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/glass_card.dart';
import 'create_course_screen.dart';
import 'profile_screen.dart';
import 'associate_to_school_screen.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProviderV2>().currentUser;
      if (user != null) {
        context.read<CourseProvider>().loadUserCourses(user.uid);
        context.read<ChildEnrollmentProvider>().loadOwnerEnrollmentsDetailed(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _selectedIndex == 0 ? _buildMainDashboard() : _selectedIndex == 1 ? const _EnrollmentsPage() : const ProfileScreen(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProviderV2>();
    final userData = auth.userData;
    final userName = userData != null ? userData['name'] : 'Chargement...';
    final profileImage = userData != null && userData['profile_images'] != null
        ? userData['profile_images']['profileImageSupabase']
        : null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour Coach,', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(userName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(
            radius: 25,
            backgroundImage: profileImage != null ? CachedNetworkImageProvider(profileImage) : null,
            child: profileImage == null ? const Icon(Icons.person) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        final user = context.read<AuthProviderV2>().currentUser;
        if (user != null) {
          await context.read<CourseProvider>().loadUserCourses(user.uid);
          await context.read<ChildEnrollmentProvider>().loadOwnerEnrollmentsDetailed(user.uid);
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatsRow(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes Cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCourseList(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final courseProvider = context.watch<CourseProvider>();
    final activeCourses = courseProvider.userCourses.where((c) => c.isActive).length;
    final activeStudents = courseProvider.userCourses.fold<int>(0, (sum, c) => sum + c.currentStudents);

    return Row(
      children: [
        Expanded(child: _buildStatItem('Cours Actifs', '$activeCourses', Icons.class_, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Élèves', '$activeStudents', Icons.people, Colors.orange)),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final userCourses = provider.userCourses;
        if (userCourses.isEmpty) return const Text('Aucun cours programmé');
        return Column(
          children: userCourses.map((course) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${course.category.displayName} • ${course.currentStudents}/${course.maxStudents} élèves', style: const TextStyle(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.business, color: Colors.green, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AssociateToSchoolScreen(course: course)),
                        );
                      },
                      tooltip: 'Associer à un club',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateCourseScreen(courseToEdit: course)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(context, course),
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Voulez-vous vraiment supprimer "${course.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final success = await context.read<CourseProvider>().deleteCourse(course.id);
              if (mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de la suppression')),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final pendingCount = childProvider.ownerEnrollmentsDetailed
        .where((e) => e['enrollment']['status'] == 'pending').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        opacity: 0.8,
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('$pendingCount'),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.people_alt_rounded),
              ), 
              label: 'Inscriptions',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentsPage extends StatelessWidget {
  const _EnrollmentsPage();

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final enrollments = childProvider.ownerEnrollmentsDetailed;

    if (enrollments.isEmpty) {
      return const Center(child: Text('Aucune inscription pour le moment.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final item = enrollments[index];
        final enrollmentJson = item['enrollment'] as Map<String, dynamic>;
        final childJson = (item["child"] as Map<String, dynamic>?) ?? ChildModel.mock().toSupabase();
        final courseJson = item['course'] as Map<String, dynamic>;

        final enrollment = EnrollmentModel.fromSupabase(enrollmentJson);
        final child = ChildModel.fromSupabase(childJson);
        final course = CourseModel.fromSupabase(courseJson);

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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('S\'inscrit à : ${course.title}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    _buildStatusBadge(enrollment.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inscrit le ${_formatDate(enrollment.enrolledAt)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    if (enrollment.status == EnrollmentStatus.pending)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.approved),
                            tooltip: 'Approuver',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.rejected),
                            tooltip: 'Refuser',
                          ),
                        ],
                      )
                    else if (enrollment.status == EnrollmentStatus.approved)
                       TextButton.icon(
                        onPressed: () => _updateStatus(context, enrollment.id, EnrollmentStatus.cancelled),
                        icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                        label: const Text('Annuler', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateStatus(BuildContext context, String enrollmentId, EnrollmentStatus status) async {
    final provider = context.read<ChildEnrollmentProvider>();
    final success = await provider.updateEnrollment(enrollmentId: enrollmentId, status: status);
    
    if (success && context.mounted) {
      final auth = context.read<AuthProviderV2>();
      context.read<CourseProvider>().loadUserCourses(auth.currentUser!.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour : ${status.displayName}')),
      );
    }
  }

  Widget _buildStatusBadge(EnrollmentStatus status) {
    Color color;
    switch (status) {
      case EnrollmentStatus.approved: color = Colors.green; break;
      case EnrollmentStatus.pending: color = Colors.orange; break;
      case EnrollmentStatus.rejected: color = Colors.red; break;
      case EnrollmentStatus.cancelled: color = Colors.grey; break;
      case EnrollmentStatus.completed: color = Colors.blue; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
