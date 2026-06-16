import 'package:flutter/material.dart';

/// Modèle pour représenter une session de cours planifiée
class SessionSchedule {
  final String id;
  final String courseId;
  final String? enrollmentId;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCancelled;
  final String? cancellationReason;
  final int currentEnrollment;
  final int maxCapacity;
  final String? location;
  final String? coachId;
  final String? roomName;
  final String? schoolId;
  final bool isActive;
  final String? courseTitle; // Nouveau champ pour le titre du cours
  final Map<String, dynamic>? recurrence;
  final Map<String, dynamic>? metadata;

  SessionSchedule({
    required this.id,
    required this.courseId,
    this.enrollmentId,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.startDate,
    required this.endDate,
    this.isCancelled = false,
    this.cancellationReason,
    required this.currentEnrollment,
    required this.maxCapacity,
    this.location,
    this.coachId,
    this.roomName,
    this.schoolId,
    this.isActive = true,
    this.courseTitle,
    this.recurrence,
    this.metadata,
  });

  /// Vérifie si la session est planifiée pour une date donnée
  bool isScheduledFor(DateTime date) {
    if (isCancelled) return false;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (normalizedDate.isBefore(normalizedStart) || normalizedDate.isAfter(normalizedEnd)) {
      return false;
    }

    return date.weekday == dayOfWeek.index + 1;
  }

  /// Désérialisation depuis Supabase
  factory SessionSchedule.fromSupabase(Map<String, dynamic> data) {
    // Gestion du join avec courses pour le titre
    String? title;
    if (data['courses'] != null) {
      title = data['courses']['title'];
    } else if (data['course_title'] != null) {
      title = data['course_title'];
    }

    return SessionSchedule(
      id: data['id'] ?? '',
      courseId: data['course_id'] ?? '',
      enrollmentId: data['enrollment_id'],
      dayOfWeek: DayOfWeek.values[data['day_of_week'] ?? 0],
      timeSlot: TimeSlot.fromMap(data['time_slot'] ?? {}),
      startDate: DateTime.parse(data['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(data['end_date'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String()),
      isCancelled: data['is_cancelled'] ?? false,
      cancellationReason: data['cancellation_reason'],
      currentEnrollment: data['current_enrollment'] ?? 0,
      maxCapacity: data['max_capacity'] ?? 30,
      location: data['location'],
      coachId: data['coach_id'],
      roomName: data['room_name'],
      schoolId: data['school_id'],
      isActive: data['is_active'] ?? true,
      courseTitle: title,
      recurrence: data['recurrence'],
      metadata: data['metadata'],
    );
  }

  /// Sérialisation vers Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'course_id': courseId,
      'enrollment_id': enrollmentId,
      'day_of_week': dayOfWeek.index,
      'time_slot': timeSlot.toMap(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_cancelled': isCancelled,
      'cancellation_reason': cancellationReason,
      'current_enrollment': currentEnrollment,
      'max_capacity': maxCapacity,
      'location': location,
      'coach_id': coachId,
      'room_name': roomName,
      'school_id': schoolId,
      'is_active': isActive,
      'recurrence': recurrence ?? {'freq': 'weekly', 'exceptions': []},
      'metadata': metadata,
    };
  }

  SessionSchedule copyWith({
    String? id,
    String? courseId,
    String? enrollmentId,
    DayOfWeek? dayOfWeek,
    TimeSlot? timeSlot,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCancelled,
    String? cancellationReason,
    int? currentEnrollment,
    int? maxCapacity,
    String? location,
    String? coachId,
    String? roomName,
    String? schoolId,
    bool? isActive,
    Map<String, dynamic>? recurrence,
    Map<String, dynamic>? metadata,
  }) {
    return SessionSchedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCancelled: isCancelled ?? this.isCancelled,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      location: location ?? this.location,
      coachId: coachId ?? this.coachId,
      roomName: roomName ?? this.roomName,
      schoolId: schoolId ?? this.schoolId,
      isActive: isActive ?? this.isActive,
      recurrence: recurrence ?? this.recurrence,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Méthode de chevauchement optimisée pour le planning hebdomadaire
  bool overlapsWith(SessionSchedule other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (isCancelled || other.isCancelled) return false;

    // Conflit si même coach ou même salle au même moment
    final sameCoach = coachId != null && other.coachId != null && coachId == other.coachId;
    final sameRoom = roomName != null && other.roomName != null && 
                     roomName!.trim().isNotEmpty && other.roomName!.trim().isNotEmpty &&
                     roomName == other.roomName;

    if (sameCoach || sameRoom) {
      return timeSlot.overlaps(other.timeSlot);
    }
    return false;
  }

  /// Vérifie si deux sessions se chevauchent dans le temps (pour l'affichage)
  bool overlapsInTime(SessionSchedule other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (isCancelled || other.isCancelled) return false;
    return timeSlot.overlaps(other.timeSlot);
  }
}

/// Énumération des jours de la semaine
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday: return 'Lundi';
      case DayOfWeek.tuesday: return 'Mardi';
      case DayOfWeek.wednesday: return 'Mercredi';
      case DayOfWeek.thursday: return 'Jeudi';
      case DayOfWeek.friday: return 'Vendredi';
      case DayOfWeek.saturday: return 'Samedi';
      case DayOfWeek.sunday: return 'Dimanche';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.monday: return 'Lun';
      case DayOfWeek.tuesday: return 'Mar';
      case DayOfWeek.wednesday: return 'Mer';
      case DayOfWeek.thursday: return 'Jeu';
      case DayOfWeek.friday: return 'Ven';
      case DayOfWeek.saturday: return 'Sam';
      case DayOfWeek.sunday: return 'Dim';
    }
  }

  static DayOfWeek fromDateTime(DateTime date) => DayOfWeek.values[date.weekday - 1];
}

/// Modèle pour un créneau horaire (optimisé pour planning hebdomadaire)
class TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeSlot({required this.start, required this.end});

  Duration get duration => Duration(
        hours: end.hour - start.hour,
        minutes: end.minute - start.minute,
      );

  String get displayTime => "${start.formatAsString()} - ${end.formatAsString()}";

  bool overlaps(TimeSlot other) {
    final s1 = start.hour * 60 + start.minute;
    final e1 = end.hour * 60 + end.minute;
    final s2 = other.start.hour * 60 + other.start.minute;
    final e2 = other.end.hour * 60 + other.end.minute;
    return s1 < e2 && s2 < e1;
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: parseTime(map['start'] ?? map['start_time']),
      end: parseTime(map['end'] ?? map['end_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': '${start.hour}:${start.minute.toString().padLeft(2, '0')}',
      'end': '${end.hour}:${end.minute.toString().padLeft(2, '0')}',
    };
  }

  static TimeOfDay parseTime(dynamic value) {
    if (value is String) {
      final parts = value.split(':').map(int.parse).toList();
      return TimeOfDay(hour: parts[0], minute: parts.length > 1 ? parts[1] : 0);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String formatAsString() => "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
}