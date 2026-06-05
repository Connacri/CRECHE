import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';

class HybridImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;
  static bool get _isWeb => kIsWeb;

  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
    bool crop = false,
    CropAspectRatio? aspectRatio,
    required BuildContext context,
  }) async {
    try {
      File? pickedFile;

      if (_isWindowsDesktop || _isWeb) {
        pickedFile = await _pickImageWithFilePicker(['jpg', 'jpeg', 'png']);
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
        if (image != null) pickedFile = File(image.path);
      }

      if (pickedFile != null && crop) {
        return await _cropImage(pickedFile, aspectRatio: aspectRatio, context: context);
      }

      return pickedFile;
    } catch (e) {
      print('❌ [HybridPicker] Erreur: $e');
      return null;
    }
  }

  static Future<File?> pickProfileImage({required BuildContext context}) async {
    return await pickImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
      crop: true,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      context: context,
    );
  }

  static Future<File?> pickDocument({required BuildContext context}) async {
    if (!_isMobile) {
      return await _pickImageWithFilePicker(['pdf', 'jpg', 'jpeg', 'png']);
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Choisir un document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo (Caméra)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Sélectionner un fichier (Galerie/PDF)'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
      return photo != null ? File(photo.path) : null;
    } else {
      // Pour les fichiers, on utilise FilePicker pour supporter PDF en plus des images
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    }
  }

  static Future<File?> _pickImageWithFilePicker(List<String> allowedExtensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  static Future<File?> _cropImage(File file, {CropAspectRatio? aspectRatio, required BuildContext context}) async {
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
  }
}
