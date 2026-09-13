class Studio {
  final int id;
  final int ownerId;
  final String name;
  final String slug;
  final String? description;
  final String? address;
  final String? city;
  final String? province;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? logo;
  final bool isVerified;
  final bool isActive;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StudioRoom> rooms;
  final List<StudioImage> images;
  final List<StudioEquipment> equipment;
  final List<StudioOpeningHour> openingHours;

  /// Whether the currently logged in user has favorited this studio.
  /// Set locally after a favorite toggle.
  bool isFavorited;

  Studio({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description,
    this.address,
    this.city,
    this.province,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.logo,
    required this.isVerified,
    required this.isActive,
    required this.averageRating,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
    this.rooms = const [],
    this.images = const [],
    this.equipment = const [],
    this.openingHours = const [],
    this.isFavorited = false,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      phone: json['phone'],
      email: json['email'],
      logo: json['logo'],
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((r) => StudioRoom.fromJson(r)).toList()
          : const [],
      images: json['images'] != null
          ? (json['images'] as List).map((i) => StudioImage.fromJson(i)).toList()
          : const [],
      equipment: json['equipment'] != null
          ? (json['equipment'] as List)
              .map((e) => StudioEquipment.fromJson(e))
              .toList()
          : const [],
      openingHours: json['opening_hours'] != null
          ? (json['opening_hours'] as List)
              .map((h) => StudioOpeningHour.fromJson(h))
              .toList()
          : const [],
      isFavorited: json['is_favorited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'slug': slug,
      'description': description,
      'address': address,
      'city': city,
      'province': province,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'logo': logo,
      'is_verified': isVerified,
      'is_active': isActive,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'is_favorited': isFavorited,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'opening_hours': openingHours.map((h) => h.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  String get fullAddress => [address, city, province].where((s) => s != null && s.isNotEmpty).join(', ');
}

class StudioRoom {
  final int id;
  final int studioId;
  final String name;
  final String? description;
  final int capacity;
  final double pricePerHour;
  final bool isActive;
  final List<String>? images;

  StudioRoom({
    required this.id,
    required this.studioId,
    required this.name,
    this.description,
    required this.capacity,
    required this.pricePerHour,
    required this.isActive,
    this.images,
  });

  factory StudioRoom.fromJson(Map<String, dynamic> json) {
    return StudioRoom(
      id: json['id'] ?? 0,
      studioId: json['studio_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      capacity: json['capacity'] ?? 0,
      pricePerHour: (json['price_per_hour'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studio_id': studioId,
      'name': name,
      'description': description,
      'capacity': capacity,
      'price_per_hour': pricePerHour,
      'is_active': isActive,
      'images': images,
    };
  }
  
  String get formattedPrice => 'Rp ${pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}/jam';
}

class StudioImage {
  final int id;
  final int studioId;
  final String url;
  final String? caption;
  final int sortOrder;

  StudioImage({
    required this.id,
    required this.studioId,
    required this.url,
    this.caption,
    required this.sortOrder,
  });

  factory StudioImage.fromJson(Map<String, dynamic> json) {
    return StudioImage(
      id: json['id'] ?? 0,
      studioId: json['studio_id'] ?? 0,
      url: json['url'] ?? '',
      caption: json['caption'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studio_id': studioId,
      'url': url,
      'caption': caption,
      'sort_order': sortOrder,
    };
  }
}

class StudioEquipment {
  final int id;
  final int studioId;
  final String name;
  final String? description;
  final int? quantity;

  StudioEquipment({
    required this.id,
    required this.studioId,
    required this.name,
    this.description,
    this.quantity,
  });

  factory StudioEquipment.fromJson(Map<String, dynamic> json) {
    return StudioEquipment(
      id: json['id'],
      studioId: json['studio_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studio_id': studioId,
      'name': name,
      'description': description,
      'quantity': quantity,
    };
  }
}

class StudioOpeningHour {
  final int id;
  final int studioId;
  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  StudioOpeningHour({
    required this.id,
    required this.studioId,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory StudioOpeningHour.fromJson(Map<String, dynamic> json) {
    return StudioOpeningHour(
      id: json['id'] ?? 0,
      studioId: json['studio_id'] ?? 0,
      dayOfWeek: json['day_of_week'] ?? 1,
      openTime: json['open_time'],
      closeTime: json['close_time'],
      isClosed: json['is_closed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studio_id': studioId,
      'day_of_week': dayOfWeek,
      'open_time': openTime,
      'close_time': closeTime,
      'is_closed': isClosed,
    };
  }
}
