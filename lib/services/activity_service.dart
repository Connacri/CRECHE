import 'supabase_service.dart';

class ActivityService extends AdminSupabaseService {
  Future<List<Map<String, dynamic>>> getRecentActivities(String clubId) async {
    try {
      // Fetching from multiple tables to aggregate activity
      final results = await Future.wait([
        _getMemberActivities(clubId),
        _getCoachActivities(clubId),
        _getEventActivities(clubId),
        _getFinanceActivities(clubId),
      ]);

      // Flatten and sort by date descending
      final allActivities = results.expand((x) => x).toList();
      allActivities.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return allActivities.take(50).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getMemberActivities(String clubId) async {
    final res = await adminClient
        .from('members')
        .select('*, user:users!user_id(name)')
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .limit(10);
    
    return (res as List).map((m) => {
      'type': 'member',
      'title': 'Nouvel adhérent',
      'subtitle': '${m['user']['name']} a rejoint le club',
      'date': m['created_at'],
      'icon': 'people',
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getCoachActivities(String clubId) async {
    // Coaches are linked to courses created by the club
    final coursesRes = await adminClient.from('courses').select('id').eq('created_by', clubId);
    final courseIds = (coursesRes as List).map((c) => c['id'] as String).toList();
    
    if (courseIds.isEmpty) return [];

    final res = await adminClient
        .from('coaching_history')
        .select('*, coach:users!coach_id(name), course:courses(title)')
        .inFilter('course_id', courseIds)
        .order('assigned_at', ascending: false)
        .limit(10);

    return (res as List).map((c) => {
      'type': 'coach',
      'title': 'Coach assigné',
      'subtitle': '${c['coach']['name']} assigné à ${c['course']['title']}',
      'date': c['assigned_at'],
      'icon': 'people_outline',
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getEventActivities(String clubId) async {
    final res = await adminClient
        .from('events')
        .select('*')
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .limit(10);

    return (res as List).map((e) => {
      'type': 'event',
      'title': 'Nouvel événement',
      'subtitle': 'Événement "${e['title']}" créé',
      'date': e['created_at'],
      'icon': 'event',
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getFinanceActivities(String clubId) async {
    final invoicesRes = await adminClient
        .from('invoices')
        .select('*')
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .limit(5);

    final expensesRes = await adminClient
        .from('club_expenses')
        .select('*')
        .eq('club_id', clubId)
        .order('date', ascending: false)
        .limit(5);

    final activities = <Map<String, dynamic>>[];

    activities.addAll((invoicesRes as List).map((i) => {
      'type': 'finance',
      'title': 'Facture générée',
      'subtitle': 'Facture ${i['invoice_number']} de ${i['total_amount']} DA',
      'date': i['created_at'],
      'icon': 'account_balance',
    }));

    activities.addAll((expensesRes as List).map((e) => {
      'type': 'finance',
      'title': 'Dépense enregistrée',
      'subtitle': '${e['description']} : ${e['amount']} DA',
      'date': e['date'],
      'icon': 'account_balance',
    }));

    return activities;
  }
}
