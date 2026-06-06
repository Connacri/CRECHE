import 'dart:io';
import 'package:flutter/material.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/daily_activity_model.dart';
import '../models/session_schedule_model.dart';
import '../services/supabase_service.dart';
import '../services/image_storage_service.dart';
import '../services/club_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChildEnrollmentProvider with ChangeNotifier {
  final SupabaseChildService _supabaseChildService = SupabaseChildService();
  final ImageStorageService _imageService = ImageStorageService();
  final ClubService _clubService = ClubService();

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

  // Realtime Subscriptions
  RealtimeChannel? _childrenChannel;
  RealtimeChannel? _enrollmentsChannel;
  RealtimeChannel? _activitiesChannel;
  RealtimeChannel? _schedulesChannel;

  @override
  void dispose() {
    _childrenChannel?.unsubscribe();
    _enrollmentsChannel?.unsubscribe();
    _activitiesChannel?.unsubscribe();
    _schedulesChannel?.unsubscribe();
    super.dispose();
  }

  void setupRealtimeListeners(String parentId) {
    if (parentId.isEmpty) return;

    // 1. Children Listener
    _childrenChannel?.unsubscribe();
    _childrenChannel = _supabaseChildService.adminClient
        .channel('public:children:parent=$parentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'children',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_id',
            value: parentId,
          ),
          callback: (payload) {
            _handleChildChange(payload);
          },
        )
        .subscribe();

    // 2. Enrollments Listener
    _enrollmentsChannel?.unsubscribe();
    _enrollmentsChannel = _supabaseChildService.adminClient
        .channel('public:enrollments:parent=$parentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'enrollments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_id',
            value: parentId,
          ),
          callback: (payload) {
            _handleEnrollmentChange(payload);
          },
        )
        .subscribe();

    // 3. Daily Activities Listener
    _activitiesChannel?.unsubscribe();
    _activitiesChannel = _supabaseChildService.adminClient
        .channel('public:daily_activities:parent=$parentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_activities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'parent_id',
            value: parentId,
          ),
          callback: (payload) {
            _handleActivityChange(payload);
          },
        )
        .subscribe();
  }

  void _handleChildChange(RealtimePostgresChangesPayload payload) {
    final eventType = payload.eventType;
    final Map<String, dynamic> data = payload.newRecord;
    final Map<String, dynamic> oldData = payload.oldRecord;

    if (eventType == PostgresChangeEvent.insert) {
      final newChild = ChildModel.fromSupabase(data);
      if (!_children.any((c) => c.id == newChild.id)) {
        _children.add(newChild);
      }
    } else if (eventType == PostgresChangeEvent.update) {
      final updatedChild = ChildModel.fromSupabase(data);
      final index = _children.indexWhere((c) => c.id == updatedChild.id);
      if (index != -1) {
        _children[index] = updatedChild;
      }
    } else if (eventType == PostgresChangeEvent.delete) {
      final id = oldData['id'];
      _children.removeWhere((c) => c.id == id);
    }
    notifyListeners();
  }

  void _handleEnrollmentChange(RealtimePostgresChangesPayload payload) {
    final eventType = payload.eventType;
    final Map<String, dynamic> data = payload.newRecord;
    final Map<String, dynamic> oldData = payload.oldRecord;

    if (eventType == PostgresChangeEvent.insert) {
      final newEnrollment = EnrollmentModel.fromSupabase(data);
      if (!_enrollments.any((e) => e.id == newEnrollment.id)) {
        _enrollments.add(newEnrollment);
      }
    } else if (eventType == PostgresChangeEvent.update) {
      final updatedEnrollment = EnrollmentModel.fromSupabase(data);
      final index = _enrollments.indexWhere((e) => e.id == updatedEnrollment.id);
      if (index != -1) {
        _enrollments[index] = updatedEnrollment;
      }
    } else if (eventType == PostgresChangeEvent.delete) {
      final id = oldData['id'];
      _enrollments.removeWhere((e) => e.id == id);
    }
    notifyListeners();
  }

  void _handleActivityChange(RealtimePostgresChangesPayload payload) {
    final eventType = payload.eventType;
    final Map<String, dynamic> data = payload.newRecord;
    final Map<String, dynamic> oldData = payload.oldRecord;

    if (eventType == PostgresChangeEvent.insert) {
      final newActivity = DailyActivity.fromSupabase(data);
      if (!_dailyActivities.any((a) => a.id == newActivity.id)) {
        _dailyActivities.add(newActivity);
      }
    } else if (eventType == PostgresChangeEvent.update) {
      final updatedActivity = DailyActivity.fromSupabase(data);
      final index = _dailyActivities.indexWhere((a) => a.id == updatedActivity.id);
      if (index != -1) {
        _dailyActivities[index] = updatedActivity;
      }
    } else if (eventType == PostgresChangeEvent.delete) {
      final id = oldData['id'];
      _dailyActivities.removeWhere((a) => a.id == id);
    }
    notifyListeners();
  }

  Future<bool> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required ChildGender gender,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
    File? photoFile,
    File? birthCertificateFile,
    File? medicalCertificateFile,
  }) async {
    try {
      _setLoading(true);
      String? finalPhotoUrl;
      if (photoFile != null) finalPhotoUrl = await _imageService.uploadImage(photoFile, 'children_photos');

      String? birthCertificateUrl;
      if (birthCertificateFile != null) birthCertificateUrl = await _imageService.uploadFile(birthCertificateFile, 'certificates');

      String? medicalCertificateUrl;
      if (medicalCertificateFile != null) medicalCertificateUrl = await _imageService.uploadFile(medicalCertificateFile, 'certificates');

      final child = ChildModel(
        id: '',
        parentId: parentId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: finalPhotoUrl,
        birthCertificateUrl: birthCertificateUrl,
        medicalCertificateUrl: medicalCertificateUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo ?? MedicalInfo(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
      );
      await _supabaseChildService.createChild(child);
      await loadChildren(parentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout: $e'; _setLoading(false);
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
    File? newBirthCertificate,
    File? newMedicalCertificate,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _setLoading(true);
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) throw 'Enfant non trouvé';

      String? finalPhotoUrl = _children[childIndex].photoUrl;
      if (newPhoto != null) finalPhotoUrl = await _imageService.uploadImage(newPhoto, 'children_photos');

      String? finalBirthCertUrl = _children[childIndex].birthCertificateUrl;
      if (newBirthCertificate != null) finalBirthCertUrl = await _imageService.uploadFile(newBirthCertificate, 'certificates');

      String? finalMedicalCertUrl = _children[childIndex].medicalCertificateUrl;
      if (newMedicalCertificate != null) finalMedicalCertUrl = await _imageService.uploadFile(newMedicalCertificate, 'certificates');

      final Map<String, dynamic> updates = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender.name,
        if (finalPhotoUrl != null) 'photo_url': finalPhotoUrl,
        if (finalBirthCertUrl != null) 'birth_certificate_url': finalBirthCertUrl,
        if (finalMedicalCertUrl != null) 'medical_certificate_url': finalMedicalCertUrl,
        if (schoolGrade != null) 'school_grade': schoolGrade,
        if (medicalInfo != null) 'medical_info': medicalInfo.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabaseChildService.updateChild(childId, updates);

      _children[childIndex] = _children[childIndex].copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: finalPhotoUrl,
        birthCertificateUrl: finalBirthCertUrl,
        medicalCertificateUrl: finalMedicalCertUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo,
        updatedAt: DateTime.now()
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      await _supabaseChildService.softDeleteChild(childId);
      _children.removeWhere((c) => c.id == childId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadChildren(String parentId) async {
    if (parentId.isEmpty) return;
    try {
      _setLoading(true);
      _children = await _supabaseChildService.getChildren(parentId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors du chargement des enfants: $e');
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

  Future<void> loadOwnerSchedules(String ownerId) async {
    if (ownerId.isEmpty) return;
    try {
      _setLoading(true);
      _schedules = await _supabaseChildService.getSchedulesByOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> createSchedule(SessionSchedule schedule) async {
    try {
      _setLoading(true);
      await _supabaseChildService.createSchedule(schedule);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      await _supabaseChildService.updateSchedule(scheduleId, updates);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      _setLoading(true);
      await _supabaseChildService.deleteSchedule(scheduleId);
      _schedules.removeWhere((s) => s.id == scheduleId);
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

  final int _memberCount = 0;
  int get memberCount => _memberCount;

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

  void _setError(String? value) { _error = value; notifyListeners(); }
  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  String get paymentDescription => totalAmount == null ? 'Gratuit' : (isFullyPaid ? 'Payé' : 'En attente');
}
