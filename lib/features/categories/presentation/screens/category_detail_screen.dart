import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/categories/presentation/providers/category_provider.dart';
import 'package:xpense/domain/repositories/category_repository.dart';
import 'package:xpense/features/categories/presentation/widgets/icon_picker.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({required this.category, super.key});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _hexToColor(category.colorHex);
    final statsAsync = ref.watch(categoryStatsProvider(category.id));
    final subcategoriesAsync = ref.watch(subcategoriesProvider(category.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: color.withValues(alpha: 0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(
                          IconPicker.iconDataFromName(category.iconName),
                          color: color,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push(
                  '/categories/add',
                  extra: category,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats cards
                statsAsync.when(
                  data: (stats) => _StatsGrid(stats: stats, color: color),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Subcategories section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subcategories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _addSubcategory(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                subcategoriesAsync.when(
                  data: (subs) {
                    if (subs.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.folder_open,
                            color: theme.colorScheme.outline,
                          ),
                          title: Text(
                            'No subcategories',
                            style: TextStyle(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: subs.map((sub) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _hexToColor(sub.colorHex)
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                IconPicker.iconDataFromName(sub.iconName),
                                color: _hexToColor(sub.colorHex),
                                size: 18,
                              ),
                            ),
                            title: Text(sub.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteSubcategory(context, ref, sub),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubcategory(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g., Fast Food',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final repo = ref.read(categoryRepositoryProvider);
              await repo.create(
                CategoryInput(
                  name: name,
                  iconName: category.iconName,
                  colorHex: category.colorHex,
                  parentId: category.id,
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
                // Invalidate providers to refresh
                ref.invalidate(subcategoriesProvider(category.id));
                ref.invalidate(categoriesProvider);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubcategory(
    BuildContext context,
    WidgetRef ref,
    Category sub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text('Delete "${sub.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      HapticService.warning();
      final repo = ref.read(categoryRepositoryProvider);
      await repo.delete(sub.id);
      ref.invalidate(subcategoriesProvider(category.id));
      ref.invalidate(categoriesProvider);
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.color});

  final CategoryStats stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'This Month',
            value: currency.format(stats.totalSpentCents / 100),
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Transactions',
            value: '${stats.transactionCount}',
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Average',
            value: currency.format(stats.averageCents / 100),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
