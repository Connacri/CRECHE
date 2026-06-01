import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider_v2.dart';
import '../models/user_model.dart';
import '../services/image_storage_service.dart';
import '../widgets/glass_card.dart';
import '../services/hybrid_image_picker.dart';

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProviderV2>();
    final user = UserModel.fromSupabase(auth.userData ?? {});
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _addressController = TextEditingController(text: user.location?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProviderV2>();
      final updates = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'location': {
          ...(UserModel.fromSupabase(auth.userData ?? {}).location?.toMap() ?? {}),
          'address': _addressController.text,
        }
      };

      final result = await auth.updateUserProfileSilent(updates);
      if (result.success && mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                      actions: [
                        if (!_isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => setState(() => _isEditing = true),
                          )
                        else
                          IconButton(
                            icon: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check, color: Colors.green),
                            onPressed: _isSaving ? null : _saveProfile,
                          ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildAvatarSection(context, user, auth),
                          const SizedBox(height: 32),
                          if (_isEditing) _buildEditForm() else _buildInfoSection(context, user),
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

  Widget _buildAvatarSection(BuildContext context, UserModel user, AuthProviderV2 auth) {
    final photoUrl = user.profileImages.profileImage;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _updateProfilePhoto(context, auth, user),
          child: Stack(
            children: [
              CircleAvatar(
                key: ValueKey(photoUrl ?? 'no-avatar'),
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              if (auth.isLoading || _isSaving)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_isEditing) ...[
          Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Future<void> _updateProfilePhoto(BuildContext context, AuthProviderV2 auth, UserModel user) async {
    try {
      final imageFile = await HybridImagePickerService.pickProfileImage(context: context);
      if (imageFile == null) return;

      final imageUrl = await ImageStorageService().uploadUserProfileImage(
        imageFile: imageFile,
        userId: user.uid,
        isProfileImage: true,
      );

      if (imageUrl != null && mounted) {
        final profileImagesUpdate = {
          'profile_images': {
            ...user.profileImages.toMapSupabase(),
            'profileImageSupabase': '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          }
        };
        await auth.updateUserProfileSilent(profileImagesUpdate);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour !')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildEditForm() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom complet', icon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone', icon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse', icon: Icon(Icons.location_on_outlined)),
              maxLines: 2,
            ),
          ],
        ),
      ),
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
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Annuler les modifications'),
            ),
          ),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
