import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import '../services/shipment_service.dart';
import '../models/shipment_model.dart';
import 'shipment_detail_screen.dart';

class FournisseurDashboard extends StatelessWidget {
  const FournisseurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProviderV2>().user;
    final shipmentService = ShipmentService();

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
              _buildStatsHeader(context, user),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Expéditions Récentes',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<ShipmentModel>>(
                  stream: shipmentService.getShipmentsStream(senderId: user?.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final shipments = snapshot.data ?? [];
                    if (shipments.isEmpty) {
                      return const Center(child: Text('Aucune expédition trouvée'));
                    }
                    return _buildOrderList(context, shipments);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, UserModel? user) {
    // In a full implementation, these would also come from real-time streams/counts
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
                  Text('Stock', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
                  const Icon(Icons.inventory, size: 20),
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
                  Text('Actif', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
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
                  Text('Prêt', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<ShipmentModel> shipments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShipmentDetailScreen(shipment: shipment),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.trackingNumber,
                        style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Vers: ${shipment.destinationAddress ?? "Inconnu"}',
                        style: GoogleFonts.oswald(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'Statut: ${shipment.status}',
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
