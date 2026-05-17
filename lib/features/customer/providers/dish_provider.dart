import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dish_model.dart';
import '../../../core/utils/mock_database.dart';
import '../../auth/providers/auth_provider.dart';

import 'package:geolocator/geolocator.dart';
import 'location_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final dishRepositoryProvider = Provider<DishRepository>((ref) {
  return DishRepository(firestore: ref.watch(firestoreProvider));
});

/// Live feed: polls MockDatabase every 2s so new dishes appear within 5s.
/// Filters dishes to only show those within 5km of the user's current location.
final dishFeedProvider = StreamProvider<List<DishModel>>((ref) async* {
  final repo = ref.watch(dishRepositoryProvider);
  final locationAsync = ref.watch(currentLocationProvider);
  
  // Default to a central Lahore coordinate if location is unavailable so feed isn't completely empty
  final userLat = locationAsync.valueOrNull?.latitude ?? 31.5204;
  final userLng = locationAsync.valueOrNull?.longitude ?? 74.3587;

  await for (final dishes in repo.watchFeed()) {
    // Filter by 5km radius
    final filteredDishes = dishes.where((d) {
      if (d.restaurantLat == null || d.restaurantLng == null) return true;
      
      final distanceInMeters = Geolocator.distanceBetween(
        userLat, userLng,
        d.restaurantLat!, d.restaurantLng!
      );
      
      return distanceInMeters <= 5000; // 5km
    }).toList();
    
    yield filteredDishes;
  }
});

final dishByIdProvider =
    FutureProvider.family<DishModel?, String>((ref, dishId) {
  return ref.watch(dishRepositoryProvider).getDishById(dishId);
});

final restaurantDishesProvider =
    StreamProvider.family<List<DishModel>, String>((ref, restaurantId) {
  return ref.watch(dishRepositoryProvider).watchRestaurantDishes(restaurantId);
});

// ─── Repository ───────────────────────────────────────────────────────────────

class DishRepository {
  const DishRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  List<DishModel> _getLocalDishes() {
    return MockDatabase.instance.getDishesOrSeed();
  }

  /// Stream that yields local dishes immediately, then polls every 2s.
  /// Also tries to get Firestore updates — if Firestore has dishes, those take
  /// priority; otherwise falls back to local.
  Stream<List<DishModel>> watchFeed() async* {
    // Yield immediately from local cache (no waiting)
    yield _getLocalDishes();

    // Poll at 2s intervals
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      // Try Firestore first
      try {
        final snapshot = await _firestore
            .collection('dishes')
            .where('isAvailable', isEqualTo: true)
            .orderBy('isFeatured', descending: true)
            .orderBy('orderCount', descending: true)
            .get()
            .timeout(const Duration(seconds: 2));

        if (snapshot.docs.isNotEmpty) {
          // Merge Firestore dishes with local ones so admin-added dishes appear
          final remoteDishes = snapshot.docs.map((doc) {
            final data = doc.data();
            return DishModel.fromJson({...data, 'id': doc.id});
          }).toList();

          // Merge: Firestore dishes + local dishes not in Firestore
          final remoteIds = remoteDishes.map((d) => d.id).toSet();
          final localOnly = _getLocalDishes()
              .where((d) => !remoteIds.contains(d.id))
              .toList();
          final merged = [...remoteDishes, ...localOnly];
          yield merged;
          continue;
        }
      } catch (_) {}

      // Fallback: yield local dishes (includes admin-added)
      yield _getLocalDishes();
    }
  }

  Stream<List<DishModel>> watchRestaurantDishes(String restaurantId) async* {
    yield _getLocalDishes()
        .where((d) => d.restaurantId == restaurantId)
        .toList();

    await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
      try {
        final snapshot = await _firestore
            .collection('dishes')
            .where('restaurantId', isEqualTo: restaurantId)
            .get()
            .timeout(const Duration(seconds: 2));
        if (snapshot.docs.isNotEmpty) {
          yield snapshot.docs
              .map((doc) => DishModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          continue;
        }
      } catch (_) {}
      yield _getLocalDishes()
          .where((d) => d.restaurantId == restaurantId)
          .toList();
    }
  }

  Future<DishModel?> getDishById(String dishId) async {
    // Check local first (fast)
    final localDish =
        _getLocalDishes().where((d) => d.id == dishId).firstOrNull;
    if (localDish != null) return localDish;

    try {
      final doc = await _firestore
          .collection('dishes')
          .doc(dishId)
          .get()
          .timeout(const Duration(seconds: 2));
      if (!doc.exists) return null;
      return DishModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  Future<String> addDish(DishModel dish) async {
    // Save locally FIRST so it's immediately visible on customer feed
    final dishes = _getLocalDishes();
    final newDish =
        dish.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}');
    dishes.add(newDish);
    await MockDatabase.instance.saveDishes(dishes);

    // Then try Firestore in the background
    try {
      final docRef = await _firestore
          .collection('dishes')
          .add({...newDish.toJson(), 'id': null})
          .timeout(const Duration(seconds: 3));

      // Update local with Firestore ID
      final updatedDish = newDish.copyWith(id: docRef.id);
      final updated = _getLocalDishes();
      final idx = updated.indexWhere((d) => d.id == newDish.id);
      if (idx >= 0) {
        updated[idx] = updatedDish;
        await MockDatabase.instance.saveDishes(updated);
      }
      return docRef.id;
    } catch (_) {
      return newDish.id;
    }
  }

  Future<void> updateDish(DishModel dish) async {
    // Update local
    final dishes = _getLocalDishes();
    final index = dishes.indexWhere((d) => d.id == dish.id);
    if (index >= 0) {
      dishes[index] = dish;
      await MockDatabase.instance.saveDishes(dishes);
    }

    // Try Firestore
    try {
      await _firestore
          .collection('dishes')
          .doc(dish.id)
          .set(dish.toJson())
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> deleteDish(String dishId) async {
    // Delete local
    final dishes = _getLocalDishes();
    dishes.removeWhere((d) => d.id == dishId);
    await MockDatabase.instance.saveDishes(dishes);

    // Try Firestore
    try {
      await _firestore
          .collection('dishes')
          .doc(dishId)
          .delete()
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<List<DishModel>> searchDishes({
    String? cuisine,
    List<String>? dietaryTags,
    double? maxPrice,
    String? spiceLevel,
    String? query,
  }) async {
    var dishes = _getLocalDishes();

    if (cuisine != null && cuisine.isNotEmpty) {
      dishes = dishes
          .where((d) =>
              d.cuisine.toLowerCase().contains(cuisine.toLowerCase()))
          .toList();
    }

    if (maxPrice != null) {
      dishes = dishes.where((d) => d.price <= maxPrice).toList();
    }

    if (dietaryTags != null && dietaryTags.isNotEmpty) {
      dishes = dishes.where((d) {
        final tagNames = d.dietaryTags.map((t) => t.name).toList();
        return dietaryTags.any((tag) => tagNames.contains(tag));
      }).toList();
    }

    if (spiceLevel != null && spiceLevel.isNotEmpty) {
      dishes = dishes
          .where((d) => d.spiceLevel.name == spiceLevel)
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      final stopWords = {'under', 'and', 'with', 'the', 'for', 'me', 'want', 'some', 'please'};
      final words = q.split(' ')
          .where((w) => w.length > 2 && !stopWords.contains(w))
          .toList();

      if (words.isNotEmpty) {
        dishes = dishes.where((d) {
          final name = d.name.toLowerCase();
          final desc = d.description.toLowerCase();
          final cui = d.cuisine.toLowerCase();
          final rest = d.restaurantName.toLowerCase();
          final tags = d.dietaryTags.map((t) => t.name.toLowerCase()).join(' ');

          return words.any((w) =>
              name.contains(w) ||
              desc.contains(w) ||
              cui.contains(w) ||
              rest.contains(w) ||
              tags.contains(w));
        }).toList();
      }
    }

    // Sort by rating if no other sort
    dishes.sort((a, b) => b.rating.compareTo(a.rating));
    return dishes;
  }
}
