import 'dart:async';
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

  StreamSubscription? _coursesSubscription;
  StreamSubscription? _userCoursesSubscription;
  StreamSubscription? _schedulesSubscription;

  CourseProvider() {
    _initRealtime();
  }

  void _initRealtime() {
    _coursesSubscription?.cancel();
    _coursesSubscription = _courseService.getCoursesStream().listen(
      (data) {
        _courses = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ [CourseProvider] getCoursesStream Error: $e');
        if (e.toString().contains('1006')) {
          debugPrint('💡 TIP: Ensure Realtime is enabled for "courses" table in Supabase (check "supabase_realtime" publication).');
        }
      },
    );
  }

  void subscribeToUserCourses(String userId) {
    _userCoursesSubscription?.cancel();
    _userCoursesSubscription = _courseService.getUserCoursesStream(userId).listen(
      (data) {
        _userCourses = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ [CourseProvider] getUserCoursesStream Error: $e');
        if (e.toString().contains('1006')) {
          debugPrint('💡 TIP: Ensure Realtime is enabled for "courses" table in Supabase.');
        }
      },
    );
  }

  void subscribeToOwnerSchedules(String ownerId) {
    _schedulesSubscription?.cancel();
    _schedulesSubscription = _childService.getSchedulesByOwnerStream(ownerId).listen(
      (data) {
        _schedules = data.where((s) => s.schoolId == ownerId || s.coachId == ownerId).toList();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('❌ [CourseProvider] getSchedulesByOwnerStream Error: $e');
        if (e.toString().contains('1006')) {
          debugPrint('💡 TIP: Ensure Realtime is enabled for "session_schedules" table in Supabase.');
        }
      },
    );
  }

  @override
  void dispose() {
    _coursesSubscription?.cancel();
    _userCoursesSubscription?.cancel();
    _schedulesSubscription?.cancel();
    super.dispose();
  }

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
    int? minAge,
    int? maxAge,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? roomId,
    String? coachId,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
    CoursePricingType pricingType = CoursePricingType.session,
    CourseLevel? level,
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        clubId: clubId,
        maxStudents: maxStudents,
        minAge: minAge,
        maxAge: maxAge,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        roomId: roomId,
        coachId: coachId,
        tags: tags,
        metadata: {
           ...?metadata,
           'currency': currency,
        },
        pricingType: pricingType,
        level: level,
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

      _setLoading(false);
      _setUploadProgress(0.0);
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
    int? minAge,
    int? maxAge,
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? roomId,
    String? coachId,
    List<String>? tags,
    bool? isActive,
    String? clubId,
    Map<String, dynamic>? metadata,
    CoursePricingType? pricingType,
    CourseLevel? level,
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
      if (minAge != null) updates['min_age'] = minAge;
      if (maxAge != null) updates['max_age'] = maxAge;
      if (dayOfWeek != null) updates['day_of_week'] = dayOfWeek;
      if (startTime != null) updates['start_time'] = '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
      if (endTime != null) updates['end_time'] = '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
      if (roomId != null) updates['room_name'] = roomId;
      if (coachId != null) updates['coach_id'] = coachId;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['is_active'] = isActive;
      if (clubId != null) updates['club_id'] = clubId;
      if (metadata != null) updates['metadata'] = metadata;
      if (pricingType != null) updates['pricing_type'] = pricingType.name;
      if (level != null) updates['level'] = level.name;

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

      _setLoading(false);
      _setUploadProgress(0.0);
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
      _setLoading(false);
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
      subscribeToUserCourses(userId);
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
      debugPrint("❌ [CourseProvider] Erreur loadCoaches: $e");
    }
  }

  Future<void> loadOwnerSchedules(String ownerId) async {
    try {
      _setLoading(true);
      subscribeToOwnerSchedules(ownerId);
      _setLoading(false);
    } catch (e) {
      _setError("Erreur chargement planning: $e");
      _setLoading(false);
    }
  }

  Future<bool> createSchedule(SessionSchedule schedule) async {
    try {
      _setLoading(true);
      await _childService.createSchedule(schedule);
      _setLoading(false);
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
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Erreur suppression session: $e");
      _setLoading(false);
      return false;
    }
  }

  void clearCourses() {
    _coursesSubscription?.cancel();
    _userCoursesSubscription?.cancel();
    _schedulesSubscription?.cancel();
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
}
