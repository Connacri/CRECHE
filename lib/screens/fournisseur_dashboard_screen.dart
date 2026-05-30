import 'package:flutter/material.dart';

class FournisseurDashboard extends StatelessWidget {
  const FournisseurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Fournisseur')),
      body: const Center(child: Text('Bienvenue dans votre espace approvisionnement')),
    );
  }
}
