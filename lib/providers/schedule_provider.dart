import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../services/schedule_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  Map<int, List<SessionSchedule>> _weeklySchedule = {};
  bool _isLoading = false;

  // Filtres actuels
  String? _currentCoachId;
  String? _currentCourseId;

  Map<int, List<SessionSchedule>> get weeklySchedule => _weeklySchedule;
  bool get isLoading => _isLoading;

  String? get currentCoachId => _currentCoachId;
  String? get currentCourseId => _currentCourseId;

  /// Charge le planning hebdomadaire avec filtres optionnels
  Future<void> loadWeeklySchedule({String? coachId, String? courseId}) async {
    _isLoading = true;
    notifyListeners();

    _currentCoachId = coachId;
    _currentCourseId = courseId;

    _weeklySchedule = await _service.generateWeeklySchedule(
      coachId: coachId,
      courseId: courseId,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Déplace une session et rafraîchit le planning
  Future<bool> moveSessionAndRefresh(
    String sessionId,
    int newDay,
    TimeOfDay newStart,
    TimeOfDay newEnd,
  ) async {
    final success = await _service.moveSession(
      sessionId,
      newDay,
      newStart,
      newEnd,
    );

    if (success) {
      // Recharger avec les mêmes filtres
      await loadWeeklySchedule(
        coachId: _currentCoachId,
        courseId: _currentCourseId,
      );
    }
    return success;
  }

  /// Permute deux sessions et rafraîchit
  Future<bool> swapSessionsAndRefresh(String id1, String id2) async {
    final success = await _service.swapSessions(id1, id2);

    if (success) {
      await loadWeeklySchedule(
        coachId: _currentCoachId,
        courseId: _currentCourseId,
      );
    }
    return success;
  }

  /// Réinitialise les filtres
  void clearFilters() {
    _currentCoachId = null;
    _currentCourseId = null;
  }
}