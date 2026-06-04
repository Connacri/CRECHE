import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider_v2.dart';
import '../services/hybrid_image_picker.dart';
import '../services/image_storage_service.dart';
import '../widgets/glass_card.dart';

class SchoolProfileScreen extends StatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProviderV2>();
    final user = UserModel.fromSupabase(auth.userData ?? {});
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber);
    _addressController = TextEditingController(text: user.location?.address);
    _cityController = TextEditingController(text: user.location?.city);
    _bioController = TextEditingController(text: user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProviderV2>();
      final user = UserModel.fromSupabase(auth.userData ?? {});
      final updates = <String, dynamic>{
        'name': _nameController.text,
        'bio': _bioController.text,
        'phone_number': _phoneController.text,
        'location': {
          ...user.location?.toMap() ?? {},
          'address': _addressController.text,
          'city': _cityController.text,
        },
      };
      final result = await auth.updateUserProfileSilent(updates);
      if (result.success && mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateProfilePhoto(AuthProviderV2 auth, UserModel user) async {
    try {
      final imageFile = await HybridImagePickerService.pickProfileImage(context: context);
      if (imageFile == null) return;
      final imageUrl = await ImageStorageService().uploadUserProfileImage(
        imageFile: imageFile,
        userId: user.uid,
        isProfileImage: true,
      );
      if (imageUrl != null && mounted) {
        final update = {
          'profile_images': {
            ...user.profileImages.toMap(),
            'profileImageSupabase': '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          },
        };
        await auth.updateUserProfileSilent(update);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo mise à jour')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateCoverPhoto(AuthProviderV2 auth, UserModel user) async {
    try {
      final imageFile = await HybridImagePickerService.pickProfileImage(context: context);
      if (imageFile == null) return;
      final imageUrl = await ImageStorageService().uploadUserProfileImage(
        imageFile: imageFile,
        userId: user.uid,
        isProfileImage: false,
      );
      if (imageUrl != null && mounted) {
        final update = {
          'profile_images': {
            ...user.profileImages.toMap(),
            'coverImageSupabase': '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          },
        };
        await auth.updateUserProfileSilent(update);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur cover: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer définitivement le compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes les données seront supprimées.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final auth = context.read<AuthProviderV2>();
      final result = await auth.deleteAccount();
      if (result.success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${result.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderV2>(
      builder: (context, auth, _) {
        if (auth.currentUser == null || auth.userData == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = UserModel.fromSupabase(auth.userData!);
        final coverUrl = user.profileImages.coverImage;
        final photoUrl = user.profileImages.profileImage;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, user, coverUrl, photoUrl, auth),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 80),
                    _buildNameSection(user),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      _buildEditForm(user)
                    else
                      _buildInfoSection(context, user),
                    const SizedBox(height: 24),
                    _buildActionsSection(context, auth),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    UserModel user,
    String? coverUrl,
    String? photoUrl,
    AuthProviderV2 auth,
  ) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: const BackButton(),
      title: Text(user.name, style: const TextStyle(fontSize: 16)),
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
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _isEditing ? () => _updateCoverPhoto(auth, user) : null,
              child: coverUrl != null
                  ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                  : Container(color: Theme.of(context).colorScheme.primaryContainer),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 0,
              child: GestureDetector(
                onTap: _isEditing ? () => _updateProfilePhoto(auth, user) : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 36, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              )
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (user.location?.city != null)
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(user.location!.city!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, 'Email', user.email),
          const Divider(height: 24),
          _infoRow(Icons.phone_outlined, 'Téléphone', user.phoneNumber ?? 'Non renseigné'),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, 'Adresse', user.location?.address ?? 'Non renseigné'),
          if (user.location?.city != null) ...[
            const Divider(height: 24),
            _infoRow(Icons.location_city, 'Ville', user.location!.city!),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const Divider(height: 24),
            _infoRow(Icons.info_outline, 'Bio', user.bio!),
          ],
          const Divider(height: 24),
          _infoRow(Icons.calendar_today, 'Membre depuis', _formatDate(user.createdAt)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier le profil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom complet', icon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio', icon: Icon(Icons.info_outline)),
              maxLines: 3,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ville', icon: Icon(Icons.location_city)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, AuthProviderV2 auth) {
    return Column(
      children: [
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: () {
                setState(() => _isEditing = false);
                final user = UserModel.fromSupabase(auth.userData ?? {});
                _nameController.text = user.name;
                _phoneController.text = user.phoneNumber ?? '';
                _addressController.text = user.location?.address ?? '';
                _cityController.text = user.location?.city ?? '';
                _bioController.text = user.bio ?? '';
              },
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
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _confirmDeleteAccount,
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text('Supprimer mon compte définitivement', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
