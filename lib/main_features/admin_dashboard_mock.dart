import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mock_services.dart';
import 'app_theme_mock.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion Crèche'),
          actions: [
            IconButton(onPressed: () => context.read<MockAuthService>().logout(), icon: const Icon(Icons.logout)),
          ],
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildAdminCard(context, 'Présences', Icons.people, AppColors.adminPrimary, '12 enfants'),
            _buildAdminCard(context, 'Factures', Icons.euro, AppColors.softGreen, '4 impayées'),
            _buildAdminCard(context, 'Menus', Icons.restaurant, AppColors.softOrange, 'Semaine 22'),
            _buildAdminCard(context, 'Personnel', Icons.badge, AppColors.adminSecondary, '8 actifs'),
            _buildAdminCard(context, 'Histoires', Icons.auto_stories, AppColors.softPurple, 'Bibliothèque'),
            _buildAdminCard(context, 'Paramètres', Icons.settings, Colors.grey, 'Config'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppColors.adminPrimary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color, String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(status, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}
