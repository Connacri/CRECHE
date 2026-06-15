import 'package:flutter/material.dart';

enum CourseCategory {
  mathematics, sciences, languages, technology, computerScience, arts, music, sports,
  business, accounting, marketing, entrepreneurship, health, cooking, crafts,
  personalDevelopment, religion, tutoring, examPreparation, professionalTraining, other;

  String get displayName { /* ... votre implémentation existante ... */ }
}

enum CourseSeason {
  spring, summer, fall, winter, schoolYear, firstSemester, secondSemester,
  holidayProgram, yearRound, custom;

  String get displayName { /* ... votre implémentation existante ... */ }
  Map<String, DateTime>? getDefaultDateRange() { /* ... votre implémentation existante ... */ }
}

enum CoursePricingType {
  hourly, session, daily, weekly, biweekly, monthly, quarterly, semester,
  yearly, season, module, package, event, participant, group, custom;

  String get displayName { /* ... votre implémentation existante ... */ }
}

enum CourseLevel { beginner, intermediate, advanced, expert; }
enum CourseStatus { draft, scheduled, active, completed, cancelled; }

class CourseLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  CourseLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  factory CourseLocation.fromMap(Map<String, dynamic> map) {
    return CourseLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      city: map['city'],
      country: map['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }
}

class CourseImage {
  final String id;
  final String? supabaseUrl;
  final String localPath;
  final bool isSynced;
  final DateTime uploadedAt;

  CourseImage({
    required this.id,
    this.supabaseUrl,
    required this.localPath,
    required this.isSynced,
    required this.uploadedAt,
  });

  factory CourseImage.fromMap(Map<String, dynamic> map) {
    return CourseImage(
      id: map['id'] ?? '',
      supabaseUrl: map['supabaseUrl'] ?? map['supabase_url'],
      localPath: map['localPath'] ?? map['local_path'] ?? '',
      isSynced: map['isSynced'] ?? map['is_synced'] ?? false,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'].toString())
          : (map['uploaded_at'] != null
              ? DateTime.parse(map['uploaded_at'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supabase_url': supabaseUrl,
      'local_path': localPath,
      'is_synced': isSynced,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  CourseImage copyWith({
    String? id,
    String? supabaseUrl,
    String? localPath,
    bool? isSynced,
    DateTime? uploadedAt,
  }) {
    return CourseImage(
      id: id ?? this.id,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      localPath: localPath ?? this.localPath,
      isSynced: isSynced ?? this.isSynced,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final CourseCategory category;
  final double? price;
  final CourseSeason season;
  final DateTime seasonStartDate;
  final DateTime seasonEndDate;
  final CourseLocation location;
  final List<CourseImage> images;
  final String createdBy;
  final String? clubId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int maxStudents;
  final int currentStudents;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final int? minAge;
  final int? maxAge;
  final CoursePricingType pricingType;

  // === CHAMPS PLANNING HEBDOMADAIRE ===
  final int? dayOfWeek;        // 1 = Lundi → 7 = Dimanche
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? roomId;        // Correspond à room_name dans session_schedules
  final String? coachId;
  final Map<String, dynamic> recurrence;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    required this.season,
    required this.seasonStartDate,
    required this.seasonEndDate,
    required this.location,
    required this.images,
    required this.createdBy,
    this.clubId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.maxStudents = 30,
    this.currentStudents = 0,
    this.tags = const [],
    this.metadata,
    this.minAge,
    this.maxAge,
    this.pricingType = CoursePricingType.session,
    // Planning
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.roomId,
    this.coachId,
    this.recurrence = const {'freq': 'weekly', 'exceptions': []},
  });

  factory CourseModel.fromSupabase(Map<String, dynamic> data) {
    return CourseModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: CourseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => CourseCategory.other,
      ),
      price: data['price']?.toDouble(),
      season: CourseSeason.values.firstWhere(
        (e) => e.name == data['season'],
        orElse: () => CourseSeason.yearRound,
      ),
      seasonStartDate: DateTime.parse(data['season_start_date']),
      seasonEndDate: DateTime.parse(data['season_end_date']),
      location: CourseLocation.fromMap(data['location'] ?? {}),
      images: (data['images'] as List<dynamic>?)
              ?.map((img) => CourseImage.fromMap(img))
              .toList() ??
          [],
      createdBy: data['created_by'] ?? '',
      clubId: data['club_id'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      isActive: data['is_active'] ?? true,
      maxStudents: data['max_students'] ?? 30,
      currentStudents: data['current_students'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
      minAge: data['min_age'],
      maxAge: data['max_age'],
      pricingType: CoursePricingType.values.firstWhere(
        (e) => e.name == data['pricing_type'],
        orElse: () => CoursePricingType.session,
      ),
      // Planning fields
      dayOfWeek: data['day_of_week'],
      startTime: _parseTime(data['start_time']),
      endTime: _parseTime(data['end_time']),
      roomId: data['room_id'] ?? data['room_name'],
      coachId: data['coach_id'],
      recurrence: data['recurrence'] ?? {'freq': 'weekly', 'exceptions': []},
    );
  }

  static TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parts = value.split(':').map(int.parse).toList();
      return TimeOfDay(hour: parts[0], minute: parts.length > 1 ? parts[1] : 0);
    }
    return null;
  }

  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'price': price,
      'season': season.name,
      'season_start_date': seasonStartDate.toIso8601String(),
      'season_end_date': seasonEndDate.toIso8601String(),
      'location': location.toMap(),
      'images': images.map((img) => img.toMap()).toList(),
      'created_by': createdBy,
      'club_id': clubId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'tags': tags,
      'metadata': metadata,
      'min_age': minAge,
      'max_age': maxAge,
      'pricing_type': pricingType.name,
      // Planning fields
      'day_of_week': dayOfWeek,
      'start_time': startTime != null ? '\( {startTime!.hour}: \){startTime!.minute.toString().padLeft(2, '0')}' : null,
      'end_time': endTime != null ? '\( {endTime!.hour}: \){endTime!.minute.toString().padLeft(2, '0')}' : null,
      'room_id': roomId,
      'coach_id': coachId,
      'recurrence': recurrence,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    CourseCategory? category,
    double? price,
    CourseSeason? season,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    CourseLocation? location,
    List<CourseImage>? images,
    String? createdBy,
    String? clubId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? maxStudents,
    int? currentStudents,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? minAge,
    int? maxAge,
    CoursePricingType? pricingType,
    // Planning
    int? dayOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? roomId,
    String? coachId,
    Map<String, dynamic>? recurrence,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      season: season ?? this.season,
      seasonStartDate: seasonStartDate ?? this.seasonStartDate,
      seasonEndDate: seasonEndDate ?? this.seasonEndDate,
      location: location ?? this.location,
      images: images ?? this.images,
      createdBy: createdBy ?? this.createdBy,
      clubId: clubId ?? this.clubId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      pricingType: pricingType ?? this.pricingType,
      // Planning
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomId: roomId ?? this.roomId,
      coachId: coachId ?? this.coachId,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  factory CourseModel.mock() {
    return CourseModel(
      id: 'mock-id',
      title: 'Cours non trouvé',
      description: 'Ce cours n\'a pas pu être chargé.',
      category: CourseCategory.other,
      price: 0.0,
      season: CourseSeason.yearRound,
      seasonStartDate: DateTime.now().subtract(const Duration(days: 365)),
      seasonEndDate: DateTime.now().add(const Duration(days: 365)),
      location: CourseLocation(latitude: 0.0, longitude: 0.0, address: 'N/A'),
      images: [],
      createdBy: 'system',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool hasAvailableSpots() => currentStudents < maxStudents;
  int get availableSpots => maxStudents - currentStudents;

  bool get isAvailableNow {
    final now = DateTime.now();
    return isActive && hasAvailableSpots() &&
        now.isAfter(seasonStartDate) && now.isBefore(seasonEndDate);
  }

  // === MÉTHODES PLANNING ===
  bool get hasWeeklySchedule => dayOfWeek != null && startTime != null && endTime != null;

  bool overlapsWith(CourseModel other) {
    if (!hasWeeklySchedule || !other.hasWeeklySchedule) return false;
    if (dayOfWeek != other.dayOfWeek) return false;
    if ((coachId != null && coachId == other.coachId) || 
        (roomId != null && roomId == other.roomId)) {
      final s1 = startTime!.hour * 60 + startTime!.minute;
      final e1 = endTime!.hour * 60 + endTime!.minute;
      final s2 = other.startTime!.hour * 60 + other.startTime!.minute;
      final e2 = other.endTime!.hour * 60 + other.endTime!.minute;
      return s1 < e2 && s2 < e1;
    }
    return false;
  }
}