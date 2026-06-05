import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';



import '../models/session_schedule_model.dart';
import '../providers/course_provider_complete.dart';


import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/enrollments_page.dart';
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
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return const _CoachOverview();
      case 1: return const EnrollmentsPage();
      case 2: return const _ClubTimetablePage();
      case 3: return const ProfileScreen();
      default: return const _CoachOverview();
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
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Inscrits'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Planning'),
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
            Expanded(child: _buildStatCard('Sessions', '12', Icons.event, Colors.orange)),
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
  List<SessionSchedule> _schedules = [];
  List<CourseModel> _allCourses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      _schools = await _clubService.getSchools();
      if (_schools.isNotEmpty) {
        _selectedSchoolId = _schools.first['id'];
        await _loadSchedules();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedules() async {
    final schoolId = _selectedSchoolId;
    if (schoolId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _clubService.adminClient.from('session_schedules').select().eq('school_id', schoolId);
      _schedules = (response as List).map((data) => SessionSchedule.fromSupabase(data)).toList();

      final courseResponse = await _clubService.adminClient.from('courses').select().eq('club_id', schoolId);
      _allCourses = (courseResponse as List).map((data) => CourseModel.fromSupabase(data)).toList();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSchoolId,
            items: _schools.map((s) => DropdownMenuItem<String>(value: s["id"].toString(), child: Text(s["name"]?.toString() ?? "Inconnu"))).toList(),
            onChanged: (val) {
              _selectedSchoolId = val;
              _loadSchedules();
            },
            decoration: const InputDecoration(labelText: 'Sélectionner un Club'),
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: InteractiveWeeklyTimetable(
              schedules: _schedules,
              courses: _allCourses,
              onEmptySlotTap: (day, slot) {},
              onSessionTap: (session) {},
            ),
          ),
      ],
    );
  }
}
