import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/customer/presentation/screens/customer_shell.dart';
import '../../features/customer/presentation/screens/home_feed_screen.dart';
import '../../features/customer/presentation/screens/search_screen.dart';
import '../../features/customer/presentation/screens/dish_detail_screen.dart';
import '../../features/customer/presentation/screens/cart_screen.dart';
import '../../features/customer/presentation/screens/checkout_screen.dart';
import '../../features/customer/presentation/screens/order_confirmation_screen.dart';
import '../../features/customer/presentation/screens/order_tracking_screen.dart';
import '../../features/customer/presentation/screens/profile_screen.dart';
import '../../features/customer/presentation/screens/edit_profile_screen.dart';
import '../../features/customer/presentation/screens/address_management_screen.dart';
import '../../features/owner/presentation/screens/owner_shell.dart';
import '../../features/owner/presentation/screens/owner_dashboard_screen.dart';
import '../../features/owner/presentation/screens/owner_orders_screen.dart';
import '../../features/owner/presentation/screens/order_detail_screen.dart';
import '../../features/owner/presentation/screens/menu_management_screen.dart';
import '../../features/owner/presentation/screens/add_edit_dish_screen.dart';
import '../../features/owner/presentation/screens/owner_analytics_screen.dart';
import '../../features/owner/presentation/screens/owner_profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState != null;
      final isOnAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isOnAuthRoute) {
        return '/auth/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Customer Routes
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => const HomeFeedScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Customer Detail Routes (outside shell)
      GoRoute(
        path: '/dish/:dishId',
        builder: (context, state) =>
            DishDetailScreen(dishId: state.pathParameters['dishId']!),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressManagementScreen(),
      ),

      // Owner Routes
      ShellRoute(
        builder: (context, state, child) => OwnerShell(child: child),
        routes: [
          GoRoute(
            path: '/owner/dashboard',
            builder: (context, state) => const OwnerDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/orders',
            builder: (context, state) => const OwnerOrdersScreen(),
          ),
          GoRoute(
            path: '/owner/menu',
            builder: (context, state) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: '/owner/analytics',
            builder: (context, state) => const OwnerAnalyticsScreen(),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (context, state) => const OwnerProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/owner/order/:orderId',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/owner/dish/add',
        builder: (context, state) => const AddEditDishScreen(),
      ),
      GoRoute(
        path: '/owner/dish/edit/:dishId',
        builder: (context, state) => AddEditDishScreen(
          dishId: state.pathParameters['dishId'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 48,
                    color: Color(0xFFFFCE1B),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}',
                style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
