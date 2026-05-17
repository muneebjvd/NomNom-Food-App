import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/dish_model.dart';
import '../../../../features/customer/providers/dish_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class AddEditDishScreen extends ConsumerStatefulWidget {
  const AddEditDishScreen({super.key, this.dishId});
  final String? dishId;

  @override
  ConsumerState<AddEditDishScreen> createState() => _AddEditDishScreenState();
}

class _AddEditDishScreenState extends ConsumerState<AddEditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cuisineController = TextEditingController(text: 'Pakistani');
  final _imageUrlController = TextEditingController();

  SpiceLevel _spiceLevel = SpiceLevel.medium;
  final List<DietaryTag> _selectedTags = [DietaryTag.halal];
  bool _isAvailable = true;
  bool _isSaving = false;
  File? _pickedImage;

  bool get isEditing => widget.dishId != null;

  // Pakistani restaurant image URLs for default
  final List<String> _defaultImages = [
    'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=800',
    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800',
    'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800',
    'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=800',
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadExistingDish();
    }
  }

  Future<void> _loadExistingDish() async {
    final dish = await ref.read(dishRepositoryProvider).getDishById(widget.dishId!);
    if (dish != null && mounted) {
      setState(() {
        _nameController.text = dish.name;
        _descriptionController.text = dish.description;
        _priceController.text = dish.price.toStringAsFixed(0);
        _cuisineController.text = dish.cuisine;
        _imageUrlController.text = dish.imageUrl ?? '';
        _spiceLevel = dish.spiceLevel;
        _selectedTags.clear();
        _selectedTags.addAll(dish.dietaryTags);
        _isAvailable = dish.isAvailable;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cuisineController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (xFile != null) {
        setState(() => _pickedImage = File(xFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate price
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Choose image URL
      String imageUrl;
      if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      } else {
        // Use a default Pakistani food image based on dish name
        final nameHash = _nameController.text.hashCode.abs();
        imageUrl = _defaultImages[nameHash % _defaultImages.length];
      }

      final user = ref.read(currentUserModelProvider);
      final rId = user?.id ?? 'demo_owner_1';
      final rName = user?.name ?? 'My Kitchen';

      final dish = DishModel(
        id: widget.dishId ?? '',
        restaurantId: rId,
        restaurantName: rName,
        restaurantLat: 31.5204, // Use center Lahore for owner's default location
        restaurantLng: 74.3587,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'A delicious ${_nameController.text.trim()} prepared with fresh Pakistani spices.'
            : _descriptionController.text.trim(),
        price: price,
        imageUrl: imageUrl,
        cuisine: _cuisineController.text.trim().isEmpty
            ? 'Pakistani'
            : _cuisineController.text.trim(),
        ingredients: [],
        dietaryTags: _selectedTags,
        spiceLevel: _spiceLevel,
        rating: 4.5,
        reviewCount: 0,
        estimatedDeliveryMinutes: 30,
        isAvailable: _isAvailable,
        isFeatured: false,
        orderCount: 0,
      );

      if (isEditing) {
        await ref.read(dishRepositoryProvider).updateDish(dish);
      } else {
        await ref.read(dishRepositoryProvider).addDish(dish);
      }

      // Invalidate the feed so changes appear within 2s
      ref.invalidate(dishFeedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? '✅ Dish updated successfully!'
                : '✅ Dish added to menu! It will appear in the customer feed shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Use pop() to go back — this fixes the back navigation issue
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/owner/menu');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dish: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // CRITICAL: always reset _isSaving to prevent infinite loading
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          isEditing ? 'Edit Dish' : 'Add New Dish',
          style: AppTextStyles.headlineLarge,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/owner/menu');
            }
          },
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Image Picker ─────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover,
                            width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Add Dish Photo',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Tap to upload from gallery',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Or URL input
            _buildTextField(
              controller: _imageUrlController,
              label: 'Or Paste Image URL',
              hint: 'https://...',
              icon: Icons.link,
            ),
            const SizedBox(height: 20),

            // ── Dish Name ─────────────────────────────────────────────────
            _buildTextField(
              controller: _nameController,
              label: 'Dish Name *',
              hint: 'e.g. Chicken Karahi',
              icon: Icons.restaurant_menu,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Please enter dish name' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────────────
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your dish...',
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // ── Price & Cuisine ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price (Rs.) *',
                    hint: '299',
                    icon: Icons.money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty == true) return 'Enter price';
                      if (double.tryParse(v!.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _cuisineController,
                    label: 'Cuisine',
                    hint: 'Pakistani',
                    icon: Icons.flag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Spice Level ───────────────────────────────────────────────
            Text('Spice Level', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: SpiceLevel.values.map((level) {
                final isSelected = _spiceLevel == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _spiceLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLighter,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              _getSpiceEmoji(level),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSpiceLabel(level),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Dietary Tags ──────────────────────────────────────────────
            Text('Dietary Tags', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DietaryTag.vegetarian,
                DietaryTag.vegan,
                DietaryTag.glutenFree,
                DietaryTag.halal,
                DietaryTag.spicy,
              ].map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(_getTagLabel(tag)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryDark,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceLighter,
                  ),
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Availability ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceLighter),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Text('Available on menu', style: AppTextStyles.titleMedium),
                  const Spacer(),
                  Switch(
                    value: _isAvailable,
                    onChanged: (val) => setState(() => _isAvailable = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────────────────
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Add to Menu',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceLighter),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceLighter),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium,
        labelStyle: AppTextStyles.bodySmall,
      ),
    );
  }

  String _getSpiceEmoji(SpiceLevel level) {
    switch (level) {
      case SpiceLevel.none:
        return '😐';
      case SpiceLevel.mild:
        return '🌶️';
      case SpiceLevel.medium:
        return '🌶️🌶️';
      case SpiceLevel.hot:
        return '🌶️🌶️🌶️';
      case SpiceLevel.extraHot:
        return '🔥🔥';
    }
  }

  String _getSpiceLabel(SpiceLevel level) {
    switch (level) {
      case SpiceLevel.none:
        return 'None';
      case SpiceLevel.mild:
        return 'Mild';
      case SpiceLevel.medium:
        return 'Medium';
      case SpiceLevel.hot:
        return 'Hot';
      case SpiceLevel.extraHot:
        return 'Extra';
    }
  }

  String _getTagLabel(DietaryTag tag) {
    switch (tag) {
      case DietaryTag.vegetarian:
        return '🥦 Vegetarian';
      case DietaryTag.vegan:
        return '🌱 Vegan';
      case DietaryTag.glutenFree:
        return '✨ Gluten-Free';
      case DietaryTag.dairyFree:
        return '🥛 Dairy-Free';
      case DietaryTag.nutFree:
        return '🚫 Nut-Free';
      case DietaryTag.keto:
        return '💪 Keto';
      case DietaryTag.halal:
        return '☪️ Halal';
      case DietaryTag.spicy:
        return '🌶️ Spicy';
    }
  }
}
