

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/user_model.dart';
import '../models/course_model_complete.dart';


import '../models/session_schedule_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/add_session_dialog.dart';
import '../widgets/enrollments_page.dart';
import 'profile_screen.dart';
import 'create_course_screen.dart';

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
      case 0: return const _DashboardOverview();
      case 1: return const _PlanningManagementPage();
      case 2: return const EnrollmentsPage();
      case 3: return const ProfileScreen();
      default: return const _DashboardOverview();
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
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Inscrits'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().userCourses;
    final enrollmentProvider = context.watch<ChildEnrollmentProvider>();
    final enrollments = enrollmentProvider.ownerEnrollmentsDetailed;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Cours actifs', courses.where((c) => c.isActive).length.toString(), Icons.school, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Inscriptions', enrollments.length.toString(), Icons.people, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        _buildEnrollmentTrend(context, enrollmentProvider),
      ],
    );
  }

  Widget _buildEnrollmentTrend(BuildContext context, ChildEnrollmentProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inscriptions récentes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _TrendChartPainter(provider.monthlyEnrollmentStats),
              child: Container(),
            ),
          ),
        ],
      ),
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
        final courseProvider = context.read<CourseProvider>();
        courseProvider.loadOwnerSchedules(auth.currentUser!.uid);
        courseProvider.loadCoaches();
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
          const Expanded(child: Center(child: Text("Créez d'abord un cours pour pouvoir planifier des horaires.")))
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

  void _showAddScheduleDialog(BuildContext context, List<CourseModel> courses, List<UserModel> coaches, {DayOfWeek? initialDay, TimeSlot? initialTimeSlot, SessionSchedule? sessionToEdit}) {
    final provider = context.read<CourseProvider>();
    showDialog(
      context: context,
      builder: (context) => AddSessionDialog(
        courses: courses,
        coaches: coaches,
        initialDay: initialDay,
        initialTimeSlot: initialTimeSlot,
        sessionToEdit: sessionToEdit,
      ),
    ).then((result) async {
      if (result != null) {
        if (result == 'delete' && sessionToEdit != null) {
          await provider.deleteSchedule(sessionToEdit.id);
        } else if (result is SessionSchedule) {
          if (sessionToEdit != null) {
            await provider.updateSchedule(sessionToEdit.id, result.toSupabase());
            if (context.mounted) {
               final auth = context.read<AuthProviderV2>();
               provider.loadOwnerSchedules(auth.currentUser!.uid);
            }
          } else {
            await provider.createSchedule(result);
          }
        }
      }
    });
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _TrendChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintPoint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final maxVal = data.fold<double>(0, (max, e) => (e['count'] as int) > max ? (e['count'] as int).toDouble() : max);
    if (maxVal == 0) return;

    final xStep = size.width / (data.length - 1);
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['count'] as int).toDouble();
      final x = i * xStep;
      final y = size.height - (val / maxVal) * size.height;

      if (i == 0) { path.moveTo(x, y); }
      else { path.lineTo(x, y); }
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['count'] as int).toDouble();
      final x = i * xStep;
      final y = size.height - (val / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 4, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
