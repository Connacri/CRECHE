import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider_v2.dart';
import '../providers/course_provider_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../models/session_schedule_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/interactive_weekly_timetable.dart';
import '../widgets/add_session_dialog.dart';
import '../widgets/enrollments_page.dart';
import '../widgets/my_courses_page.dart';
import '../widgets/attendance_management_page.dart';
import 'club_school_planning_screen.dart';
import 'profile_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProviderV2>();
      if (auth.currentUser != null) {
        final uid = auth.currentUser!.uid;
        context.read<ChildEnrollmentProvider>().subscribeToOwnerEnrollments(uid);
        context.read<ChildEnrollmentProvider>().subscribeToExpenses(uid);
        context.read<CourseProvider>().loadUserCourses(uid);
        context.read<CourseProvider>().loadOwnerSchedules(uid);
        context.read<CourseProvider>().loadCoaches();
      }
    });
  }

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
      case 0: return const _DashboardOverview();
      case 1: return const MyCoursesPage();
      case 2: return const EnrollmentsPage();
      case 3: return const ClubSchoolPlanningScreen(); // ✅ Planning Global Club
      case 4: return const _PlanningManagementPage();
      case 5: return const AttendanceManagementPage();
      case 6: return const ProfileScreen();
      default: return const _DashboardOverview();
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
            BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), activeIcon: Icon(Icons.event_note), label: 'Club'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Planning'),
            BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Présence'),
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
    final enrollmentProvider = context.watch<ChildEnrollmentProvider>();
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Statistiques en temps réel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        // Finances
        Row(
          children: [
            Expanded(child: _buildStatCard('Recettes', '${enrollmentProvider.totalRevenue.toInt()} DA', Icons.trending_up, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Dépenses', '${enrollmentProvider.totalExpenses.toInt()} DA', Icons.trending_down, Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('Bénéfice Net', '${enrollmentProvider.netIncome.toInt()} DA', Icons.account_balance_wallet, Colors.blue, isWide: true),
        
        const SizedBox(height: 24),
        
        // Inscriptions
        Row(
          children: [
            Expanded(child: _buildStatCard('Approuvées', enrollmentProvider.approvedEnrollmentsCount.toString(), Icons.check_circle, Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('En attente', enrollmentProvider.pendingEnrollmentsCount.toString(), Icons.hourglass_empty, Colors.orange)),
          ],
        ),
        
        const SizedBox(height: 24),
        _buildEnrollmentChart(context, enrollmentProvider),
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEnrollmentChart(BuildContext context, ChildEnrollmentProvider provider) {
    final data = provider.weeklyEnrollmentData;
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activité des 7 derniers jours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Text(data[index]['day'], style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['count'])).toList(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isWide = false}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
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
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final courses = provider.userCourses;
    final schedules = provider.schedules;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gestion du Planning', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                onPressed: () => _showAddSession(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveWeeklyTimetable(
            schedules: schedules,
            courses: courses,
            onEmptySlotTap: (day, slot) => _showAddSession(context, day: day, slot: slot),
            onSessionTap: (session) => _showAddSession(context, session: session),
          ),
        ),
      ],
    );
  }

  void _showAddSession(BuildContext context, {DayOfWeek? day, TimeSlot? slot, SessionSchedule? session}) {
    final provider = context.read<CourseProvider>();
    showDialog(
      context: context,
      builder: (context) => AddSessionDialog(
        courses: provider.userCourses,
        coaches: provider.coaches,
        initialDay: day,
        initialTimeSlot: slot,
        sessionToEdit: session,
      ),
    );
  }
}
