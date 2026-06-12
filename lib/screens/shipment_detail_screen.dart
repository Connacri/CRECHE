import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';
import '../models/shipment_model.dart';
import 'package:intl/intl.dart';

class ShipmentDetailScreen extends StatelessWidget {
  final ShipmentModel shipment;

  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Détails de l\'expédition',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_bg_zoomed.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMainInfo(context),
                const SizedBox(height: 20),
                _buildTimeline(context),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shipment.trackingNumber,
                style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(shipment.createdAt),
                style: GoogleFonts.oswald(color: Colors.white60),
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.white24),
          _buildInfoRow(Icons.location_on, 'Origine', shipment.originAddress ?? 'N/A'),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.flag, 'Destination', shipment.destinationAddress ?? 'N/A'),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.inventory_2, 'Statut', shipment.status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.oswald(fontSize: 12, color: Colors.white38)),
              Text(value, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivi', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTimelineItem('Livré', 'Arrivée à destination', '', shipment.status == 'delivered'),
          _buildTimelineItem('En transit', 'Expédition en cours', '', shipment.status == 'in_transit' || shipment.status == 'delivered'),
          _buildTimelineItem('Pris en charge', 'Collecté par le transporteur', '', ['picked_up', 'in_transit', 'delivered'].contains(shipment.status)),
          _buildTimelineItem('Planifié', 'Expédition enregistrée', DateFormat('HH:mm').format(shipment.createdAt), true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String time, bool isDone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 40, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.oswald(fontWeight: FontWeight.bold, color: isDone ? Colors.white : Colors.white38)),
              Text(subtitle, style: GoogleFonts.oswald(fontSize: 12, color: Colors.white60)),
            ],
          ),
        ),
        Text(time, style: GoogleFonts.oswald(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.map),
            label: const Text('Voir Carte'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner QR'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}
