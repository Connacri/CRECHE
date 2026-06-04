import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/user_model.dart';
import '../models/session_schedule_model.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/glass_card.dart';
import "../widgets/interactive_weekly_timetable.dart";
import "../widgets/add_session_dialog.dart";
import 'club_menu_screen.dart';
import 'create_course_screen.dart';

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
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      if (auth.userData != null) {
        _user = UserModel.fromSupabase(auth.userData!);
      }
      await Future.wait([
        context.read<CourseProvider>().loadUserCourses(userId),
        context.read<ChildEnrollmentProvider>().loadOwnerEnrollmentsDetailed(userId),
        context.read<ChildEnrollmentProvider>().loadSchedulesForSchool(userId),
      ]);
    }
    setState(() => _isLoadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      body: SafeArea(child: Column(children: [_buildHeader(), Expanded(child: _getPage(_selectedIndex))])),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Aperçu'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Inscriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Menu'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProviderV2>();
    final user = auth.userData != null ? UserModel.fromSupabase(auth.userData!) : _user;
    final avatarUrl = user?.profileImages.profileImageSupabase;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        CircleAvatar(radius: 25, backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null, child: avatarUrl == null ? const Icon(Icons.person) : null),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour,', style: TextStyle(color: Colors.grey[600])),
          Text(user?.name ?? 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: return const _DashboardOverview();
      case 1: return const _EnrollmentsPage();
      case 2: return const _PlanningManagementPage();
      case 3: return const ClubMenuScreen();
      default: return const Center(child: Text('Statistiques'));
    }
  }
}

class _PlanningManagementPage extends StatefulWidget {
  const _PlanningManagementPage();
  @override
  State<_PlanningManagementPage> createState() => _PlanningManagementPageState();
}
class _PlanningManagementPageState extends State<_PlanningManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProviderV2>();
        final provider = context.read<CourseProvider>();
        provider.loadOwnerSchedules(auth.currentUser!.uid);
        provider.loadCoaches();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final schedules = provider.schedules;
    final courses = provider.userCourses;
    final coaches = provider.coaches;

    final Map<String, String> coachesNames = {
      for (var c in coaches) c['id'] as String: c['name'] as String? ?? 'Sans nom'
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Planning & Horaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddScheduleDialog(context, courses, coaches),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (courses.isEmpty)
          const Expanded(child: Center(child: Text('Créez d\'abord un cours pour pouvoir planifier des horaires.')))
        else
          Expanded(
            child: InteractiveWeeklyTimetable(
              schedules: schedules,
              courses: courses,
              coachesNames: coachesNames,
              onEmptySlotTap: (day, slot) => _showAddScheduleDialog(context, courses, coaches, initialDay: day, initialTimeSlot: slot),
              onSessionTap: (session) => _showAddScheduleDialog(context, courses, coaches, sessionToEdit: session),
            ),
          ),
      ],
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    List<CourseModel> courses,
    List<Map<String, dynamic>> coaches,
    {DayOfWeek? initialDay, TimeSlot? initialTimeSlot, SessionSchedule? sessionToEdit}
  ) async {
    final provider = context.read<CourseProvider>();
    final result = await showDialog(
      context: context,
      builder: (context) => AddSessionDialog(
        courses: courses,
        coaches: coaches,
        initialDay: initialDay,
        initialTimeSlot: initialTimeSlot,
        sessionToEdit: sessionToEdit,
      ),
    );

    if (result != null) {
      if (result == 'delete' && sessionToEdit != null) {
        await provider.deleteSchedule(sessionToEdit.id);
      } else if (result is SessionSchedule) {
        if (sessionToEdit != null) {
          await provider.updateSchedule(sessionToEdit.id, result.toSupabase());
          // Rafraîchir
          final auth = context.read<AuthProviderV2>();
          provider.loadOwnerSchedules(auth.currentUser!.uid);
        } else {
          await provider.createSchedule(result);
        }
      }
    }
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().userCourses;
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    final pendingEnrollments = enrollments.where((e) {
      final enrollment = EnrollmentModel.fromSupabase(e['enrollment']);
      return enrollment.status == EnrollmentStatus.pending;
    }).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _StatCard('Cours actifs', courses.where((c) => c.isActive).length.toString(), Icons.school, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Inscriptions', enrollments.length.toString(), Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard('En attente', pendingEnrollments.toString(), Icons.hourglass_empty, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Adhérents', '0', Icons.card_membership, Colors.purple)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Actions rapides', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_circle, color: Colors.blue, size: 28)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Créer un cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('Ajouter un nouveau cours au catalogue', style: TextStyle(fontSize: 13, color: Colors.grey))])),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: color), const Spacer(), Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _EnrollmentsPage extends StatelessWidget {
  const _EnrollmentsPage();
  @override
  Widget build(BuildContext context) {
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    final provider = context.read<ChildEnrollmentProvider>();
    if (enrollments.isEmpty) return const Center(child: Text('Aucune inscription.'));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
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
                Row(children: [
                  CircleAvatar(backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null, child: child.photoUrl == null ? const Icon(Icons.person) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${child.firstName} ${child.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(course.title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ])),
                  _buildStatusChip(enrollment.status),
                ]),
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
                ],
              ],
            ),
          ),
        );
      },
    );
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)), child: Text(text, style: TextStyle(color: color, fontSize: 10)));
  }
}
