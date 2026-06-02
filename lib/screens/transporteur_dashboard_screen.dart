import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_v2.dart';

class TransporteurDashboard extends StatelessWidget {
  const TransporteurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Transporteur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProviderV2>().logout(),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: const Center(child: Text('Bienvenue dans votre espace logistique')),
    );
  }
}
