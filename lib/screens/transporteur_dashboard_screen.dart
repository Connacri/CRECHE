import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import 'shipment_detail_screen.dart';
import '../services/shipment_service.dart';
import '../models/shipment_model.dart';

class TransporteurDashboard extends StatelessWidget {
  const TransporteurDashboard({super.key});

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
          'LOGISTIQUE',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
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
              _buildHeader(context, user),
              Expanded(
                child: StreamBuilder<List<ShipmentModel>>(
                  stream: shipmentService.getShipmentsStream(transporteurId: user?.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    final shipments = snapshot.data ?? [];
                    if (shipments.isEmpty) {
                      return const Center(child: Text('Aucune expédition en cours'));
                    }
                    return _buildShipmentList(context, shipments);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.profileImages.profileImage != null 
                  ? NetworkImage(user!.profileImages.profileImage!) 
                  : const AssetImage('assets/images/app_icon.jpg') as ImageProvider,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${user?.name ?? "Transporteur"}',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Suivi de vos expéditions en temps réel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentList(BuildContext context, List<ShipmentModel> shipments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        final progress = _calculateProgress(shipment.status);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShipmentDetailScreen(shipment: shipment),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      shipment.trackingNumber,
                      style: GoogleFonts.oswald(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildStatusChip(shipment.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${shipment.originAddress ?? "N/A"} -> ${shipment.destinationAddress ?? "N/A"}',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  shipment.estimatedDelivery != null 
                      ? 'Livraison prévue: ${shipment.estimatedDelivery!.day}/${shipment.estimatedDelivery!.month}'
                      : 'Livraison non planifiée',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateProgress(String status) {
    switch (status) {
      case 'pending': return 0.1;
      case 'picked_up': return 0.3;
      case 'in_transit': return 0.65;
      case 'delivered': return 1.0;
      default: return 0.0;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'in_transit':
        color = Colors.blue;
        label = 'En transit';
        break;
      case 'picked_up':
        color = Colors.orange;
        label = 'Chargement';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Livré';
        break;
      case 'pending':
        color = Colors.grey;
        label = 'Attente';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.oswald(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
