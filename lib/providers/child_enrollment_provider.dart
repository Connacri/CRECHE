import 'dart:io';
import 'package:flutter/material.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../models/daily_activity_model.dart';
import '../services/supabase_service.dart';
import '../services/image_storage_service.dart';

class ChildEnrollmentProvider extends ChangeNotifier {
  final SupabaseChildService _supabaseChildService = SupabaseChildService();
  final ImageStorageService _imageService = ImageStorageService();

  List<ChildModel> _children = [];
  List<ChildModel> get children => _children;

  List<EnrollmentModel> _enrollments = [];
  List<EnrollmentModel> get enrollments => _enrollments;

  List<SessionSchedule> _schedules = [];
  List<SessionSchedule> get schedules => _schedules;

  List<Map<String, dynamic>> _ownerEnrollmentsDetailed = [];
  List<Map<String, dynamic>> get ownerEnrollmentsDetailed =>
      _ownerEnrollmentsDetailed;

  List<DailyActivity> _dailyActivities = [];
  List<DailyActivity> get dailyActivities => _dailyActivities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // === GESTION DES ACTIVITÉS QUOTIDIENNES ===
  Future<void> loadDailyActivities(String parentId, DateTime date) async {
    try {
      _setLoading(true);
      _dailyActivities =
          await _supabaseChildService.getDailyActivities(parentId, date);
      _setLoading(false);
    } catch (e) {
      print('❌ Erreur loadDailyActivities: $e');
      _setError('Impossible de charger les activités');
      _setLoading(false);
    }
  }

  // === CHARGEMENT DES INSCRIPTIONS POUR UN PROPRIÉTAIRE (ÉCOLE/COACH) ===
  Future<void> loadEnrollmentsForOwner(String ownerId) async {
    try {
      _setLoading(true);
      _enrollments = await _supabaseChildService.getEnrollmentsForOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      print('❌ Erreur loadEnrollmentsForOwner: $e');
      _setError('Impossible de charger les inscriptions');
      _setLoading(false);
    }
  }

  Future<void> loadOwnerEnrollmentsDetailed(String ownerId) async {
    try {
      _setLoading(true);
      _ownerEnrollmentsDetailed =
          await _supabaseChildService.getOwnerEnrollmentsWithDetails(ownerId);
      _setLoading(false);
    } catch (e) {
      print('❌ Erreur loadOwnerEnrollmentsDetailed: $e');
      _setError('Impossible de charger les détails des inscriptions');
      _setLoading(false);
    }
  }

  Future<void> loadChildren(String parentId) async {
    if (parentId.isEmpty) {
      _children = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _children = await _supabaseChildService.getChildren(parentId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadChildren: $e');
      _error = 'Impossible de charger les enfants';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required ChildGender gender,
    File? photoFile,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? finalPhotoUrl;
      if (photoFile != null) {
        try {
          print('📸 [ChildProvider] Tentative upload photo...');
          finalPhotoUrl = await _imageService.uploadChildPhoto(
            imageFile: photoFile,
            userId: parentId,
            childId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (finalPhotoUrl != null) {
            print('✅ [ChildProvider] Photo uploadée avec succès: $finalPhotoUrl');
          }
        } catch (e) {
          print('❌ [ChildProvider] Erreur upload photo: $e');
        }
      }

      final child = ChildModel(
        id: '',
        parentId: parentId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: finalPhotoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo ?? MedicalInfo(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await _supabaseChildService.createChild(child);

      if (finalPhotoUrl != null && photoFile != null) {
        final permanentUrl = await _imageService.uploadChildPhoto(
          imageFile: photoFile,
          userId: parentId,
          childId: newId,
        );
        if (permanentUrl != null) {
          await _supabaseChildService.updateChild(newId, {'photo_url': permanentUrl});
        }
      }

      await loadChildren(parentId);
      return true;
    } catch (e) {
      print('❌ Erreur addChild: $e');
      _error = 'Erreur lors de l\'ajout';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChild({
    required String childId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    ChildGender? gender,
    File? newPhoto,
    String? newPhotoUrl,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) throw Exception('Enfant non trouvé localement');

      final currentChild = _children[childIndex];
      String? photoUrl = currentChild.photoUrl;

      if (newPhotoUrl != null) {
        photoUrl = newPhotoUrl;
      } else if (newPhoto != null) {
        photoUrl = await _imageService.uploadChildPhoto(
          imageFile: newPhoto,
          userId: currentChild.parentId,
          childId: childId,
        );
        if (photoUrl != null) {
          photoUrl = '$photoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      final updates = <String, dynamic>{
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender.name,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (schoolGrade != null) 'school_grade': schoolGrade,
        if (medicalInfo != null) 'medical_info': medicalInfo.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabaseChildService.updateChild(childId, updates);

      final updatedChild = currentChild.copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: photoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo,
        updatedAt: DateTime.now(),
      );

      final newList = List<ChildModel>.from(_children);
      newList[childIndex] = updatedChild;
      _children = newList;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur updateChild: $e');
      _error = 'Erreur lors de la modification';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabaseChildService.softDeleteChild(childId);

      _children = _children.where((c) => c.id != childId).toList();
      _enrollments = _enrollments.where((e) => e.childId != childId).toList();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur deleteChild: $e');
      _error = 'Erreur lors de la suppression';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createEnrollment({
    required String courseId,
    required String childId,
    required String parentId,
    double? totalAmount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final enrollment = EnrollmentModel(
        id: '',
        courseId: courseId,
        childId: childId,
        parentId: parentId,
        status: EnrollmentStatus.pending,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.pending,
        totalAmount: totalAmount,
        paidAmount: 0,
        attendanceHistory: [],
      );

      await _supabaseChildService.createEnrollment(enrollment);
      await loadEnrollments(parentId);

      _setLoading(false);
      return true;
    } catch (e) {
      print('❌ Erreur createEnrollment: $e');
      _setError('Erreur lors de l\'inscription');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadEnrollments(String parentId) async {
    if (parentId.isEmpty) {
      _enrollments = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _enrollments = await _supabaseChildService.getEnrollments(parentId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadEnrollments: $e');
      _setError('Impossible de charger les inscriptions');
      _setLoading(false);
    }
  }

  Future<bool> updateEnrollment({
    required String enrollmentId,
    EnrollmentStatus? status,
    PaymentStatus? paymentStatus,
    double? paidAmount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updates = <String, dynamic>{
        if (status != null) 'status': status.name,
        if (paymentStatus != null) 'payment_status': paymentStatus.name,
        if (paidAmount != null) 'paid_amount': paidAmount,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabaseChildService.updateEnrollment(enrollmentId, updates);

      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) {
        _enrollments[index] = _enrollments[index].copyWith(
          status: status ?? _enrollments[index].status,
          paymentStatus: paymentStatus ?? _enrollments[index].paymentStatus,
          paidAmount: paidAmount ?? _enrollments[index].paidAmount,
        );
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur updateEnrollment: $e');
      _setError('Erreur lors de la mise à jour');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelEnrollment(String enrollmentId) async {
    return updateEnrollment(
      enrollmentId: enrollmentId,
      status: EnrollmentStatus.cancelled,
    );
  }

  Future<void> loadAllSchedulesForParent(String parentId) async {
    if (parentId.isEmpty) {
      _schedules = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _schedules = await _supabaseChildService.getSchedulesForParent(parentId);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadAllSchedulesForParent: $e');
      _setError('Impossible de charger les horaires');
      _setLoading(false);
    }
  }

  /// ✅ Charger les horaires pour une école
  Future<void> loadSchedulesForSchool(String schoolId) async {
    if (schoolId.isEmpty) {
      _schedules = [];
      notifyListeners();
      return;
    }
    try {
      _setLoading(true);
      _clearError();
      final response = await _supabaseChildService.adminClient.from('session_schedules').select().eq('school_id', schoolId);
      _schedules = (response as List).map((data) => SessionSchedule.fromSupabase(data)).toList();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadSchedulesForSchool: $e');
      _setError('Impossible de charger les horaires de l\'école');
      _setLoading(false);
    }
  }

  Map<DateTime, List<SessionSchedule>> groupSchedulesByDate(
    DateTime startDate,
    DateTime endDate,
  ) {
    final grouped = <DateTime, List<SessionSchedule>>{};
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);

    while (!currentDate.isAfter(endDate)) {
      final schedulesForDay = _schedules.where((schedule) {
        return schedule.isScheduledFor(currentDate) && !schedule.isCancelled;
      }).toList();

      grouped[currentDate] = schedulesForDay;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return grouped;
  }

  List<SessionSchedule> getSchedulesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _schedules
        .where((s) => s.isScheduledFor(normalizedDate) && !s.isCancelled)
        .toList();
  }

  List<EnrollmentModel> getEnrollmentsForChild(String childId) {
    return _enrollments.where((e) => e.childId == childId).toList();
  }

  EnrollmentModel? getEnrollmentForChildAndCourse(
    String childId,
    String courseId,
  ) {
    return _enrollments
        .where((e) => e.childId == childId && e.courseId == courseId)
        .firstOrNull;
  }

  bool isChildEnrolledInCourse(String childId, String courseId) {
    return _enrollments.any(
      (e) =>
          e.childId == childId &&
          e.courseId == courseId &&
          e.status != EnrollmentStatus.rejected &&
          e.status != EnrollmentStatus.cancelled,
    );
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

  void clearAll() {
    _children.clear();
    _enrollments.clear();
    _schedules.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

extension ChildModelExtensions on ChildModel {
  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
  String get displayName => '$firstName $lastName';
  String get ageDescription {
    if (age == 0) return 'Moins d\'un an';
    if (age == 1) return '1 an';
    return '$age ans';
  }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  bool get isActive =>
      status == EnrollmentStatus.approved || status == EnrollmentStatus.pending;

  String get paymentDescription {
    if (totalAmount == null) return 'Gratuit';
    if (isFullyPaid) return 'Payé';
    if (paidAmount != null && paidAmount! > 0) {
      return 'Partiel (${paidAmount!.toStringAsFixed(0)} / ${totalAmount!.toStringAsFixed(0)} DA)';
    }
    return 'En attente (${totalAmount!.toStringAsFixed(0)} DA)';
  }

  double get paymentPercentage {
    if (totalAmount == null || totalAmount == 0) return 100.0;
    return ((paidAmount ?? 0) / totalAmount!) * 100;
  }
}
