import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/models/user_model.dart';
import 'map_picker_screen.dart';

class AddressManagementScreen extends ConsumerStatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  ConsumerState<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState
    extends ConsumerState<AddressManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(user),
        label: const Text('Add Address',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      body: user.addresses.isEmpty
          ? _buildEmptyState(user)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: user.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _AddressCard(
                  address: user.addresses[index],
                  isDefault: index == 0,
                  onSetDefault: index > 0
                      ? () => _setDefault(user, index)
                      : null,
                  onDelete: () => _deleteAddress(user, index),
                  onEdit: () => _editAddress(user, index),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(UserModel user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📍', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 20),
          Text('No addresses saved', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Add your delivery addresses\nfor faster checkout',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddSheet(user),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add First Address'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSheet(UserModel user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAddressSheet(
        onAddManual: (addr) async {
          Navigator.pop(ctx);
          await _addAddress(user, addr);
        },
        onOpenMap: () async {
          Navigator.pop(ctx);
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
                builder: (_) => const MapPickerScreen()),
          );
          if (result != null && result.isNotEmpty && mounted) {
            await _addAddress(user, result);
          }
        },
      ),
    );
  }

  Future<void> _addAddress(UserModel user, String address) async {
    if (address.isEmpty) return;
    final updated = [...user.addresses, address];
    final updatedUser = user.copyWith(addresses: updated);
    await ref.read(authRepositoryProvider).updateUser(updatedUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Address added!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteAddress(UserModel user, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text(user.addresses[index]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final updated = List<String>.from(user.addresses)..removeAt(index);
    await ref
        .read(authRepositoryProvider)
        .updateUser(user.copyWith(addresses: updated));
  }

  Future<void> _setDefault(UserModel user, int index) async {
    final updated = List<String>.from(user.addresses);
    final addr = updated.removeAt(index);
    updated.insert(0, addr);
    await ref
        .read(authRepositoryProvider)
        .updateUser(user.copyWith(addresses: updated));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Default address updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _editAddress(UserModel user, int index) async {
    final controller =
        TextEditingController(text: user.addresses[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Address'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter address',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updated = List<String>.from(user.addresses);
      updated[index] = result;
      await ref
          .read(authRepositoryProvider)
          .updateUser(user.copyWith(addresses: updated));
    }
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({
    required this.onAddManual,
    required this.onOpenMap,
  });
  final ValueChanged<String> onAddManual;
  final VoidCallback onOpenMap;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Add Delivery Address', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 20),

            // Map option
            GestureDetector(
              onTap: widget.onOpenMap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.map_outlined,
                          color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick on Map',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                        Text('Use Google Maps to pin location',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            // Manual input
            TextField(
              controller: _controller,
              style: AppTextStyles.bodyLarge,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type address: House 12, Block C, DHA Lahore',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.surfaceLighter),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) widget.onAddManual(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Save Address',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onDelete,
    required this.onEdit,
    this.onSetDefault,
  });

  final String address;
  final bool isDefault;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.surfaceLighter,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDefault
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on,
                  color: isDefault ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('DEFAULT',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            )),
                      ),
                    Text(address, style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onSetDefault != null)
                TextButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Set Default'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
