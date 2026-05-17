import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/utils/mock_database.dart';

/// Polls both Firestore and MockDatabase every 2 seconds.
final ownerOrdersProvider = StreamProvider<List<OrderModel>>((ref) async* {
  // Yield immediately from local cache
  yield MockDatabase.instance.getOrders();

  // Then poll every 2 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
    List<OrderModel> firestoreOrders = [];

    // Try Firestore
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap.docs.isNotEmpty) {
        firestoreOrders = snap.docs.map((doc) {
          final data = doc.data();
          return OrderModel.fromJson({...data, 'id': doc.id});
        }).toList();

        // Merge with local: local takes precedence for status (owner updated locally)
        final localOrders = MockDatabase.instance.getOrders();
        final localById = {for (var o in localOrders) o.id: o};

        final merged = <String, OrderModel>{};
        // Add Firestore orders
        for (final o in firestoreOrders) {
          merged[o.id] = o;
        }
        // Local orders override (newer status info)
        for (final o in localOrders) {
          if (!merged.containsKey(o.id) ||
              (o.updatedAt ?? DateTime(0))
                  .isAfter(merged[o.id]!.updatedAt ?? DateTime(0))) {
            merged[o.id] = o;
          }
        }

        final list = merged.values.toList()
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        // Persist merged list locally
        await MockDatabase.instance.saveOrders(list);
        yield list;
        continue;
      }
    } catch (_) {}

    // Firestore failed or empty — yield local
    yield MockDatabase.instance.getOrders();
  }
});

class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ownerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Orders', style: AppTextStyles.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.invalidate(ownerOrdersProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.labelLarge,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Error loading orders', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(ownerOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          final active = orders
              .where((o) =>
                  o.status != OrderStatus.delivered &&
                  o.status != OrderStatus.cancelled &&
                  o.status != OrderStatus.pending)
              .toList();
          final pending =
              orders.where((o) => o.status == OrderStatus.pending).toList();
          final completed = orders
              .where((o) =>
                  o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.cancelled)
              .toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Orders will appear here once customers place them',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(active),
              _buildOrderList(pending),
              _buildOrderList(completed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No orders here', style: AppTextStyles.headlineMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OwnerOrderCard(
        order: orders[index],
        onStatusChanged: () => ref.invalidate(ownerOrdersProvider),
      ),
    );
  }
}

class _OwnerOrderCard extends ConsumerStatefulWidget {
  const _OwnerOrderCard({required this.order, required this.onStatusChanged});
  final OrderModel order;
  final VoidCallback onStatusChanged;

  @override
  ConsumerState<_OwnerOrderCard> createState() => _OwnerOrderCardState();
}

class _OwnerOrderCardState extends ConsumerState<_OwnerOrderCard> {
  late OrderStatus _currentStatus;
  bool _isAdvancing = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  void didUpdateWidget(_OwnerOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status) {
      _currentStatus = widget.order.status;
    }
  }

  Future<void> _advanceStatus() async {
    final next = _currentStatus.next;
    if (next == null) return;

    setState(() => _isAdvancing = true);

    try {
      // Update local immediately
      await MockDatabase.instance.updateOrderStatus(widget.order.id, next);

      // Try Firestore
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.order.id)
            .update({
              'status': next.name,
              'updatedAt': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 3));
      } catch (_) {}

      setState(() {
        _currentStatus = next;
        _isAdvancing = false;
      });

      widget.onStatusChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Order → ${next.label} ${next.emoji}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAdvancing = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel Order',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    await MockDatabase.instance
        .updateOrderStatus(widget.order.id, OrderStatus.cancelled);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
            'status': 'cancelled',
            'updatedAt': DateTime.now().toIso8601String()
          })
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    setState(() {
      _currentStatus = OrderStatus.cancelled;
      _isCancelling = false;
    });
    widget.onStatusChanged();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentStatus);
    final canAdvance = _currentStatus.next != null &&
        _currentStatus != OrderStatus.cancelled &&
        _currentStatus != OrderStatus.delivered;
    final canCancel = _currentStatus != OrderStatus.cancelled &&
        _currentStatus != OrderStatus.delivered &&
        _currentStatus != OrderStatus.outForDelivery;

    return GestureDetector(
      onTap: () => context.push('/owner/order/${widget.order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${widget.order.id.length > 8 ? widget.order.id.substring(0, 8).toUpperCase() : widget.order.id}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_currentStatus.emoji} ${_currentStatus.label}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.order.customerName,
                      style: AppTextStyles.bodyLarge),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rs. ${widget.order.total.toStringAsFixed(0)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              widget.order.items
                  .map((i) => '${i.quantity}x ${i.dishName}')
                  .join(', '),
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.order.deliveryAddress,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (canAdvance || canCancel) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canCancel)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: (_isCancelling || _isAdvancing)
                            ? null
                            : _cancelOrder,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isCancelling
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.error))
                            : Text('Cancel',
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.error)),
                      ),
                    ),
                  if (canCancel && canAdvance) const SizedBox(width: 8),
                  if (canAdvance)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (_isAdvancing || _isCancelling)
                            ? null
                            : _advanceStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isAdvancing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                '${_currentStatus.next?.emoji ?? ''} ${_currentStatus.next?.label ?? ''}',
                                style: AppTextStyles.labelLarge,
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
