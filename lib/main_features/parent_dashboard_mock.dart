import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/mock_services.dart';
import '../theme/app_theme.dart';
import 'story_detail_screen.dart';
import 'package:intl/intl.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = MockDatabaseService();
    final user = context.watch<MockAuthService>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bonjour 👋'),
        actions: [
          IconButton(onPressed: () => context.read<MockAuthService>().logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Selector
            SizedBox(
              height: 100,
              child: FutureBuilder<List<Child>>(
                future: db.getChildren(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final child = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(child.avatarUrl),
                              backgroundColor: AppColors.softPurple,
                            ),
                            const SizedBox(height: 5),
                            Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // Story Section (Innovative Feature)
            _buildSectionTitle('L\'histoire du soir 🌙'),
            FutureBuilder<List<Story>>(
              future: db.getStories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final story = snapshot.data![0];
                return Card(
                  color: AppColors.softPurple,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StoryDetailScreen(story: story)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(story.coverImage, height: 80, width: 80, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Par ${story.author}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 5),
                                const Text('Prêt à raconter ? ✨', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Timeline / Today
            _buildSectionTitle('Aujourd\'hui'),
            _buildInfoCard(
              icon: Icons.restaurant,
              color: AppColors.softOrange,
              title: 'Au menu',
              subtitle: 'Purée de carottes & Compote',
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.brush,
              color: AppColors.softGreen,
              title: 'Activité',
              subtitle: 'Peinture aux doigts à 15h30',
            ),
            const SizedBox(height: 10),
             _buildInfoCard(
              icon: Icons.receipt_long,
              color: AppColors.softBlue,
              title: 'Facturation',
              subtitle: '1 facture en attente',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Histoires'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: 0,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
