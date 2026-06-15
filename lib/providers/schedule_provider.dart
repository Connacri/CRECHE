import 'package:flutter/material.dart';
import '../models/session_schedule_model.dart';
import '../services/schedule_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _service = ScheduleService();

  Map<int, List<SessionSchedule>> _weeklySchedule = {};
  bool _isLoading = false;
  String? _currentFilter; // coachId ou courseId

  Map<int, List<SessionSchedule>> get weeklySchedule => _weeklySchedule;
  bool get isLoading => _isLoading;

  Future<void> loadWeeklySchedule({String? coachId, String? courseId}) async {
    _isLoading = true;
    notifyListeners();

    _currentFilter = coachId ?? courseId;
    _weeklySchedule = await _service.generateWeeklySchedule(
      coachId: coachId,
      courseId: courseId,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> moveSessionAndRefresh(
    String sessionId,
    int newDay,
    TimeOfDay newStart,
    TimeOfDay newEnd,
  ) async {
    final success = await _service.moveSession(sessionId, newDay, newStart, newEnd);
    if (success) {
      await loadWeeklySchedule(coachId: _currentFilter); // refresh
    }
    return success;
  }

  Future<bool> swapSessionsAndRefresh(String id1, String id2) async {
    final success = await _service.swapSessions(id1, id2);
    if (success) {
      await loadWeeklySchedule(coachId: _currentFilter);
    }
    return success;
  }
}