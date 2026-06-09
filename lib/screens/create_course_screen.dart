import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../providers/auth_provider_v2.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../services/club_service.dart';
import '../widgets/location_picker_dialog_widget.dart';
import '../widgets/location_picker_windows.dart';
import '../services/hybrid_image_picker.dart';

class CreateCourseScreen extends StatefulWidget {
  final CourseModel? courseToEdit;

  const CreateCourseScreen({super.key, this.courseToEdit});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  CourseCategory _selectedCategory = CourseCategory.other;
  CourseSeason _selectedSeason = CourseSeason.yearRound;
  DateTime _seasonStartDate = DateTime.now();
  DateTime _seasonEndDate = DateTime.now().add(const Duration(days: 365));
  CourseLocation? _selectedLocation;
  final List<File> _selectedImages = [];
  bool _isLoadingLocation = false;

  List<UserModel> _availableClubs = [];
  UserModel? _selectedClub;
  bool _isLoadingClubs = false;

  @override
  void initState() {
    super.initState();
    _loadClubs();
    if (widget.courseToEdit != null) {
      _loadCourseData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentLocation();
      });
    }
  }

  void _loadCourseData() {
    final course = widget.courseToEdit!;
    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _priceController.text = course.price?.toString() ?? '';
    _maxStudentsController.text = course.maxStudents.toString();
    _selectedCategory = course.category;
    _selectedSeason = course.season;
    _seasonStartDate = course.seasonStartDate;
    _seasonEndDate = course.seasonEndDate;
    _selectedLocation = course.location;
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoadingClubs = true);
    try {
      final clubs = await ClubService().getAvailableClubs();
      setState(() {
        _availableClubs = clubs;
        if (widget.courseToEdit?.clubId != null) {
          _selectedClub = _availableClubs.firstWhere(
            (c) => c.uid == widget.courseToEdit!.clubId,
            orElse: () => _availableClubs.first, // Fallback or handle differently
          );
        }
      });
    } catch (e) {
      print('Error loading clubs: $e');
    } finally {
      setState(() => _isLoadingClubs = false);
    }
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final locationService = LocationService();
      final location = await locationService.getCurrentCourseLocation();
      if (location != null && mounted) {
        setState(() {
          _selectedLocation = location;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur localisation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _seasonStartDate : _seasonEndDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _seasonStartDate = picked;
        } else {
          _seasonEndDate = picked;
        }
      });
    }
  }

  Future<void> _selectLocation() async {
    final bool useWindowsVersion = !kIsWeb && Platform.isWindows;

    final CourseLocation? result = await showDialog<CourseLocation>(
      context: context,
      builder: (context) => useWindowsVersion
          ? LocationPickerDialogWindows(
              initialLocation: _selectedLocation != null ? AppLocation(latitude: _selectedLocation!.latitude, longitude: _selectedLocation!.longitude, address: _selectedLocation!.address, city: _selectedLocation!.city, country: _selectedLocation!.country) : null,
            )
          : LocationPickerDialog(
              initialLocation: _selectedLocation != null ? AppLocation(latitude: _selectedLocation!.latitude, longitude: _selectedLocation!.longitude, address: _selectedLocation!.address, city: _selectedLocation!.city, country: _selectedLocation!.country) : null,
            ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _pickImages() async {
    final image = await HybridImagePickerService.pickImage(context: context);

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une localisation')),
      );
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProviderV2>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final hasImages = _selectedImages.isNotEmpty;
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SaveProgressDialog(
        hasImages: hasImages,
        isEdit: widget.courseToEdit != null,
        progressNotifier: courseProvider.uploadProgressNotifier,
      ),
    );

    bool success;
    if (widget.courseToEdit == null) {
      success = await courseProvider.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.tryParse(_priceController.text),
        season: _selectedSeason,
        seasonStartDate: _seasonStartDate,
        seasonEndDate: _seasonEndDate,
        location: _selectedLocation!,
        imageFiles: _selectedImages,
        currentUserId: authProvider.currentUser!.uid,
        currentUserRole: authProvider.userData!['role'],
        clubId: _selectedClub?.uid,
        maxStudents: int.tryParse(_maxStudentsController.text) ?? 30,
      );
    } else {
      success = await courseProvider.updateCourse(
        courseId: widget.courseToEdit!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.tryParse(_priceController.text),
        season: _selectedSeason,
        seasonStartDate: _seasonStartDate,
        seasonEndDate: _seasonEndDate,
        location: _selectedLocation,
        newImageFiles: _selectedImages,
        clubId: _selectedClub?.uid,
        maxStudents: int.tryParse(_maxStudentsController.text),
      );
    }

    if (mounted) {
      navigator.pop(); // Fermer le dialog de progression
      if (success) {
        navigator.pop(); // Retourner au dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.courseToEdit == null ? 'Cours créé !' : 'Cours mis à jour !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${courseProvider.error ?? "Inconnue"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseToEdit == null ? 'Nouveau cours' : 'Modifier le cours'),
      ),
      body: SafeArea(child: _buildForm()),
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: SingleChildScrollView(child: _buildFormFields())),
              Expanded(flex: 2, child: _buildPreviewPanel()),
            ],
          );
        }
        return SingleChildScrollView(child: _buildFormFields());
      },
    );
  }

  Widget _buildFormFields() {
    return Padding(
      padding: ResponsiveLayout.getResponsivePadding(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du cours *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            _isLoadingClubs
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<UserModel>(
                  initialValue: _selectedClub,
                  decoration: const InputDecoration(
                    labelText: 'Club partenaire (Optionnel)',
                    prefixIcon: Icon(Icons.business),
                    helperText: 'Choisissez un club si le cours y a lieu',
                  ),
                  items: [
                    const DropdownMenuItem<UserModel>(value: null, child: Text('Aucun club (Indépendant)')),
                    ..._availableClubs.map((club) => DropdownMenuItem(
                      value: club,
                      child: Text(club.name),
                    )),
                  ],
                  onChanged: (val) => setState(() => _selectedClub = val),
                ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CourseCategory>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                    items: CourseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<CourseSeason>(
                    initialValue: _selectedSeason,
                    decoration: const InputDecoration(labelText: 'Saison', prefixIcon: Icon(Icons.calendar_today)),
                    items: CourseSeason.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSeason = val;
                          final dates = val.getDefaultDateRange();
                          _seasonStartDate = dates['start']!;
                          _seasonEndDate = dates['end']!;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Prix (DA)', prefixIcon: Icon(Icons.money)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStudentsController,
                    decoration: const InputDecoration(labelText: 'Places max', prefixIcon: Icon(Icons.people)),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Début'),
                    subtitle: Text('${_seasonStartDate.day}/${_seasonStartDate.month}/${_seasonStartDate.year}'),
                    onTap: () => _selectDate(context, true),
                    leading: const Icon(Icons.date_range),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text('${_seasonEndDate.day}/${_seasonEndDate.month}/${_seasonEndDate.year}'),
                    onTap: () => _selectDate(context, false),
                    leading: const Icon(Icons.date_range),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: _isLoadingLocation ? const CircularProgressIndicator() : const Icon(Icons.location_on),
                title: const Text('Localisation'),
                subtitle: Text(_selectedLocation?.address ?? 'Non sélectionnée'),
                onTap: _selectLocation,
              ),
            ),
            const SizedBox(height: 24),
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, i) => Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImages[i], width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(right: 4, top: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeImage(i))),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.add_a_photo), label: const Text('Ajouter des images')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveCourse,
                icon: const Icon(Icons.save),
                label: Text(widget.courseToEdit == null ? 'Créer le cours' : 'Mettre à jour'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).dividerColor))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aperçu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text(_titleController.text.isEmpty ? 'Titre' : _titleController.text, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(_descriptionController.text.isEmpty ? 'Description...' : _descriptionController.text),
        ],
      ),
    );
  }
}

class _SaveProgressDialog extends StatelessWidget {
  final bool hasImages;
  final bool isEdit;
  final ValueNotifier<double> progressNotifier;

  const _SaveProgressDialog({required this.hasImages, required this.isEdit, required this.progressNotifier});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(isEdit ? 'Mise à jour...' : 'Création...'),
            if (hasImages)
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, val, _) => Column(
                  children: [
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: val > 0 ? val : null),
                    Text('${(val * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
