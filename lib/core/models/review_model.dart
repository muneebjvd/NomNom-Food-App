// Plain Dart ReviewModel — no Freezed dependency

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.dishId,
    required this.restaurantId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.createdAt,
  });

  final String id;
  final String dishId;
  final String restaurantId;
  final String customerId;
  final String customerName;
  final double rating;
  final String? comment;
  final List<String> imageUrls;
  final DateTime? createdAt;

  ReviewModel copyWith({
    String? id,
    String? dishId,
    String? restaurantId,
    String? customerId,
    String? customerName,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      dishId: dishId ?? this.dishId,
      restaurantId: restaurantId ?? this.restaurantId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dishId': dishId,
        'restaurantId': restaurantId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String? ?? '',
        dishId: json['dishId'] as String? ?? '',
        restaurantId: json['restaurantId'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        comment: json['comment'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
