enum ActivityType {
  meal,
  activity,
  task,
  nap,
  other;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityType.other,
    );
  }
}

class DailyActivity {
  final String id;
  final String childId;
  final DateTime date;
  final ActivityType type;
  final String title;
  final String? description;
  final String status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  DailyActivity({
    required this.id,
    required this.childId,
    required this.date,
    required this.type,
    required this.title,
    this.description,
    this.status = 'pending',
    this.metadata,
    required this.createdAt,
  });

  factory DailyActivity.fromSupabase(Map<String, dynamic> data) {
    return DailyActivity(
      id: data['id'],
      childId: data['child_id'],
      date: DateTime.parse(data['date']),
      type: ActivityType.fromString(data['type']),
      title: data['title'],
      description: data['description'],
      status: data['status'] ?? 'pending',
      metadata: data['metadata'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'child_id': childId,
      'date': date.toIso8601String().split('T')[0],
      'type': type.name,
      'title': title,
      'description': description,
      'status': status,
      'metadata': metadata,
    };
  }
}
