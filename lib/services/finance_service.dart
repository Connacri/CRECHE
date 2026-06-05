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

  Future<void> createExpense(Map<String, dynamic> data) async {
    try {
      await adminClient.from('club_expenses').insert(data);
    } catch (e) {
      throw Exception('Erreur createExpense: $e');
    }
  }

  Future<void> createInvoice(Map<String, dynamic> data) async {
    try {
      await adminClient.from('invoices').insert(data);
    } catch (e) {
      throw Exception('Erreur createInvoice: $e');
    }
  }

  Future<void> recordPayment(Map<String, dynamic> data) async {
    try {
      await adminClient.from('payments').insert(data);
    } catch (e) {
      throw Exception('Erreur recordPayment: $e');
    }
  }

  // ── INVENTORY METHODS ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getInventoryItems(String clubId) async {
    final response = await adminClient
        .from('inventory_items')
        .select('*')
        .eq('club_id', clubId)
        .order('name');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> createInventoryItem(Map<String, dynamic> data) async {
    await adminClient.from('inventory_items').insert(data);
  }

  Future<void> updateInventoryStock(String itemId, String clubId, int quantity, String type, {String? notes}) async {
    await adminClient.from('inventory_transactions').insert({
      'item_id': itemId,
      'club_id': clubId,
      'transaction_type': type,
      'quantity': quantity,
      'notes': notes,
      'created_by': clubId, // Use clubId as default creator for admin ops
    });
  }

  // ── SUBSCRIPTION METHODS ────────────────────────────────────────

  Future<Map<String, dynamic>> getSubscriptionStatus(String clubId) async {
    final response = await adminClient.rpc('get_club_subscription_status', params: {
      'p_club_id': clubId,
    });
    if (response is List && response.isNotEmpty) return response[0];
    return {};
  }
}
