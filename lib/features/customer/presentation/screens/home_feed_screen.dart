import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../providers/dish_provider.dart';
import '../../providers/cart_provider.dart';
import '../widgets/add_to_cart_dialog.dart';
import '../widgets/dish_action_buttons.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(dishFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: feedAsync.when(
        loading: () => _buildShimmerFeed(),
        error: (err, _) => _buildErrorState(err),
        data: (dishes) {
          if (dishes.isEmpty) {
            return _buildEmptyState();
          }
          return _buildFeed(dishes);
        },
      ),
    );
  }

  Widget _buildFeed(List<DishModel> dishes) {
    return Stack(
      children: [
        // Main vertical page view (TikTok style)
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: dishes.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            HapticFeedback.lightImpact();
          },
          itemBuilder: (context, index) {
            return _FeedCard(
              dish: dishes[index],
              isActive: index == _currentIndex,
              onAddToCart: () => _showAddToCartDialog(dishes[index]),
            );
          },
        ),

        // Top overlay - App name + actions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'NN',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'NomNom',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 10,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Live badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartDialog(DishModel dish) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AddToCartBottomSheet(dish: dish),
    );
  }

  Widget _buildShimmerFeed() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceLighter,
      child: Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Failed to load feed', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(err.toString(), style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(dishFeedProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text('No dishes yet', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Be the first to add a dish!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends ConsumerStatefulWidget {
  const _FeedCard({
    required this.dish,
    required this.isActive,
    required this.onAddToCart,
  });

  final DishModel dish;
  final bool isActive;
  final VoidCallback onAddToCart;

  @override
  ConsumerState<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<_FeedCard>
    with TickerProviderStateMixin {
  bool _isLiked = false;
  late AnimationController _heartController;
  late AnimationController _addController;
  bool _showHeart = false;
  
  double _dragOffset = 0.0;
  bool _isSwiping = false;
  bool _showCartAdded = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _addController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _addController.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLiked = true;
      _showHeart = true;
    });
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      onTap: () => context.push('/dish/${widget.dish.id}'),
      onHorizontalDragStart: (details) {
        setState(() => _isSwiping = true);
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 || _dragOffset > 0) {
          setState(() {
            _dragOffset += details.delta.dx;
            if (_dragOffset < 0) _dragOffset = 0; // Only allow right swipe
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset > size.width * 0.35) {
          // Trigger add to cart
          HapticFeedback.heavyImpact();
          widget.onAddToCart();
          
          setState(() {
            _showCartAdded = true;
          });
          
          // Animate back to original position
          _addController.forward(from: 0).then((_) {
            setState(() {
              _dragOffset = 0.0;
              _isSwiping = false;
            });
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) setState(() => _showCartAdded = false);
            });
          });
        } else {
          // Not swiped far enough, reset
          setState(() {
            _dragOffset = 0.0;
            _isSwiping = false;
          });
        }
      },
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Underlying swipe-to-add background (revealed during drag)
            if (_isSwiping || _showCartAdded)
              Container(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showCartAdded ? Icons.check_circle : Icons.shopping_cart,
                          color: Colors.black,
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showCartAdded ? 'Added!' : 'Release to Add',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Draggable Foreground Layer
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  _buildBackground(),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.videoOverlay,
              ),
            ),

            // Double tap heart animation
            if (_showHeart)
              Center(
                child: AnimatedBuilder(
                  animation: _heartController,
                  builder: (_, child) {
                    final value = _heartController.value;
                    return Transform.scale(
                      scale: 1.0 + (value < 0.5 ? value * 2 : (1 - value) * 2),
                      child: Opacity(
                        opacity: value < 0.7 ? 1.0 : (1 - value) / 0.3,
                        child: child,
                      ),
                    );
                  },
                  child: const Text('❤️', style: TextStyle(fontSize: 80)),
                ),
              ),

            // Right action buttons
            Positioned(
              right: 16,
              bottom: 140,
              child: DishActionButtons(
                dish: widget.dish,
                isLiked: _isLiked,
                onLike: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isLiked = !_isLiked);
                },
                onAddToCart: widget.onAddToCart,
                onShare: () {},
                onInfo: () => context.push('/dish/${widget.dish.id}'),
              ),
            ),

            // Bottom dish info
            Positioned(
              bottom: 0,
              left: 0,
              right: 80,
              child: _buildDishInfo(),
            ),

            // Swipe hint (shown for first card)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              right: 20,
              child: _buildSwipeHint(),
            ),
          ],
        ),
      ),
      ],
      ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.dish.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.dish.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceLight,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackBackground(),
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceLighter,
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getCuisineEmoji(widget.dish.cuisine),
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  String _getCuisineEmoji(String cuisine) {
    switch (cuisine.toLowerCase()) {
      case 'indian':
        return '🍛';
      case 'japanese':
        return '🍜';
      case 'american':
        return '🍔';
      case 'italian':
        return '🍕';
      case 'healthy':
        return '🥗';
      case 'chinese':
        return '🥡';
      default:
        return '🍽️';
    }
  }

  Widget _buildDishInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restaurant name
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  widget.dish.restaurantName,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Cuisine tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  widget.dish.cuisine,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dish name
          Text(
            widget.dish.name,
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              shadows: [
                const Shadow(
                  blurRadius: 15,
                  color: Colors.black54,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Description (max 2 lines)
          Text(
            widget.dish.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
              shadows: [
                const Shadow(blurRadius: 10, color: Colors.black45),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Price + Rating + Tags row
          Row(
            children: [
              // Price
              Text(
                widget.dish.priceFormatted,
                style: AppTextStyles.priceLarge.copyWith(
                  color: AppColors.primary,
                  shadows: [
                    Shadow(
                      blurRadius: 15,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Rating
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.dish.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Delivery time
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.dish.estimatedDeliveryMinutes} min',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dietary tags
          if (widget.dish.dietaryTags.isNotEmpty)
            Wrap(
              spacing: 6,
              children: widget.dish.dietaryTags.take(3).map((tag) {
                return _DietaryTagChip(tag: tag);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Column(
      children: [
        const Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 20),
        Text(
          'Swipe',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
        ),
      ],
    );
  }
}

class _DietaryTagChip extends StatelessWidget {
  const _DietaryTagChip({required this.tag});

  final DietaryTag tag;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    String emoji;

    switch (tag) {
      case DietaryTag.vegetarian:
        label = 'Veg';
        color = AppColors.success;
        emoji = '🥦';
        break;
      case DietaryTag.vegan:
        label = 'Vegan';
        color = AppColors.success;
        emoji = '🌱';
        break;
      case DietaryTag.glutenFree:
        label = 'GF';
        color = const Color(0xFF9B59B6);
        emoji = '✨';
        break;
      case DietaryTag.halal:
        label = 'Halal';
        color = const Color(0xFF4DA6FF);
        emoji = '☪️';
        break;
      case DietaryTag.spicy:
        label = 'Spicy';
        color = AppColors.accent;
        emoji = '🌶️';
        break;
      default:
        label = tag.name;
        color = AppColors.textSecondary;
        emoji = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$emoji $label',
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
