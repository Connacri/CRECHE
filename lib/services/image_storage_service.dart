import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/course_model_complete.dart';
import 'supabase_service.dart';

class ImageStorageService extends AdminSupabaseService {
  final Uuid _uuid = const Uuid();

  static const String _coursesBucket = 'courses';
  static const String _profileBucket = 'profiles';
  static const String _coverBucket = 'covers';

  static const int imageQuality = 80;

  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  Future<File> _compressImage(File file) async {
    if (_isWindowsDesktop || kIsWeb) return file;

    final path = file.path.toLowerCase();
    if (!path.endsWith('.jpg') && !path.endsWith('.jpeg') && !path.endsWith('.png')) return file;

    final tempDir = await getTemporaryDirectory();
    final output = '${tempDir.path}/${_uuid.v4()}.jpg';
    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        output,
        quality: imageQuality,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (compressed == null) return file;
      return File(compressed.path);
    } catch (e) {
      return file;
    }
  }

  /// Upload une image vers le bucket des profils
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      final fileToUpload = await _compressImage(imageFile);
      final String fileName = '${_uuid.v4()}.jpg';
      final String filePath = '$folder/$fileName';
      final bytes = await fileToUpload.readAsBytes();

      await adminClient.storage.from(_profileBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );

      final url = adminClient.storage.from(_profileBucket).getPublicUrl(filePath);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception("Erreur upload generic: $e");
    }
  }

  Future<String?> uploadFile(File file, String folder) async {
    try {
      final String fileName = '${_uuid.v4()}_${file.path.split('/').last}';
      final String filePath = '$folder/$fileName';

      final fileToUpload = await _compressImage(file);
      final bytes = await fileToUpload.readAsBytes();

      String contentType = 'application/octet-stream';
      if (fileName.toLowerCase().endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) contentType = 'image/jpeg';
      else if (fileName.toLowerCase().endsWith('.png')) contentType = 'image/png';

      await adminClient.storage.from(_profileBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final url = adminClient.storage.from(_profileBucket).getPublicUrl(filePath);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception("Erreur upload file: $e");
    }
  }

  Future<CourseImage> uploadCourseImage({required File imageFile, required String courseId}) async {
    final fileToUpload = await _compressImage(imageFile);
    final imgId = _uuid.v4();
    final filePath = '$courseId/$imgId.jpg';
    final bytes = await fileToUpload.readAsBytes();
    await adminClient.storage.from(_coursesBucket).uploadBinary(filePath, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
    return CourseImage(
      id: imgId,
      supabaseUrl: adminClient.storage.from(_coursesBucket).getPublicUrl(filePath),
      localPath: imageFile.path,
      isSynced: true,
      uploadedAt: DateTime.now()
    );
  }

  Future<List<CourseImage>> uploadMultipleCourseImages({required List<File> imageFiles, required String courseId, Function(int, int)? onProgress}) async {
    final results = <CourseImage>[];
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final img = await uploadCourseImage(imageFile: imageFiles[i], courseId: courseId);
        results.add(img);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        // Silently ignore individual upload failures to continue with others
      }
    }
    return results;
  }

  Future<void> deleteCourseImage(CourseImage img, String courseId) async {
    if (img.supabaseUrl == null || img.supabaseUrl!.isEmpty) return;
    await adminClient.storage.from(_coursesBucket).remove(['$courseId/${img.id}.jpg']);
  }

  Future<void> deleteMultipleImages(List<CourseImage> images, String courseId) async {
    final paths = images.where((img) => img.supabaseUrl != null && img.supabaseUrl!.isNotEmpty).map((img) => '$courseId/${img.id}.jpg').toList();
    if (paths.isNotEmpty) await adminClient.storage.from(_coursesBucket).remove(paths);
  }

  Future<String?> uploadUserProfileImage({required File imageFile, required String userId, required bool isProfileImage}) async {
    final String bucketName = isProfileImage ? _profileBucket : _coverBucket;
    final fileToUpload = await _compressImage(imageFile);
    final String filePath = isProfileImage ? '$userId/avatar.jpg' : '$userId/cover.jpg';
    final bytes = await fileToUpload.readAsBytes();

    await adminClient.storage.from(bucketName).uploadBinary(
      filePath,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg')
    );

    final url = adminClient.storage.from(bucketName).getPublicUrl(filePath);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String?> uploadChildPhoto({required File imageFile, required String userId, required String childId}) async {
    final fileToUpload = await _compressImage(imageFile);
    final path = '$userId/children/$childId.jpg';
    final bytes = await fileToUpload.readAsBytes();
    await adminClient.storage.from(_profileBucket).uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));

    final url = adminClient.storage.from(_profileBucket).getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> deleteAllUserStorageData(String userId, List<String> courseIds) async {
    try {
      // 1. Delete profiles (avatar + children)
      final profileFiles = await adminClient.storage.from(_profileBucket).list(path: userId);
      if (profileFiles.isNotEmpty) {
        final paths = profileFiles.map((f) => '$userId/${f.name}').toList();
        await adminClient.storage.from(_profileBucket).remove(paths);
      }

      // Also check children subfolder in profiles
      final childrenFiles = await adminClient.storage.from(_profileBucket).list(path: '$userId/children');
      if (childrenFiles.isNotEmpty) {
        final paths = childrenFiles.map((f) => '$userId/children/${f.name}').toList();
        await adminClient.storage.from(_profileBucket).remove(paths);
      }

      // 2. Delete covers
      final coverFiles = await adminClient.storage.from(_coverBucket).list(path: userId);
      if (coverFiles.isNotEmpty) {
        final paths = coverFiles.map((f) => '$userId/${f.name}').toList();
        await adminClient.storage.from(_coverBucket).remove(paths);
      }

      // 3. Delete course images
      for (final courseId in courseIds) {
        final courseFiles = await adminClient.storage.from(_coursesBucket).list(path: courseId);
        if (courseFiles.isNotEmpty) {
          final paths = courseFiles.map((f) => '$courseId/${f.name}').toList();
          await adminClient.storage.from(_coursesBucket).remove(paths);
        }
      }
    } catch (e) {
      debugPrint('Error deleting storage data: $e');
    }
  }
}
