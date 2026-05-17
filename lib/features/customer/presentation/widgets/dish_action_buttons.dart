import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../providers/cart_provider.dart';

class DishActionButtons extends ConsumerWidget {
  const DishActionButtons({
    super.key,
    required this.dish,
    required this.isLiked,
    required this.onLike,
    required this.onAddToCart,
    required this.onShare,
    required this.onInfo,
  });

  final DishModel dish;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onAddToCart;
  final VoidCallback onShare;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? AppColors.error : Colors.white,
          label: '${dish.reviewCount + (isLiked ? 1 : 0)}',
          onTap: onLike,
        ),
        const SizedBox(height: 20),

        // Add to cart (big CTA)
        GestureDetector(
          onTap: onAddToCart,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(blurRadius: 5, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Share button
        _ActionButton(
          icon: Icons.share_outlined,
          color: Colors.white,
          label: 'Share',
          onTap: onShare,
        ),
        const SizedBox(height: 20),

        // Info button
        _ActionButton(
          icon: Icons.info_outline,
          color: Colors.white,
          label: 'Details',
          onTap: onInfo,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.9,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: Column(
        children: [
          ScaleTransition(
            scale: _controller,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              shadows: [const Shadow(blurRadius: 5, color: Colors.black54)],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
