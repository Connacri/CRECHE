import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/course_model_complete.dart';
import '../core/config/supabase_config.dart';

class ImageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final SupabaseClient _adminClient;
  final Uuid _uuid = const Uuid();

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

  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  Future<File> _compressImage(File file) async {
    if (_isWindowsDesktop) return file;
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
      if (compressed == null) return file;
      return File(compressed.path);
    } catch (e) {
      return file;
    }
  }

  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      final fileToUpload = await _compressImage(imageFile);
      final String fileName = '${_uuid.v4()}.jpg';
      final String filePath = '$folder/$fileName';
      final bytes = await fileToUpload.readAsBytes();
      await _adminClient.storage.from(_profileBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
      return _adminClient.storage.from(_profileBucket).getPublicUrl(filePath);
    } catch (e) {
      throw Exception("Erreur upload generic: $e");
    }
  }

  Future<CourseImage> uploadCourseImage({required File imageFile, required String courseId}) async {
    final fileToUpload = await _compressImage(imageFile);
    final imgId = _uuid.v4();
    final filePath = '$courseId/$imgId.jpg';
    final bytes = await fileToUpload.readAsBytes();
    await _adminClient.storage.from(_coursesBucket).uploadBinary(filePath, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
    return CourseImage(id: imgId, supabaseUrl: _adminClient.storage.from(_coursesBucket).getPublicUrl(filePath), localPath: imageFile.path, isSynced: true, uploadedAt: DateTime.now());
  }

  Future<List<CourseImage>> uploadMultipleCourseImages({required List<File> imageFiles, required String courseId, Function(int, int)? onProgress}) async {
    final results = <CourseImage>[];
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final img = await uploadCourseImage(imageFile: imageFiles[i], courseId: courseId);
        results.add(img);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {}
    }
    return results;
  }

  Future<void> deleteCourseImage(CourseImage img, String courseId) async {
    if (img.supabaseUrl == null || img.supabaseUrl!.isEmpty) return;
    await _adminClient.storage.from(_coursesBucket).remove(['$courseId/${img.id}.jpg']);
  }

  Future<void> deleteMultipleImages(List<CourseImage> images, String courseId) async {
    final paths = images.where((img) => img.supabaseUrl != null && img.supabaseUrl!.isNotEmpty).map((img) => '$courseId/${img.id}.jpg').toList();
    if (paths.isNotEmpty) await _adminClient.storage.from(_coursesBucket).remove(paths);
  }

  Future<String?> uploadUserProfileImage({required File imageFile, required String userId, required bool isProfileImage}) async {
    final String bucketName = isProfileImage ? _profileBucket : _coverBucket;
    final fileToUpload = await _compressImage(imageFile);
    final String filePath = isProfileImage ? '$userId/avatar.jpg' : '$userId/cover.jpg';
    final bytes = await fileToUpload.readAsBytes();
    await _adminClient.storage.from(bucketName).uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return _adminClient.storage.from(bucketName).getPublicUrl(filePath);
  }

  Future<String?> uploadChildPhoto({required File imageFile, required String userId, required String childId}) async {
    final fileToUpload = await _compressImage(imageFile);
    final path = '$userId/children/$childId.jpg';
    final bytes = await fileToUpload.readAsBytes();
    await _adminClient.storage.from(_profileBucket).uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return _adminClient.storage.from(_profileBucket).getPublicUrl(path);
  }
}
