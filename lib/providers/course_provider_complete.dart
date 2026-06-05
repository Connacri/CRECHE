import 'dart:io';
import 'package:flutter/material.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../models/session_schedule_model.dart';
import '../services/supabase_service.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart';
import '../services/auth_service.dart';

class CourseProvider extends ChangeNotifier {
  final SupabaseCourseService _courseService = SupabaseCourseService();
  final ImageStorageService _imageService = ImageStorageService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final SupabaseChildService _childService = SupabaseChildService();

  List<CourseModel> _courses = [];
  List<CourseModel> get courses => _courses;

  List<CourseModel> _userCourses = [];
  List<CourseModel> get userCourses => _userCourses;

  CourseModel? _selectedCourse;
  CourseModel? get selectedCourse => _selectedCourse;

  List<UserModel> _coaches = [];
  List<UserModel> get coaches => _coaches;

  List<SessionSchedule> _schedules = [];
  List<SessionSchedule> get schedules => _schedules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier<double>(0.0);

  DateTime? _lastDocumentTimestamp;
  bool _hasMoreCourses = true;
  bool get hasMoreCourses => _hasMoreCourses;

  Future<void> loadCourses({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _courses.clear();
      _lastDocumentTimestamp = null;
      _hasMoreCourses = true;
    }
    if (!_hasMoreCourses) return;

    try {
      _setLoading(true);
      _clearError();
      final newCourses = await _courseService.getCourses(
        limit: 10,
        lastDocumentTimestamp: _lastDocumentTimestamp,
      );
      if (newCourses.length < 10) {
        _hasMoreCourses = false;
      }
      if (newCourses.isNotEmpty) {
        _courses.addAll(newCourses);
        _lastDocumentTimestamp = newCourses.last.createdAt;
      }
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours: $e');
      _setLoading(false);
    }
  }

  Future<bool> createCourse({
    required String title,
    required String description,
    required CourseCategory category,
    double? price,
    String currency = '',
    required CourseSeason season,
    required DateTime seasonStartDate,
    required DateTime seasonEndDate,
    required CourseLocation location,
    required List<File> imageFiles,
    required String currentUserId,
    required String currentUserRole,
    String? clubId,
    int maxStudents = 30,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
    Function(int current, int total)? onImageUploadProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _setUploadProgress(0.0);

      final newCourse = CourseModel(
        id: '',
        title: title,
        description: description,
        category: category,
        price: price,
        season: season,
        seasonStartDate: seasonStartDate,
        seasonEndDate: seasonEndDate,
        location: location,
        images: [],
        createdBy: currentUserId,
        clubId: clubId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        maxStudents: maxStudents,
        currentStudents: 0,
        tags: tags,
        metadata: metadata,
      );

      final courseId = await _courseService.createCourse(newCourse);

      List<CourseImage> uploadedImages = [];
      if (imageFiles.isNotEmpty) {
        uploadedImages = await _imageService.uploadMultipleCourseImages(
          imageFiles: imageFiles,
          courseId: courseId,
          onProgress: (current, total) {
            _setUploadProgress(current / total);
            onImageUploadProgress?.call(current, total);
          },
        );
      }

      if (uploadedImages.isNotEmpty) {
        await _courseService.updateCourse(
          courseId,
          {
            'images': uploadedImages.map((img) => img.toMap()).toList(),
          },
        );
      }

      final createdCourse = await _courseService.getCourse(courseId);
      if (createdCourse != null) {
        _courses.insert(0, createdCourse);
        _userCourses.insert(0, createdCourse);
      }

      _setLoading(false);
      _setUploadProgress(0.0);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la création: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateCourse({
    required String courseId,
    String? title,
    String? description,
    CourseCategory? category,
    double? price,
    CourseSeason? season,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    CourseLocation? location,
    List<File>? newImageFiles,
    int? maxStudents,
    List<String>? tags,
    bool? isActive,
    String? clubId,
    Map<String, dynamic>? metadata,
    Function(int current, int total)? onImageUploadProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _setUploadProgress(0.0);

      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.name;
      if (price != null) updates['price'] = price;
      if (season != null) updates['season'] = season.name;
      if (seasonStartDate != null) updates['season_start_date'] = seasonStartDate.toIso8601String();
      if (seasonEndDate != null) updates['season_end_date'] = seasonEndDate.toIso8601String();
      if (location != null) updates['location'] = location.toMap();
      if (maxStudents != null) updates['max_students'] = maxStudents;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['is_active'] = isActive;
      if (clubId != null) updates['club_id'] = clubId;
      if (metadata != null) updates['metadata'] = metadata;

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final uploadedImages = await _imageService.uploadMultipleCourseImages(
          imageFiles: newImageFiles,
          courseId: courseId,
          onProgress: (current, total) {
            _setUploadProgress(current / total);
            onImageUploadProgress?.call(current, total);
          },
        );

        final existingCourse = await _courseService.getCourse(courseId);
        if (existingCourse != null) {
          final allImages = [...existingCourse.images, ...uploadedImages];
          updates['images'] = allImages.map((img) => img.toMap()).toList();
        }
      }

      await _courseService.updateCourse(courseId, updates);

      final updatedCourse = await _courseService.getCourse(courseId);
      if (updatedCourse != null) {
        _updateLocalCourse(updatedCourse);
      }

      _setLoading(false);
      _setUploadProgress(0.0);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      _setLoading(true);
      final course = await _courseService.getCourse(courseId);
      if (course != null && course.images.isNotEmpty) {
        await _imageService.deleteMultipleImages(course.images, courseId);
      }
      await _courseService.deleteCourse(courseId);
      _courses.removeWhere((c) => c.id == courseId);
      _userCourses.removeWhere((c) => c.id == courseId);
      if (_selectedCourse?.id == courseId) _selectedCourse = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadUserCourses(String userId) async {
    try {
      _setLoading(true);
      _userCourses = await _courseService.getUserCourses(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours utilisateur: $e');
      _setLoading(false);
    }
  }

  Future<void> loadCourseById(String courseId) async {
    try {
      _setLoading(true);
      _selectedCourse = await _courseService.getCourse(courseId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement du cours: $e');
      _setLoading(false);
    }
  }

  Future<bool> removeImageFromCourse(String courseId, CourseImage image) async {
    try {
      await _imageService.deleteCourseImage(image, courseId);
      final course = await _courseService.getCourse(courseId);
      if (course != null) {
        final updatedImages = course.images.where((img) => img.id != image.id).toList();
        await _courseService.updateCourse(
          courseId,
          {'images': updatedImages.map((img) => img.toMap()).toList()},
        );
        _updateLocalCourse(course.copyWith(images: updatedImages));
      }
      return true;
    } catch (e) {
      _setError("Erreur lors de la suppression de l'image: $e");
      return false;
    }
  }

  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      return await _courseService.searchCourses(searchTerm);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      return [];
    }
  }

  Future<void> sortCoursesByDistance() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return;
      _courses = await _locationService.sortCoursesByDistance(
        _courses,
        position.latitude,
        position.longitude,
      );
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du tri par distance: $e');
    }
  }

  Future<void> loadCoursesNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      _setLoading(true);
      _courses = await _courseService.getCoursesNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours à proximité: $e');
      _setLoading(false);
    }
  }

  List<CourseModel> filterCoursesBySeason(CourseSeason season) {
    return _courses.where((course) => course.season == season).toList();
  }

  List<CourseModel> filterCoursesByCategory(CourseCategory category) {
    return _courses.where((course) => course.category == category).toList();
  }

  List<CourseModel> getAvailableCourses() {
    return _courses.where((course) => course.isActive).toList();
  }

  void selectCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  Future<void> loadCoaches() async {
    try {
      final rawCoaches = await _authService.getCoaches();
      _coaches = rawCoaches.map((json) => UserModel.fromSupabase(json)).toList();
      notifyListeners();
    } catch (e) {
      print("❌ [CourseProvider] Erreur loadCoaches: $e");
    }
  }

  Future<void> loadOwnerSchedules(String ownerId) async {
    try {
      _setLoading(true);
      _schedules = await _childService.getSchedulesByOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      _setError("Erreur chargement planning: $e");
      _setLoading(false);
    }
  }

  Future<bool> createSchedule(SessionSchedule schedule) async {
    try {
      _setLoading(true);
      final id = await _childService.createSchedule(schedule);
      final newSchedule = schedule.copyWith(id: id);
      _schedules.add(newSchedule);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Erreur création session: $e");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateSchedule(String id, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      await _childService.updateSchedule(id, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Erreur mise à jour session: $e");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      _setLoading(true);
      await _childService.deleteSchedule(id);
      _schedules.removeWhere((s) => s.id == id);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Erreur suppression session: $e");
      _setLoading(false);
      return false;
    }
  }

  void clearCourses() {
    _schedules.clear();
    _coaches.clear();
    _courses.clear();
    _userCourses.clear();
    _selectedCourse = null;
    _lastDocumentTimestamp = null;
    _hasMoreCourses = true;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setUploadProgress(double progress) {
    uploadProgressNotifier.value = progress;
  }

  void _updateLocalCourse(CourseModel updatedCourse) {
    final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) _courses[index] = updatedCourse;
    final userIndex = _userCourses.indexWhere((c) => c.id == updatedCourse.id);
    if (userIndex != -1) _userCourses[userIndex] = updatedCourse;
  }
}
