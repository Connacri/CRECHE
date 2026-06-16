import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import 'package:intl/intl.dart';

class AutresDashboardScreen extends StatefulWidget {
  const AutresDashboardScreen({super.key});

  @override
  State<AutresDashboardScreen> createState() => _AutresDashboardScreenState();
}

class _AutresDashboardScreenState extends State<AutresDashboardScreen> {
  String _formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProviderV2>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Utilisateur non trouvé')));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/forest_bg_zoomed.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(user),
                const SizedBox(height: 20),
                _buildCoverAndAvatar(user),
                const SizedBox(height: 60), // Increased height for avatar overflow
                _buildProfileInfo(user),
                const SizedBox(height: 20),
                _buildProfessionalInfo(user),
                const SizedBox(height: 20),
                _buildSystemInfo(user),
                const SizedBox(height: 30),
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de Bord',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Profil ${user.role.displayName}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        _buildRoleBadge(user.role),
      ],
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    IconData icon;
    Color color;

    switch (role) {
      case UserRole.parent:
        icon = Icons.family_restroom;
        color = Colors.blue;
        break;
      case UserRole.coach:
        icon = Icons.sports;
        color = Colors.green;
        break;
      case UserRole.school:
        icon = Icons.school;
        color = Colors.orange;
        break;
      case UserRole.transporteur:
        icon = Icons.local_shipping;
        color = Colors.teal;
        break;
      case UserRole.fournisseur:
        icon = Icons.inventory_2;
        color = Colors.deepPurple;
        break;
      case UserRole.user:
        icon = Icons.person;
        color = Colors.indigo;
        break;
      case UserRole.autres:
        icon = Icons.account_box;
        color = Colors.blue;
        break;
      case UserRole.admin:
        icon = Icons.admin_panel_settings;
        color = Colors.red;
        break;
      case UserRole.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        role.displayName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withValues(alpha: 0.7),
    );
  }

  Widget _buildCoverAndAvatar(UserModel user) {
    final coverUrl = user.profileImages.coverImage;
    final profileUrl = user.profileImages.profileImage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          opacity: 0.3,
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: coverUrl != null
                ? Image.network(coverUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          bottom: -40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: profileUrl != null
                  ? NetworkImage(profileUrl)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserModel user) {
    final hasLocation = user.location?.hasLocation ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadOnlyField(label: 'Nom complet', value: user.name),
          _buildReadOnlyField(label: 'Email', value: user.email),
          _buildReadOnlyField(label: 'Téléphone', value: user.phoneNumber ?? 'Non renseigné'),
          if (hasLocation)
            _buildReadOnlyField(label: 'Adresse', value: user.location!.address),
          _buildReadOnlyField(label: 'Bio', value: user.bio ?? 'Aucune bio', isLongText: true),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo(UserModel user) {
    if (user.role != UserRole.coach && user.role != UserRole.school) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Professionnelles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(label: 'Palmarès', value: user.palmares ?? 'Non renseigné', isLongText: true),
          _buildListField(label: 'Diplômes', items: user.diplomas),
          _buildListField(label: 'Certificats', items: user.certificates),
          if (user.cvUrl != null)
            ListTile(
              leading: const Icon(Icons.description, color: Colors.white),
              title: const Text('CV / Documentation', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.open_in_new, color: Colors.white70),
              onTap: () {
                // Logic to open URL
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données Système',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(label: 'ID Unique', value: user.uid),
          _buildReadOnlyField(label: 'Créé le', value: _formatDateTime(user.createdAt)),
          _buildReadOnlyField(label: 'Mis à jour le', value: _formatDateTime(user.updatedAt)),
          _buildReadOnlyField(label: 'Statut', value: user.isActive ? 'Actif' : 'Inactif'),
          _buildReadOnlyField(label: 'Profil complété', value: user.profileCompleted ? 'Oui' : 'Non'),
          _buildImageInfo(
            label: 'Photo de profil',
            url: user.profileImages.profileImageSupabase,
          ),
          _buildImageInfo(
            label: 'Image de couverture',
            url: user.profileImages.coverImageSupabase,
          ),
          if (user.profileImages.lastUpdated != null)
            _buildReadOnlyField(
              label: 'Dernière mise à jour',
              value: _formatDateTime(user.profileImages.lastUpdated!),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: isLongText ? 5 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildListField({required String label, List<String>? items}) {
    if (items == null || items.isEmpty) {
      return _buildReadOnlyField(label: label, value: 'Aucun');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: items.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white24,
            )).toList(),
          ),
          const Divider(color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildImageInfo({required String label, String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            url != null ? 'Disponible' : 'Non disponible',
            style: TextStyle(
              color: url != null ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Provider.of<AuthProviderV2>(context, listen: false).logout(),
        icon: const Icon(Icons.logout),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
