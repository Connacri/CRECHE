import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider_v2.dart';
import '../models/user_model.dart';
import '../services/image_storage_service.dart';
import '../widgets/glass_card.dart';
import '../services/hybrid_image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _palmaresController;

  List<String> _diplomas = [];
  List<String> _certificates = [];
  String? _cvUrl;

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
    _palmaresController = TextEditingController(text: user.palmares);
    _diplomas = List<String>.from(user.diplomas ?? []);
    _certificates = List<String>.from(user.certificates ?? []);
    _cvUrl = user.cvUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _palmaresController.dispose();
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
        },
        'palmares': _palmaresController.text,
        'diplomas': _diplomas,
        'certificates': _certificates,
        'cv_url': _cvUrl,
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

  Future<void> _pickFile(bool isCV, {bool isDiploma = false}) async {
    File? pickedFile;
    if (isCV) {
      pickedFile = await HybridImagePickerService.pickDocument(context: context);
    } else if (isDiploma) {
      pickedFile = await HybridImagePickerService.pickDiploma(context: context);
    } else {
      pickedFile = await HybridImagePickerService.pickMedicalCertificate(context: context);
    }

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isSaving = true);
      try {
        final auth = context.read<AuthProviderV2>();
        final url = await ImageStorageService().uploadFile(pickedFile, '${auth.currentUser!.uid}/coach_docs');

        if (url != null) {
          setState(() {
            if (isCV) {
              _cvUrl = url;
            } else if (isDiploma) {
              _diplomas.add(url);
            } else {
              _certificates.add(url);
            }
          });
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildProfileHeader(context, auth, user),
                            const SizedBox(height: 24),
                            _isEditing ? _buildEditForm(user) : _buildInfoSection(context, user),
                            const SizedBox(height: 24),
                            _buildActionsSection(context, auth),
                          ],
                        ),
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

  Widget _buildProfileHeader(BuildContext context, AuthProviderV2 auth, UserModel user) {
    final photoUrl = user.profileImages.profileImage;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _updateProfilePhoto(auth, user),
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
        final profileImagesUpdate = {
          'profile_images': {
            ...user.profileImages.toMap(),
            'profileImageSupabase': '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          }
        };
        
        await auth.updateUserProfileSilent(profileImagesUpdate);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour !')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildEditForm(UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (user.role == UserRole.coach) ...[
              const Divider(height: 32),
              const Text('Professionnel (Coach)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _palmaresController,
                decoration: const InputDecoration(labelText: 'Palmarès / Expérience', icon: Icon(Icons.emoji_events_outlined)),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildDocPicker('CV', _cvUrl, () => _pickFile(true)),
              const SizedBox(height: 16),
              _buildDocList('Diplômes', _diplomas, () => _pickFile(false, isDiploma: true)),
              const SizedBox(height: 16),
              _buildDocList('Certificats', _certificates, () => _pickFile(false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocPicker(String label, String? url, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildThumbnailPreview(url, onTap, placeholder: Icons.description),
      ],
    );
  }

  Widget _buildDocList(String label, List<String> urls, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
          ],
        ),
        if (urls.isEmpty)
          const Text('Aucun document', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (c,i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = urls[index];
                return Stack(
                  children: [
                    _buildThumbnailPreview(url, () {}, size: 100),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => urls.remove(url)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailPreview(String? url, VoidCallback onTap, {IconData placeholder = Icons.image, double size = 120}) {
    final bool hasFile = url != null;
    final bool isImage = url != null && (url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('.png') || url.toLowerCase().contains('.jpeg'));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasFile ? Colors.green.withValues(alpha: 0.5) : Colors.grey[300]!),
        ),
        child: hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isImage
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (c,u) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (c,u,e) => const Icon(Icons.error)
                      )
                    : Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(placeholder, size: size/3, color: Colors.blue),
                          const Text("Fichier", style: TextStyle(fontSize: 10)),
                        ],
                      )),
              )
            : Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[400], size: size/3)),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Téléphone', user.phoneNumber ?? 'Non renseigné'),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on_outlined, 'Adresse', user.location?.address ?? 'Non renseigné'),
          const Divider(height: 32),
          _buildInfoRow(Icons.person_outline, 'Rôle', user.role.displayName),
          if (user.role == UserRole.coach) ...[
            const Divider(height: 32),
            const Text('Informations Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.emoji_events, 'Palmarès', user.palmares ?? 'Non renseigné'),
            const SizedBox(height: 24),
            _buildDocDisplay('CV', user.cvUrl),
            const SizedBox(height: 16),
            _buildDocDisplayList('Diplômes', user.diplomas ?? []),
            const SizedBox(height: 16),
            _buildDocDisplayList('Certificats', user.certificates ?? []),
          ],
        ],
      ),
    );
  }

  Widget _buildDocDisplay(String label, String? url) {
    if (url == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        _buildThumbnailPreview(url, () {}, placeholder: Icons.description, size: 100),
      ],
    );
  }

  Widget _buildDocDisplayList(String label, List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (c,i) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildThumbnailPreview(urls[index], () {}, size: 100),
          ),
        ),
      ],
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
        const SizedBox(height: 60),


        TextButton.icon(
          onPressed: _confirmDeleteAccount,
         // icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text('Supprimer mon compte définitivement', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 8)),
          // style: TextButton.styleFrom(
          //   minimumSize: const Size(double.infinity, 50),
          //   padding: const EdgeInsets.symmetric(vertical: 12),
          // ),
        ),
      ],
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text('Cette action est irréversible. Toutes vos données seront supprimées après 30 jours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final auth = dialogContext.read<AuthProviderV2>();
              await auth.deleteAccount();
              if (mounted) {
                // Check if dialog is still open by checking its context's mounted property
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
