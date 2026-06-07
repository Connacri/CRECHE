import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/child_model_complete.dart';
import '../providers/child_enrollment_provider.dart';
import '../services/hybrid_image_picker.dart';

class ChildFormDialog extends StatefulWidget {
  final String parentId;
  final ChildModel? child;

  const ChildFormDialog({super.key, required this.parentId, this.child});

  @override
  State<ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _schoolGradeController;
  DateTime? _dateOfBirth;
  ChildGender _gender = ChildGender.male;
  File? _photo;
  File? _birthCertificate;
  File? _medicalCertificate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.child?.firstName);
    _lastNameController = TextEditingController(text: widget.child?.lastName);
    _schoolGradeController = TextEditingController(text: widget.child?.schoolGrade);
    _dateOfBirth = widget.child?.dateOfBirth;
    if (widget.child != null) _gender = widget.child!.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolGradeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await HybridImagePickerService.pickImage(context: context, crop: true, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
    if (image != null) {
      setState(() => _photo = image);
    }
  }

  Future<void> _pickBirthCertificate() async {
    final file = await HybridImagePickerService.pickImage(context: context, crop: false);
    if (file != null) {
      setState(() => _birthCertificate = file);
    } else {
      final doc = await HybridImagePickerService.pickDocument(context: context);
      if (doc != null) setState(() => _birthCertificate = doc);
    }
  }

  Future<void> _pickMedicalCertificate() async {
    final file = await HybridImagePickerService.pickImage(context: context, crop: false);
    if (file != null) {
      setState(() => _medicalCertificate = file);
    } else {
      if (!mounted) return;
      final doc = await HybridImagePickerService.pickDocument(context: context);
      if (doc != null) setState(() => _medicalCertificate = doc);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || (_dateOfBirth == null && widget.child == null)) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<ChildEnrollmentProvider>();

    bool success;
    if (widget.child == null) {
      success = await provider.addChild(
        parentId: widget.parentId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        photoFile: _photo,
        birthCertificateFile: _birthCertificate,
        medicalCertificateFile: _medicalCertificate,
        schoolGrade: _schoolGradeController.text,
      );
    } else {
      success = await provider.updateChild(
        childId: widget.child!.id,
        parentId: widget.parentId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        newPhoto: _photo,
        newBirthCertificate: _birthCertificate,
        newMedicalCertificate: _medicalCertificate,
        schoolGrade: _schoolGradeController.text,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Une erreur est survenue')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.child == null ? 'Ajouter un enfant' : 'Modifier l\'enfant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _photo != null
                      ? FileImage(_photo!)
                      : (widget.child?.photoUrl != null ? CachedNetworkImageProvider(widget.child!.photoUrl!) : null) as ImageProvider?,
                  child: _photo == null && widget.child?.photoUrl == null ? const Icon(Icons.camera_alt, size: 30) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_dateOfBirth == null
                    ? 'Date de naissance'
                    : 'Né(e) le: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 3)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChildGender>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: ChildGender.values.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g == ChildGender.male ? 'Garçon' : g == ChildGender.female ? 'Fille' : 'Autre'),
                )).toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              TextFormField(
                controller: _schoolGradeController,
                decoration: const InputDecoration(labelText: 'Niveau scolaire (ex: Petite Section)'),
              ),
              const SizedBox(height: 24),
              _buildDocumentPicker(
                label: "Extrait de naissance",
                file: _birthCertificate,
                currentUrl: widget.child?.birthCertificateUrl,
                onTap: _pickBirthCertificate,
              ),
              const SizedBox(height: 16),
              _buildDocumentPicker(
                label: "Certificat médical",
                file: _medicalCertificate,
                currentUrl: widget.child?.medicalCertificateUrl,
                onTap: _pickMedicalCertificate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Enregistrer"),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    File? file,
    String? currentUrl,
    required VoidCallback onTap,
  }) {
    final bool hasFile = file != null || currentUrl != null;
    final bool isImage = file != null && (file.path.endsWith('.jpg') || file.path.endsWith('.png') || file.path.endsWith('.jpeg')) ||
                        (currentUrl != null && (currentUrl.toLowerCase().contains('.jpg') || currentUrl.toLowerCase().contains('.png') || currentUrl.toLowerCase().contains('.jpeg')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasFile ? Colors.green.withValues(alpha: 0.5) : Colors.grey[300]!),
            ),
            child: hasFile
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (isImage)
                          Positioned.fill(
                            child: file != null
                              ? Image.file(file, fit: BoxFit.cover)
                              : CachedNetworkImage(imageUrl: currentUrl!, fit: BoxFit.cover, placeholder: (c,u) => const Center(child: CircularProgressIndicator()), errorWidget: (c,u,e) => const Icon(Icons.error)),
                          )
                        else
                          const Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description, size: 40, color: Colors.blue),
                              Text("Fichier PDF/Doc", style: TextStyle(fontSize: 10)),
                            ],
                          )),
                        Container(color: Colors.black26),
                        const Center(child: Icon(Icons.refresh, color: Colors.white, size: 30)),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 32, color: Colors.grey),
                      SizedBox(height: 4),
                      Text("Cliquez pour télécharger", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
