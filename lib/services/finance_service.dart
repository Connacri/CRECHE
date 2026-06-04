import 'supabase_service.dart';

class FinanceService extends AdminSupabaseService {
  /// Récupère le résumé financier pour un club et une année donnés
  Future<Map<String, dynamic>> getFinancialSummary(String clubId, int year) async {
    try {
      final response = await adminClient.rpc('get_club_financial_summary', params: {
        'p_club_id': clubId,
        'p_year': year,
      });
      return response ?? {};
    } catch (e) {
      throw Exception('Erreur getFinancialSummary: $e');
    }
  }

  /// Récupère les factures récentes pour un club
  Future<List<Map<String, dynamic>>> getRecentInvoices(String clubId, {int limit = 20}) async {
    try {
      final response = await adminClient
          .from('invoices')
          .select('*, member:members!member_id(user_id, membership_number)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur getRecentInvoices: $e');
    }
  }

  /// Récupère les dépenses récentes pour un club
  Future<List<Map<String, dynamic>>> getClubExpenses(String clubId, {int limit = 20}) async {
    try {
      final response = await adminClient
          .from('club_expenses')
          .select('*')
          .eq('club_id', clubId)
          .order('date', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur getClubExpenses: $e');
    }
  }
}
