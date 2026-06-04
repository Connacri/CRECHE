import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'club_members_screen.dart';
import 'club_events_screen.dart';
import 'club_finance_screen.dart';
import 'club_coaches_screen.dart';
import 'school_profile_screen.dart';
import 'club_logs_screen.dart';

class ClubMenuScreen extends StatelessWidget {
  const ClubMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.people, 'Adhérents', const ClubMembersScreen(), Colors.blue),
      _MenuItem(Icons.people_outline, 'Coaches', const ClubCoachesScreen(), Colors.indigo),
      _MenuItem(Icons.event, 'Événements', const ClubEventsScreen(), Colors.purple),
      _MenuItem(Icons.account_balance, 'Finances', const ClubFinanceScreen(), Colors.green),
      _MenuItem(Icons.history, 'Journal', const ClubLogsScreen(), Colors.blueGrey),
      _MenuItem(Icons.person, 'Profil', const SchoolProfileScreen(), Colors.orange),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            debugPrint('Menu Tapped: ${item.label}');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.screen),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, size: 36, color: item.color),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Widget screen;
  final Color color;
  _MenuItem(this.icon, this.label, this.screen, this.color);
}
