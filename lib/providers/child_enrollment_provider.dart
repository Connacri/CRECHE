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

  // Geofencing simulé (position actuelle des enfants)
  final Map<String, Map<String, dynamic>> _childrenLocations = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _ownerEnrollmentsDetailed = [];
  List<Map<String, dynamic>> get ownerEnrollmentsDetailed => _ownerEnrollmentsDetailed;

  List<DailyActivity> _dailyActivities = [];
  List<DailyActivity> get dailyActivities => _dailyActivities;

  Future<void> loadDailyActivities(String parentId, DateTime date) async {
    try {
      _setLoading(true);
      _dailyActivities = await _supabaseChildService.getDailyActivities(parentId, date);
      _setLoading(false);
    } catch (e) {
      _setError('Impossible de charger les activités');
      _setLoading(false);
    }
  }

  List<DailyActivity> getActivitiesForChild(String childId) {
    return _dailyActivities.where((a) => a.childId == childId).toList();
  }

  Future<void> loadEnrollmentsForOwner(String ownerId) async {
    try {
      _setLoading(true);
      _enrollments = await _supabaseChildService.getEnrollmentsForOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      _setError('Impossible de charger les inscriptions');
      _setLoading(false);
    }
  }

  Future<void> loadOwnerEnrollmentsDetailed(String ownerId) async {
    try {
      _setLoading(true);
      _ownerEnrollmentsDetailed = await _supabaseChildService.getOwnerEnrollmentsWithDetails(ownerId);
      _setLoading(false);
    } catch (e) {
      _setError('Impossible de charger les détails');
      _setLoading(false);
    }
  }

  Future<void> loadChildren(String parentId) async {
    if (parentId.isEmpty) { _children = []; notifyListeners(); return; }
    try {
      _isLoading = true; notifyListeners();
      _children = await _supabaseChildService.getChildren(parentId);
      _isLoading = false; notifyListeners();
    } catch (e) {
      _error = 'Impossible de charger les enfants'; _isLoading = false; notifyListeners();
    }
  }

  Future<bool> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required dynamic gender,
    String? photoUrl,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
    File? photoFile,
  }) async {
    try {
      _isLoading = true; notifyListeners();
      String? finalPhotoUrl = photoUrl;
      if (photoFile != null) finalPhotoUrl = await _imageService.uploadImage(photoFile, 'children_photos');
      ChildGender genderEnum = gender is ChildGender ? gender : ChildGender.values.firstWhere((g) => g.name == gender.toString(), orElse: () => ChildGender.other);
      final child = ChildModel(id: '', parentId: parentId, firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth, gender: genderEnum, photoUrl: finalPhotoUrl, schoolGrade: schoolGrade, medicalInfo: medicalInfo ?? MedicalInfo(), createdAt: DateTime.now(), updatedAt: DateTime.now());
      await _supabaseChildService.createChild(child);
      await loadChildren(parentId);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout'; _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> updateChild({
    required String childId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    dynamic gender,
    String? photoUrl,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
    File? newPhoto,
  }) async {
    try {
      _isLoading = true; notifyListeners();
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) throw 'Enfant non trouvé';
      String? finalPhotoUrl = photoUrl;
      if (newPhoto != null) finalPhotoUrl = await _imageService.uploadImage(newPhoto, 'children_photos');
      ChildGender? genderEnum;
      if (gender != null) genderEnum = gender is ChildGender ? gender : ChildGender.values.firstWhere((g) => g.name == gender.toString(), orElse: () => ChildGender.other);
      final updates = <String, dynamic>{
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': genderEnum?.name ?? gender.toString(),
        if (finalPhotoUrl != null) 'photo_url': finalPhotoUrl,
        if (schoolGrade != null) 'school_grade': schoolGrade,
        if (medicalInfo != null) 'medical_info': medicalInfo.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabaseChildService.updateChild(childId, updates);
      _children[childIndex] = _children[childIndex].copyWith(firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth, gender: genderEnum, photoUrl: finalPhotoUrl, schoolGrade: schoolGrade, medicalInfo: medicalInfo, updatedAt: DateTime.now());
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur modification'; _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _isLoading = true; notifyListeners();
      await _supabaseChildService.softDeleteChild(childId);
      _children.removeWhere((c) => c.id == childId);
      _enrollments.removeWhere((e) => e.childId == childId);
      _isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false; notifyListeners(); return false;
    }
  }

  Future<bool> createEnrollment({required String courseId, required String childId, required String parentId, double? totalAmount}) async {
    try {
      _setLoading(true);
      final enrollment = EnrollmentModel(id: '', courseId: courseId, childId: childId, parentId: parentId, status: EnrollmentStatus.pending, enrolledAt: DateTime.now(), paymentStatus: PaymentStatus.pending, totalAmount: totalAmount, paidAmount: 0, attendanceHistory: []);
      await _supabaseChildService.createEnrollment(enrollment);
      await loadEnrollments(parentId);
      _setLoading(false); return true;
    } catch (e) {
      _setLoading(false); return false;
    }
  }

  Future<void> loadEnrollments(String parentId) async {
    if (parentId.isEmpty) { _enrollments = []; notifyListeners(); return; }
    try {
      _setLoading(true);
      _enrollments = await _supabaseChildService.getEnrollments(parentId);
      _setLoading(false); notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<bool> updateEnrollment({required String enrollmentId, EnrollmentStatus? status, PaymentStatus? paymentStatus, double? paidAmount}) async {
    try {
      _setLoading(true);
      final updates = <String, dynamic>{ if (status != null) 'status': status.name, if (paymentStatus != null) 'payment_status': paymentStatus.name, if (paidAmount != null) 'paid_amount': paidAmount, 'updated_at': DateTime.now().toIso8601String() };
      await _supabaseChildService.updateEnrollment(enrollmentId, updates);
      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) _enrollments[index] = _enrollments[index].copyWith(status: status, paymentStatus: paymentStatus, paidAmount: paidAmount);
      _setLoading(false); notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false); return false;
    }
  }

  Future<bool> cancelEnrollment(String enrollmentId) async {
    return updateEnrollment(enrollmentId: enrollmentId, status: EnrollmentStatus.cancelled);
  }

  Future<void> loadAllSchedulesForParent(String parentId) async {
    if (parentId.isEmpty) { _schedules = []; notifyListeners(); return; }
    try {
      _setLoading(true);
      _schedules = await _supabaseChildService.getSchedulesForParent(parentId);
      _setLoading(false); notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> loadSchedulesForSchool(String schoolId) async {
    if (schoolId.isEmpty) { _schedules = []; notifyListeners(); return; }
    try {
      _setLoading(true);
      final response = await _supabaseChildService.adminClient.from('session_schedules').select().eq('school_id', schoolId);
      _schedules = (response as List).map((data) => SessionSchedule.fromSupabase(data)).toList();
      _setLoading(false); notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  List<SessionSchedule> getSchedulesForDate(DateTime date) {
    return _schedules.where((s) => s.isScheduledFor(date) && !s.isCancelled).toList();
  }

  List<EnrollmentModel> getEnrollmentsForChild(String childId) => _enrollments.where((e) => e.childId == childId).toList();

  bool isChildEnrolledInCourse(String childId, String courseId) {
    return _enrollments.any((e) => e.childId == childId && e.courseId == courseId && e.status != EnrollmentStatus.rejected && e.status != EnrollmentStatus.cancelled);
  }

  // === ✅ CALCULS DE FACTURATION ===

  double getTotalDueForChild(String childId) {
    return getEnrollmentsForChild(childId).fold(0.0, (sum, e) => sum + e.remainingAmount);
  }

  double getTotalPaidForChild(String childId) {
    return getEnrollmentsForChild(childId).fold(0.0, (sum, e) => sum + (e.paidAmount ?? 0));
  }

  double getTotalDueAllChildren() {
    return _enrollments.fold(0.0, (sum, e) => sum + e.remainingAmount);
  }

  DateTime? getNextRenewalDateForChild(String childId) {
    final enrollments = getEnrollmentsForChild(childId).where((e) => e.status == EnrollmentStatus.approved).toList();
    if (enrollments.isEmpty) return null;

    final earliest = enrollments.fold<DateTime?>(null, (min, e) {
      final renewal = (e.approvedAt ?? e.enrolledAt).add(const Duration(days: 30));
      if (min == null || renewal.isBefore(min)) return renewal;
      return min;
    });

    return earliest;
  }

  // === ✅ ACTIVITÉS ET GEOFENCING ===

  Map<String, dynamic>? getChildLocation(String childId) {
    if (!_childrenLocations.containsKey(childId)) {
      _childrenLocations[childId] = {
        'lat': 36.7538 + (childId.hashCode % 100) * 0.0001,
        'lng': 3.0588 + (childId.hashCode % 100) * 0.0001,
        'speed': 15.0 + (childId.hashCode % 10),
        'is_in_transport': true,
      };
    }
    return _childrenLocations[childId];
  }

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void _setError(String error) { _error = error; notifyListeners(); }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  String get paymentDescription => totalAmount == null ? 'Gratuit' : (isFullyPaid ? 'Payé' : 'En attente');
}
