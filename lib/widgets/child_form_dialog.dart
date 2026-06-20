import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/child_model_complete.dart';
import '../models/models_widgets.dart';
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
  
  // Medical Info Controllers
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _notesController;

  DateTime? _dateOfBirth;
  ChildGender _gender = ChildGender.male;
  File? _photo;
  File? _birthCertificate;
  File? _medicalCertificate;
  bool _isLoading = false;

  String? _selectedBloodType;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.child?.firstName);
    _lastNameController = TextEditingController(text: widget.child?.lastName);
    _schoolGradeController = TextEditingController(text: widget.child?.schoolGrade);
    
    final medical = widget.child?.medicalInfo;
    _bloodTypeController = TextEditingController(text: medical?.bloodType);
    _selectedBloodType = medical?.bloodType;
    _allergiesController = TextEditingController(text: medical?.allergies.join(', '));
    _medicationsController = TextEditingController(text: medical?.medications.join(', '));
    _emergencyContactController = TextEditingController(text: medical?.emergencyContact);
    _emergencyPhoneController = TextEditingController(text: medical?.emergencyPhone);
    _notesController = TextEditingController(text: medical?.additionalNotes);

    _dateOfBirth = widget.child?.dateOfBirth;
    if (widget.child != null) _gender = widget.child!.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolGradeController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await HybridImagePickerService.pickImage(context: context, crop: true, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
    if (image != null) {
      setState(() => _photo = image);
    }
  }

  Future<void> _pickBirthCertificate() async {
    final file = await HybridImagePickerService.pickBirthCertificate(context: context);
    if (file != null) {
      setState(() => _birthCertificate = file);
    }
  }

  Future<void> _pickMedicalCertificate() async {
    final file = await HybridImagePickerService.pickMedicalCertificate(context: context);
    if (file != null) {
      setState(() => _medicalCertificate = file);
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

    final medicalInfo = MedicalInfo(
      bloodType: _selectedBloodType,
      allergies: _allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      medications: _medicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      emergencyContact: _emergencyContactController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
      additionalNotes: _notesController.text.trim(),
    );

    bool success;
    if (widget.child == null) {
      success = await provider.addChild(
        parentId: widget.parentId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        photoFile: _photo,
        birthCertificateFile: _birthCertificate,
        medicalCertificateFile: _medicalCertificate,
        schoolGrade: _schoolGradeController.text.trim(),
        medicalInfo: medicalInfo,
      );
    } else {
      success = await provider.updateChild(
        childId: widget.child!.id,
        parentId: widget.parentId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        newPhoto: _photo,
        newBirthCertificate: _birthCertificate,
        newMedicalCertificate: _medicalCertificate,
        schoolGrade: _schoolGradeController.text.trim(),
        medicalInfo: medicalInfo,
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
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _photo != null
                          ? FileImage(_photo!)
                          : (widget.child?.photoUrl != null ? CachedNetworkImageProvider(widget.child!.photoUrl!) : null) as ImageProvider?,
                      child: _photo == null && widget.child?.photoUrl == null ? const Icon(Icons.camera_alt, size: 30) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Informations de base', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const Divider(),
                
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(_dateOfBirth == null
                      ? 'Sélectionner la date de naissance'
                      : 'Né(e) le: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SegmentedButton<ChildGender>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ChildGender.male,
                            icon: Icon(Icons.male, size: 28),
                            tooltip: 'Garçon',
                          ),
                          ButtonSegment(
                            value: ChildGender.female,
                            icon: Icon(Icons.female, size: 28),
                            tooltip: 'Fille',
                          ),
                        ],
                        selected: {_gender},
                        onSelectionChanged: (Set<ChildGender> newSelection) {
                          setState(() => _gender = newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.comfortable,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          selectedBackgroundColor: _gender == ChildGender.male 
                              ? Colors.blue.withValues(alpha: 0.2) 
                              : Colors.pink.withValues(alpha: 0.2),
                          selectedForegroundColor: _gender == ChildGender.male 
                              ? Colors.blue 
                              : Colors.pink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _schoolGradeController,
                        decoration: const InputDecoration(
                          labelText: 'Niveau',
                          prefixIcon: Icon(Icons.school),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text('Santé & Urgence', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Groupe sanguin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bloodTypes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.8,
                      ),
                      itemBuilder: (context, index) {
                        final type = bloodTypes[index];
                        final selected = _selectedBloodType == type;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBloodType = type;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // TextFormField(
                //   controller: _bloodTypeController,
                //   decoration: const InputDecoration(labelText: 'Groupe Sanguin (ex: A+)', prefixIcon: Icon(Icons.bloodtype)),
                // ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Allergies (séparées par des virgules)',
                    prefixIcon: Icon(Icons.warning_amber),
                    hintText: 'ex: Arachides, Pénicilline',
                  ),
                ),
                TextFormField(
                  controller: _medicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Médicaments réguliers',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyContactController,
                  decoration: const InputDecoration(labelText: 'Contact d\'urgence (Nom)', prefixIcon: Icon(Icons.contact_phone)),
                ),
                TextFormField(
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone d\'urgence', prefixIcon: Icon(Icons.phone)),
                ),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes médicales additionnelles', prefixIcon: Icon(Icons.note_alt)),
                ),
                
                const SizedBox(height: 32),
                const Text('Documents Officiels', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const Divider(),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDocumentPicker(
                        label: "Extrait de naissance",
                        file: _birthCertificate,
                        currentUrl: widget.child?.birthCertificateUrl,
                        onTap: _pickBirthCertificate,
                        onRemove: () => setState(() => _birthCertificate = null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDocumentPicker(
                        label: "Certificat médical",
                        file: _medicalCertificate,
                        currentUrl: widget.child?.medicalCertificateUrl,
                        onTap: _pickMedicalCertificate,
                        onRemove: () => setState(() => _medicalCertificate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Enregistrer"),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    File? file,
    String? currentUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null || currentUrl != null;
    final bool isImage = (file != null && (file.path.toLowerCase().endsWith('.jpg') || file.path.toLowerCase().endsWith('.png') || file.path.toLowerCase().endsWith('.jpeg'))) ||
                        (currentUrl != null && (currentUrl.toLowerCase().contains('.jpg') || currentUrl.toLowerCase().contains('.png') || currentUrl.toLowerCase().contains('.jpeg')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (hasFile)
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: isImage
                      ? (file != null
                          ? Image.file(file, fit: BoxFit.cover)
                          : CachedNetworkImage(imageUrl: currentUrl!, fit: BoxFit.cover, placeholder: (c, u) => const Center(child: CircularProgressIndicator())))
                      : Container(
                          color: Colors.grey[50],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_rounded, size: 60, color: Colors.blue.shade400),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    file != null ? file.path.split('/').last : "Document",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 48, color: Colors.blue.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    "Ajouter",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }


}
