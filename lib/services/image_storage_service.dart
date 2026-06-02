import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/course_model_complete.dart';
import '../core/config/supabase_config.dart';

/// Service de gestion des images via Supabase Storage
/// ✅ MODE ADMIN : Utilise la clé Service Role pour contourner le RLS lors des uploads
class ImageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// 🛡️ Client Admin (Service Role) pour contourner le RLS
  late final SupabaseClient _adminClient;
  
  final Uuid _uuid = const Uuid();

  // Buckets Supabase
  static const String _coursesBucket = 'courses';
  static const String _profileBucket = 'profiles';
  static const String _coverBucket = 'covers';

  static const int maxImageSizeKB = 500;
  static const int imageQuality = 85;

  ImageStorageService() {
    _adminClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceRoleKey,
    );
  }

  /// 🖥️ Détecte si on est sur Windows Desktop
  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  /// Compresse une image pour optimiser le stockage
  Future<File> _compressImage(File file) async {
    if (_isWindowsDesktop) {
      print('🖥️ [ImageStorage] Windows détecté : Compression SKIP');
      return file;
    }

    print('📦 [ImageStorage] Compression image: ${file.path}');

    final tempDir = await getTemporaryDirectory();
    final output = '${tempDir.path}/${_uuid.v4()}.jpg';

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        output,
        quality: imageQuality,
        minWidth: 1280,
        minHeight: 720,
      );

      if (compressed == null) {
        print('⚠️ [ImageStorage] Compression échouée, utilisation fichier original');
        return file;
      }

      final compressedFile = File(compressed.path);
      final sizeKB = (await compressedFile.length()) / 1024;

      if (sizeKB > maxImageSizeKB) {
        final adjustedQuality = (imageQuality * (maxImageSizeKB / sizeKB)).round();
        final finalCompressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          output,
          quality: adjustedQuality,
          minWidth: 1280,
          minHeight: 720,
        );
        if (finalCompressed != null) return File(finalCompressed.path);
      }

      return compressedFile;
    } catch (e) {
      print('⚠️ [ImageStorage] Erreur compression: $e');
      return file;
    }
  }

  /// 📤 Upload une image de cours via ADMIN
  Future<CourseImage> uploadCourseImage({
    required File imageFile,
    required String courseId,
  }) async {
    try {
      print('📤 [ImageStorage] Début upload image ADMIN pour course: $courseId');
      final fileToUpload = await _compressImage(imageFile);
      final imgId = _uuid.v4();
      final filePath = '$courseId/$imgId.jpg';

      final Uint8List imageBytes = await fileToUpload.readAsBytes();
      
      // ✅ Utilisation du client ADMIN pour contourner le RLS
      await _adminClient.storage.from(_coursesBucket).uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _adminClient.storage.from(_coursesBucket).getPublicUrl(filePath);

      if (fileToUpload.path != imageFile.path) {
        try { await fileToUpload.delete(); } catch (_) {}
      }

      return CourseImage(
        id: imgId,
        supabaseUrl: publicUrl,
        localPath: imageFile.path,
        isSynced: true,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ [ImageStorage] Erreur upload Admin: $e');
      throw Exception("Erreur upload Storage Admin: $e");
    }
  }

  /// Upload multiple d'images de cours
  Future<List<CourseImage>> uploadMultipleCourseImages({
    required List<File> imageFiles,
    required String courseId,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <CourseImage>[];
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final img = await uploadCourseImage(imageFile: imageFiles[i], courseId: courseId);
        results.add(img);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        print("❌ [ImageStorage] Erreur image ${i + 1}: $e");
      }
    }
    return results;
  }

  /// Supprime une image de cours via ADMIN
  Future<void> deleteCourseImage(CourseImage img, String courseId) async {
    if (img.supabaseUrl == null || img.supabaseUrl!.isEmpty) return;
    final path = '$courseId/${img.id}.jpg';
    try {
      await _adminClient.storage.from(_coursesBucket).remove([path]);
    } catch (e) {
      print("❌ [ImageStorage] Erreur suppression Admin: $e");
    }
  }

  /// Supprime plusieurs images via ADMIN
  Future<void> deleteMultipleImages(List<CourseImage> images, String courseId) async {
    final paths = images
        .where((img) => img.supabaseUrl != null && img.supabaseUrl!.isNotEmpty)
        .map((img) => '$courseId/${img.id}.jpg')
        .toList();
    if (paths.isEmpty) return;
    try {
      await _adminClient.storage.from(_coursesBucket).remove(paths);
    } catch (e) {
      print("❌ [ImageStorage] Erreur suppression multiple Admin: $e");
    }
  }

  /// 📤 Upload d'une image de profil utilisateur via ADMIN
  Future<String?> uploadUserProfileImage({
    required File imageFile,
    required String userId,
    required bool isProfileImage,
  }) async {
    try {
      final String bucketName = isProfileImage ? _profileBucket : _coverBucket;
      final fileToUpload = await _compressImage(imageFile);
      final String filePath = isProfileImage ? '$userId/avatar.jpg' : '$userId/cover.jpg';

      final bytes = await fileToUpload.readAsBytes();

      // ✅ Utilisation du client ADMIN pour contourner le RLS
      await _adminClient.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final publicUrl = _adminClient.storage.from(bucketName).getPublicUrl(filePath);

      if (fileToUpload.path != imageFile.path) {
        try { await fileToUpload.delete(); } catch (_) {}
      }

      return publicUrl;
    } catch (e) {
      print("❌ [ImageStorage] Erreur upload profil Admin: $e");
      throw Exception("Erreur upload profil Admin: $e");
    }
  }

  /// 📤 Upload d'une photo d'enfant via ADMIN
  Future<String?> uploadChildPhoto({
    required File imageFile,
    required String userId,
    required String childId,
  }) async {
    try {
      final fileToUpload = await _compressImage(imageFile);
      final path = '$userId/children/$childId.jpg';
      const String targetBucket = _profileBucket;

      final bytes = await fileToUpload.readAsBytes();

      // ✅ Utilisation du client ADMIN pour contourner le RLS
      await _adminClient.storage.from(targetBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      if (fileToUpload.path != imageFile.path) {
        try { await fileToUpload.delete(); } catch (_) {}
      }

      return _adminClient.storage.from(targetBucket).getPublicUrl(path);
    } catch (e) {
      print('❌ [ImageStorage] Erreur upload enfant Admin: $e');
      throw Exception("Erreur upload enfant Admin: $e");
    }
  }
}
