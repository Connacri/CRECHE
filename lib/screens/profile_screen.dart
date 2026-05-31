import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider_v2.dart';
import '../models/user_model.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/meditation_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Consumer<AuthProviderV2>(
            builder: (context, auth, _) {
              if (auth.currentUser == null || auth.userData == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = UserModel.fromSupabase(auth.userData!);
              return SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: const BackButton(),
                      title: const Text('Profil'),
                      pinned: true,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildAvatarSection(context, user),
                          const SizedBox(height: 32),
                          _buildInfoSection(context, user),
                          const SizedBox(height: 32),
                          _buildActionsSection(context, auth),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, UserModel user) {
    final photoUrl = user.profileImages.profileImage;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 40)) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 18,
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Téléphone', user.phoneNumber ?? 'Non renseigné'),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Adresse', user.location?.address ?? 'Non renseigné'),
          const Divider(height: 32),
          _buildInfoRow(Icons.person_outline, 'Rôle', user.role.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, AuthProviderV2 auth) {
    return Column(
      children: [
        FilledButton.tonalIcon(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier le profil'),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => auth.logout(),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }
}
