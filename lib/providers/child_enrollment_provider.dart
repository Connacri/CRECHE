import 'dart:io';
import 'package:flutter/material.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../models/daily_activity_model.dart';
import '../services/supabase_service.dart';
import '../services/club_service.dart';
import '../services/image_storage_service.dart';

class ChildEnrollmentProvider extends ChangeNotifier {
  final SupabaseChildService _supabaseChildService = SupabaseChildService();
  final ClubService _clubService = ClubService();
  final ImageStorageService _imageService = ImageStorageService();

  List<ChildModel> _children = [];
  List<ChildModel> get children => _children;

  List<EnrollmentModel> _enrollments = [];
  List<EnrollmentModel> get enrollments => _enrollments;

  List<SessionSchedule> _schedules = [];
  List<SessionSchedule> get schedules => _schedules;

  List<DailyActivity> _dailyActivities = [];
  List<DailyActivity> get dailyActivities => _dailyActivities;

  final Map<String, Map<String, dynamic>> _childrenLocations = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void _setError(String error) { _error = error; notifyListeners(); }

  Future<void> loadChildren(String parentId) async {
    if (parentId.isEmpty) return;
    try {
      _setLoading(true);
      _children = await _supabaseChildService.getChildren(parentId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
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
  }) async {
    try {
      _setLoading(true);
      String? photoUrl;

      if (photoFile != null) {
        final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
        photoUrl = await _imageService.uploadChildPhoto(
          imageFile: photoFile,
          userId: parentId,
          childId: tempId
        );
      }

      final child = ChildModel(
        id: "",
        parentId: parentId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: photoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: MedicalInfo(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _supabaseChildService.createChild(child);
      _children.add(child.copyWith(id: id));
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
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
    String? schoolGrade,
  }) async {
    try {
      _setLoading(true);
      final Map<String, dynamic> updates = {};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender.name;
      if (schoolGrade != null) updates['school_grade'] = schoolGrade;

      final index = _children.indexWhere((c) => c.id == childId);
      if (index == -1) return false;
      final parentId = _children[index].parentId;

      if (newPhoto != null) {
        final photoUrl = await _imageService.uploadChildPhoto(
          imageFile: newPhoto,
          userId: parentId,
          childId: childId
        );
        if (photoUrl != null) updates['photo_url'] = photoUrl;
      }

      await _supabaseChildService.updateChild(childId, updates);
      _children[index] = ChildModel.fromSupabase({..._children[index].toSupabase(), ...updates, 'id': childId});

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      await _supabaseChildService.softDeleteChild(childId);
      _children.removeWhere((c) => c.id == childId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadEnrollments(String parentId) async {
    if (parentId.isEmpty) return;
    try {
      _setLoading(true);
      _enrollments = await _supabaseChildService.getEnrollments(parentId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> loadOwnerEnrollments(String ownerId) async {
    if (ownerId.isEmpty) return;
    try {
      _setLoading(true);
      _enrollments = await _supabaseChildService.getEnrollmentsForOwner(ownerId);
      await loadOwnerEnrollmentsDetailed(ownerId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
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
      final enrollment = EnrollmentModel(
        id: "",
        courseId: courseId,
        childId: childId,
        parentId: parentId,
        status: EnrollmentStatus.pending,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.pending,
        totalAmount: totalAmount,
        paidAmount: 0,
      );
      await _supabaseChildService.createEnrollment(enrollment);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
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
      final Map<String, dynamic> updates = {};
      if (status != null) {
        updates['status'] = status.name;
        if (status == EnrollmentStatus.approved) updates['approved_at'] = DateTime.now().toIso8601String();
      }
      if (paymentStatus != null) updates['payment_status'] = paymentStatus.name;
      if (paidAmount != null) updates['paid_amount'] = paidAmount;

      await _supabaseChildService.updateEnrollment(enrollmentId, updates);

      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index != -1) {
        _enrollments[index] = _enrollments[index].copyWith(
          status: status,
          paymentStatus: paymentStatus,
          paidAmount: paidAmount
        );
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelEnrollment(String enrollmentId) async {
    return updateEnrollment(enrollmentId: enrollmentId, status: EnrollmentStatus.cancelled);
  }

  Future<void> loadAllSchedulesForParent(String parentId) async {
    if (parentId.isEmpty) {
      _schedules = [];
      notifyListeners();
      return;
    }
    try {
      _setLoading(true);
      _schedules = await _supabaseChildService.getSchedulesForParent(parentId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> loadSchedulesForSchool(String schoolId) async {
    if (schoolId.isEmpty) {
      _schedules = [];
      notifyListeners();
      return;
    }
    try {
      _setLoading(true);
      final response = await _supabaseChildService.adminClient.from('session_schedules').select().eq('school_id', schoolId);
      _schedules = (response as List).map((data) => SessionSchedule.fromSupabase(data)).toList();
      _setLoading(false);
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

  List<Map<String, dynamic>> _monthlyEnrollmentStats = [];
  List<Map<String, dynamic>> get monthlyEnrollmentStats => _monthlyEnrollmentStats;

  Future<void> loadDashboardStats(String ownerId) async {
    try {
      _setLoading(true);
      await _clubService.getClubMembers(ownerId);

      final enrollments = await _supabaseChildService.getEnrollmentsForOwner(ownerId);

      Map<String, int> stats = {};
      final now = DateTime.now();
      for (int i = 0; i < 6; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final key = "${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}";
        stats[key] = 0;
      }

      for (var e in enrollments) {
        final date = e.enrolledAt;
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        if (stats.containsKey(key)) {
          stats[key] = stats[key]! + 1;
        }
      }

      _monthlyEnrollmentStats = stats.entries.map((entry) => {
        'month': entry.key,
        'count': entry.value
      }).toList();
      _monthlyEnrollmentStats.sort((a, b) => a['month'].compareTo(b['month']));
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  List<Map<String, dynamic>> _ownerEnrollmentsDetailed = [];
  List<Map<String, dynamic>> get ownerEnrollmentsDetailed => _ownerEnrollmentsDetailed;

  Future<void> loadOwnerEnrollmentsDetailed(String ownerId) async {
    try {
      _setLoading(true);
      _ownerEnrollmentsDetailed = await _supabaseChildService.getOwnerEnrollmentsWithDetails(ownerId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  List<DailyActivity> getActivitiesForChild(String childId) {
    return _dailyActivities.where((a) => a.childId == childId).toList();
  }

  Future<void> loadDailyActivities(String parentId, DateTime date) async {
    try {
      _setLoading(true);
      _dailyActivities = await _supabaseChildService.getDailyActivities(parentId, date);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  String get paymentDescription => totalAmount == null ? 'Gratuit' : (isFullyPaid ? 'Payé' : 'En attente');
}
