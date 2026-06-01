import 'dart:io';

import 'package:flutter/material.dart';

import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../services/image_storage_service.dart';
import '../services/supabase_service.dart';

import '../models/daily_activity_model.dart';

/// ✅ VERSION CORRIGÉE ET COMPLÉTÉE du ChildEnrollmentProvider
class ChildEnrollmentProvider extends ChangeNotifier {
  final SupabaseChildService _supabaseChildService = SupabaseChildService();
  final ImageStorageService _imageService = ImageStorageService();

  List<ChildModel> _children = [];
  List<EnrollmentModel> _enrollments = [];
  List<SessionSchedule> _schedules = [];
  List<DailyActivity> _dailyActivities = [];

  bool _isLoading = false;
  String? _error;

  List<ChildModel> get children => _children;
  List<EnrollmentModel> get enrollments => _enrollments;
  List<SessionSchedule> get schedules => _schedules;
  List<DailyActivity> get dailyActivities => _dailyActivities;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ... (existing code)

  // === ✅ CHARGEMENT DES ACTIVITÉS QUOTIDIENNES ===
  Future<void> loadDailyActivities(String parentId, DateTime date) async {
    if (parentId.isEmpty) return;
    try {
      _setLoading(true);
      _dailyActivities = await _supabaseChildService.getDailyActivities(parentId, date);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadDailyActivities: $e');
      _setError('Impossible de charger les activités');
      _setLoading(false);
    }
  }

  List<DailyActivity> getActivitiesForChild(String childId) {
    return _dailyActivities.where((a) => a.childId == childId).toList();
  }

  // === CHARGEMENT DES ENFANTS ===
  Future<void> loadChildren(String parentId) async {
    if (parentId.isEmpty) {
      _children = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final childrenList = await _supabaseChildService.getChildren(parentId);

      _children = childrenList;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Erreur loadChildren: $e');
      _setError('Impossible de charger les enfants');
      _setLoading(false);
    }
  }

  // === AJOUT D'UN ENFANT ===
  Future<bool> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required ChildGender gender,
    File? photo,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      String? finalPhotoUrl = photoUrl;

      if (photo != null) {
        finalPhotoUrl = await _imageService.uploadChildPhoto(
          imageFile: photo,
          childId: '$parentId-${DateTime.now().millisecondsSinceEpoch}',
        );
        // Ajout d'un timestamp pour briser le cache
        if (finalPhotoUrl != null) {
          finalPhotoUrl = '$finalPhotoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
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
        isActive: true,
      );

      final newId = await _supabaseChildService.createChild(child);
      
      // ✅ Mise à jour locale instantanée
      final childWithId = child.copyWith(id: newId);
      _children.add(childWithId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur addChild: $e');
      _setError('Erreur lors de l\'ajout de l\'enfant');
      _setLoading(false);
      return false;
    }
  }

  // === ✅ MISE À JOUR D'UN ENFANT - VERSION OPTIMISÉE ===
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
      _setLoading(true);
      _clearError();

      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) throw Exception('Enfant non trouvé localement');

      final currentChild = _children[childIndex];
      String? photoUrl = currentChild.photoUrl;

      if (newPhotoUrl != null) {
        photoUrl = newPhotoUrl;
      } else if (newPhoto != null) {
        photoUrl = await _imageService.uploadChildPhoto(
          imageFile: newPhoto,
          childId: childId,
        );
        // Ajout d'un timestamp pour briser le cache
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

      // ✅ Mise à jour locale instantanée sans recharger tout
      _children[childIndex] = currentChild.copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: photoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur updateChild: $e');
      _setError('Erreur lors de la modification');
      _setLoading(false);
      return false;
    }
  }

  // === SUPPRESSION DOUCE D'UN ENFANT ===
  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseChildService.softDeleteChild(childId);

      // Retirer localement
      _children.removeWhere((c) => c.id == childId);
      _enrollments.removeWhere((e) => e.childId == childId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur deleteChild: $e');
      _setError('Erreur lors de la suppression');
      _setLoading(false);
      return false;
    }
  }

  // === ✅ CRÉATION D'UNE INSCRIPTION ===
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
        // Supabase génère l'UUID
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

      // Recharger les inscriptions
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

  // === ✅ CHARGEMENT DES INSCRIPTIONS ===
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

  // === ✅ MISE À JOUR D'UNE INSCRIPTION ===
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

      // Mettre à jour localement
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

  // === ✅ CHARGEMENT DES HORAIRES ===
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

  // === GROUPER LES HORAIRES PAR DATE ===
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

  // === MÉTHODES UTILITAIRES ===
  List<SessionSchedule> getSchedulesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _schedules
        .where((s) => s.isScheduledFor(normalizedDate) && !s.isCancelled)
        .toList();
  }

  /// ✅ Obtenir toutes les inscriptions d'un enfant spécifique
  List<EnrollmentModel> getEnrollmentsForChild(String childId) {
    return _enrollments.where((e) => e.childId == childId).toList();
  }

  /// ✅ Obtenir l'inscription d'un enfant pour un cours spécifique
  EnrollmentModel? getEnrollmentForChildAndCourse(
    String childId,
    String courseId,
  ) {
    return _enrollments
        .where((e) => e.childId == childId && e.courseId == courseId)
        .firstOrNull;
  }

  /// ✅ Vérifier si un enfant est déjà inscrit à un cours
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

// === ✅ EXTENSIONS POUR FACILITER L'UTILISATION ===

extension ChildModelExtensions on ChildModel {
  /// Obtient l'initiale du prénom pour l'avatar
  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  /// Formatte le nom complet
  String get displayName => '$firstName $lastName';

  /// Obtient une description de l'âge
  String get ageDescription {
    if (age == 0) return 'Moins d\'un an';
    if (age == 1) return '1 an';
    return '$age ans';
  }
}

extension EnrollmentModelExtensions on EnrollmentModel {
  /// Vérifie si l'inscription est active
  bool get isActive =>
      status == EnrollmentStatus.approved || status == EnrollmentStatus.pending;

  /// Obtient une description du statut de paiement
  String get paymentDescription {
    if (totalAmount == null) return 'Gratuit';
    if (isFullyPaid) return 'Payé';
    if (paidAmount != null && paidAmount! > 0) {
      return 'Partiel (${paidAmount!.toStringAsFixed(0)} / ${totalAmount!.toStringAsFixed(0)} DA)';
    }
    return 'En attente (${totalAmount!.toStringAsFixed(0)} DA)';
  }

  /// Obtient le pourcentage de paiement
  double get paymentPercentage {
    if (totalAmount == null || totalAmount == 0) return 100.0;
    return ((paidAmount ?? 0) / totalAmount!) * 100;
  }
}
