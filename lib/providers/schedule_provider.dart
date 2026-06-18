import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_schedule_model.dart';
import '../services/schedule_service.dart';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _service = ScheduleService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<DayOfWeek, List<SessionSchedule>> _weeklySchedule = {};
  bool _isLoading = false;

  // Filtres actuels
  String? _currentCoachId;
  String? _currentCourseId;
  String? _currentSchoolId;

  Map<DayOfWeek, List<SessionSchedule>> get weeklySchedule => _weeklySchedule;
  bool get isLoading => _isLoading;

  int get minHour {
    int min = 8;
    for (var sessions in _weeklySchedule.values) {
      for (var session in sessions) {
        if (session.timeSlot.start.hour < min) min = session.timeSlot.start.hour;
      }
    }
    return min.clamp(0, 8);
  }

  int get maxHour {
    int max = 22;
    for (var sessions in _weeklySchedule.values) {
      for (var session in sessions) {
        final endHour = session.timeSlot.end.minute > 0 
            ? session.timeSlot.end.hour + 1 
            : session.timeSlot.end.hour;
        if (endHour > max) max = endHour;
      }
    }
    return max.clamp(20, 24);
  }

  String? get currentCoachId => _currentCoachId;
  String? get currentCourseId => _currentCourseId;
  String? get currentSchoolId => _currentSchoolId;

  RealtimeChannel? _scheduleSubscription;
  RealtimeChannel? _courseSubscription;

  ScheduleProvider() {
    _initRealtime();
  }

  void _initRealtime() {
    // S'abonner aux changements des sessions
    _scheduleSubscription = _supabase
        .channel('public:session_schedules')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'session_schedules',
          callback: (payload) {
            debugPrint('🔄 [ScheduleProvider] session_schedules changed: ${payload.eventType}');
            loadWeeklySchedule(
              coachId: _currentCoachId,
              courseId: _currentCourseId,
              schoolId: _currentSchoolId,
            );
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
            debugPrint('❌ [ScheduleProvider] Realtime Channel Error: $error');
            if (error?.toString().contains('1006') ?? false) {
              debugPrint('💡 TIP: Check if "session_schedules" is in "supabase_realtime" publication.');
            }
          }
        });

    // S'abonner aux changements des cours
    _courseSubscription = _supabase
        .channel('public:courses')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courses',
          callback: (payload) {
            debugPrint('🔄 [ScheduleProvider] courses changed: ${payload.eventType}');
            loadWeeklySchedule(
              coachId: _currentCoachId,
              courseId: _currentCourseId,
              schoolId: _currentSchoolId,
            );
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError) {
             debugPrint('❌ [ScheduleProvider] Realtime Channel Error (courses): $error');
          }
        });
  }

  @override
  void dispose() {
    _scheduleSubscription?.unsubscribe();
    _courseSubscription?.unsubscribe();
    super.dispose();
  }

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