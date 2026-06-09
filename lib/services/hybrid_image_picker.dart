import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class HybridImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image en fonction de la plateforme
  static Future<File?> pickImage({
    bool crop = false,
    CropAspectRatio? aspectRatio,
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
  }) async {
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      debugPrint('ℹ️ [HybridPicker] Utilisation de FilePicker sur Desktop');
      return await _pickImageWithFilePicker(crop: crop, aspectRatio: aspectRatio, context: context);
    }

    try {
      debugPrint('ℹ️ [HybridPicker] Utilisation de ImagePicker sur Mobile');
      final XFile? pickedXFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedXFile == null) return null;

      File pickedFile = File(pickedXFile.path);

      if (crop) {
        return await _cropImage(pickedFile, aspectRatio: aspectRatio, context: context);
      }

      return pickedFile;
    } catch (e) {
      debugPrint('❌ [HybridPicker] Erreur ImagePicker: $e');
      return await _pickImageWithFilePicker(crop: crop, aspectRatio: aspectRatio, context: context);
    }
  }

  /// Méthode interne pour picking d'image via FilePicker (Desktop ou Fallback)
  static Future<File?> _pickImageWithFilePicker({
    bool crop = false,
    CropAspectRatio? aspectRatio,
    required BuildContext context,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return null;

      File pickedFile = File(result.files.single.path!);

      if (crop) {
        return await _cropImage(pickedFile, aspectRatio: aspectRatio, context: context);
      }

      return pickedFile;
    } catch (e) {
      debugPrint('❌ [HybridPicker] Erreur FilePicker Image: $e');
      return null;
    }
  }

  /// Alias pour _pickImageWithFilePicker gardé pour compatibilité si besoin
  static Future<File?> _fallbackPickImage({
    bool crop = false,
    CropAspectRatio? aspectRatio,
    required BuildContext context,
  }) async {
    return _pickImageWithFilePicker(crop: crop, aspectRatio: aspectRatio, context: context);
  }

  static Future<File?> pickProfileImage({required BuildContext context}) async {
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      return await pickImage(context: context, crop: true, aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
    }

    // Proposer le choix entre Caméra et Galerie sur mobile
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    return await pickImage(
      source: source,
      crop: true,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      context: context,
    );
  }

  static Future<File?> pickDocument({required BuildContext context}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [HybridPicker] Erreur doc: $e');
      return null;
    }
  }

  /// Alias sémantiques pour les documents demandés
  static Future<File?> pickBirthCertificate({required BuildContext context}) => pickDocument(context: context);
  static Future<File?> pickMedicalCertificate({required BuildContext context}) => pickDocument(context: context);
  static Future<File?> pickAchievement({required BuildContext context}) => pickDocument(context: context); // Palmarès
  static Future<File?> pickDiploma({required BuildContext context}) => pickDocument(context: context);

  static Future<File?> _cropImage(File file, {CropAspectRatio? aspectRatio, required BuildContext context}) async {
    if (!kIsWeb && Platform.isWindows) {
      debugPrint('ℹ️ [HybridPicker] Cropping non supporté sur Windows, retour du fichier original.');
      return file;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: aspectRatio != null,
          ),
          IOSUiSettings(title: 'Recadrer'),
        ],
      );
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      debugPrint('❌ [HybridPicker] Erreur crop: $e');
      return file;
    }
  }
}
