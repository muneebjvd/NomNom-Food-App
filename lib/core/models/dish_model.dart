// Simplified DishModel without Freezed dependency
// Run: dart run build_runner build --delete-conflicting-outputs
// to regenerate with proper Freezed output

enum DietaryTag {
  vegetarian,
  vegan,
  glutenFree,
  halal,
  spicy,
  dairyFree,
  nutFree,
  keto,
}

enum SpiceLevel {
  none,
  mild,
  medium,
  hot,
  extraHot,
}

extension SpiceLevelExt on SpiceLevel {
  String get label {
    switch (this) {
      case SpiceLevel.none:
        return 'No Spice';
      case SpiceLevel.mild:
        return 'Mild';
      case SpiceLevel.medium:
        return 'Medium';
      case SpiceLevel.hot:
        return 'Hot 🌶️';
      case SpiceLevel.extraHot:
        return 'Extra Hot 🔥';
    }
  }
}

class DishModel {
  const DishModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantLat,
    this.restaurantLng,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.videoUrl,
    required this.cuisine,
    this.ingredients = const [],
    this.dietaryTags = const [],
    this.spiceLevel = SpiceLevel.none,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.estimatedDeliveryMinutes = 30,
    this.isAvailable = true,
    this.isFeatured = false,
    this.orderCount = 0,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final double? restaurantLat;
  final double? restaurantLng;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? videoUrl;
  final String cuisine;
  final List<String> ingredients;
  final List<DietaryTag> dietaryTags;
  final SpiceLevel spiceLevel;
  final double rating;
  final int reviewCount;
  final int estimatedDeliveryMinutes;
  final bool isAvailable;
  final bool isFeatured;
  final int orderCount;

  String get priceFormatted => 'Rs. ${price.toStringAsFixed(0)}';

  String get spiceLevelLabel => spiceLevel.label;

  bool get isVegetarian =>
      dietaryTags.contains(DietaryTag.vegetarian) ||
      dietaryTags.contains(DietaryTag.vegan);

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
      restaurantLat: (json['restaurantLat'] as num?)?.toDouble(),
      restaurantLng: (json['restaurantLng'] as num?)?.toDouble(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      cuisine: json['cuisine'] as String? ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)?.cast<String>() ?? [],
      dietaryTags: (json['dietaryTags'] as List<dynamic>?)
              ?.map((t) => _parseDietaryTag(t as String))
              .whereType<DietaryTag>()
              .toList() ??
          [],
      spiceLevel:
          _parseSpiceLevel(json['spiceLevel'] as String?) ?? SpiceLevel.none,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      estimatedDeliveryMinutes:
          (json['estimatedDeliveryMinutes'] as num?)?.toInt() ?? 30,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantLat': restaurantLat,
      'restaurantLng': restaurantLng,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'cuisine': cuisine,
      'ingredients': ingredients,
      'dietaryTags': dietaryTags.map((t) => t.name).toList(),
      'spiceLevel': spiceLevel.name,
      'rating': rating,
      'reviewCount': reviewCount,
      'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'orderCount': orderCount,
    };
  }

  DishModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? videoUrl,
    String? cuisine,
    List<String>? ingredients,
    List<DietaryTag>? dietaryTags,
    SpiceLevel? spiceLevel,
    double? rating,
    int? reviewCount,
    int? estimatedDeliveryMinutes,
    bool? isAvailable,
    bool? isFeatured,
    int? orderCount,
  }) {
    return DishModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      cuisine: cuisine ?? this.cuisine,
      ingredients: ingredients ?? this.ingredients,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      orderCount: orderCount ?? this.orderCount,
    );
  }

  static DietaryTag? _parseDietaryTag(String value) {
    try {
      return DietaryTag.values.firstWhere((t) => t.name == value);
    } catch (_) {
      return null;
    }
  }

  static SpiceLevel? _parseSpiceLevel(String? value) {
    if (value == null) return null;
    try {
      return SpiceLevel.values.firstWhere((t) => t.name == value);
    } catch (_) {
      return null;
    }
  }
}
