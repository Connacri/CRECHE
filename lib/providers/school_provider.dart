import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/school_slot_model.dart';
import '../models/session_schedule_model.dart';
import '../services/school_service.dart';

class SchoolProvider extends ChangeNotifier {
  final SupabaseSchoolService _schoolService = SupabaseSchoolService();

  List<UserModel> _schools = [];
  List<UserModel> get schools => _schools;

  List<SchoolSlotModel> _currentSchoolSlots = [];
  List<SchoolSlotModel> get currentSchoolSlots => _currentSchoolSlots;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _slotsSubscription;

  void subscribeToSchoolSlots(String schoolId) {
    if (schoolId.isEmpty) return;
    _slotsSubscription?.cancel();
    _slotsSubscription = _schoolService.getSchoolSlotsStream(schoolId).listen((data) {
      _currentSchoolSlots = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadSchools() async {
    _setLoading(true);
    try {
      _schools = await _schoolService.getSchools();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSchoolSlots(String schoolId) async {
    _setLoading(true);
    try {
      subscribeToSchoolSlots(schoolId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<SchoolSlotModel>> getAvailableSlots(String schoolId) async {
    return await _schoolService.getAvailableSlots(schoolId);
  }

  Future<void> addSlot(SchoolSlotModel slot) async {
    _setLoading(true);
    try {
      await _schoolService.createSlot(slot);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSlot(String slotId, String schoolId) async {
    _setLoading(true);
    try {
      await _schoolService.deleteSlot(slotId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> associateCourseToSlot({
    required String courseId,
    required String schoolId,
    required SchoolSlotModel slot,
    required DateTime startDate,
    required DateTime endDate,
    String? coachId,
  }) async {
    _setLoading(true);
    try {
      final schedule = SessionSchedule(
        id: '',
        courseId: courseId,
        enrollmentId: '', // Pas lié à une inscription spécifique si c'est pour tout le cours
        dayOfWeek: slot.dayOfWeek,
        timeSlot: slot.timeSlot,
        startDate: startDate,
        endDate: endDate,
        currentEnrollment: 0,
        maxCapacity: 30,
        schoolId: schoolId,
        coachId: coachId,
      );

      await _schoolService.createSessionSchedule(schedule);

      // Marquer le créneau comme occupé
      await _schoolService.updateSlot(slot.id, {'is_occupied': true});

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
