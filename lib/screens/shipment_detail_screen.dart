import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_card.dart';

class ShipmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> shipment;

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
                _buildDriverInfo(context),
                const SizedBox(height: 30),
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
                shipment['id'],
                style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                '04 Juin 2024',
                style: GoogleFonts.oswald(color: Colors.white60),
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.white24),
          _buildInfoRow(Icons.location_on, 'Origine', 'Dépôt Central, Alger'),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.flag, 'Destination', 'Crèche Les Petits Anges, Oran'),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.inventory_2, 'Contenu', 'Matériel pédagogique, Denrées alimentaires'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.oswald(fontSize: 12, color: Colors.white38)),
            Text(value, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
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
          _buildTimelineItem('Livré', 'Arrivée à destination', '08:45', true),
          _buildTimelineItem('En transit', 'Sortie de l\'autoroute Est-Ouest', '07:30', true),
          _buildTimelineItem('Pris en charge', 'Chargement terminé au dépôt', '06:15', true),
          _buildTimelineItem('Planifié', 'Assigné au chauffeur', 'Hier, 18:00', true),
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

  Widget _buildDriverInfo(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chauffeur', style: GoogleFonts.oswald(fontSize: 12, color: Colors.white38)),
                Text('Ahmed Mansouri', style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
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
