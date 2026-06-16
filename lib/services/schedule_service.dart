import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_schedule_model.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère toutes les sessions actives pour le planning hebdomadaire
  Future<List<SessionSchedule>> getActiveSessions({String? courseId, String? coachId, String? schoolId}) async {
    try {
      debugPrint('🔍 [ScheduleService] fetching sessions. Filters: courseId=$courseId, coachId=$coachId, schoolId=$schoolId');
      
      // 1. Fetch from session_schedules
      var sessionQuery = _supabase
          .from('session_schedules')
          .select('*, courses(title)')
          .eq('is_active', true);

      if (courseId != null) sessionQuery = sessionQuery.eq('course_id', courseId);
      if (coachId != null) sessionQuery = sessionQuery.eq('coach_id', coachId);
      if (schoolId != null) sessionQuery = sessionQuery.eq('school_id', schoolId);

      final sessionData = await sessionQuery;
      final List<SessionSchedule> sessions = sessionData.map((e) => SessionSchedule.fromSupabase(e)).toList();

      // 2. Fetch from courses (those with planning fields populated)
      var courseQuery = _supabase
          .from('courses')
          .select()
          .not('day_of_week', 'is', null)
          .not('start_time', 'is', null)
          .not('end_time', 'is', null)
          .eq('is_active', true);

      if (courseId != null) courseQuery = courseQuery.eq('id', courseId);
      if (coachId != null) courseQuery = courseQuery.eq('coach_id', coachId);
      if (schoolId != null) courseQuery = courseQuery.eq('club_id', schoolId);

      final courseData = await courseQuery;
      debugPrint('🔍 [ScheduleService] Found ${sessions.length} sessions and ${courseData.length} courses with planning');

      for (var c in courseData) {
        // Normalisation: DB day_of_week is 1-7, DayOfWeek enum is 0-6
        final rawDay = c['day_of_week'] as int;
        final dayIndex = rawDay - 1; 
        
        if (dayIndex < 0 || dayIndex > 6) {
          debugPrint('⚠️ [ScheduleService] Invalid day_of_week: $rawDay for course ${c['title']}');
          continue;
        }

        final startTimeStr = c['start_time'] as String;
        final endTimeStr = c['end_time'] as String;
        
        // Comparaison robuste (on parse les deux pour comparer les TimeOfDay)
        final parsedStart = TimeSlot.parseTime(startTimeStr);
        
        final exists = sessions.any((s) => 
          s.courseId == c['id'] && 
          s.dayOfWeek.index == dayIndex && 
          s.timeSlot.start.hour == parsedStart.hour &&
          s.timeSlot.start.minute == parsedStart.minute
        );

        if (!exists) {
          debugPrint('➕ [ScheduleService] Adding course to schedule: ${c['title']} on day $rawDay at $startTimeStr');
          sessions.add(SessionSchedule(
            id: 'course-${c['id']}',
            courseId: c['id'],
            courseTitle: c['title'],
            dayOfWeek: DayOfWeek.values[dayIndex],
            timeSlot: TimeSlot.fromMap({'start': startTimeStr, 'end': endTimeStr}),
            startDate: DateTime.parse(c['season_start_date']),
            endDate: DateTime.parse(c['season_end_date']),
            currentEnrollment: c['current_students'] ?? 0,
            maxCapacity: c['max_students'] ?? 30,
            coachId: c['coach_id'],
            roomName: c['room_name'],
            schoolId: c['club_id'],
          ));
        }
      }

      return sessions;
    } catch (e) {
      debugPrint('❌ [ScheduleService] getActiveSessions Error: $e');
      return [];
    }
  }

  /// Génère le planning hebdomadaire groupé par jour
  Future<Map<DayOfWeek, List<SessionSchedule>>> generateWeeklySchedule({
    String? courseId,
    String? coachId,
  }) async {
    final sessions = await getActiveSessions(courseId: courseId, coachId: coachId);
    final Map<DayOfWeek, List<SessionSchedule>> schedule = {};

    for (var session in sessions) {
      schedule.putIfAbsent(session.dayOfWeek, () => []).add(session);
    }

    // Tri par heure de début pour chaque jour
    schedule.forEach((day, list) {
      list.sort((a, b) => 
        (a.timeSlot.start.hour * 60 + a.timeSlot.start.minute)
            .compareTo(b.timeSlot.start.hour * 60 + b.timeSlot.start.minute));
    });

    return schedule;
  }

  /// Vérifie les chevauchements
  bool hasConflict(List<SessionSchedule> sessions, SessionSchedule candidate, {String? excludeId}) {
    return sessions.any((s) =>
      s.id != excludeId && s.overlapsWith(candidate));
  }

  /// Déplace une session (avec validation anti-chevauchement)
  Future<bool> moveSession(
    String sessionId,
    DayOfWeek newDay,
    TimeOfDay newStart,
    TimeOfDay newEnd,
  ) async {
    final allSessions = await getActiveSessions();
    final sessionIndex = allSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return false;

    final target = allSessions[sessionIndex];
    final updated = SessionSchedule(
      id: target.id,
      courseId: target.courseId,
      dayOfWeek: newDay,
      timeSlot: TimeSlot(start: newStart, end: newEnd),
      startDate: target.startDate,
      endDate: target.endDate,
      currentEnrollment: target.currentEnrollment,
      maxCapacity: target.maxCapacity,
      coachId: target.coachId,
      roomName: target.roomName,
      schoolId: target.schoolId,
      isActive: target.isActive,
    );

    if (hasConflict(allSessions, updated, excludeId: sessionId)) {
      return false; // Conflit détecté
    }

    // Mise à jour dans Supabase
    await _supabase.from('session_schedules').update(updated.toSupabase()).eq('id', sessionId);
    return true;
  }

  /// Permutation (swap) entre deux sessions
  Future<bool> swapSessions(String id1, String id2) async {
    final sessions = await getActiveSessions();
    final s1 = sessions.firstWhere((s) => s.id == id1);
    final s2 = sessions.firstWhere((s) => s.id == id2);

    // Échange des créneaux
    final success1 = await moveSession(id1, s2.dayOfWeek, s2.timeSlot.start, s2.timeSlot.end);
    if (!success1) return false;

    return await moveSession(id2, s1.dayOfWeek, s1.timeSlot.start, s1.timeSlot.end);
  }

  /// Crée une nouvelle session liée à un cours
  Future<String?> createSession({
    required String courseId,
    required DayOfWeek dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime startDate,
    required DateTime endDate,
    required int maxCapacity,
    int currentEnrollment = 0,
    String? coachId,
    String? roomName,
    String? schoolId,
  }) async {
    final newSession = SessionSchedule(
      id: '', // généré par Supabase
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      timeSlot: TimeSlot(start: startTime, end: endTime),
      startDate: startDate,
      endDate: endDate,
      maxCapacity: maxCapacity,
      currentEnrollment: currentEnrollment,
      coachId: coachId,
      roomName: roomName,
      schoolId: schoolId,
    );

    final data = await _supabase.from('session_schedules').insert(newSession.toSupabase()).select();
    return data.first['id'] as String?;
  }
}