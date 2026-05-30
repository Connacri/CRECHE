import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/glass_card.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProviderV2>();
    final courseProvider = context.read<CourseProvider>();
    if (auth.userData != null) {
      _user = UserModel.fromSupabase(auth.userData!);
      await courseProvider.loadUserCourses(auth.currentUser!.id);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/meditation_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.school_rounded)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('École ${_user?.name ?? ""}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Gestion de l\'établissement'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildStats(),
        const SizedBox(height: 32),
        const Text('Vos cours et activités', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCourseGrid(),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Élèves', '120', Icons.group_rounded, Colors.teal)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Profs', '8', Icons.person_search_rounded, Colors.indigo)),
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

  Widget _buildCourseGrid() {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        if (provider.courses.isEmpty) return const Text('Aucune activité créée');
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: provider.courses.length,
          itemBuilder: (context, index) {
            final course = provider.courses[index];
            return GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 2),
                  const SizedBox(height: 4),
                  Text(course.category, style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        );
      },
    );
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Gérer'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Élèves'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Paramètres'),
          ],
        ),
      ),
    );
  }
}
