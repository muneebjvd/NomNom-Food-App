import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cart_model.dart';
import '../../../core/models/dish_model.dart';
import '../../../core/utils/mock_database.dart';

final cartNotifierProvider = NotifierProvider<CartNotifier, Cart>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    return MockDatabase.instance.getCart() ?? const Cart(
      deliveryFee: 49.0,
      serviceFee: 20.0,
      taxRate: 0.05,
    );
  }

  void _saveState() {
    MockDatabase.instance.saveCart(state);
  }

  void addItem(DishModel dish, {int quantity = 1}) {
    final currentCart = state;

    if (currentCart.isNotEmpty &&
        currentCart.restaurantId != dish.restaurantId) {
      throw Exception(
          'DIFFERENT_RESTAURANT:${dish.restaurantId}:${dish.restaurantName}');
    }

    _addToCart(dish, quantity);
  }

  void _addToCart(DishModel dish, int quantity) {
    final currentItems = List<CartItem>.from(state.items);
    final existingIndex =
        currentItems.indexWhere((item) => item.dishId == dish.id);

    if (existingIndex >= 0) {
      currentItems[existingIndex] = currentItems[existingIndex].copyWith(
        quantity: currentItems[existingIndex].quantity + quantity,
      );
    } else {
      currentItems.add(CartItem(
        dishId: dish.id,
        dishName: dish.name,
        restaurantId: dish.restaurantId,
        restaurantName: dish.restaurantName,
        price: dish.price,
        quantity: quantity,
        imageUrl: dish.imageUrl,
        videoUrl: dish.videoUrl,
      ));
    }

    state = state.copyWith(items: currentItems);
    _saveState();
  }

  void clearAndAddItem(DishModel dish, {int quantity = 1}) {
    state = const Cart(
      deliveryFee: 49.0,
      serviceFee: 20.0,
      taxRate: 0.05,
    );
    _addToCart(dish, quantity);
  }

  void removeItem(String dishId) {
    final updatedItems =
        state.items.where((item) => item.dishId != dishId).toList();
    state = state.copyWith(items: updatedItems);
    _saveState();
  }

  void incrementQuantity(String dishId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.dishId == dishId);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      state = state.copyWith(items: items);
      _saveState();
    }
  }

  void decrementQuantity(String dishId) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((item) => item.dishId == dishId);
    if (index >= 0) {
      if (items[index].quantity <= 1) {
        removeItem(dishId);
      } else {
        items[index] =
            items[index].copyWith(quantity: items[index].quantity - 1);
        state = state.copyWith(items: items);
        _saveState();
      }
    }
  }

  void clearCart() {
    state = const Cart(
      deliveryFee: 49.0,
      serviceFee: 20.0,
      taxRate: 0.05,
    );
    MockDatabase.instance.clearCart();
  }

  void applyPromoCode(String code, double discount) {
    state = state.copyWith(promoCode: code, promoDiscount: discount);
    _saveState();
  }
}

// Convenience selectors
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).totalItems;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartNotifierProvider).total;
});
