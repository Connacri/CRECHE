enum UserRole {
  admin,
  parent,
  coach,
  school,
  unknown;

  static UserRole fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'parent':
        return UserRole.parent;
      case 'coach':
        return UserRole.coach;
      case 'school':
      case 'club':
      case 'organisation':
        return UserRole.school;
      default:
        return UserRole.unknown;
    }
  }

  String toJson() => name;
}

class AppLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  AppLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  factory AppLocation.fromMap(Map<String, dynamic> map) {
    return AppLocation(
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

class UserProfileImages {
  final String? profileImageSupabase;
  final String? profileImageLocal;
  final bool isSynced;

  UserProfileImages({
    this.profileImageSupabase,
    this.profileImageLocal,
    this.isSynced = false,
  });

  factory UserProfileImages.fromMap(Map<String, dynamic> map) {
    return UserProfileImages(
      profileImageSupabase: map['profileImageSupabase'] ?? map['profile_image_supabase'],
      profileImageLocal: map['profileImageLocal'] ?? map['profile_image_local'],
      isSynced: map['isSynced'] ?? map['is_synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile_image_supabase': profileImageSupabase,
      'profile_image_local': profileImageLocal,
      'is_synced': isSynced,
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? deactivatedAt;
  final DateTime? scheduledDeletionDate;
  final UserProfileImages profileImages;
  final AppLocation? location;
  final String? bio;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;
  final bool profileCompleted;
  final String? palmares;
  final List<String>? diplomas;
  final List<String>? certificates;
  final String? cvUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.deactivatedAt,
    this.scheduledDeletionDate,
    required this.profileImages,
    this.location,
    this.bio,
    this.phoneNumber,
    this.metadata,
    this.profileCompleted = false,
    this.palmares,
    this.diplomas,
    this.certificates,
    this.cvUrl,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    final locationData = data['location'];
    final hasFlatLocation =
        data['address'] != null ||
        data['city'] != null ||
        data['country'] != null;

    return UserModel(
      uid: data['id'] ?? data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromJson(data['role'] ?? 'parent'),
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
      isActive: data['is_active'] ?? true,
      deactivatedAt: _parseDateTimeNullable(data['deactivated_at']),
      scheduledDeletionDate: _parseDateTimeNullable(data['scheduled_deletion_date']),
      profileImages: data['profile_images'] != null
          ? UserProfileImages.fromMap(data['profile_images'])
          : UserProfileImages(),
      location: locationData != null
          ? AppLocation.fromMap(locationData)
          : hasFlatLocation
          ? AppLocation(
              latitude: 0.0,
              longitude: 0.0,
              address: data['address'] ?? '',
              city: data['city'],
              country: data['country'],
            )
          : null,
      bio: data['bio'],
      phoneNumber: data['phone_number'] ?? data['phone'],
      metadata: data['metadata'],
      profileCompleted: data['profile_completed'] ?? false,
      palmares: data['palmares'],
      diplomas: data['diplomas'] != null ? List<String>.from(data['diplomas']) : null,
      certificates: data['certificates'] != null ? List<String>.from(data['certificates']) : null,
      cvUrl: data['cv_url'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'email': email,
      'name': name,
      'role': role.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'deactivated_at': deactivatedAt?.toIso8601String(),
      'scheduled_deletion_date': scheduledDeletionDate?.toIso8601String(),
      'profile_images': profileImages.toMap(),
      'location': location?.toMap(),
      'bio': bio,
      'phone_number': phoneNumber,
      'metadata': metadata,
      'profile_completed': profileCompleted,
      'palmares': palmares,
      'diplomas': diplomas,
      'certificates': certificates,
      'cv_url': cvUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? deactivatedAt,
    DateTime? scheduledDeletionDate,
    UserProfileImages? profileImages,
    AppLocation? location,
    String? bio,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
    bool? profileCompleted,
    String? palmares,
    List<String>? diplomas,
    List<String>? certificates,
    String? cvUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      scheduledDeletionDate:
          scheduledDeletionDate ?? this.scheduledDeletionDate,
      profileImages: profileImages ?? this.profileImages,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      metadata: metadata ?? this.metadata,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      palmares: palmares ?? this.palmares,
      diplomas: diplomas ?? this.diplomas,
      certificates: certificates ?? this.certificates,
      cvUrl: cvUrl ?? this.cvUrl,
    );
  }

  int? getDaysUntilDeletion() {
    return scheduledDeletionDate?.difference(DateTime.now()).inDays;
  }

  bool canReactivate() {
    if (!isActive && scheduledDeletionDate != null) {
      return DateTime.now().isBefore(scheduledDeletionDate!);
    }
    return false;
  }
}
