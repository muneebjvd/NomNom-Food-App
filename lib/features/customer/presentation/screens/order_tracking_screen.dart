import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/order_model.dart';

// Order stream provider
final orderStreamProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    return OrderModel.fromJson({...data, 'id': doc.id});
  });
});

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late AnimationController _pulseController;

  // Simulated courier position
  double _courierLat = 31.5204;
  double _courierLng = 74.3587;
  Timer? _simulatorTimer;
  int _simulationStep = 0;

  // Target position (customer)
  static const double _targetLat = 31.5580;
  static const double _targetLng = 74.3507;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _startCourierSimulation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulatorTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startCourierSimulation() {
    _simulatorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final totalSteps = 30;
      if (_simulationStep >= totalSteps) {
        timer.cancel();
        return;
      }

      final progress = _simulationStep / totalSteps;
      final oldStatus = _getStatusFromStep(_simulationStep);
      final newStatus = _getStatusFromStep(_simulationStep + 1);
      
      setState(() {
        _courierLat = _lerp(28.6139, _targetLat, progress);
        _courierLng = _lerp(77.2090, _targetLng, progress);
        _simulationStep++;
      });

      if (oldStatus != newStatus && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Order Status: ${newStatus.label}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _updateMapMarkers();
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _updateMapMarkers() {
    if (!mounted) return;
    setState(() {
      _markers.clear();

      // Courier marker
      _markers.add(Marker(
        markerId: const MarkerId('courier'),
        position: LatLng(_courierLat, _courierLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Ali Khan',
          snippet: '🛵 On the way!',
        ),
      ));

      // Restaurant marker
      _markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: const LatLng(28.6139, 77.2090),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: 'Restaurant', snippet: 'Pickup point'),
      ));

      // Customer marker
      _markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: const LatLng(_targetLat, _targetLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'You', snippet: 'Delivery point'),
      ));

      // Polyline
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_courierLat, _courierLng),
          const LatLng(_targetLat, _targetLng),
        ],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a mock order for demo since Firestore may not be configured
    final mockOrder = OrderModel(
      id: widget.orderId,
      customerId: 'demo',
      customerName: 'Demo Customer',
      restaurantId: 'restaurant_1',
      restaurantName: 'Spice Garden',
      items: [
        OrderItem(
          dishId: 'dish_1',
          dishName: 'Butter Chicken',
          restaurantId: 'restaurant_1',
          price: 320.0,
          quantity: 2,
        )
      ],
      status: _getStatusFromStep(_simulationStep),
      subtotal: 640.0,
      deliveryFee: 49.0,
      serviceFee: 20.0,
      tax: 32.0,
      total: 741.0,
      deliveryAddress: '123 Food Street, New Lahore',
      estimatedMinutes: max(0, 35 - (_simulationStep * 35 ~/ 30)),
      courierName: 'Ali Khan',
      courierVehicle: 'Motorcycle',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Track Order', style: AppTextStyles.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/feed');
          }
        },
        ),
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: _buildMap(),
          ),

          // Order status panel
          Expanded(
            flex: 4,
            child: _buildStatusPanel(mockOrder),
          ),
        ],
      ),
    );
  }

  OrderStatus _getStatusFromStep(int step) {
    if (step < 5) return OrderStatus.pending;
    if (step < 10) return OrderStatus.confirmed;
    if (step < 15) return OrderStatus.preparing;
    if (step < 20) return OrderStatus.ready;
    if (step < 29) return OrderStatus.outForDelivery;
    return OrderStatus.delivered;
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMapMarkers();
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(28.617, 77.212),
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      style: _mapStyle,
    );
  }

  Widget _buildStatusPanel(OrderModel order) {
    final progress = (_simulationStep / 30).clamp(0.0, 1.0);
    final eta = order.estimatedMinutes;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status header
            Row(
              children: [
                Text(
                  order.status.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.status.label,
                        style: AppTextStyles.headlineMedium),
                    if (order.status == OrderStatus.outForDelivery)
                      Text(
                        'ETA: $eta minutes',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Courier info
                if (order.status == OrderStatus.outForDelivery ||
                    order.status == OrderStatus.delivered)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order.courierName, style: AppTextStyles.titleMedium),
                      Text(order.courierVehicle, style: AppTextStyles.bodySmall),
                    ],
                  ),
              ],
            ),
            
            if (order.status == OrderStatus.delivered) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(context, order),
                  icon: const Icon(Icons.star),
                  label: const Text('Leave a Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLighter,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 24),

            // Status timeline
            _buildTimeline(order),

            const SizedBox(height: 20),

            // Order details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow('Restaurant', order.restaurantName),
                  const Divider(height: 20),
                  _InfoRow('Delivery to', order.deliveryAddress),
                  const Divider(height: 20),
                  _InfoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    return Column(
      children: statuses.map((status) {
        final isCompleted = order.status.step >= status.step;
        final isCurrent = order.status == status;

        return Row(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.surfaceLighter,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : Text(
                            status.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
                if (status != statuses.last)
                  Container(
                    width: 2,
                    height: 24,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.surfaceLighter,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: status != statuses.last ? 24 : 0,
                ),
                child: Text(
                  status.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showReviewDialog(BuildContext context, OrderModel order) {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLighter,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('How was your food?', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Rate ${order.restaurantName}', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => rating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us about your experience (optional)',
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLighter),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Add a photo (optional)')),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Upload', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Review submitted! Thank you.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Submit Review', style: AppTextStyles.headlineSmall.copyWith(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.titleMedium),
        ),
      ],
    );
  }
}

// Dark map style JSON
const String? _mapStyle = null; // Will use default map style
