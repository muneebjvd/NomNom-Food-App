import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../providers/dish_provider.dart';
import '../../providers/cart_provider.dart';
import '../widgets/add_to_cart_dialog.dart';

class DishDetailScreen extends ConsumerWidget {
  const DishDetailScreen({super.key, required this.dishId});

  final String dishId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishAsync = ref.watch(dishByIdProvider(dishId));

    return dishAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Error: $err')),
      ),
      data: (dish) {
        if (dish == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Dish not found', style: AppTextStyles.headlineMedium),
                  ElevatedButton(
                    onPressed: () => context.go('/feed'),
                    child: const Text('Go to Feed'),
                  ),
                ],
              ),
            ),
          );
        }
        return _DishDetailContent(dish: dish);
      },
    );
  }
}

class _DishDetailContent extends ConsumerWidget {
  const _DishDetailContent({required this.dish});

  final DishModel dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverToBoxAdapter(
            child: SizedBox(
              height: size.height * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (dish.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: dish.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: Text('🍽️', style: TextStyle(fontSize: 80)),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Text('🍽️', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Restaurant + cuisine row
                Row(
                  children: [
                    _InfoChip(text: dish.restaurantName, color: AppColors.primary),
                    const SizedBox(width: 8),
                    _InfoChip(text: dish.cuisine, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: 16),

                // Dish name
                Text(dish.name, style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),

                // Rating row
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.primary, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.rating.toStringAsFixed(1)} (${dish.reviewCount} reviews)',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${dish.estimatedDeliveryMinutes} min',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 16),

                // Description
                Text('About this dish', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  dish.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Spice level
                _DetailRow(
                  icon: '🌶️',
                  label: 'Spice Level',
                  value: dish.spiceLevelLabel,
                ),
                const SizedBox(height: 12),

                // Dietary tags
                if (dish.dietaryTags.isNotEmpty) ...[
                  Text('Dietary Info', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dish.dietaryTags.map((tag) {
                      return Chip(
                        label: Text(tag.name),
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                        ),
                        side: BorderSide(color: AppColors.success.withOpacity(0.3)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Ingredients
                if (dish.ingredients.isNotEmpty) ...[
                  Text('Ingredients', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dish.ingredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: AppTextStyles.labelMedium,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Reviews Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reviews', style: AppTextStyles.headlineSmall),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildReviewItem('Fatima Ahmed', 5, 'Absolutely delicious! The spices were perfect. Highly recommend.', '2 days ago'),
                const Divider(height: 32, color: AppColors.surfaceLighter),
                _buildReviewItem('Umar Farooq', 4, 'Very good taste, but delivery was a bit slow today.', '5 days ago'),
                
                const SizedBox(height: 80), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price', style: AppTextStyles.bodySmall),
                Text(dish.priceFormatted, style: AppTextStyles.priceLarge),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 56,
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
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (ctx) => AddToCartBottomSheet(dish: dish),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String name, int rating, String comment, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: AppTextStyles.titleMedium),
            Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: AppColors.primary,
            size: 14,
          )),
        ),
        const SizedBox(height: 8),
        Text(comment, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value, style: AppTextStyles.titleMedium),
      ],
    );
  }
}
