import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/school_slot_model.dart';
import '../models/session_schedule_model.dart';
import 'supabase_service.dart';

class SupabaseSchoolService extends AdminSupabaseService {
  Stream<List<SchoolSlotModel>> getSchoolSlotsStream(String schoolId) {
    return adminClient
        .from('school_available_slots')
        .stream(primaryKey: ['id'])
        .eq('school_id', schoolId)
        .order('day_of_week', ascending: true)
        .handleError((error) {
          debugPrint('❌ [SupabaseSchoolService] Error in getSchoolSlotsStream: $error');
          return <Map<String, dynamic>>[];
        })
        .map((data) => data.map((json) => SchoolSlotModel.fromSupabase(json)).toList());
  }

  Future<List<UserModel>> getSchools() async {
    try {
      final response = await adminClient.rpc('get_schools');
      return (response as List<dynamic>)
          .map((json) => UserModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur getSchools: $e');
    }
  }

  Future<List<SchoolSlotModel>> getAvailableSlots(String schoolId) async {
    try {
      final response = await adminClient
          .from('school_available_slots')
          .select()
          .eq('school_id', schoolId)
          .eq('is_occupied', false)
          .order('day_of_week', ascending: true);

      return (response as List<dynamic>)
          .map((json) => SchoolSlotModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur getAvailableSlots: $e');
    }
  }

  Future<List<SchoolSlotModel>> getAllSchoolSlots(String schoolId) async {
    try {
      final response = await adminClient
          .from('school_available_slots')
          .select()
          .eq('school_id', schoolId)
          .order('day_of_week', ascending: true);

      return (response as List<dynamic>)
          .map((json) => SchoolSlotModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur getAllSchoolSlots: $e');
    }
  }

  Future<void> createSlot(SchoolSlotModel slot) async {
    try {
      await adminClient.from('school_available_slots').insert(slot.toSupabase());
    } catch (e) {
      throw Exception('Erreur createSlot: $e');
    }
  }

  Future<void> updateSlot(String slotId, Map<String, dynamic> updates) async {
    try {
      await adminClient.from('school_available_slots').update(updates).eq('id', slotId);
    } catch (e) {
      throw Exception('Erreur updateSlot: $e');
    }
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await adminClient.from('school_available_slots').delete().eq('id', slotId);
    } catch (e) {
      throw Exception('Erreur deleteSlot: $e');
    }
  }

  Future<void> createSessionSchedule(SessionSchedule schedule) async {
    try {
      await adminClient.from('session_schedules').insert(schedule.toSupabase());
    } catch (e) {
      throw Exception('Erreur createSessionSchedule: $e');
    }
  }
}
