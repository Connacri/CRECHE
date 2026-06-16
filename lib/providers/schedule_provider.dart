import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../services/schedule_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  Map<DayOfWeek, List<SessionSchedule>> _weeklySchedule = {};
  bool _isLoading = false;

  // Filtres actuels
  String? _currentCoachId;
  String? _currentCourseId;
  String? _currentSchoolId;

  Map<DayOfWeek, List<SessionSchedule>> get weeklySchedule => _weeklySchedule;
  bool get isLoading => _isLoading;

  String? get currentCoachId => _currentCoachId;
  String? get currentCourseId => _currentCourseId;
  String? get currentSchoolId => _currentSchoolId;

  /// Charge le planning hebdomadaire avec filtres optionnels
  Future<void> loadWeeklySchedule({String? coachId, String? courseId, String? schoolId}) async {
    _isLoading = true;
    notifyListeners();

    _currentCoachId = coachId;
    _currentCourseId = courseId;
    _currentSchoolId = schoolId;

    final sessions = await _service.getActiveSessions(
      coachId: coachId,
      courseId: courseId,
      schoolId: schoolId,
    );

    // Groupement par jour
    final Map<DayOfWeek, List<SessionSchedule>> grouped = {};
    for (var session in sessions) {
      grouped.putIfAbsent(session.dayOfWeek, () => []).add(session);
    }
    
    // Tri par heure
    grouped.forEach((day, list) {
      list.sort((a, b) => 
        (a.timeSlot.start.hour * 60 + a.timeSlot.start.minute)
            .compareTo(b.timeSlot.start.hour * 60 + b.timeSlot.start.minute));
    });

    _weeklySchedule = grouped;
    _isLoading = false;
    notifyListeners();
  }

  /// Déplace une session et rafraîchit le planning
  Future<bool> moveSessionAndRefresh(
    String sessionId,
    DayOfWeek newDay,
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