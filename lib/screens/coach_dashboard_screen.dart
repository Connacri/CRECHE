import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../models/enrollment_model_complete.dart';
import '../models/child_model_complete.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../widgets/glass_card.dart';
import 'create_course_screen.dart';
import 'profile_screen.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;
  bool _isLoadingData = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    final auth = context.read<AuthProviderV2>();
    final courseProvider = context.read<CourseProvider>();
    final childProvider = context.read<ChildEnrollmentProvider>();

    if (auth.userData != null) {
      _user = UserModel.fromSupabase(auth.userData!);
    }
    if (auth.currentUser != null) {
      await Future.wait([
        courseProvider.loadUserCourses(auth.currentUser!.uid),
        childProvider.loadOwnerEnrollmentsDetailed(auth.currentUser!.uid),
      ]);
    }
    setState(() => _isLoadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProviderV2>();
    final childProvider = context.watch<ChildEnrollmentProvider>();
    
    final isGlobalLoading = auth.isLoading || _isLoadingData || childProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard Coach' : _selectedIndex == 1 ? 'Inscriptions' : 'Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/meditation_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          SafeArea(
            child: isGlobalLoading && _selectedIndex != 1
              ? const Center(child: CircularProgressIndicator())
              : _getSelectedPage(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return const _EnrollmentsPage();
      case 2: return const ProfileScreen();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.sports)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach ${_user?.name ?? ""}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Prêt pour la séance ?'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildStats(),
        const SizedBox(height: 32),
        const Text('Vos cours et activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCourseList(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStats() {
    final childProvider = context.read<ChildEnrollmentProvider>();
    final activeStudents = childProvider.ownerEnrollmentsDetailed
        .where((e) => e['enrollment']['status'] == 'approved').length;
    final courseCount = context.read<CourseProvider>().userCourses.length;

    return Row(
      children: [
        Expanded(child: _buildStatItem('Cours', '$courseCount', Icons.event, Colors.green)),
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
        final childJson = item['child'] as Map<String, dynamic>;
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
