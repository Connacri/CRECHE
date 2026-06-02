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

  bool get hasLocation => latitude != 0.0 && longitude != 0.0;

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

  AppLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}

enum UserRole {
  transporteur,
  fournisseur,
  user,
  parent,
  school,
  coach,
  autres;

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (role) => role.name == json,
      orElse: () => UserRole.parent,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.school:
        return 'School';
      case UserRole.coach:
        return 'Coach';
      case UserRole.transporteur:
        return 'Transporteur';
      case UserRole.fournisseur:
        return 'Fournisseur';
      case UserRole.user:
        return 'Utilisateur';
      case UserRole.autres:
        return 'Autres';
    }
  }
}

class UserProfileImages {
  final String? profileImageSupabase;
  final String? coverImageSupabase;
  final DateTime? lastUpdated;

  UserProfileImages({
    this.profileImageSupabase,
    this.coverImageSupabase,
    this.lastUpdated,
  });

  factory UserProfileImages.fromMap(Map<String, dynamic> map) {
    return UserProfileImages(
      profileImageSupabase: map['profileImageSupabase'] ?? map['profileImage'],
      coverImageSupabase: map['coverImageSupabase'] ?? map['coverImage'],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] is String
              ? DateTime.parse(map['lastUpdated'])
              : DateTime.fromMillisecondsSinceEpoch(0)) // Fallback if format is weird
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileImageSupabase': profileImageSupabase,
      'coverImageSupabase': coverImageSupabase,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  static String? _withCacheVersion(String? url, DateTime? lastUpdated) {
    if (url == null || url.isEmpty) {
      return url;
    }

    if (lastUpdated == null) {
      return url;
    }

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${lastUpdated.millisecondsSinceEpoch}';
  }

  String? get profileImage => _withCacheVersion(
        profileImageSupabase,
        lastUpdated,
      );

  String? get coverImage => _withCacheVersion(
        coverImageSupabase,
        lastUpdated,
      );

  UserProfileImages copyWith({
    String? profileImageSupabase,
    String? coverImageSupabase,
    DateTime? lastUpdated,
  }) {
    return UserProfileImages(
      profileImageSupabase: profileImageSupabase ?? this.profileImageSupabase,
      coverImageSupabase: coverImageSupabase ?? this.coverImageSupabase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
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

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.deactivatedAt,
    this.scheduledDeletionDate,
    UserProfileImages? profileImages,
    this.location,
    this.bio,
    this.phoneNumber,
    this.metadata,
  }) : profileImages = profileImages ?? UserProfileImages();

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
