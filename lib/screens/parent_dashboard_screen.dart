import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dependences/calendar_timeline/calendar_timeline.dart';
import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../models/user_model.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/modern_course_card_widget.dart';
import '../widgets/weekly_timeline_widget.dart';
import '../widgets/glass_card.dart';
import 'profile_screen.dart';
import 'course_details_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  UserModel? _user;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProviderV2>();
      if (authProvider.userData != null) {
        _user = UserModel.fromSupabase(authProvider.userData!);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
            bottom: false,
            child: _getSelectedPage(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        opacity: 0.8,
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Accueil'),
            _buildNavItem(1, Icons.calendar_today_rounded, 'Planning'),
            _buildNavItem(2, Icons.child_care_rounded, 'Enfants'),
            _buildNavItem(3, Icons.search_rounded, 'Cours'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    switch (_selectedIndex) {
      case 0: return _buildHomePage();
      case 1: return _buildPlanningPage();
      case 2: return _buildChildrenPage();
      case 3: return _buildCoursesPage();
      default: return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Consumer3<AuthProviderV2, ChildEnrollmentProvider, CourseProvider>(
      builder: (context, auth, childProvider, courseProvider, _) {
        final userName = auth.userData?['name'] ?? 'Parent';
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildUserHeader(userName),
            const SizedBox(height: 32),
            _buildQuickChildren(childProvider),
            const SizedBox(height: 32),
            _buildStatCards(childProvider),
            const SizedBox(height: 32),
            _buildCalendarSection(childProvider),
            const SizedBox(height: 100), // Space for bottom nav
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(String userName) {
    return Row(
      children: [
        const CircleAvatar(radius: 28, child: Icon(Icons.person)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour, $userName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Votre espace de sérénité'),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildQuickChildren(ChildEnrollmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes enfants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.children.length,
            itemBuilder: (context, index) {
              final child = provider.children[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(radius: 30, child: Text(child.firstName[0])),
                    const SizedBox(height: 4),
                    Text(child.firstName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(ChildEnrollmentProvider provider) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Présences', '18/20', Icons.check_circle_outline, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Cours Actifs', '${provider.enrollments.length}', Icons.book_outlined, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(ChildEnrollmentProvider childProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Planning hebdomadaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: CalendarTimeline(
            initialDate: _selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateSelected: (date) => setState(() => _selectedDate = date),
            leftMargin: 20,
            monthColor: Theme.of(context).colorScheme.onSurfaceVariant,
            dayColor: Theme.of(context).colorScheme.onSurfaceVariant,
            activeDayColor: Colors.white,
            activeBackgroundDayColor: Theme.of(context).colorScheme.primary,
            locale: 'fr',
          ),
        ),
        const SizedBox(height: 16),
        _buildDaySessions(childProvider),
      ],
    );
  }

  Widget _buildDaySessions(ChildEnrollmentProvider provider) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 12),
              const Text('09:00 - 10:30', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              const Expanded(child: Text('Éveil Musical')),
              _buildBadge('Salle A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlanningPage() => _buildCalendarSection(context.read<ChildEnrollmentProvider>());

  Widget _buildChildrenPage() {
    final provider = context.watch<ChildEnrollmentProvider>();
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: provider.children.length,
      itemBuilder: (context, i) {
        final child = provider.children[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: CircleAvatar(child: Text(child.firstName[0])),
              title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${child.age} ans • ${child.schoolGrade ?? ""}'),
              trailing: const Icon(Icons.edit_outlined),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesPage() {
    final provider = context.watch<CourseProvider>();
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8
      ),
      itemCount: provider.courses.length,
      itemBuilder: (context, i) => CourseCard(course: provider.courses[i], onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: provider.courses[i])));
      }),
    );
  }
}
