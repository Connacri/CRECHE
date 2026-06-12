class ShipmentModel {
  final String id;
  final String trackingNumber;
  final String? senderId;
  final String? receiverId;
  final String? transporteurId;
  final String status;
  final String? originAddress;
  final String? destinationAddress;
  final Map<String, dynamic>? currentLocation;
  final double? weight;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShipmentModel({
    required this.id,
    required this.trackingNumber,
    this.senderId,
    this.receiverId,
    this.transporteurId,
    this.status = 'pending',
    this.originAddress,
    this.destinationAddress,
    this.currentLocation,
    this.weight,
    this.estimatedDelivery,
    this.actualDelivery,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShipmentModel.fromSupabase(Map<String, dynamic> data) {
    return ShipmentModel(
      id: data['id'],
      trackingNumber: data['tracking_number'],
      senderId: data['sender_id'],
      receiverId: data['receiver_id'],
      transporteurId: data['transporteur_id'],
      status: data['status'] ?? 'pending',
      originAddress: data['origin_address'],
      destinationAddress: data['destination_address'],
      currentLocation: data['current_location'],
      weight: data['weight']?.toDouble(),
      estimatedDelivery: data['estimated_delivery'] != null 
          ? DateTime.parse(data['estimated_delivery']) : null,
      actualDelivery: data['actual_delivery'] != null 
          ? DateTime.parse(data['actual_delivery']) : null,
      metadata: data['metadata'] ?? {},
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'tracking_number': trackingNumber,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'transporteur_id': transporteurId,
      'status': status,
      'origin_address': originAddress,
      'destination_address': destinationAddress,
      'current_location': currentLocation,
      'weight': weight,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'actual_delivery': actualDelivery?.toIso8601String(),
      'metadata': metadata,
    };
  }
}
