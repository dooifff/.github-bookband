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
  final List<StudioRoom>? rooms;
  final List<StudioImage>? images;

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
    this.rooms,
    this.images,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      slug: json['slug'],
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((r) => StudioRoom.fromJson(r)).toList()
          : null,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => StudioImage.fromJson(i)).toList()
          : null,
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
      id: json['id'],
      studioId: json['studio_id'],
      name: json['name'],
      description: json['description'],
      capacity: json['capacity'],
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
      id: json['id'],
      studioId: json['studio_id'],
      url: json['url'],
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
