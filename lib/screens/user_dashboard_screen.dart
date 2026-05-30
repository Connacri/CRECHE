import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Utilisateur')),
      body: const Center(child: Text('Explorez les services de Crèche')),
    );
  }
}
