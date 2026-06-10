import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class EventService extends AdminSupabaseService {
  Stream<List<Map<String, dynamic>>> getClubEventsStream(String clubId) {
    return adminClient
        .from('events')
        .stream(primaryKey: ['id'])
        .order('start_date', ascending: false)
        .handleError((error) {
          debugPrint('❌ [EventService] Error in getClubEventsStream: $error');
          return <Map<String, dynamic>>[];
        })
        .map((data) => data.where((e) => e['club_id'] == clubId || e['created_by'] == clubId).toList());
  }

  Future<List<Map<String, dynamic>>> getClubEvents(String clubId) async {
    final response = await adminClient
        .from('events')
        .select('*')
        .or('club_id.eq.$clubId,created_by.eq.$clubId')
        .order('start_date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getEvent(String eventId) async {
    final response = await adminClient
        .from('events')
        .select('*')
        .eq('id', eventId)
        .single();
    return response;
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    await adminClient.from('events').insert(eventData);
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await adminClient
        .from('events')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await adminClient.from('events').delete().eq('id', eventId);
  }

  Future<List<Map<String, dynamic>>> getEventRegistrations(String eventId) async {
    final response = await adminClient
        .from('event_registrations')
        .select('*, registrant:users!registrant_id(name, email, profile_images)')
        .eq('event_id', eventId)
        .order('registered_at');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> registerForEvent({
    required String eventId,
    required String registrantId,
    String? childId,
  }) async {
    await adminClient.from('event_registrations').insert({
      'event_id': eventId,
      'registrant_id': registrantId,
      'child_id': childId,
      'status': 'pending',
    });
  }

  Future<void> updateRegistrationStatus(String registrationId, String status) async {
    await adminClient
        .from('event_registrations')
        .update({
          'status': status,
          if (status == 'confirmed') 'confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', registrationId);
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents(String clubId, {int limit = 10}) async {
    final response = await adminClient
        .from('events')
        .select('*')
        .or('club_id.eq.$clubId,created_by.eq.$clubId')
        .gte('start_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: true)
        .limit(limit);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getEventStats(String clubId) async {
    final response = await adminClient.rpc('get_club_financial_summary', params: {
      'p_club_id': clubId,
    });
    return response as Map<String, dynamic>? ?? {};
  }
}
