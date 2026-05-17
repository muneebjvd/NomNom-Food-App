import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../providers/dish_provider.dart';
import '../widgets/add_to_cart_dialog.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isSearching = false;
  List<DishModel> _results = [];
  bool _hasSearched = false;
  String _aiSuggestion = '';
  late AnimationController _micController;

  final List<Map<String, String>> _quickSuggestions = [
    {'emoji': '🔥', 'label': 'Spicy Pakistani'},
    {'emoji': '🥗', 'label': 'Vegetarian'},
    {'emoji': '💰', 'label': 'Under Rs. 300'},
    {'emoji': '⭐', 'label': 'Highly Rated'},
    {'emoji': '🍗', 'label': 'Chicken'},
    {'emoji': '🥘', 'label': 'Biryani'},
    {'emoji': '🌶️', 'label': 'Karahi'},
    {'emoji': '🥙', 'label': 'Halal Food'},
  ];

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _micController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _aiSuggestion = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    // Unfocus keyboard
    _focusNode.unfocus();

    try {
      final filters = await _parseQueryWithAI(trimmed);
      final dishes = await ref.read(dishRepositoryProvider).searchDishes(
            cuisine: filters['cuisine'],
            maxPrice: filters['maxPrice'],
            dietaryTags: filters['dietaryTags'] as List<String>?,
            spiceLevel: filters['spiceLevel'],
            query: trimmed,
          );

      if (mounted) {
        setState(() {
          _results = dishes;
          _isSearching = false;
          _aiSuggestion = _buildAISuggestionText(filters, trimmed);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _results = [];
        });
      }
    }
  }

  String _buildAISuggestionText(Map<String, dynamic> filters, String query) {
    final parts = <String>[];
    if (filters['cuisine'] != null) parts.add('Cuisine: ${filters['cuisine']}');
    if (filters['maxPrice'] != null) parts.add('Under Rs. ${filters['maxPrice']}');
    if (filters['spiceLevel'] != null) parts.add('Spice: ${filters['spiceLevel']}');
    if (filters['dietaryTags'] != null &&
        (filters['dietaryTags'] as List).isNotEmpty) {
      parts.add('Diet: ${(filters['dietaryTags'] as List).join(', ')}');
    }
    if (parts.isEmpty) return '';
    return '🤖 AI matched: ${parts.join(' • ')}';
  }

  Future<Map<String, dynamic>> _parseQueryWithAI(String query) async {
    final result = <String, dynamic>{};
    final lower = query.toLowerCase();

    // Price extraction
    final priceRegex =
        RegExp(r'under\s*(?:rs\.?\s*)?([\d,]+)', caseSensitive: false);
    final priceMatch = priceRegex.firstMatch(lower);
    if (priceMatch != null) {
      final val = priceMatch.group(1)?.replaceAll(',', '');
      result['maxPrice'] = double.tryParse(val ?? '');
    }

    // Pakistani cuisine detection
    const cuisineMap = {
      'pakistani': 'Pakistani',
      'desi': 'Pakistani',
      'karahi': 'Pakistani',
      'biryani': 'Pakistani',
      'nihari': 'Pakistani',
      'haleem': 'Pakistani',
      'paye': 'Pakistani',
      'chaat': 'Pakistani',
      'burger': 'Pakistani',
      'american': 'Pakistani',
      'healthy': 'Pakistani',
      'chinese': 'Pakistani',
    };
    for (final entry in cuisineMap.entries) {
      if (lower.contains(entry.key)) {
        result['cuisine'] = entry.value;
        break;
      }
    }

    // Dietary
    final tags = <String>[];
    if (lower.contains('vegan')) tags.add('vegan');
    if (lower.contains('vegetarian') ||
        lower.contains('veg ') ||
        lower.contains('sabzi')) tags.add('vegetarian');
    if (lower.contains('gluten')) tags.add('glutenFree');
    if (lower.contains('halal')) tags.add('halal');
    if (tags.isNotEmpty) result['dietaryTags'] = tags;

    // Spice
    if (lower.contains('spicy') ||
        lower.contains('hot') ||
        lower.contains('tez') ||
        lower.contains('teekha')) {
      result['spiceLevel'] = 'hot';
    } else if (lower.contains('mild') || lower.contains('light')) {
      result['spiceLevel'] = 'mild';
    }

    return result;
  }

  Future<void> _startListening() async {
    final available = await _speechToText.initialize(
      onError: (err) => setState(() => _isListening = false),
    );
    if (available && mounted) {
      setState(() => _isListening = true);
      HapticFeedback.lightImpact();
      _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            _searchController.text = result.recognizedWords;
            if (result.finalResult) {
              setState(() => _isListening = false);
              _search(result.recognizedWords);
            }
          }
        },
        localeId: 'en_US',
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Search', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Describe what you\'re craving in Urdu or English',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // ── Search bar ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? AppColors.primary
                                  : AppColors.surfaceLighter,
                              width: _focusNode.hasFocus ? 2 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: AppTextStyles.bodyLarge,
                            textInputAction: TextInputAction.search,
                            onChanged: (v) => setState(() {}),
                            // FIX: onSubmitted triggers _search on Enter
                            onSubmitted: (v) => _search(v),
                            decoration: InputDecoration(
                              hintText:
                                  '"Something spicy and halal under Rs. 400"',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.primary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: AppColors.textMuted),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _results = [];
                                          _hasSearched = false;
                                          _aiSuggestion = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Mic button
                      GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? AppColors.error
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? AppColors.error
                                        : AppColors.primary)
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search button
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _search(_searchController.text),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Search Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  // AI suggestion tag
                  if (_aiSuggestion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Text(
                        _aiSuggestion,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Results Area ──────────────────────────────────────────────
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text(
                            '🤖 Searching menu...',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : _hasSearched
                      ? _results.isEmpty
                          ? _buildNoResults()
                          : _buildResults()
                      : _buildSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No dishes found', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different search like "chicken karahi" or "halal burger"',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _results = [];
                _hasSearched = false;
                _aiSuggestion = '';
              });
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try these...', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  final query = '${s['emoji']} ${s['label']}';
                  _searchController.text = s['label']!;
                  _search(query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surfaceLighter),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    '${s['emoji']} ${s['label']}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('AI Search Tips', style: AppTextStyles.titleLarge),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  '"Something spicy and halal under Rs. 400"',
                  '"Vegetarian karahi options"',
                  '"Quick delivery biryani"',
                  '"Teekha aur halal khaana"',
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $tip',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${_results.length} result${_results.length == 1 ? '' : 's'} found',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SearchResultCard(dish: _results[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.dish});
  final DishModel dish;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dish/${dish.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLighter),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: dish.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: dish.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _FallbackImage(dish: dish),
                    )
                  : _FallbackImage(dish: dish),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 2),
                  Text(dish.restaurantName,
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Rs. ${dish.price.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star,
                          color: AppColors.primary, size: 14),
                      Text(' ${dish.rating}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => AddToCartBottomSheet(dish: dish),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(60, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.dish});
  final DishModel dish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '🍛',
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
