import 'session_schedule_model.dart';

class SchoolSlotModel {
  final String id;
  final String schoolId;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final bool isOccupied;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolSlotModel({
    required this.id,
    required this.schoolId,
    required this.dayOfWeek,
    required this.timeSlot,
    this.isOccupied = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolSlotModel.fromSupabase(Map<String, dynamic> data) {
    return SchoolSlotModel(
      id: data['id'] ?? '',
      schoolId: data['school_id'] ?? '',
      dayOfWeek: DayOfWeek.values[data['day_of_week'] ?? 0],
      timeSlot: TimeSlot.fromMap(data['time_slot'] ?? {}),
      isOccupied: data['is_occupied'] ?? false,
      metadata: data['metadata'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'school_id': schoolId,
      'day_of_week': dayOfWeek.index,
      'time_slot': timeSlot.toMap(),
      'is_occupied': isOccupied,
      'metadata': metadata,
    };
  }

  SchoolSlotModel copyWith({
    String? id,
    String? schoolId,
    DayOfWeek? dayOfWeek,
    TimeSlot? timeSlot,
    bool? isOccupied,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolSlotModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      isOccupied: isOccupied ?? this.isOccupied,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
