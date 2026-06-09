import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';

class FournisseurDashboard extends StatelessWidget {
  const FournisseurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FOURNISSEUR',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProviderV2>().logout(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_bg_zoomed.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Commandes Récentes',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildOrderList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Icon(Icons.shopping_cart, size: 30),
                  const SizedBox(height: 5),
                  Text('12', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Commandes', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Icon(Icons.pending_actions, size: 30, color: Colors.orange),
                  const SizedBox(height: 5),
                  Text('4', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('À préparer', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 30, color: Colors.green),
                  const SizedBox(height: 5),
                  Text('8', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Livrées', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {'id': 'CMD-782', 'client': 'Crèche Les Petits Anges', 'items': '5x Lait, 10x Couches', 'status': 'En préparation'},
      {'id': 'CMD-785', 'client': 'EURL Logistique Pro', 'items': '2x Bureaux, 4x Chaises', 'status': 'Prêt pour expédition'},
      {'id': 'CMD-789', 'client': 'Pharmacie Centrale', 'items': '20x Gants, 15x Masques', 'status': 'Validée'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['id'],
                        style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        order['client'],
                        style: GoogleFonts.oswald(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        order['items'],
                        style: GoogleFonts.oswald(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        );
      },
    );
  }
}
