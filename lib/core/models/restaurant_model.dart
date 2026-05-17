// Plain Dart RestaurantModel — no Freezed dependency

class RestaurantModel {
  const RestaurantModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.cuisineType = 'Multi-Cuisine',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
    this.imageUrl,
    this.bannerUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.averageDeliveryMinutes = 30,
    this.deliveryFee = 49.0,
    this.minimumOrder = 100.0,
    this.isOpen = true,
    this.tags = const [],
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String cuisineType;
  final double latitude;
  final double longitude;
  final String address;
  final String? imageUrl;
  final String? bannerUrl;
  final double rating;
  final int reviewCount;
  final int averageDeliveryMinutes;
  final double deliveryFee;
  final double minimumOrder;
  final bool isOpen;
  final List<String> tags;
  final DateTime? createdAt;

  RestaurantModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? cuisineType,
    double? latitude,
    double? longitude,
    String? address,
    String? imageUrl,
    String? bannerUrl,
    double? rating,
    int? reviewCount,
    int? averageDeliveryMinutes,
    double? deliveryFee,
    double? minimumOrder,
    bool? isOpen,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisineType: cuisineType ?? this.cuisineType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      averageDeliveryMinutes:
          averageDeliveryMinutes ?? this.averageDeliveryMinutes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isOpen: isOpen ?? this.isOpen,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'description': description,
        'cuisineType': cuisineType,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'imageUrl': imageUrl,
        'bannerUrl': bannerUrl,
        'rating': rating,
        'reviewCount': reviewCount,
        'averageDeliveryMinutes': averageDeliveryMinutes,
        'deliveryFee': deliveryFee,
        'minimumOrder': minimumOrder,
        'isOpen': isOpen,
        'tags': tags,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id'] as String? ?? '',
        ownerId: json['ownerId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        cuisineType: json['cuisineType'] as String? ?? 'Multi-Cuisine',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        address: json['address'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        bannerUrl: json['bannerUrl'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        averageDeliveryMinutes:
            (json['averageDeliveryMinutes'] as num?)?.toInt() ?? 30,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 49.0,
        minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 100.0,
        isOpen: json['isOpen'] as bool? ?? true,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
