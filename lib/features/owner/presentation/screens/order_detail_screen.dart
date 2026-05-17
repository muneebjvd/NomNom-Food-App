import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/utils/mock_database.dart';
import 'owner_orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadOrder() {
    final order = MockDatabase.instance.getOrderById(widget.orderId);
    setState(() => _order = order);
  }

  Future<void> _advanceStatus() async {
    final order = _order;
    if (order == null) return;
    final next = order.status.next;
    if (next == null) return;

    setState(() => _isLoading = true);

    await MockDatabase.instance.updateOrderStatus(order.id, next);
    _loadOrder();

    ref.invalidate(ownerOrdersProvider);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Status → ${next.label} ${next.emoji}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('Order Details', style: AppTextStyles.headlineLarge),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Order not found', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Order ID: ${widget.orderId.substring(0, 8)}...',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final statusColor = _getStatusColor(order.status);
    final canAdvance = order.status.next != null &&
        order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.delivered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Order Details', style: AppTextStyles.headlineLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: canAdvance
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _advanceStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            '→ Mark as: ${order.status.next?.label ?? ''} ${order.status.next?.emoji ?? ''}',
                            style: AppTextStyles.titleLarge,
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.2),
                    AppColors.background,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(order.status.emoji,
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(order.status.label,
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Placed ${_formatTime(order.createdAt!)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer info
            _SectionCard(
              title: '👤 Customer',
              child: Column(
                children: [
                  _InfoRow('Name', order.customerName),
                  const Divider(height: 20),
                  _InfoRow('Delivery', order.deliveryAddress),
                  if (order.courierName.isNotEmpty) ...[
                    const Divider(height: 20),
                    _InfoRow('Courier',
                        '${order.courierName} (${order.courierVehicle})'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items
            _SectionCard(
              title: '🛒 Order Items',
              child: Column(
                children: order.items.asMap().entries.map((e) {
                  final item = e.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.dishName,
                                style: AppTextStyles.bodyLarge),
                          ),
                          Text(
                            'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: AppTextStyles.titleMedium,
                          ),
                        ],
                      ),
                      if (e.key < order.items.length - 1)
                        const Divider(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Price breakdown
            _SectionCard(
              title: '💰 Price Summary',
              child: Column(
                children: [
                  _PriceRow(
                      'Subtotal', 'Rs. ${order.subtotal.toStringAsFixed(0)}'),
                  _PriceRow('Delivery Fee',
                      'Rs. ${order.deliveryFee.toStringAsFixed(0)}'),
                  _PriceRow('Service Fee',
                      'Rs. ${order.serviceFee.toStringAsFixed(0)}'),
                  _PriceRow('Tax', 'Rs. ${order.tax.toStringAsFixed(0)}'),
                  if (order.discount > 0)
                    _PriceRow('Discount',
                        '- Rs. ${order.discount.toStringAsFixed(0)}'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.headlineMedium),
                      Text(
                        'Rs. ${order.total.toStringAsFixed(0)}',
                        style: AppTextStyles.priceLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.outForDelivery:
        return AppColors.statusOutForDelivery;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
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
          width: 80,
          child: Text(label,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.titleMedium),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
