import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/dish_model.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import 'mock_database_seed.dart';

/// Persistent local storage — all data survives app restart.
class MockDatabase {
  static final MockDatabase instance = MockDatabase._init();
  SharedPreferences? _prefs;

  MockDatabase._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Seed initial dishes if none exist yet
    if (getDishes() == null) {
      await saveDishes(_seedDishes());
    }
    // Pre-seed demo accounts so login works offline
    final existing = getSignedUpUsers();
    if (!existing.containsKey('subhani@itu.com')) {
      await saveSignedUpUser(UserModel(
        id: 'demo_customer_1',
        email: 'subhani@itu.com',
        name: 'Ali Subhani',
        role: UserRole.customer,
        phone: '+92 300 1234567',
        addresses: ['House 12, Block C, DHA Lahore', 'Office 3rd Floor, MM Alam Road, Lahore'],
        createdAt: DateTime(2024, 1, 1),
      ));
    }
    if (!existing.containsKey('muneeb@itu.com')) {
      await saveSignedUpUser(UserModel(
        id: 'demo_owner_1',
        email: 'muneeb@itu.com',
        name: 'Muneeb Ahmed',
        role: UserRole.owner,
        phone: '+92 321 9876543',
        addresses: [],
        createdAt: DateTime(2024, 1, 1),
      ));
    }
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  UserModel? getUser() {
    final str = _prefs?.getString('mock_user');
    if (str != null) {
      try {
        return UserModel.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs?.setString('mock_user', jsonEncode(user.toJson()));
    // Also update in the signed-up users map
    await saveSignedUpUser(user);
  }

  Future<void> clearUser() async {
    await _prefs?.remove('mock_user');
  }

  // ─── Users (Signup DB) ───────────────────────────────────────────────────

  Future<void> saveSignedUpUser(UserModel user) async {
    final users = getSignedUpUsers();
    users[user.email] = user;
    await _prefs?.setString(
        'mock_users_db',
        jsonEncode(users.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Map<String, UserModel> getSignedUpUsers() {
    final str = _prefs?.getString('mock_users_db');
    if (str != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(str);
        return map.map((k, v) => MapEntry(k, UserModel.fromJson(v as Map<String, dynamic>)));
      } catch (_) {}
    }
    return {};
  }

  // ─── Dishes ──────────────────────────────────────────────────────────────

  List<DishModel>? getDishes() {
    final str = _prefs?.getString('mock_dishes_v2');
    if (str != null) {
      try {
        final List<dynamic> list = jsonDecode(str);
        return list.map((e) => DishModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveDishes(List<DishModel> dishes) async {
    await _prefs?.setString(
        'mock_dishes_v2', jsonEncode(dishes.map((e) => e.toJson()).toList()));
  }

  List<DishModel> getDishesOrSeed() {
    return getDishes() ?? _seedDishes();
  }

  // ─── Cart ─────────────────────────────────────────────────────────────────

  Cart? getCart() {
    final str = _prefs?.getString('mock_cart');
    if (str != null) {
      try {
        return Cart.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveCart(Cart cart) async {
    await _prefs?.setString('mock_cart', jsonEncode(cart.toJson()));
  }

  Future<void> clearCart() async {
    await _prefs?.remove('mock_cart');
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  List<OrderModel> getOrders() {
    final str = _prefs?.getString('mock_orders_v2');
    if (str != null) {
      try {
        final List<dynamic> list = jsonDecode(str);
        return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    await _prefs?.setString(
        'mock_orders_v2', jsonEncode(orders.map((e) => e.toJson()).toList()));
  }

  Future<void> addOrder(OrderModel order) async {
    final orders = getOrders();
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order); // newest first
    await saveOrders(orders);
  }

  Future<void> updateOrder(OrderModel order) async {
    final orders = getOrders();
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      orders[index] = order;
      await saveOrders(orders);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final orders = getOrders();
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      orders[index] = orders[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await saveOrders(orders);
    }
  }

  OrderModel? getOrderById(String orderId) {
    return getOrders().where((o) => o.id == orderId).firstOrNull;
  }

  // ─── Promo Codes (backend simulation) ───────────────────────────────────

  static const Map<String, double> _promoCodes = {
    'WELCOME50': 50.0,
    'NOMNOM20': 20.0,
    'FIRSTORDER': 100.0,
    'STUDENT15': 15.0,
    'FOODIE30': 30.0,
    'EID25': 25.0,
    'LAHORE10': 10.0,
  };

  /// Returns discount amount if valid, null if invalid
  double? validatePromoCode(String code) {
    return _promoCodes[code.toUpperCase().trim()];
  }

  // ─── Seed Data ───────────────────────────────────────────────────────────

  List<DishModel> _seedDishes() {
    return getGeneratedMockDishes();
  }
}
