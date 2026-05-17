// Plain Dart UserModel — no Freezed dependency

enum UserRole { customer, owner, courier }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.restaurantId,
    this.restaurantName,
    this.addresses = const [],
    this.fcmToken,
    this.isOnline = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? restaurantId;
  final String? restaurantName;
  final List<String> addresses;
  final String? fcmToken;
  final bool isOnline;
  final DateTime? createdAt;

  bool get isOwner => role == UserRole.owner;
  bool get isCustomer => role == UserRole.customer;
  bool get isCourier => role == UserRole.courier;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    String? restaurantId,
    String? restaurantName,
    List<String>? addresses,
    String? fcmToken,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      addresses: addresses ?? this.addresses,
      fcmToken: fcmToken ?? this.fcmToken,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'addresses': addresses,
        'fcmToken': fcmToken,
        'isOnline': isOnline,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: _parseRole(json['role'] as String?),
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        restaurantId: json['restaurantId'] as String?,
        restaurantName: json['restaurantName'] as String?,
        addresses:
            (json['addresses'] as List<dynamic>?)?.cast<String>() ?? [],
        fcmToken: json['fcmToken'] as String?,
        isOnline: json['isOnline'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  static UserRole _parseRole(String? value) {
    if (value == null) return UserRole.customer;
    try {
      return UserRole.values.firstWhere((r) => r.name == value);
    } catch (_) {
      return UserRole.customer;
    }
  }
}
