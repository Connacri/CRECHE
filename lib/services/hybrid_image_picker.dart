import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class HybridImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image en utilisant ImagePicker (Standard pour Android/iOS)
  static Future<File?> pickImage({
    bool crop = false,
    CropAspectRatio? aspectRatio,
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
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
      // Fallback vers FilePicker si ImagePicker échoue (rare mais possible sur certains Android modifiés)
      return await _fallbackPickImage(crop: crop, aspectRatio: aspectRatio, context: context);
    }
  }

  static Future<File?> _fallbackPickImage({
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
      debugPrint('❌ [HybridPicker] Erreur Fallback: $e');
      return null;
    }
  }

  static Future<File?> pickProfileImage({required BuildContext context}) async {
    // Proposer le choix entre Caméra et Galerie
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
