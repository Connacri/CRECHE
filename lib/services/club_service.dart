import 'supabase_service.dart';
import '../models/user_model.dart';

class ClubService extends AdminSupabaseService {
  /// Récupère les cours créés par le club
  Future<List<Map<String, dynamic>>> getClubCourses(String clubId) async {
    final response = await adminClient
        .from('courses')
        .select('id, title')
        .eq('created_by', clubId)
        .eq('is_active', true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Récupère l'historique du coaching pour un club
  Future<List<Map<String, dynamic>>> getClubCoachingHistory(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    final response = await adminClient
        .from('coaching_history')
        .select('*, course:courses(title)')
        .inFilter('course_id', courseIds)
        .eq('is_active', true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Récupère les détails des coachs par leurs IDs
  Future<List<Map<String, dynamic>>> getCoachesDetails(List<String> coachIds) async {
    if (coachIds.isEmpty) return [];
    final response = await adminClient
        .from('users')
        .select('id, name, email, role, profile_images, phone_number')
        .inFilter('id', coachIds);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Assigne un coach à un cours
  Future<void> assignCoachToCourse({
    required String courseId,
    required String coachId,
    required String role,
  }) async {
    await adminClient.from('coaching_history').insert({
      'course_id': courseId,
      'coach_id': coachId,
      'role': role,
    });
  }

  /// Retire un coach d'un cours (désactivation)
  Future<void> removeCoachFromCourse(String coachId, String courseId) async {
    await adminClient
        .from('coaching_history')
        .update({
          'is_active': false, 
          'unassigned_at': DateTime.now().toIso8601String()
        })
        .match({'coach_id': coachId, 'course_id': courseId, 'is_active': true});
  }

  /// Recherche des coachs par nom ou email
  Future<List<Map<String, dynamic>>> searchCoaches(String query) async {
    final response = await adminClient
        .from('users')
        .select('id, name, email, role, profile_images, phone_number')
        .or('name.ilike.%${query}%,email.ilike.%${query}%')
        .eq('role', 'coach')
        .limit(20);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Recherche des utilisateurs (parents/coachs) pour ajout comme membres
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await adminClient
        .from('users')
        .select('id, name, email, profile_images')
        .or('name.ilike.%${query}%,email.ilike.%${query}%')
        .limit(20);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Ajoute un membre au club
  Future<void> addMember({required String clubId, required String userId, String type = 'standard'}) async {
    await adminClient.from('members').insert({
      'club_id': clubId,
      'user_id': userId,
      'membership_type': type,
      'status': 'active',
      'start_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  /// Récupère les membres d'un club
  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    final response = await adminClient
        .from('members')
        .select('*, user:users!user_id(name, email, profile_images, phone_number)')
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Met à jour le statut d'un membre
  Future<void> updateMemberStatus(String memberId, String status) async {
    await adminClient
        .from('members')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', memberId);
  }

  /// Supprime un membre (ou le désactive)
  Future<void> removeMember(String memberId) async {
    await adminClient.from('members').delete().eq('id', memberId);
  }

  /// Récupère tous les clubs disponibles
  /// Alias pour getAvailableClubs
  Future<List<Map<String, dynamic>>> getSchools() async {
    final response = await adminClient.from("users").select("id, name").eq("role", "school");
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<UserModel>> getAvailableClubs() async {
    final response = await adminClient
        .from('users')
        .select()
        .eq('role', 'school')
        .eq('is_active', true);
    return (response as List).map((json) => UserModel.fromSupabase(json)).toList();
  }
}
