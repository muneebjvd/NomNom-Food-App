import 'dart:math';

void main() {
  final random = Random(42);
  final minLat = 31.42;
  final maxLat = 31.58;
  final minLng = 74.25;
  final maxLng = 74.45;

  final restaurantNames = [
    'Lahore Broast', 'Spice Bazaar', 'Salt n Pepper', 'Monal Lahore',
    'Yasir Broast', 'Bundu Khan', 'Howdy', 'Tabaq', 'Zouk', 'Cafe Aylanto',
    'Gourmet', 'KFC Lahore', 'McDonalds', 'Hardees', 'Subway', 'Pizza Hut',
    'Dominos', 'Cheezious', 'Broadway Pizza', 'Forks n Knives',
    'Charsi Tikka', 'Butt Karahi', 'Nisa Sultan', 'Turkish Kebab', 'Optp',
    'FriChicks', 'Savour Foods', 'Bhaiya Kebab', 'Fazal-e-Haq', 'Nadeem Tikka',
    'Mian Ji', 'Bashir Darul Mahi', 'Bismillah Karahi', 'Waris Nihari',
    'Muhammadi Nihari', 'Haji Nihari', 'Phajjay Ke Paye', 'Capri', 'Amir Broast',
    'Cock N Bull', 'Dogar Restaurant', 'Zakdir Tikka', 'Riaz Falooda',
    'Grato Jalebi', 'Hafiz Sweets', 'Nirala Sweets', 'Chaman Ice Cream',
    'Yousaf Falooda', 'English Tea House', 'Arcadian Cafe'
  ];

  final dishNames = [
    'Biryani', 'Karahi', 'Nihari', 'Haleem', 'Tikka', 'Kebab', 'Pulao',
    'Sajji', 'Shawarma', 'Burger', 'Pizza', 'Pasta', 'Steak', 'Broast'
  ];

  final drinkNames = [
    'Lassi', 'Gatorade', 'Coke', 'Sprite', 'Fanta', 'Pakola', 'Mango Shake',
    'Mint Margarita', 'Lemonade', 'Pina Colada', 'Tea', 'Coffee'
  ];

  print('  List<DishModel> _seedDishes() {');
  print('    return [');

  int dishIdCount = 1;
  for (int i = 0; i < 50; i++) {
    final rName = restaurantNames[i];
    final rId = 'restaurant_${i + 1}';
    final lat = minLat + random.nextDouble() * (maxLat - minLat);
    final lng = minLng + random.nextDouble() * (maxLng - minLng);

    // 2 dishes
    for (int j = 0; j < 2; j++) {
      final dName = '${rName.split(" ").first} ${dishNames[random.nextInt(dishNames.length)]}';
      print('''
      DishModel(
        id: 'dish_pk_\${dishIdCount++}',
        restaurantId: '$rId',
        restaurantName: '$rName',
        restaurantLat: $lat,
        restaurantLng: $lng,
        name: '$dName',
        description: 'Delicious $dName prepared fresh at $rName.',
        price: \${(random.nextInt(100) + 20) * 10.0},
        imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=800',
        cuisine: 'Pakistani',
        ingredients: ['Fresh ingredients', 'Spices'],
        dietaryTags: [DietaryTag.halal],
        spiceLevel: SpiceLevel.medium,
        rating: \${(random.nextDouble() * 1.5 + 3.5).toStringAsFixed(1)},
        reviewCount: \${random.nextInt(500) + 50},
        estimatedDeliveryMinutes: \${random.nextInt(30) + 15},
        isAvailable: true,
        isFeatured: \${random.nextBool()},
        orderCount: \${random.nextInt(1000) + 100},
      ),''');
    }

    // 1 drink
    final drinkName = '${drinkNames[random.nextInt(drinkNames.length)]}';
    print('''
      DishModel(
        id: 'dish_pk_\${dishIdCount++}',
        restaurantId: '$rId',
        restaurantName: '$rName',
        restaurantLat: $lat,
        restaurantLng: $lng,
        name: '$drinkName',
        description: 'Refreshing $drinkName at $rName.',
        price: \${(random.nextInt(20) + 5) * 10.0},
        imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=800',
        cuisine: 'Beverage',
        ingredients: ['Water', 'Flavor'],
        dietaryTags: [DietaryTag.halal, DietaryTag.vegetarian, DietaryTag.vegan],
        spiceLevel: SpiceLevel.none,
        rating: \${(random.nextDouble() * 1.5 + 3.5).toStringAsFixed(1)},
        reviewCount: \${random.nextInt(200) + 20},
        estimatedDeliveryMinutes: \${random.nextInt(20) + 10},
        isAvailable: true,
        isFeatured: false,
        orderCount: \${random.nextInt(500) + 50},
      ),''');
  }

  print('    ];');
  print('  }');
}
