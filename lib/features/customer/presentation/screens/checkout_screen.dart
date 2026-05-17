import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/utils/mock_database.dart';
import '../../providers/cart_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _promoController = TextEditingController();
  String _selectedPayment = 'JazzCash';
  bool _isPlacingOrder = false;
  bool _isPickup = false;
  bool _promoApplied = false;
  String _promoError = '';
  // ignore: unused_field
  double _promoDiscount = 0.0;
  String? _selectedSavedAddress;


  @override
  void initState() {
    super.initState();
    // Pre-fill address from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserModelProvider);
      if (user != null && user.addresses.isNotEmpty) {
        _selectedSavedAddress = user.addresses.first;
        _addressController.text = user.addresses.first;
      } else {
        _addressController.text = 'House 12, Block C, DHA Lahore, Pakistan';
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    // Server-side validation (via MockDatabase)
    final discount = MockDatabase.instance.validatePromoCode(code);
    if (discount != null) {
      setState(() {
        _promoApplied = true;
        _promoDiscount = discount;
        _promoError = '';
      });
      ref.read(cartNotifierProvider.notifier).applyPromoCode(code, discount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Promo code applied! Rs. ${discount.toStringAsFixed(0)} off'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      setState(() {
        _promoError = 'Invalid promo code. Try: WELCOME50, NOMNOM20';
        _promoApplied = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final cart = ref.read(cartNotifierProvider);
      final user = ref.read(currentUserModelProvider);

      if (user == null || cart.isEmpty) {
        setState(() => _isPlacingOrder = false);
        return;
      }

      final orderId = const Uuid().v4();

      // Lahore restaurant coordinates
      const restaurantLat = 31.5204;
      const restaurantLng = 74.3587;

      // Customer coordinates (slightly different for simulation)
      const customerLat = 31.5350;
      const customerLng = 74.3850;

      final order = OrderModel(
        id: orderId,
        customerId: user.id,
        customerName: user.name,
        restaurantId: cart.restaurantId ?? 'restaurant_1',
        restaurantName: cart.restaurantName ?? 'Restaurant',
        items: cart.items
            .map((item) => OrderItem(
                  dishId: item.dishId,
                  dishName: item.dishName,
                  restaurantId: item.restaurantId,
                  price: item.price,
                  quantity: item.quantity,
                  imageUrl: item.imageUrl,
                ))
            .toList(),
        status: OrderStatus.pending,
        subtotal: cart.subtotal,
        deliveryFee: _isPickup ? 0 : cart.calculatedDeliveryFee,
        serviceFee: cart.serviceFee,
        tax: cart.tax,
        total: cart.subtotal + cart.tax + cart.serviceFee + (_isPickup ? 0 : cart.calculatedDeliveryFee) - cart.promoDiscount,
        isPickup: _isPickup,
        deliveryAddress: _isPickup ? 'Self-Pickup' : _addressController.text.trim(),
        promoCode: _promoApplied ? _promoController.text.trim() : null,
        discount: cart.promoDiscount,
        paymentMethod: _selectedPayment,
        isPaid: true,
        restaurantCoordinates: const GeoPoint(restaurantLat, restaurantLng),
        customerCoordinates: const GeoPoint(customerLat, customerLng),
        courierName: _isPickup ? 'Self-Pickup' : _getPakistaniCourierName(),
        courierVehicle: _isPickup ? 'None' : 'Motorcycle',
        estimatedMinutes: _isPickup ? 15 : 35,
        createdAt: DateTime.now(),
      );

      // 1. Save to MockDatabase FIRST (this is how owner sees it immediately)
      await MockDatabase.instance.addOrder(order);

      // 2. Try Firestore (non-blocking)
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .set(order.toJson())
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Firestore failed — order is still saved locally
      }

      // Clear cart after successful order
      ref.read(cartNotifierProvider.notifier).clearCart();

      if (!mounted) return;
      context.go('/order-confirmation/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  String _getPakistaniCourierName() {
    final names = ['Waqas Ali', 'Bilal Ahmed', 'Usman Khan', 'Asim Raza', 'Fahad Malik'];
    return names[DateTime.now().second % names.length];
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final user = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Checkout', style: AppTextStyles.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Delivery vs Pickup ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLighter),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPickup = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isPickup ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          '🛵 Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isPickup ? Colors.black : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPickup = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isPickup ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          '🚶 Pickup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isPickup ? Colors.black : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Delivery Address ───────────────────────────────────────────
          if (!_isPickup) ...[
            _SectionHeader(title: '📍 Delivery Address'),
            const SizedBox(height: 12),

          if (user != null && user.addresses.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLighter),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSavedAddress,
                  hint: Text('Select a saved address', style: AppTextStyles.bodyMedium),
                  items: [
                    ...user.addresses.map((addr) => DropdownMenuItem(
                          value: addr,
                          child: Text(addr,
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        )),
                    const DropdownMenuItem(
                      value: '__custom__',
                      child: Text('Enter custom address'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSavedAddress = val;
                      if (val != null && val != '__custom__') {
                        _addressController.text = val;
                      } else {
                        _addressController.text = '';
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _addressController,
            maxLines: 3,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'e.g. House 12, Block C, DHA Lahore',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.surfaceLighter),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          ],

          const SizedBox(height: 24),

          // ── Order Summary ──────────────────────────────────────────────
          _SectionHeader(title: '🛒 Order Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLighter),
            ),
            child: Column(
              children: [
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.dishName,
                                style: AppTextStyles.bodyLarge),
                          ),
                          Text(
                            'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Payment Method ─────────────────────────────────────────────
          _SectionHeader(title: '💳 Payment Method'),
          const SizedBox(height: 12),
          _PaymentOptions(
            selected: _selectedPayment,
            onChanged: (val) => setState(() => _selectedPayment = val),
          ),

          const SizedBox(height: 24),

          // ── Promo Code ─────────────────────────────────────────────────
          _SectionHeader(title: '🏷️ Promo Code'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: AppTextStyles.bodyLarge.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. WELCOME50',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.surfaceLighter)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.local_offer_outlined,
                        color: AppColors.primary),
                    suffixIcon: _promoApplied
                        ? const Icon(Icons.check_circle,
                            color: AppColors.success)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _promoApplied ? null : _validatePromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(80, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_promoApplied ? '✅' : 'Apply',
                    style: AppTextStyles.labelLarge),
              ),
            ],
          ),
          if (_promoError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_promoError,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),

          const SizedBox(height: 24),

          // ── Price Breakdown ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLighter),
            ),
            child: Column(
              children: [
                _PriceRow('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                _PriceRow('Delivery Fee',
                    _isPickup ? 'Free (Pickup)' : 'Rs. ${cart.calculatedDeliveryFee.toStringAsFixed(0)}'),
                _PriceRow(
                    'Service Fee', 'Rs. ${cart.serviceFee.toStringAsFixed(0)}'),
                _PriceRow('Tax (5%)', 'Rs. ${cart.tax.toStringAsFixed(0)}'),
                if (cart.promoDiscount > 0)
                  _PriceRow(
                      'Promo Discount',
                      '-Rs. ${cart.promoDiscount.toStringAsFixed(0)}',
                      isDiscount: true),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.headlineMedium),
                    Text(
                      'Rs. ${(cart.total - cart.promoDiscount - (_isPickup ? cart.calculatedDeliveryFee : 0)).toStringAsFixed(0)}',
                      style: AppTextStyles.priceLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Place Order ────────────────────────────────────────────────
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Place Order',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PaymentOptions extends StatelessWidget {
  const _PaymentOptions({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('JazzCash', Icons.phone_android),
      ('EasyPaisa', Icons.account_balance_wallet),
      ('Cash on Delivery', Icons.money),
      ('Bank Card', Icons.credit_card),
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.surfaceLighter,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(opt.$2,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textMuted,
                    size: 22),
                const SizedBox(width: 14),
                Text(opt.$1,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headlineSmall);
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.isDiscount = false});
  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
