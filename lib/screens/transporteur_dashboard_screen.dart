import 'package:flutter/material.dart';

class TransporteurDashboard extends StatelessWidget {
  const TransporteurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Transporteur')),
      body: const Center(child: Text('Bienvenue dans votre espace logistique')),
    );
  }
}
