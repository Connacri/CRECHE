import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/user_model.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/glass_card.dart';
import '../widgets/weekly_timeline_widget.dart';
import 'school_slots_management_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
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

    final userId = auth.currentUser?.uid;
    if (userId != null) {
      await Future.wait([
        courseProvider.loadUserCourses(userId),
        childProvider.loadOwnerEnrollmentsDetailed(userId),
        childProvider.loadSchedulesForSchool(userId),
      ]);
    }

    if (mounted) setState(() => _isLoadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard École' : _selectedIndex == 1 ? 'Gestion des Élèves' : _selectedIndex == 2 ? 'Planning & Horaires' : 'Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingData ? null : _loadInitialData,
          ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildMainDashboard();
      case 1: return const _EnrollmentsPage();
      case 2: return const _PlanningManagementPage();
      default: return const Center(child: Text('Paramètres bientôt disponibles'));
    }
  }

  Widget _buildMainDashboard() {
    final courses = context.watch<CourseProvider>().userCourses;
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    final activeEnrollments = enrollments.where((e) => e['enrollment']['status'] == 'approved').length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(radius: 30, child: Icon(Icons.school_rounded)),
              const SizedBox(height: 16),
              Text('École ${_user?.name ?? ""}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_user?.email ?? ""}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildStatCard('Cours', '${courses.length}', Icons.book, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Inscriptions', '$activeEnrollments', Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Actions Rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildActionTile(Icons.add_box_outlined, 'Créer un cours', 'Ajouter une nouvelle activité', () {
          // Navigator.push...
        }),
        _buildActionTile(Icons.calendar_month_outlined, 'Gérer le planning', 'Voir et modifier les horaires', () {
          setState(() => _selectedIndex = 2);
        }),
        _buildActionTile(Icons.person_search_outlined, 'Profil de l\'école', 'Mettre à jour les informations', () {
          // Navigator.push...
        }),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
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
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Gérer'),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('$pendingCount'),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.people_alt_rounded),
              ), 
              label: 'Élèves',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Planning'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Paramètres'),
          ],
        ),
      ),
    );
  }
}

class _PlanningManagementPage extends StatefulWidget {
  const _PlanningManagementPage();

  @override
  State<_PlanningManagementPage> createState() => _PlanningManagementPageState();
}

class _PlanningManagementPageState extends State<_PlanningManagementPage> {
  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final schedules = childProvider.schedules;
    final courses = context.read<CourseProvider>().userCourses;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Planning & Horaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddScheduleDialog(context, courses),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text('Aucun créneau planifié.'),
          ))
        else
          ...schedules.map((schedule) {
            final course = courses.firstWhere((c) => c.id == schedule.courseId, orElse: () => CourseModel.mock());
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(schedule.dayOfWeek.displayName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(schedule.timeSlot.displayTime),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(schedule.roomName ?? 'Salle non définie'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(schedule.coachId != null ? 'Coach assigné' : 'Pas de coach assigné'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddScheduleDialog(BuildContext context, List<CourseModel> courses) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SchoolSlotsManagementScreen()));
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
      // Recharger aussi les cours pour mettre à jour current_students (même si le trigger s'en occupe en base)
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
