import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';

class OwnerAnalyticsScreen extends ConsumerWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Analytics', style: AppTextStyles.headlineLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Row(
              children: ['Today', 'Week', 'Month', 'Year']
                  .asMap()
                  .entries
                  .map((e) => _PeriodChip(
                        label: e.value,
                        isActive: e.key == 1,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Revenue chart (mock)
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue', style: AppTextStyles.bodyMedium),
                  Text('Rs. 28,450', style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.accent,
                  )),
                  Text('+18.5% vs last week', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  )),
                  const Spacer(),
                  _MockChart(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stat cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _AnalyticsCard(
                  title: 'Total Orders',
                  value: '186',
                  delta: '+12',
                  isPositive: true,
                  emoji: '📦',
                  color: AppColors.primary,
                ),
                _AnalyticsCard(
                  title: 'Avg Order Value',
                  value: 'Rs. 482',
                  delta: '+Rs. 32',
                  isPositive: true,
                  emoji: '💰',
                  color: AppColors.success,
                ),
                _AnalyticsCard(
                  title: 'Cancellations',
                  value: '4',
                  delta: '-2',
                  isPositive: true,
                  emoji: '❌',
                  color: AppColors.error,
                ),
                _AnalyticsCard(
                  title: 'Avg Rating',
                  value: '4.8',
                  delta: '+0.2',
                  isPositive: true,
                  emoji: '⭐',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top dishes
            Text('Top Dishes This Week', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ..._getTopDishes().asMap().entries.map((e) {
              return _TopDishRow(rank: e.key + 1, dish: e.value);
            }),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTopDishes() {
    return [
      {'name': 'Butter Chicken', 'orders': 64, 'revenue': 'Rs. 20,480'},
      {'name': 'Chicken Biryani', 'orders': 48, 'revenue': 'Rs. 21,600'},
      {'name': 'Paneer Tikka', 'orders': 35, 'revenue': 'Rs. 10,500'},
      {'name': 'Karahi', 'orders': 29, 'revenue': 'Rs. 11,600'},
    ];
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: isActive ? Colors.black : AppColors.textMuted,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _MockChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 1.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((h) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 40 * h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.isPositive,
    required this.emoji,
    required this.color,
  });

  final String title;
  final String value;
  final String delta;
  final bool isPositive;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const Spacer(),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(title, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            delta,
            style: AppTextStyles.bodySmall.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopDishRow extends StatelessWidget {
  const _TopDishRow({required this.rank, required this.dish});

  final int rank;
  final Map<String, dynamic> dish;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppColors.primary
                  : rank == 2
                      ? AppColors.textSecondary
                      : AppColors.accent.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dish['name'] as String, style: AppTextStyles.titleMedium),
                Text('${dish['orders']} orders', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            dish['revenue'] as String,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
