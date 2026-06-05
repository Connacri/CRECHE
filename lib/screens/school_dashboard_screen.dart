import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/auth_provider_v2.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/user_model.dart';
import '../models/session_schedule_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/add_session_dialog.dart';
import 'profile_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return const _OverviewPage();
      case 1: return const _PlanningManagementPage();
      case 2: return const ProfileScreen();
      default: return const _OverviewPage();
    }
  }

  Widget _buildBottomNav() {
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Aperçu'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProviderV2>();
    final user = auth.userData != null ? UserModel.fromSupabase(auth.userData!) : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Tableau de Bord', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            background: Container(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Bienvenue, ${user?.name ?? "Club"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStatsGrid(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(context, 'Membres', '124', Icons.people, Colors.blue),
        _buildStatCard(context, 'Cours Actifs', '12', Icons.school, Colors.green),
        _buildStatCard(context, 'Sessions/Jour', '8', Icons.timer, Colors.orange),
        _buildStatCard(context, 'Revenus', '450k', Icons.payments, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
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
      for (var c in coaches) c.uid: c.name
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

  void _showAddScheduleDialog(BuildContext context, List<dynamic> courses, List<UserModel> coaches, {DayOfWeek? initialDay, TimeSlot? initialTimeSlot, SessionSchedule? sessionToEdit}) {
    showDialog(
      context: context,
      builder: (context) => AddSessionDialog(
        courses: courses,
        coaches: coaches,
        initialDay: initialDay,
        initialTimeSlot: initialTimeSlot,
        sessionToEdit: sessionToEdit,
      ),
    );
  }
}
