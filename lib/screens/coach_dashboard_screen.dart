import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session_schedule_model.dart';
import '../providers/course_provider_complete.dart';
import '../providers/schedule_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/enrollments_page.dart';
import '../widgets/my_courses_page.dart';
import '../widgets/attendance_management_page.dart';
import '../services/club_service.dart';
import 'create_course_screen.dart';
import 'profile_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/forest_bg_zoomed.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          SafeArea(child: _buildPage()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return const _CoachOverview();
      case 1: return const MyCoursesPage();
      case 2: return const EnrollmentsPage();
      case 3: return const _ClubTimetablePage();
      case 4: return const AttendanceManagementPage();
      case 5: return const ProfileScreen();
      default: return const _CoachOverview();
    }
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassCard(
        opacity: 0.8,
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Cours'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Inscrits'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Présence'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _CoachOverview extends StatelessWidget {
  const _CoachOverview();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final courses = provider.userCourses;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Mon Tableau de Bord', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildStatCard('Mes Cours', courses.length.toString(), Icons.school, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Sessions', '${provider.schedules.length}', Icons.event, Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Actions Rapides', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCourseScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Créer un nouveau cours'),
        ),
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
}

class _ClubTimetablePage extends StatefulWidget {
  const _ClubTimetablePage();

  @override
  State<_ClubTimetablePage> createState() => _ClubTimetablePageState();
}

class _ClubTimetablePageState extends State<_ClubTimetablePage> {
  final ClubService _clubService = ClubService();
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      _schools = await _clubService.getSchools();
      if (_schools.isNotEmpty && mounted) {
        setState(() {
          _selectedSchoolId = _schools.first['id'];
          _isInit = true;
        });
        _refreshSchedule();
      }
    } catch (e) {
      debugPrint('Error loading schools: $e');
    }
  }

  void _refreshSchedule() {
    if (_selectedSchoolId != null) {
      context.read<ScheduleProvider>().loadWeeklySchedule(schoolId: _selectedSchoolId);
      context.read<CourseProvider>().loadUserCourses(_selectedSchoolId!); // Pour avoir la liste des cours du club
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final courseProvider = context.watch<CourseProvider>();

    // Aplatir le Map du provider en List pour le widget InteractiveWeeklyTimetable
    final List<SessionSchedule> allSessions = [];
    scheduleProvider.weeklySchedule.forEach((day, sessions) {
      allSessions.addAll(sessions);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSchoolId,
            items: _schools.map((s) => DropdownMenuItem<String>(value: s["id"].toString(), child: Text(s["name"]?.toString() ?? "Inconnu"))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSchoolId = val;
              });
              _refreshSchedule();
            },
            decoration: const InputDecoration(labelText: 'Sélectionner un Club'),
          ),
        ),
        if (scheduleProvider.isLoading || !_isInit)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: InteractiveWeeklyTimetable(
              schedules: allSessions,
              courses: courseProvider.courses, // Utilise tous les cours chargés
              onEmptySlotTap: (day, slot) {},
              onSessionTap: (session) {},
            ),
          ),
      ],
    );
  }
}
