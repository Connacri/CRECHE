import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/daily_activity_model.dart';
import '../models/session_schedule_model.dart';
import '../services/supabase_service.dart';
import '../services/image_storage_service.dart';
import '../services/club_service.dart';

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

  List<Map<String, dynamic>> _ownerEnrollmentsDetailed = [];
  List<Map<String, dynamic>> get ownerEnrollmentsDetailed => _ownerEnrollmentsDetailed;

  final Map<String, Map<String, dynamic>> _childrenLocations = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _enrollmentsSubscription;
  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _ownerSchedulesSubscription;
  StreamSubscription? _ownerEnrollmentsSubscription;

  void subscribeToParentData(String parentId) {
    if (parentId.isEmpty) return;

    _childrenSubscription?.cancel();
    _childrenSubscription = _supabaseChildService.getChildrenStream(parentId).listen((data) {
      _children = data;
      notifyListeners();
    });

    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = _supabaseChildService.getEnrollmentsStream(parentId).listen((data) {
      _enrollments = data;
      notifyListeners();
    });
  }

  void subscribeToDailyActivities(String parentId, DateTime date) {
    _activitiesSubscription?.cancel();
    _activitiesSubscription = _supabaseChildService.getDailyActivitiesStream(parentId, date).listen((data) {
      _dailyActivities = data;
      notifyListeners();
    });
  }

  void subscribeToOwnerSchedules(String ownerId) {
    _ownerSchedulesSubscription?.cancel();
    _ownerSchedulesSubscription = _supabaseChildService.getSchedulesByOwnerStream(ownerId).listen((data) {
       _schedules = data.where((s) => s.schoolId == ownerId || s.coachId == ownerId).toList();
       notifyListeners();
    });
  }

  void subscribeToOwnerEnrollments(String ownerId) {
    if (ownerId.isEmpty) return;
    _ownerEnrollmentsSubscription?.cancel();
    _ownerEnrollmentsSubscription = _supabaseChildService.adminClient
        .from('enrollments')
        .stream(primaryKey: ['id'])
        .listen((_) {
          loadOwnerEnrollmentsDetailed(ownerId);
        });
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    _enrollmentsSubscription?.cancel();
    _activitiesSubscription?.cancel();
    _ownerSchedulesSubscription?.cancel();
    _ownerEnrollmentsSubscription?.cancel();
    super.dispose();
  }

  void setupRealtimeListeners(String parentId) => subscribeToParentData(parentId);

  Future<bool> addChild({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required ChildGender gender,
    required String parentId,
    File? photoFile,
    File? birthCertificateFile,
    File? medicalCertificateFile,
    String? schoolGrade,
    String? medicalInfo,
  }) async {
    try {
      _setLoading(true);
      String? photoUrl;
      String? birthCertUrl;
      String? medicalCertUrl;

      final tempChildId = 'temp_\${DateTime.now().millisecondsSinceEpoch}';

      if (photoFile != null) photoUrl = await _imageService.uploadChildPhoto(imageFile: photoFile, userId: parentId, childId: tempChildId);
      if (birthCertificateFile != null) birthCertUrl = await _imageService.uploadFile(birthCertificateFile, '\$parentId/children/certs');
      if (medicalCertificateFile != null) medicalCertUrl = await _imageService.uploadFile(medicalCertificateFile, '\$parentId/children/certs');

      final newChild = ChildModel(
        id: '',
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        parentId: parentId,
        photoUrl: photoUrl,
        birthCertificateUrl: birthCertUrl,
        medicalCertificateUrl: medicalCertUrl,
        schoolGrade: schoolGrade,
        medicalInfo: MedicalInfo(additionalNotes: medicalInfo),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
      );

      final realId = await _supabaseChildService.createChild(newChild);

      if (photoUrl != null && photoUrl.contains(tempChildId)) {
        final finalPhotoUrl = await _imageService.uploadChildPhoto(imageFile: photoFile!, userId: parentId, childId: realId);
        await _supabaseChildService.updateChild(realId, {'photo_url': finalPhotoUrl});
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la création: \$e');
      return false;
    }
  }

  Future<bool> updateChild({
    required String childId,
    required String parentId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    ChildGender? gender,
    String? schoolGrade,
    String? medicalInfo,
    File? newPhoto,
    File? newBirthCertificate,
    File? newMedicalCertificate,
  }) async {
    try {
      _setLoading(true);
      final Map<String, dynamic> updates = {'updated_at': DateTime.now().toIso8601String()};

      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender.name;
      if (schoolGrade != null) updates['school_grade'] = schoolGrade;
      if (medicalInfo != null) updates['medical_info'] = MedicalInfo(additionalNotes: medicalInfo).toMap();

      if (newPhoto != null) updates['photo_url'] = await _imageService.uploadChildPhoto(imageFile: newPhoto, userId: parentId, childId: childId);
      if (newBirthCertificate != null) updates['birth_certificate_url'] = await _imageService.uploadFile(newBirthCertificate, '\$parentId/children/certs');
      if (newMedicalCertificate != null) updates['medical_certificate_url'] = await _imageService.uploadFile(newMedicalCertificate, '\$parentId/children/certs');

      await _supabaseChildService.updateChild(childId, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour: \$e');
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      await _supabaseChildService.softDeleteChild(childId);
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
      subscribeToParentData(parentId);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors du chargement des enfants: \$e');
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
      subscribeToOwnerEnrollments(ownerId);
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
    dynamic attendanceHistory,
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
      if (attendanceHistory != null) updates['attendance_history'] = attendanceHistory;

      await _supabaseChildService.updateEnrollment(enrollmentId, updates);
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
      subscribeToOwnerSchedules(ownerId);
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
        final key = "\${monthDate.year}-\${monthDate.month.toString().padLeft(2, '0')}";
        stats[key] = 0;
      }

      for (var e in enrollments) {
        final date = e.enrolledAt;
        final key = "\${date.year}-\${date.month.toString().padLeft(2, '0')}";
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

  Future<void> loadOwnerEnrollmentsDetailed(String ownerId) async {
    try {
      final data = await _supabaseChildService.getOwnerEnrollmentsWithDetails(ownerId);
      _ownerEnrollmentsDetailed = data;
      notifyListeners();
    } catch (e) {
    }
  }

  List<DailyActivity> getActivitiesForChild(String childId) {
    return _dailyActivities.where((a) => a.childId == childId).toList();
  }

  Future<void> loadDailyActivities(String parentId, DateTime date) async {
    try {
      _setLoading(true);
      subscribeToDailyActivities(parentId, date);
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
