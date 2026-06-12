import 'supabase_service.dart';
import '../models/shipment_model.dart';

class ShipmentService extends AdminSupabaseService {
  static const String _tableName = 'shipments';

  Stream<List<ShipmentModel>> getShipmentsStream({String? transporteurId, String? senderId, String? receiverId}) {
    var query = adminClient.from(_tableName).stream(primaryKey: ['id']);
    
    if (transporteurId != null) {
      return query.eq('transporteur_id', transporteurId)
          .map((data) => data.map((json) => ShipmentModel.fromSupabase(json)).toList());
    } else if (senderId != null) {
      return query.eq('sender_id', senderId)
          .map((data) => data.map((json) => ShipmentModel.fromSupabase(json)).toList());
    } else if (receiverId != null) {
      return query.eq('receiver_id', receiverId)
          .map((data) => data.map((json) => ShipmentModel.fromSupabase(json)).toList());
    }

    return query.map((data) => data.map((json) => ShipmentModel.fromSupabase(json)).toList());
  }

  Future<void> updateShipmentStatus(String id, String status, {Map<String, dynamic>? currentLocation}) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (currentLocation != null) {
      updates['current_location'] = currentLocation;
    }
    await adminClient.from(_tableName).update(updates).eq('id', id);
  }
}
