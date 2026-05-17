import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Your Cart', style: AppTextStyles.headlineLarge),
        elevation: 0,
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(cartNotifierProvider.notifier).clearCart(),
              child: Text(
                'Clear',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      // Checkout button in bottomNavigationBar slot (above the nav bar)
      bottomNavigationBar: cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.surfaceLighter, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment_outlined,
                            color: Colors.black, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Checkout  •  ${cart.totalFormatted}',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartContent(context, ref, cart),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text('Your cart is empty', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Discover amazing food in the feed',
            style:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/feed'),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Feed'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, cart) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Restaurant info
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceLighter),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏪', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cart.restaurantName ?? '',
                    style: AppTextStyles.titleLarge,
                  ),
                  Text(
                    '${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cart items
        ...cart.items.map((item) => _CartItemCard(
              item: item,
              onIncrement: () => ref
                  .read(cartNotifierProvider.notifier)
                  .incrementQuantity(item.dishId),
              onDecrement: () => ref
                  .read(cartNotifierProvider.notifier)
                  .decrementQuantity(item.dishId),
              onRemove: () => ref
                  .read(cartNotifierProvider.notifier)
                  .removeItem(item.dishId),
            )),

        const SizedBox(height: 20),

        // Price breakdown
        _PriceBreakdown(cart: cart),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final dynamic item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.dishId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLighter),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _FallbackImg(),
                    )
                  : _FallbackImg(),
            ),

            const SizedBox(width: 14),

            // Name and price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.dishName, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)} each',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                _QtyBtn(onTap: onDecrement, icon: Icons.remove),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                _QtyBtn(onTap: onIncrement, icon: Icons.add, isPrimary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.fastfood, color: AppColors.primary, size: 28),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.onTap, required this.icon, this.isPrimary = false});
  final VoidCallback onTap;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceLighter,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isPrimary ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.cart});
  final dynamic cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          _Row('Subtotal', cart.subtotalFormatted),
          const SizedBox(height: 8),
          _Row('Delivery Fee',
              'Rs. ${cart.calculatedDeliveryFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _Row('Service Fee', 'Rs. ${cart.serviceFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _Row('Tax (5%)', 'Rs. ${cart.tax.toStringAsFixed(0)}'),
          if (cart.promoDiscount > 0) ...[
            const SizedBox(height: 8),
            _Row(
              'Promo Discount',
              '-Rs. ${cart.promoDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headlineMedium),
              Text(
                cart.totalFormatted,
                style: AppTextStyles.priceLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.isDiscount = false});
  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color:
                isDiscount ? AppColors.success : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
