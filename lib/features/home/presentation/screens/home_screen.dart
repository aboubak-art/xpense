import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:xpense/core/haptics/haptic_service.dart';
import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/core/providers/onboarding_provider.dart';
import 'package:xpense/domain/entities/category.dart';
import 'package:xpense/domain/entities/expense.dart';
import 'package:xpense/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:xpense/features/expenses/presentation/widgets/empty_expense_state.dart';
import 'package:xpense/features/expenses/presentation/widgets/expense_card.dart';
import 'package:xpense/features/budgets/presentation/providers/budget_provider.dart';
import 'package:xpense/features/budgets/presentation/widgets/budget_summary_bar.dart';
import 'package:xpense/features/expenses/presentation/widgets/expense_filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseListProvider.notifier).refresh();
      ref.read(budgetListNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_isSelecting) {
        _isSelecting = true;
        _selectedIds.add(id);
      } else if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  Future<void> _confirmBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expenses'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} expenses?',
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
      unawaited(HapticService.warning());
      final dao = ref.read(expenseDaoProvider);
      for (final id in _selectedIds) {
        await dao.deleteExpense(id);
      }
      _exitSelectionMode();
      await ref.read(expenseListProvider.notifier).refresh();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    unawaited(HapticService.warning());
    final dao = ref.read(expenseDaoProvider);
    await dao.deleteExpense(expense.id);
    await ref.read(expenseListProvider.notifier).refresh();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Recreate the expense since soft delete keeps the record
            // but we'd need to clear deleted_at. For now, re-create.
            await dao.create(
              ExpenseInput(
                amountCents: expense.amountCents,
                categoryId: expense.categoryId,
                date: expense.date,
                currency: expense.currency,
                note: expense.note,
                merchant: expense.merchant,
                paymentMethod: expense.paymentMethod,
                tags: expense.tags,
                location: expense.location,
              ),
            );
            await ref.read(expenseListProvider.notifier).refresh();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _editExpense(Expense expense) {
    context.push('/add-expense', extra: expense);
  }

  Future<void> _showFilters() async {
    final categoriesAsync = ref.read(_homeCategoriesProvider);
    final current = ref.read(expenseListProvider);

    final categories = categoriesAsync.when(
      data: (list) => list,
      loading: () => <Category>[],
      error: (_, __) => <Category>[],
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpenseFilterSheet(
        categories: categories,
        selectedCategoryId: current.filterCategoryId,
        selectedSortBy: current.sortBy,
        onApply: (categoryId, sortBy) {
          final notifier = ref.read(expenseListProvider.notifier);
          if (categoryId != current.filterCategoryId) {
            notifier.setCategoryFilter(categoryId);
          }
          if (sortBy != current.sortBy) {
            notifier.setSortBy(sortBy);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expenseListProvider);
    final categoriesAsync = ref.watch(_homeCategoriesProvider);

    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmBulkDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text('Xpense'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsMenu(context, ref),
                ),
              ],
            ),
      body: Column(
        children: [
          // Search bar
          if (!_isSelecting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(expenseListProvider.notifier)
                                .setSearch('');
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilters,
                      ),
                    ],
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(expenseListProvider.notifier).setSearch(value);
                  setState(() {});
                },
              ),
            ),

          // Budget summary
          if (!_isSelecting) const BudgetSummaryBar(),

          // Expense list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(expenseListProvider.notifier).refresh(),
              child: _buildList(listState, categoriesAsync),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/add-expense'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
    );
  }

  Widget _buildList(
    ExpenseListState listState,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    if (listState.isLoading && listState.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final expenses = listState.expenses;
    if (expenses.isEmpty) {
      return const EmptyExpenseState();
    }

    final categories = categoriesAsync.when(
      data: (list) => {for (final c in list) c.id: c},
      loading: () => <String, Category>{},
      error: (_, __) => <String, Category>{},
    );

    final grouped = _groupByDate(expenses);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          ref.read(expenseListProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: grouped.length + (listState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == grouped.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = grouped.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              ...entry.value.map(
                (e) => ExpenseCard(
                  expense: e,
                  category: categories[e.categoryId],
                  onEdit: () => _editExpense(e),
                  onDelete: () => _deleteExpense(e),
                  isSelected: _isSelecting ? _selectedIds.contains(e.id) : null,
                  onToggleSelect: () => _toggleSelection(e.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Expense>>{};

    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        label = 'This Week';
      } else if (date.isAfter(today.subtract(const Duration(days: 14)))) {
        label = 'Last Week';
      } else if (date.year == today.year && date.month == today.month) {
        label = 'This Month';
      } else if (date.year == today.year) {
        label = _monthName(date.month);
      } else {
        label = '${_monthName(date.month)} ${date.year}';
      }

      groups.putIfAbsent(label, () => []).add(expense);
    }

    final ordered = <String, List<Expense>>{};
    for (final key in _orderedKeys) {
      if (groups.containsKey(key)) {
        ordered[key] = groups[key]!;
      }
    }
    for (final key in groups.keys) {
      if (!ordered.containsKey(key)) {
        ordered[key] = groups[key]!;
      }
    }

    return ordered;
  }

  static final _orderedKeys = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Replay Onboarding'),
              subtitle: const Text('Walk through setup again'),
              onTap: () {
                Navigator.pop(context);
                ref.read(onboardingProvider.notifier).reset();
                context.go('/onboarding');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.repeat,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Recurring Expenses'),
              subtitle: const Text('Manage subscriptions and bills'),
              onTap: () {
                Navigator.pop(context);
                context.push('/recurring');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Categories'),
              subtitle: const Text('Organize your spending'),
              onTap: () {
                Navigator.pop(context);
                context.push('/categories');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Budgets'),
              subtitle: const Text('Set spending limits'),
              onTap: () {
                Navigator.pop(context);
                context.push('/budgets');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Theme'),
              subtitle: const Text('Coming soon'),
              enabled: false,
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Notifications'),
              subtitle: const Text('Coming soon'),
              enabled: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

final _homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getAll();
});
