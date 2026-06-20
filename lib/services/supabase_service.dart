import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../models/daily_activity_model.dart';
import '../core/config/supabase_config.dart';

abstract class AdminSupabaseService {
  static SupabaseClient? _cachedAdminClient;

  SupabaseClient get adminClient {
    _cachedAdminClient ??= SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceRoleKey,
      realtimeClientOptions: const RealtimeClientOptions(
        timeout: Duration(seconds: 30),
      ),
    );
    return _cachedAdminClient!;
  }
}

class SupabaseCourseService extends AdminSupabaseService {
  static const String _tableName = 'courses';

  Stream<List<CourseModel>> getCoursesStream() {
    return adminClient
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CourseModel.fromSupabase(json)).toList());
  }

  Stream<List<CourseModel>> getUserCoursesStream(String userId) {
    return adminClient
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CourseModel.fromSupabase(json)).toList());
  }

  Future<List<CourseModel>> getCourses({
    CourseCategory? category,
    CourseSeason? season,
    bool? isActive,
    DateTime? lastDocumentTimestamp,
    int limit = 20,
  }) async {
    try {
      var query = adminClient.from(_tableName).select();
      if (category != null) query = query.eq('category', category.name);
      if (season != null) query = query.eq('season', season.name);
      if (isActive != null) query = query.eq('is_active', isActive);
      if (lastDocumentTimestamp != null) {
        query = query.lt('created_at', lastDocumentTimestamp.toIso8601String());
      }
      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Échec de la récupération des cours. Veuillez vérifier votre connexion. Détails: $e');
    }
  }

  Future<String> createCourse(CourseModel course) async {
    try {
      final data = course.toSupabase();
      data.remove('id');
      final response = await adminClient.from(_tableName).insert(data).select('id').single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Impossible de créer le cours. Assurez-vous que tous les champs sont valides. Détails: $e');
    }
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      updates.remove('created_at');
      updates['updated_at'] = DateTime.now().toIso8601String();
      await adminClient.from(_tableName).update(updates).eq('id', courseId);
    } catch (e) {
      throw Exception('Mise à jour du cours échouée. Détails: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await adminClient.from(_tableName).delete().eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur deleteCourse: $e');
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final response = await adminClient.from(_tableName).select().eq('id', courseId).maybeSingle();
      if (response == null) return null;
      return CourseModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Erreur getCourse: $e');
    }
  }

  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      final response = await adminClient
          .from(_tableName)
          .select()
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('La recherche a échoué. Détails: $e');
    }
  }

  Future<List<CourseModel>> getUserCourses(String userId) async {
    try {
      final response = await adminClient
          .from(_tableName)
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur getUserCourses: $e');
    }
  }

  Future<List<CourseModel>> getCoursesNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 50,
  }) async {
    try {
      final response = await adminClient
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(500);

      final courses = (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();

      final coursesWithDistance = courses.map((course) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          course.location.latitude,
          course.location.longitude,
        );
        return {'course': course, 'distance': distance};
      }).where((item) {
        return (item['distance'] as double) <= radiusKm;
      }).toList();

      coursesWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      return coursesWithDistance
          .take(limit)
          .map((item) => item['course'] as CourseModel)
          .toList();
    } catch (e) {
      throw Exception('Erreur getCoursesNearby: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }
}

class SupabaseChildService extends AdminSupabaseService {
  Stream<List<ChildModel>> getChildrenStream(String parentId) {
    return adminClient
        .from('children')
        .stream(primaryKey: ['id'])
        .eq('parent_id', parentId)
        .map((data) => data.where((json) => json['is_active'] == true).map((json) => ChildModel.fromSupabase(json)).toList());
  }

  Stream<List<EnrollmentModel>> getEnrollmentsStream(String parentId) {
    return adminClient
        .from('enrollments')
        .stream(primaryKey: ['id'])
        .eq('parent_id', parentId)
        .map((data) => data.map((json) => EnrollmentModel.fromSupabase(json)).toList());
  }

  Stream<List<DailyActivity>> getDailyActivitiesStream(String parentId, DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return adminClient
        .from('daily_activities')
        .stream(primaryKey: ['id'])
        .eq('date', dateStr)
        .map((data) => data.map((json) => DailyActivity.fromSupabase(json)).toList());
  }

  Future<List<ChildModel>> getChildren(String parentId) async {
    final response = await adminClient.from('children').select().eq('parent_id', parentId).eq('is_active', true);
    return response.map((data) => ChildModel.fromSupabase(data)).toList();
  }

  Future<String> createChild(ChildModel child) async {
    final response = await adminClient.from('children').insert(child.toSupabase()).select().single();
    return response['id'] as String;
  }

  Future<void> updateChild(String childId, Map<String, dynamic> updates) async {
    await adminClient.from('children').update(updates).eq('id', childId);
  }

  Future<void> softDeleteChild(String childId) async {
    await adminClient.from('children').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', childId);
  }

  Future<List<EnrollmentModel>> getEnrollments(String parentId) async {
    final response = await adminClient.from('enrollments').select().eq('parent_id', parentId);
    return response.map((data) => EnrollmentModel.fromSupabase(data)).toList();
  }

  Future<List<EnrollmentModel>> getEnrollmentsForOwner(String ownerId) async {
    // Chercher les cours créés par l'utilisateur OU appartenant à son club
    final coursesResponse = await adminClient
        .from('courses')
        .select('id')
        .or('created_by.eq.$ownerId,club_id.eq.$ownerId');
    
    final courseIds = (coursesResponse as List).map((c) => c['id'] as String).toList();
    if (courseIds.isEmpty) return [];
    
    final response = await adminClient.from('enrollments').select().inFilter('course_id', courseIds);
    return response.map((data) => EnrollmentModel.fromSupabase(data)).toList();
  }

  Future<List<Map<String, dynamic>>> getEnrollmentsForOwnerDetailed(String ownerId) async {
    final response = await adminClient.from("enrollments").select("*, courses(*), children(*)").eq("courses.created_by", ownerId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getOwnerEnrollmentsWithDetails(String ownerId) async {
    try {
      final response = await adminClient.rpc('get_owner_enrollments_with_details', params: {'owner_id': ownerId});
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<String> createEnrollment(EnrollmentModel enrollment) async {
    try {
      final data = enrollment.toSupabase();
      debugPrint('🛰️ [SupabaseChildService] createEnrollment (Supabase): $data');
      
      final response = await adminClient
          .from('enrollments')
          .insert(data)
          .select()
          .single();
          
      debugPrint('🛰️ [SupabaseChildService] Supabase response: $response');
      return response['id'] as String;
    } catch (e) {
      debugPrint('❌ [SupabaseChildService] createEnrollment Error: $e');
      if (e is PostgrestException) {
        debugPrint('   - Code: ${e.code}');
        debugPrint('   - Message: ${e.message}');
        debugPrint('   - Details: ${e.details}');
        debugPrint('   - Hint: ${e.hint}');
      }
      rethrow;
    }
  }

  Future<void> updateEnrollment(String enrollmentId, Map<String, dynamic> updates) async {
    await adminClient.from('enrollments').update(updates).eq('id', enrollmentId);
  }

  Future<List<SessionSchedule>> getSchedulesForParent(String parentId) async {
    // 1. Récupérer les inscriptions pour identifier les cours concernés
    final enrollmentsResponse = await adminClient
        .from('enrollments')
        .select('course_id')
        .eq('parent_id', parentId)
        .or('status.eq.approved,status.eq.pending');
        
    final courseIds = (enrollmentsResponse as List).map((e) => e['course_id'] as String).toList();
    if (courseIds.isEmpty) return [];
    
    // 2. Récupérer les sessions explicites (table session_schedules)
    final schedulesResponse = await adminClient
        .from('session_schedules')
        .select('*, courses(*)')
        .inFilter('course_id', courseIds);

    final List<SessionSchedule> sessions = (schedulesResponse as List)
        .map((data) => SessionSchedule.fromSupabase(data))
        .toList();

    // 3. Récupérer les cours qui ont un planning intégré (champs day_of_week, start_time, etc.)
    final coursesWithPlanningResponse = await adminClient
        .from('courses')
        .select()
        .inFilter('id', courseIds)
        .not('day_of_week', 'is', null)
        .not('start_time', 'is', null)
        .not('end_time', 'is', null)
        .eq('is_active', true);

    final courseData = coursesWithPlanningResponse as List;
    
    for (var c in courseData) {
      final courseId = c['id'] as String;
      final rawDay = c['day_of_week'] as int;
      final dayIndex = rawDay - 1; // 1-7 -> 0-6
      
      if (dayIndex < 0 || dayIndex > 6) continue;

      final startTimeStr = c['start_time'] as String;
      final endTimeStr = c['end_time'] as String;
      final parsedStart = TimeSlot.parseTime(startTimeStr);
      
      // Éviter les doublons si une session explicite existe déjà pour ce créneau
      final exists = sessions.any((s) => 
        s.courseId == courseId && 
        s.dayOfWeek.index == dayIndex && 
        s.timeSlot.start.hour == parsedStart.hour &&
        s.timeSlot.start.minute == parsedStart.minute
      );

      if (!exists) {
        sessions.add(SessionSchedule(
          id: 'course-$courseId',
          courseId: courseId,
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
          courseCategory: c['category'],
        ));
      }
    }

    return sessions;
  }

  Future<List<DailyActivity>> getDailyActivities(String parentId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final childrenResponse = await adminClient.from('children').select('id').eq('parent_id', parentId).eq('is_active', true);
    final childIds = (childrenResponse as List).map((e) => e['id'] as String).toList();
    if (childIds.isEmpty) return [];
    final activitiesResponse = await adminClient.from('daily_activities').select().inFilter('child_id', childIds).eq('date', dateStr);
    return (activitiesResponse as List).map((data) => DailyActivity.fromSupabase(data)).toList();
  }
}

extension SupabaseChildServiceSchedules on SupabaseChildService {
  Stream<List<SessionSchedule>> getSchedulesByOwnerStream(String ownerId) {
    // Note: session_schedules doesn't have a direct owner_id filter in the stream
    // ideally, we should filter by school_id or coach_id if possible
    return adminClient
        .from('session_schedules')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => SessionSchedule.fromSupabase(json)).toList());
  }

  Future<List<SessionSchedule>> getSchedulesByOwner(String ownerId) async {
    final coursesResponse = await adminClient.from('courses').select('id').eq('created_by', ownerId);
    final courseIds = (coursesResponse as List).map((c) => c['id'] as String).toList();
    if (courseIds.isEmpty) return [];
    final response = await adminClient.from('session_schedules').select().inFilter('course_id', courseIds);
    return (response as List).map((data) => SessionSchedule.fromSupabase(data)).toList();
  }

  Future<String> createSchedule(SessionSchedule schedule) async {
    final data = schedule.toSupabase();
    data.remove('id');
    final response = await adminClient.from('session_schedules').insert(data).select().single();
    return response['id'] as String;
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> updates) async {
    await adminClient.from('session_schedules').update(updates).eq('id', scheduleId);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await adminClient.from('session_schedules').delete().eq('id', scheduleId);
  }
}
