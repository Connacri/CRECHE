import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
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

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> get expenses => _expenses;

  StreamSubscription? _expensesSubscription;

  // Getters Statistiques Réels (Réactifs)
  double get totalRevenue => _ownerEnrollmentsDetailed.fold(0.0, (sum, item) {
    try {
      final e = item['enrollment'];
      return sum + (e?['paid_amount']?.toDouble() ?? 0.0);
    } catch (_) { return sum; }
  });

  double get totalExpenses => _expenses.fold(0.0, (sum, item) => sum + (item['amount']?.toDouble() ?? 0.0));

  double get netIncome => totalRevenue - totalExpenses;

  int get approvedEnrollmentsCount => _ownerEnrollmentsDetailed.where((item) {
    return item['enrollment']?['status'] == 'approved';
  }).length;

  int get pendingEnrollmentsCount => _ownerEnrollmentsDetailed.where((item) {
    return item['enrollment']?['status'] == 'pending';
  }).length;

  int get paidEnrollmentsCount => _ownerEnrollmentsDetailed.where((item) {
    return item['enrollment']?['payment_status'] == 'paid';
  }).length;

  int get unpaidEnrollmentsCount => _ownerEnrollmentsDetailed.where((item) {
    final status = item['enrollment']?['status'];
    final paymentStatus = item['enrollment']?['payment_status'];
    return status != 'rejected' && status != 'cancelled' && paymentStatus != 'paid';
  }).length;

  int get confirmedEnrollmentsCount => _ownerEnrollmentsDetailed.where((item) {
    return item['enrollment']?['status'] == 'approved' && item['enrollment']?['payment_status'] == 'paid';
  }).length;

  List<Map<String, dynamic>> get weeklyEnrollmentData {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    
    return last7Days.map((date) {
      final dayStr = "${date.day}/${date.month}";
      final count = _ownerEnrollmentsDetailed.where((item) {
        try {
          final enrolledAt = DateTime.parse(item['enrollment']['enrolled_at']);
          return enrolledAt.year == date.year && enrolledAt.month == date.month && enrolledAt.day == date.day;
        } catch (_) { return false; }
      }).length;
      return {'day': dayStr, 'count': count.toDouble()};
    }).toList();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _enrollmentsSubscription;
  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _ownerSchedulesSubscription;
  StreamSubscription? _ownerEnrollmentsSubscription;

  final Map<String, CourseModel> _courseById = {};

  CourseModel? getCourse(String id) => _courseById[id];

  Future<void> loadCourses(String ownerId) async {
    try {
      final response = await _supabaseChildService.adminClient
          .from('courses')
          .select()
          .eq('created_by', ownerId);

      final list = (response as List)
          .map((e) => CourseModel.fromSupabase(e))
          .toList();

      _courseById
        ..clear()
        ..addEntries(list.map((c) => MapEntry(c.id, c)));

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void subscribeToParentData(String parentId) {
    if (parentId.isEmpty) return;

    _childrenSubscription?.cancel();
    _childrenSubscription = _supabaseChildService.getChildrenStream(parentId).listen(
      (data) {
        _children = data;
        notifyListeners();
      },
      onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] getChildrenStream Error: $e'),
    );

    _enrollmentsSubscription?.cancel();
    _enrollmentsSubscription = _supabaseChildService.getEnrollmentsStream(parentId).listen(
      (data) {
        _enrollments = data;
        notifyListeners();
      },
      onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] getEnrollmentsStream Error: $e'),
    );
  }

  void subscribeToDailyActivities(String parentId, DateTime date) {
    _activitiesSubscription?.cancel();
    _activitiesSubscription = _supabaseChildService.getDailyActivitiesStream(parentId, date).listen(
      (data) {
        _dailyActivities = data;
        notifyListeners();
      },
      onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] getDailyActivitiesStream Error: $e'),
    );
  }

  void subscribeToOwnerSchedules(String ownerId) {
    _ownerSchedulesSubscription?.cancel();
    _ownerSchedulesSubscription = _supabaseChildService.getSchedulesByOwnerStream(ownerId).listen(
      (data) {
        _schedules = data.where((s) => s.schoolId == ownerId || s.coachId == ownerId).toList();
        notifyListeners();
      },
      onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] getSchedulesByOwnerStream Error: $e'),
    );
  }

  void subscribeToOwnerEnrollments(String ownerId) {
    if (ownerId.isEmpty) return;
    
    // Charger immédiatement les données initiales
    loadOwnerEnrollmentsDetailed(ownerId);
    
    _ownerEnrollmentsSubscription?.cancel();
    _ownerEnrollmentsSubscription = _supabaseChildService.adminClient
        .from('enrollments')
        .stream(primaryKey: ['id'])
        .listen(
          (_) {
            debugPrint('🔄 [ChildEnrollmentProvider] Enrollments changed, reloading...');
            loadOwnerEnrollmentsDetailed(ownerId);
          },
          onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] Enrollments Stream Error: $e'),
        );
  }

  void subscribeToExpenses(String ownerId) {
    if (ownerId.isEmpty) return;
    
    _expensesSubscription?.cancel();
    _expensesSubscription = _supabaseChildService.adminClient
        .from('club_expenses')
        .stream(primaryKey: ['id'])
        .eq('club_id', ownerId)
        .listen(
          (data) {
            _expenses = data;
            notifyListeners();
          },
          onError: (e) => debugPrint('❌ [ChildEnrollmentProvider] Expenses Stream Error: $e'),
        );
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    _enrollmentsSubscription?.cancel();
    _activitiesSubscription?.cancel();
    _ownerSchedulesSubscription?.cancel();
    _ownerEnrollmentsSubscription?.cancel();
    _expensesSubscription?.cancel();
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
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _setLoading(true);
      String? photoUrl;
      String? birthCertUrl;
      String? medicalCertUrl;

      final tempChildId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🔍 Starting addChild operation');
      debugPrint('🆔 Temp child ID: $tempChildId');
      if (photoFile != null) {
        debugPrint('📤 Uploading child photo: ${photoFile.path}');
        photoUrl = await _imageService.uploadChildPhoto(imageFile: photoFile, userId: parentId, childId: tempChildId);
        debugPrint('✅ Photo upload URL: $photoUrl');
      }
      if (birthCertificateFile != null) {
        debugPrint('📄 Uploading birth certificate: ${birthCertificateFile.path}');
        birthCertUrl = await _imageService.uploadFile(birthCertificateFile, '$parentId/children/certs');
        debugPrint('✅ Birth certificate URL: $birthCertUrl');
      }
      if (medicalCertificateFile != null) {
        debugPrint('📄 Uploading medical certificate: ${medicalCertificateFile.path}');
        medicalCertUrl = await _imageService.uploadFile(medicalCertificateFile, '$parentId/children/certs');
        debugPrint('✅ Medical certificate URL: $medicalCertUrl');
      }

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
        medicalInfo: medicalInfo ?? MedicalInfo(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
      );
      debugPrint('🛠️ Created ChildModel, now inserting into Supabase');
      final realId = await _supabaseChildService.createChild(newChild);
      debugPrint('✅ Child created with real ID: $realId');

      if (photoUrl != null && photoUrl.contains(tempChildId)) {
        debugPrint('🔄 Re‑uploading photo with real child ID');
        final finalPhotoUrl = await _imageService.uploadChildPhoto(imageFile: photoFile!, userId: parentId, childId: realId);
        await _supabaseChildService.updateChild(realId, {'photo_url': finalPhotoUrl});
        debugPrint('✅ Updated child photo URL: $finalPhotoUrl');
      }

      _setLoading(false);
      debugPrint('✅ addChild operation completed successfully');
      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint('❌ Error in addChild: $e');
      _setError('Erreur lors de la création: $e');
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
    MedicalInfo? medicalInfo,
    File? newPhoto,
    File? newBirthCertificate,
    File? newMedicalCertificate,
  }) async {
    try {
      _setLoading(true);
      final Map<String, dynamic> updates = {'updated_at': DateTime.now().toIso8601String()};

      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      if (gender != null) updates['gender'] = gender.name;
      if (schoolGrade != null) updates['school_grade'] = schoolGrade;
      if (medicalInfo != null) updates['medical_info'] = medicalInfo.toMap();

      if (newPhoto != null) updates['photo_url'] = await _imageService.uploadChildPhoto(imageFile: newPhoto, userId: parentId, childId: childId);
      if (newBirthCertificate != null) updates['birth_certificate_url'] = await _imageService.uploadFile(newBirthCertificate, '$parentId/children/certs');
      if (newMedicalCertificate != null) updates['medical_certificate_url'] = await _imageService.uploadFile(newMedicalCertificate, '$parentId/children/certs');

      await _supabaseChildService.updateChild(childId, updates);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour: $e');
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

  Future<void> loadOwnerEnrollmentsDetailed(String ownerId) async {
    try {
      final data = await _supabaseChildService.getOwnerEnrollmentsWithDetails(ownerId);
      
      // Adaptation pour assurer la compatibilité entre la structure de la RPC et les attentes de l'UI
      _ownerEnrollmentsDetailed = data.map<Map<String, dynamic>>((item) {
        if (item.containsKey('enrollment')) {
          return Map<String, dynamic>.from(item);
        }
        
        // Si la structure est plate (ancienne version de la RPC ou appel direct Supabase)
        return {
          'enrollment': item,
          'course': item['courses'] ?? item['course'],
          'child': item['children'] ?? item['child'],
        };
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ChildEnrollmentProvider] Error loading owner enrollments: $e');
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

  Future<bool> validatePayment(String enrollmentId, double amount) async {
    return updateEnrollment(
      enrollmentId: enrollmentId,
      paymentStatus: PaymentStatus.paid,
      paidAmount: amount,
    );
  }

  void _setError(String? value) { _error = value; notifyListeners(); }
  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  String get paymentDescription => totalAmount == null ? 'Gratuit' : (isFullyPaid ? 'Payé' : 'En attente');
}
