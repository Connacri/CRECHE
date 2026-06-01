import 'dart:math' show sqrt, asin, pi, sin, cos;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/daily_activity_model.dart';
import '../models/session_schedule_model.dart';

/// Service dédié pour les opérations CRUD des cours dans Supabase
class SupabaseCourseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tableName = 'courses';
  static const int _defaultLimit = 20;

  Future<List<CourseModel>> getCourses({
    int limit = _defaultLimit,
    DateTime? lastDocumentTimestamp,
    CourseSeason? season,
    CourseCategory? category,
    bool? isActive,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase.from(_tableName).select();
      if (season != null) query = query.eq('season', season.name);
      if (category != null) query = query.eq('category', category.name);
      if (isActive != null) query = query.eq('is_active', isActive);
      if (lastDocumentTimestamp != null) {
        query = query.lt('created_at', lastDocumentTimestamp.toIso8601String());
      }
      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur getCourses: $e');
    }
  }

  Future<String> createCourse(CourseModel course) async {
    try {
      final data = course.toSupabase();
      data.remove('id');
      final response = await _supabase.from(_tableName).insert(data).select('id').single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Erreur createCourse: $e');
    }
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      updates.remove('created_at');
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from(_tableName).update(updates).eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur updateCourse: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur deleteCourse: $e');
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final response = await _supabase.from(_tableName).select().eq('id', courseId).maybeSingle();
      if (response == null) return null;
      return CourseModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Erreur getCourse: $e');
    }
  }

  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur searchCourses: $e');
    }
  }

  Future<List<CourseModel>> getUserCourses(String userId) async {
    try {
      final response = await _supabase
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
      final response = await _supabase
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
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

class SupabaseChildService {
  final _supabase = Supabase.instance.client;

  // === GESTION DES ENFANTS ===
  Future<List<ChildModel>> getChildren(String parentId) async {
    final response = await _supabase.from('children').select().eq('parent_id', parentId).eq('is_active', true);
    return response.map((data) => ChildModel.fromSupabase(data)).toList();
  }

  Future<String> createChild(ChildModel child) async {
    final response = await _supabase.from('children').insert(child.toSupabase()).select().single();
    return response['id'] as String;
  }

  Future<void> updateChild(String childId, Map<String, dynamic> updates) async {
    await _supabase.from('children').update(updates).eq('id', childId);
  }

  Future<void> softDeleteChild(String childId) async {
    await _supabase.from('children').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', childId);
  }

  // === GESTION DES INSCRIPTIONS ===
  Future<List<EnrollmentModel>> getEnrollments(String parentId) async {
    final response = await _supabase.from('enrollments').select().eq('parent_id', parentId);
    return response.map((data) => EnrollmentModel.fromSupabase(data)).toList();
  }

  Future<String> createEnrollment(EnrollmentModel enrollment) async {
    final response = await _supabase.from('enrollments').insert(enrollment.toSupabase()).select().single();
    return response['id'] as String;
  }

  Future<void> updateEnrollment(String enrollmentId, Map<String, dynamic> updates) async {
    await _supabase.from('enrollments').update(updates).eq('id', enrollmentId);
  }

  // === GESTION DES HORAIRES (SCHEDULES) ===
  Future<List<SessionSchedule>> getSchedulesForParent(String parentId) async {
    final enrollmentsResponse = await _supabase.from('enrollments').select('course_id').eq('parent_id', parentId).eq('status', 'approved');
    final courseIds = (enrollmentsResponse as List).map((e) => e['course_id'] as String).toList();
    if (courseIds.isEmpty) return [];
    final schedulesResponse = await _supabase.from('session_schedules').select().inFilter('course_id', courseIds);
    return (schedulesResponse as List).map((data) => SessionSchedule.fromSupabase(data)).toList();
  }

  // === GESTION DES ACTIVITÉS QUOTIDIENNES ===
  Future<List<DailyActivity>> getDailyActivities(String parentId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final childrenResponse = await _supabase.from('children').select('id').eq('parent_id', parentId).eq('is_active', true);
    final childIds = (childrenResponse as List).map((e) => e['id'] as String).toList();
    if (childIds.isEmpty) return [];
    final activitiesResponse = await _supabase.from('daily_activities').select().inFilter('child_id', childIds).eq('date', dateStr);
    return (activitiesResponse as List).map((data) => DailyActivity.fromSupabase(data)).toList();
  }
}
