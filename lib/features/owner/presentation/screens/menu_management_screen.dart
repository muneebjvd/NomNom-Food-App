import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../../customer/providers/dish_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider);

    // Use mock data for demo
    final dishes = _getMockDishes();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('My Menu', style: AppTextStyles.headlineLarge),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/owner/dish/add'),
              icon: const Icon(Icons.add, size: 18, color: Colors.black),
              label: const Text('Add Dish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      body: dishes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No dishes yet', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/owner/dish/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Dish'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: dishes.length,
              itemBuilder: (context, index) {
                return _DishMenuCard(dish: dishes[index]);
              },
            ),
    );
  }

  List<DishModel> _getMockDishes() {
    return [
      DishModel(
        id: 'dish_1',
        restaurantId: 'rest_1',
        restaurantName: 'Spice Garden',
        name: 'Butter Chicken',
        description: 'Classic creamy tomato curry',
        price: 320.0,
        imageUrl: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=400',
        cuisine: 'Pakistann',
        rating: 4.8,
        reviewCount: 312,
        isAvailable: true,
        orderCount: 1840,
        dietaryTags: [DietaryTag.halal],
        spiceLevel: SpiceLevel.medium,
      ),
      DishModel(
        id: 'dish_2',
        restaurantId: 'rest_1',
        restaurantName: 'Spice Garden',
        name: 'Dal Makhani',
        description: 'Slow-cooked black lentils',
        price: 220.0,
        imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
        cuisine: 'Pakistann',
        rating: 4.6,
        reviewCount: 228,
        isAvailable: true,
        orderCount: 1200,
        dietaryTags: [DietaryTag.vegetarian],
        spiceLevel: SpiceLevel.mild,
      ),
    ];
  }
}

class _DishMenuCard extends ConsumerStatefulWidget {
  const _DishMenuCard({required this.dish});

  final DishModel dish;

  @override
  ConsumerState<_DishMenuCard> createState() => _DishMenuCardState();
}

class _DishMenuCardState extends ConsumerState<_DishMenuCard> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.dish.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: widget.dish.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.dish.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLighter,
                            child: const Center(
                              child: Text('🍽️', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceLighter,
                          child: const Center(
                            child: Text('🍽️', style: TextStyle(fontSize: 32)),
                          ),
                        ),
                ),
                // Unavailable overlay
                if (!_isAvailable)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(
                      child: Text(
                        'Unavailable',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.dish.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.dish.priceFormatted,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/owner/dish/edit/${widget.dish.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLighter,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAvailable = !_isAvailable),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _isAvailable
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isAvailable ? Icons.check : Icons.close,
                            size: 16,
                            color: _isAvailable ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
