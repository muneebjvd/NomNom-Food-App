// Plain Dart OrderModel — no Freezed dependency
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '📦';
      case OrderStatus.outForDelivery:
        return '🛵';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  OrderStatus? get next {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready ||
      this == OrderStatus.outForDelivery;
}

class OrderItem {
  const OrderItem({
    required this.dishId,
    required this.dishName,
    required this.restaurantId,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.specialInstructions,
  });

  final String dishId;
  final String dishName;
  final String restaurantId;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? specialInstructions;

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'dishName': dishName,
        'restaurantId': restaurantId,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'specialInstructions': specialInstructions,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        dishId: json['dishId'] as String? ?? '',
        dishName: json['dishName'] as String? ?? '',
        restaurantId: json['restaurantId'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: json['imageUrl'] as String?,
        specialInstructions: json['specialInstructions'] as String?,
      );
}

class CourierLocation {
  const CourierLocation({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp?.toIso8601String(),
      };

  factory CourierLocation.fromJson(Map<String, dynamic> json) =>
      CourierLocation(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.tax,
    required this.total,
    this.isPickup = false,
    required this.deliveryAddress,
    this.promoCode,
    this.discount = 0.0,
    this.paymentMethod = 'Simulated',
    this.isPaid = false,
    this.restaurantCoordinates,
    this.customerCoordinates,
    this.courierLocation,
    this.courierName = 'Courier',
    this.courierVehicle = 'Motorcycle',
    this.estimatedMinutes = 35,
    this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double total;
  final bool isPickup;
  final String deliveryAddress;
  final String? promoCode;
  final double discount;
  final String paymentMethod;
  final bool isPaid;
  final GeoPoint? restaurantCoordinates;
  final GeoPoint? customerCoordinates;
  final CourierLocation? courierLocation;
  final String courierName;
  final String courierVehicle;
  final int estimatedMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  bool get isActive => status.isActive;

  String get totalFormatted => 'Rs. ${total.toStringAsFixed(0)}';

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? restaurantId,
    String? restaurantName,
    List<OrderItem>? items,
    OrderStatus? status,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? tax,
    double? total,
    bool? isPickup,
    String? deliveryAddress,
    String? promoCode,
    double? discount,
    String? paymentMethod,
    bool? isPaid,
    GeoPoint? restaurantCoordinates,
    GeoPoint? customerCoordinates,
    CourierLocation? courierLocation,
    String? courierName,
    String? courierVehicle,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      isPickup: isPickup ?? this.isPickup,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      restaurantCoordinates:
          restaurantCoordinates ?? this.restaurantCoordinates,
      customerCoordinates: customerCoordinates ?? this.customerCoordinates,
      courierLocation: courierLocation ?? this.courierLocation,
      courierName: courierName ?? this.courierName,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'tax': tax,
        'total': total,
        'isPickup': isPickup,
        'deliveryAddress': deliveryAddress,
        'promoCode': promoCode,
        'discount': discount,
        'paymentMethod': paymentMethod,
        'isPaid': isPaid,
        'courierName': courierName,
        'courierVehicle': courierVehicle,
        'estimatedMinutes': estimatedMinutes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        restaurantId: json['restaurantId'] as String? ?? '',
        restaurantName: json['restaurantName'] as String? ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        status: _parseStatus(json['status'] as String?),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
        serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        isPickup: json['isPickup'] as bool? ?? false,
        deliveryAddress: json['deliveryAddress'] as String? ?? '',
        promoCode: json['promoCode'] as String?,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: json['paymentMethod'] as String? ?? 'Simulated',
        isPaid: json['isPaid'] as bool? ?? false,
        courierName: json['courierName'] as String? ?? 'Courier',
        courierVehicle: json['courierVehicle'] as String? ?? 'Motorcycle',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 35,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'] as String)
            : null,
      );

  static OrderStatus _parseStatus(String? value) {
    if (value == null) return OrderStatus.pending;
    try {
      return OrderStatus.values.firstWhere((s) => s.name == value);
    } catch (_) {
      return OrderStatus.pending;
    }
  }
}
