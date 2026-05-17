// Plain Dart CartModel — no Freezed dependency

class CartItem {
  const CartItem({
    required this.dishId,
    required this.dishName,
    required this.restaurantId,
    required this.restaurantName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.videoUrl,
    this.specialInstructions,
  });

  final String dishId;
  final String dishName;
  final String restaurantId;
  final String restaurantName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? videoUrl;
  final String? specialInstructions;

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? dishId,
    String? dishName,
    String? restaurantId,
    String? restaurantName,
    double? price,
    int? quantity,
    String? imageUrl,
    String? videoUrl,
    String? specialInstructions,
  }) {
    return CartItem(
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'dishName': dishName,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'specialInstructions': specialInstructions,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        dishId: json['dishId'] as String,
        dishName: json['dishName'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        imageUrl: json['imageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        specialInstructions: json['specialInstructions'] as String?,
      );
}

class Cart {
  const Cart({
    this.items = const [],
    this.deliveryFee = 49.0,
    this.serviceFee = 20.0,
    this.taxRate = 0.05,
    this.promoCode,
    this.promoDiscount = 0.0,
    this.deliveryAddress,
  });

  final List<CartItem> items;
  final double deliveryFee;
  final double serviceFee;
  final double taxRate;
  final String? promoCode;
  final double promoDiscount;
  final String? deliveryAddress;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get calculatedDeliveryFee => isEmpty ? 0 : deliveryFee;

  double get tax => subtotal * taxRate;

  double get total =>
      subtotal + calculatedDeliveryFee + serviceFee + tax - promoDiscount;

  String get subtotalFormatted => 'Rs. ${subtotal.toStringAsFixed(0)}';
  String get totalFormatted => 'Rs. ${total.toStringAsFixed(0)}';

  String? get restaurantId => items.isNotEmpty ? items.first.restaurantId : null;
  String? get restaurantName =>
      items.isNotEmpty ? items.first.restaurantName : null;

  Cart copyWith({
    List<CartItem>? items,
    double? deliveryFee,
    double? serviceFee,
    double? taxRate,
    String? promoCode,
    double? promoDiscount,
    String? deliveryAddress,
  }) {
    return Cart(
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      taxRate: taxRate ?? this.taxRate,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'taxRate': taxRate,
        'promoCode': promoCode,
        'promoDiscount': promoDiscount,
        'deliveryAddress': deliveryAddress,
      };

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        serviceFee: (json['serviceFee'] as num).toDouble(),
        taxRate: (json['taxRate'] as num).toDouble(),
        promoCode: json['promoCode'] as String?,
        promoDiscount: (json['promoDiscount'] as num).toDouble(),
        deliveryAddress: json['deliveryAddress'] as String?,
      );
}
