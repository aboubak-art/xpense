import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/utils/color_utils.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/features/categories/presentation/providers/category_provider.dart';
import 'package:xpense/features/categories/presentation/widgets/icon_picker.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryListNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: Icon(_isReordering ? Icons.done : Icons.drag_handle),
            onPressed: () {
              HapticService.mediumImpact();
              setState(() => _isReordering = !_isReordering);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense', icon: Icon(Icons.arrow_downward)),
            Tab(text: 'Income', icon: Icon(Icons.arrow_upward)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(state, isIncome: false),
          _buildCategoryList(state, isIncome: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/categories/add'),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }

  Widget _buildCategoryList(
    AsyncValue<List<Category>> state, {
    required bool isIncome,
  }) {
    return state.when(
      data: (categories) {
        final filtered = categories
            .where((c) => c.isIncome == isIncome && c.parentId == null)
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${isIncome ? 'income' : 'expense'} categories yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        if (_isReordering) {
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            onReorder: (oldIndex, newIndex) {
              final notifier = ref.read(categoryListNotifierProvider.notifier);
              unawaited(notifier.reorder(oldIndex, newIndex));
            },
            itemBuilder: (context, index) {
              final category = filtered[index];
              return _CategoryListTile(
                key: ValueKey(category.id),
                category: category,
                onTap: null,
                showReorderHandle: true,
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final category = filtered[index];
            return _CategoryListTile(
              category: category,
              onTap: () => context.push('/categories/detail', extra: category),
              onArchive: () => _toggleArchive(category),
              onDelete: () => _confirmDelete(category),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _toggleArchive(Category category) async {
    HapticService.warning();
    await ref
        .read(categoryListNotifierProvider.notifier)
        .toggleArchive(category.id, !category.isArchived);
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'This will not delete existing expenses.',
        ),
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

    if ((confirmed ?? false) && mounted) {
      HapticService.warning();
      await ref
          .read(categoryListNotifierProvider.notifier)
          .delete(category.id);
    }
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.showReorderHandle = false,
    super.key,
  });

  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final bool showReorderHandle;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(category.colorHex);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            IconPicker.iconDataFromName(category.iconName),
            color: color,
            size: 20,
          ),
        ),
        title: Text(category.name),
        subtitle: category.isArchived ? const Text('Archived') : null,
        trailing: showReorderHandle
            ? const Icon(Icons.drag_handle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onArchive != null)
                    IconButton(
                      icon: Icon(
                        category.isArchived
                            ? Icons.unarchive
                            : Icons.archive,
                      ),
                      onPressed: onArchive,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }

}
