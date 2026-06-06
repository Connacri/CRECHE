import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';

class HybridImagePickerService {
  /// Sélectionne une image en utilisant FilePicker (plus stable que ImagePicker sur certains appareils)
  static Future<File?> pickImage({
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
      debugPrint('❌ [HybridPicker] Erreur: $e');
      return null;
    }
  }

  static Future<File?> pickProfileImage({required BuildContext context}) async {
    return await pickImage(
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
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Recadrer'),
        ],
      );
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      debugPrint('❌ [HybridPicker] Erreur crop: $e');
      return file; // Retourner l'original si le crop échoue
    }
  }
}
