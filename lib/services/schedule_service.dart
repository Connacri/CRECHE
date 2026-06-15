import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_schedule_model.dart';
import '../models/course_model_complete.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère toutes les sessions actives pour le planning hebdomadaire
  Future<List<SessionSchedule>> getActiveSessions({String? courseId, String? coachId}) async {
    var query = _supabase
        .from('session_schedules')
        .select()
        .eq('is_active', true);

    if (courseId != null) query = query.eq('course_id', courseId);
    if (coachId != null) query = query.eq('coach_id', coachId);

    final data = await query;
    return data.map((e) => SessionSchedule.fromSupabase(e)).toList();
  }

  /// Génère le planning hebdomadaire groupé par jour
  Future<Map<int, List<SessionSchedule>>> generateWeeklySchedule({
    String? courseId,
    String? coachId,
  }) async {
    final sessions = await getActiveSessions(courseId: courseId, coachId: coachId);
    final Map<int, List<SessionSchedule>> schedule = {};

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
    int newDay,
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
    required int dayOfWeek,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? coachId,
    String? roomName,
    String? schoolId,
  }) async {
    final newSession = SessionSchedule(
      id: '', // généré par Supabase
      courseId: courseId,
      dayOfWeek: dayOfWeek,
      timeSlot: TimeSlot(start: startTime, end: endTime),
      coachId: coachId,
      roomName: roomName,
      schoolId: schoolId,
    );

    final data = await _supabase.from('session_schedules').insert(newSession.toSupabase()).select();
    return data.first['id'] as String?;
  }
}