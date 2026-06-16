import 'course_model_complete.dart';

enum EventType {
  competition,
  stage,
  porteOuverte,
  reunion,
  examen,
  tournoi,
  gala,
  formation,
  social,
  autre;

  static EventType fromString(String v) {
    if (v == 'competiton') return EventType.competition;
    if (v == 'porte_ouverte') return EventType.porteOuverte;
    return EventType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EventType.autre,
    );
  }
}

enum EventStatus {
  draft,
  published,
  registrationOpen,
  registrationClosed,
  ongoing,
  completed,
  cancelled;

  static EventStatus fromString(String v) {
    if (v == 'registration_open') return EventStatus.registrationOpen;
    if (v == 'registration_closed') return EventStatus.registrationClosed;
    if (v == 'inProgress') return EventStatus.ongoing;
    return EventStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EventStatus.draft,
    );
  }

  String get supabaseValue {
    if (this == EventStatus.registrationOpen) return 'registration_open';
    if (this == EventStatus.registrationClosed) return 'registration_closed';
    return name;
  }
}

enum RegistrationStatus {
  pending,
  confirmed,
  waitlist,
  cancelled,
  noShow;

  static RegistrationStatus fromString(String v) {
    if (v == 'no_show') return RegistrationStatus.noShow;
    return RegistrationStatus.values.firstWhere(
        (e) => e.name == v, orElse: () => RegistrationStatus.pending);
  }
}

// ── MODELS ─────────────────────────────────────────────────────────

class EventModel {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final CourseLocation? location;
  final int? maxParticipants;
  final int currentParticipants;
  final bool isPaid;
  final double? price;
  final double? memberPrice;
  final bool isPublic;
  final bool requiresMedicalCert;
  final List<String> images;
  final List<String> targetRoles;
  final List<String> allowedCategories;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.clubId,
    required this.title,
    this.description = '',
    required this.type,
    this.status = EventStatus.draft,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    this.location,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.isPaid = false,
    this.price,
    this.memberPrice,
    this.isPublic = true,
    this.requiresMedicalCert = false,
    this.images = const [],
    this.targetRoles = const [],
    this.allowedCategories = const [],
    this.tags = const [],
    this.metadata,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRegistrationOpen {
    final now = DateTime.now();
    if (status != EventStatus.registrationOpen && status != EventStatus.published) return false;
    if (registrationDeadline != null && now.isAfter(registrationDeadline!)) return false;
    if (maxParticipants != null && currentParticipants >= maxParticipants!) return false;
    return true;
  }

  bool get isFull =>
      maxParticipants != null && currentParticipants >= maxParticipants!;

  int? get availableSpots =>
      maxParticipants != null ? maxParticipants! - currentParticipants : null;

  Duration get duration => endDate.difference(startDate);

  bool get isMultiDay => duration.inDays >= 1;

  bool get isUpcoming => startDate.isAfter(DateTime.now());

  bool get isPast => endDate.isBefore(DateTime.now());

  factory EventModel.fromSupabase(Map<String, dynamic> d) {
    final locData = d['location'];
    return EventModel(
      id: d['id'] ?? '',
      clubId: d['club_id'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      type: EventType.fromString(d['type'] ?? 'autre'),
      status: EventStatus.fromString(d['status'] ?? 'draft'),
      startDate: DateTime.parse(d['start_date']),
      endDate: DateTime.parse(d['end_date']),
      registrationDeadline: d['registration_deadline'] != null
          ? DateTime.parse(d['registration_deadline']) : null,
      location: locData != null && locData is Map
          ? CourseLocation.fromMap(Map<String, dynamic>.from(locData)) : null,
      maxParticipants: d['max_participants'],
      currentParticipants: d['current_participants'] ?? 0,
      isPaid: d['is_paid'] ?? false,
      price: d['price']?.toDouble(),
      memberPrice: d['member_price']?.toDouble(),
      isPublic: d['is_public'] ?? true,
      requiresMedicalCert: d['requires_medical_cert'] ?? false,
      images: List<String>.from(d['images'] ?? []),
      targetRoles: List<String>.from(d['target_roles'] ?? []),
      allowedCategories: List<String>.from(d['allowed_categories'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      metadata: d['metadata'],
      createdBy: d['created_by'] ?? '',
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toSupabase() => {
    'club_id': clubId,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.supabaseValue,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'registration_deadline': registrationDeadline?.toIso8601String(),
    'location': location?.toMap(),
    'max_participants': maxParticipants,
    'is_paid': isPaid,
    'price': price,
    'member_price': memberPrice,
    'is_public': isPublic,
    'requires_medical_cert': requiresMedicalCert,
    'images': images,
    'target_roles': targetRoles,
    'allowed_categories': allowedCategories,
    'tags': tags,
    'metadata': metadata,
    'created_by': createdBy,
    'updated_at': DateTime.now().toIso8601String(),
  };

  EventModel copyWith({
    String? id, String? clubId, String? title, String? description,
    EventType? type, EventStatus? status, DateTime? startDate, DateTime? endDate,
    DateTime? registrationDeadline, CourseLocation? location,
    int? maxParticipants, int? currentParticipants,
    bool? isPaid, double? price, double? memberPrice,
    bool? isPublic, bool? requiresMedicalCert,
    List<String>? images, List<String>? targetRoles,
    List<String>? allowedCategories, List<String>? tags,
    Map<String, dynamic>? metadata, String? createdBy,
    DateTime? createdAt, DateTime? updatedAt,
  }) => EventModel(
    id: id ?? this.id,
    clubId: clubId ?? this.clubId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    registrationDeadline: registrationDeadline ?? this.registrationDeadline,
    location: location ?? this.location,
    maxParticipants: maxParticipants ?? this.maxParticipants,
    currentParticipants: currentParticipants ?? this.currentParticipants,
    isPaid: isPaid ?? this.isPaid,
    price: price ?? this.price,
    memberPrice: memberPrice ?? this.memberPrice,
    isPublic: isPublic ?? this.isPublic,
    requiresMedicalCert: requiresMedicalCert ?? this.requiresMedicalCert,
    images: images ?? this.images,
    targetRoles: targetRoles ?? this.targetRoles,
    allowedCategories: allowedCategories ?? this.allowedCategories,
    tags: tags ?? this.tags,
    metadata: metadata ?? this.metadata,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ── EVENT REGISTRATION ──────────────────────────────────────────────

class EventRegistration {
  final String id;
  final String eventId;
  final String registrantId;
  final String? childId;
  final RegistrationStatus status;
  final String paymentStatus;
  final double paidAmount;
  final String? bibNumber;
  final String? category;
  final bool medicalCertSubmitted;
  final String? notes;
  final DateTime registeredAt;
  final DateTime? confirmedAt;
  final DateTime updatedAt;

  // Relations (joined)
  final EventModel? event;
  final Map<String, dynamic>? registrantData;
  final Map<String, dynamic>? childData;

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.registrantId,
    this.childId,
    this.status = RegistrationStatus.pending,
    this.paymentStatus = 'not_required',
    this.paidAmount = 0,
    this.bibNumber,
    this.category,
    this.medicalCertSubmitted = false,
    this.notes,
    required this.registeredAt,
    this.confirmedAt,
    required this.updatedAt,
    this.event,
    this.registrantData,
    this.childData,
  });

  String get participantName {
    if (childData != null) {
      return '${childData!['first_name']} ${childData!['last_name']}';
    }
    return registrantData?['name'] ?? 'Inconnu';
  }

  factory EventRegistration.fromSupabase(Map<String, dynamic> d) => EventRegistration(
    id: d['id'] ?? '',
    eventId: d['event_id'] ?? '',
    registrantId: d['registrant_id'] ?? '',
    childId: d['child_id'],
    status: RegistrationStatus.fromString(d['status'] ?? 'pending'),
    paymentStatus: d['payment_status'] ?? 'not_required',
    paidAmount: (d['paid_amount'] ?? 0).toDouble(),
    bibNumber: d['bib_number'],
    category: d['category'],
    medicalCertSubmitted: d['medical_cert_submitted'] ?? false,
    notes: d['notes'],
    registeredAt: DateTime.parse(d['registered_at']),
    confirmedAt: d['confirmed_at'] != null ? DateTime.parse(d['confirmed_at']) : null,
    updatedAt: DateTime.parse(d['updated_at'] ?? d['registered_at']),
    event: d['event'] != null ? EventModel.fromSupabase(d['event']) : null,
    registrantData: d['registrant'],
    childData: d['child'],
  );

  Map<String, dynamic> toSupabase() => {
    'event_id': eventId,
    'registrant_id': registrantId,
    'child_id': childId,
    'status': status.name,
    'payment_status': paymentStatus,
    'paid_amount': paidAmount,
    'bib_number': bibNumber,
    'category': category,
    'medical_cert_submitted': medicalCertSubmitted,
    'notes': notes,
    'updated_at': DateTime.now().toIso8601String(),
  };

  EventRegistration copyWith({
    String? id, String? eventId, String? registrantId, String? childId,
    RegistrationStatus? status, String? paymentStatus, double? paidAmount,
    String? bibNumber, String? category, bool? medicalCertSubmitted, String? notes,
    DateTime? registeredAt, DateTime? confirmedAt, DateTime? updatedAt,
  }) => EventRegistration(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    registrantId: registrantId ?? this.registrantId,
    childId: childId ?? this.childId,
    status: status ?? this.status,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paidAmount: paidAmount ?? this.paidAmount,
    bibNumber: bibNumber ?? this.bibNumber,
    category: category ?? this.category,
    medicalCertSubmitted: medicalCertSubmitted ?? this.medicalCertSubmitted,
    notes: notes ?? this.notes,
    registeredAt: registeredAt ?? this.registeredAt,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
