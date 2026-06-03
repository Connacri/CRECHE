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
import '../widgets/interactive_weekly_timetable.dart';
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = _user?.profileImages.profileImageSupabase;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        CircleAvatar(radius: 25, backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null, child: avatarUrl == null ? const Icon(Icons.person) : null),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour,', style: TextStyle(color: Colors.grey[600])),
          Text(_user?.name ?? 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: return const Center(child: Text('Statistiques'));
      case 1: return const _EnrollmentsPage();
      case 2: return const _PlanningManagementPage();
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
      final auth = context.read<AuthProviderV2>();
      if (auth.currentUser != null) {
        context.read<CourseProvider>().loadOwnerSchedules(auth.currentUser!.uid);
        context.read<CourseProvider>().loadCoaches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final Map<String, String> coachesNames = { for (var c in provider.coaches) c['id'] as String: c['name'] as String? ?? 'Sans nom' };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Planning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _showAddScheduleDialog(context, provider.userCourses, provider.coaches)),
      ])),
      if (provider.isLoading) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (provider.userCourses.isEmpty) const Expanded(child: Center(child: Text('Aucun cours trouvé.')))
      else Expanded(child: InteractiveWeeklyTimetable(
        schedules: provider.schedules,
        courses: provider.userCourses,
        coachesNames: coachesNames,
        onEmptySlotTap: (day, slot) => _showAddScheduleDialog(context, provider.userCourses, provider.coaches, initialDay: day, initialTimeSlot: slot),
        onSessionTap: (session) => _showAddScheduleDialog(context, provider.userCourses, provider.coaches, sessionToEdit: session),
      )),
    ]);
  }

  void _showAddScheduleDialog(BuildContext context, List<CourseModel> courses, List<Map<String, dynamic>> coaches, {DayOfWeek? initialDay, TimeSlot? initialTimeSlot, SessionSchedule? sessionToEdit}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SchoolSlotsManagementScreen()));
  }
}

class _EnrollmentsPage extends StatelessWidget {
  const _EnrollmentsPage();
  @override
  Widget build(BuildContext context) {
    final enrollments = context.watch<ChildEnrollmentProvider>().ownerEnrollmentsDetailed;
    if (enrollments.isEmpty) return const Center(child: Text('Aucune inscription.'));
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: enrollments.length,
      itemBuilder: (context, index) {
        final item = enrollments[index];
        final enrollment = EnrollmentModel.fromSupabase(item['enrollment']);
        final child = ChildModel.fromSupabase(item['child']);
        final course = CourseModel.fromSupabase(item['course']);
        return Padding(padding: const EdgeInsets.only(bottom: 16), child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
          CircleAvatar(backgroundImage: child.photoUrl != null ? CachedNetworkImageProvider(child.photoUrl!) : null, child: child.photoUrl == null ? const Icon(Icons.person) : null),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${child.firstName} ${child.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(course.title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          _buildStatusChip(enrollment.status),
        ])));
      },
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
