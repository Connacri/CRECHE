import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../widgets/glass_card.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
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
    if (auth.userData != null) {
      _user = UserModel.fromSupabase(auth.userData!);
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
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.sports)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coach ${_user?.name ?? ""}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Prêt pour la séance ?'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildStats(),
        const SizedBox(height: 32),
        const Text('Vos prochains cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildCourseList(),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Cours', '12', Icons.event, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatItem('Élèves', '45', Icons.people, Colors.orange)),
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

  Widget _buildCourseList() {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        if (provider.courses.isEmpty) return const Text('Aucun cours programmé');
        return Column(
          children: provider.courses.map((course) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${course.category} • ${course.sessions.length} sessions'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          )).toList(),
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
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Nouveau'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
