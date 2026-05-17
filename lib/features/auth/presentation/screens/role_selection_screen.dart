import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Who are you?', style: AppTextStyles.displayMedium),
              const SizedBox(height: 40),
              _RoleButton(
                emoji: '🍔',
                label: 'Customer',
                subtitle: 'Discover and order amazing food',
                gradient: AppColors.primaryGradient,
                onTap: () => context.go('/feed'),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                emoji: '👨‍🍳',
                label: 'Restaurant Owner',
                subtitle: 'Manage your restaurant and orders',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF3B3B)],
                ),
                onTap: () => context.go('/owner/dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.headlineMedium.copyWith(color: Colors.black)),
                Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
