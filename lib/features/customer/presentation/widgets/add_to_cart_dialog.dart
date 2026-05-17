import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../providers/cart_provider.dart';

class AddToCartBottomSheet extends ConsumerStatefulWidget {
  const AddToCartBottomSheet({super.key, required this.dish});

  final DishModel dish;

  @override
  ConsumerState<AddToCartBottomSheet> createState() =>
      _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends ConsumerState<AddToCartBottomSheet>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _animController;
  bool _showAddedAnimation = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _addToCart() {
    try {
      ref
          .read(cartNotifierProvider.notifier)
          .addItem(widget.dish, quantity: _quantity);

      HapticFeedback.heavyImpact();
      setState(() => _showAddedAnimation = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } on Exception catch (e) {
      final message = e.toString();
      if (message.contains('DIFFERENT_RESTAURANT')) {
        // Show dialog to confirm new cart
        _showNewCartDialog();
      }
    }
  }

  void _showNewCartDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Start a New Cart?', style: AppTextStyles.headlineMedium),
        content: Text(
          'Your cart has items from ${ref.read(cartNotifierProvider).restaurantName}. Adding this item will clear your current cart.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(cartNotifierProvider.notifier)
                  .clearAndAddItem(widget.dish, quantity: _quantity);
              HapticFeedback.heavyImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start New Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.dish.price * _quantity;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Dish info
            Row(
              children: [
                if (widget.dish.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.dish.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.restaurant, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.dish.name, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(widget.dish.restaurantName, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Text(widget.dish.priceFormatted, style: AppTextStyles.priceLarge),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quantity selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity', style: AppTextStyles.titleLarge),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: _quantity > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _quantity--);
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Add to cart button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showAddedAnimation
                  ? Container(
                      key: const ValueKey('added'),
                      height: 58,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Added to Cart! ✨',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('add'),
                      height: 58,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.black),
                              const SizedBox(width: 10),
                              Text(
                                'Add to Cart • Rs. ${totalPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppColors.primary : AppColors.textMuted,
          size: 18,
        ),
      ),
    );
  }
}
