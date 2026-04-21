import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xpense/core/providers/dao_providers.dart';
import 'package:xpense/data/datasources/expense_dao.dart';
import 'package:xpense/domain/entities/expense.dart';

/// State holder for the expense list.
class ExpenseListState {
  const ExpenseListState({
    this.expenses = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.searchQuery = '',
    this.filterCategoryId,
    this.filterPaymentMethod,
    this.startDate,
    this.endDate,
    this.sortBy = 'date',
    this.page = 0,
  });

  final List<Expense> expenses;
  final bool isLoading;
  final bool hasMore;
  final String searchQuery;
  final String? filterCategoryId;
  final String? filterPaymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final int page;

  static const _pageSize = 25;

  ExpenseListState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    bool? hasMore,
    String? searchQuery,
    String? filterCategoryId,
    String? filterPaymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    int? page,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategoryId: filterCategoryId ?? this.filterCategoryId,
      filterPaymentMethod: filterPaymentMethod ?? this.filterPaymentMethod,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }
}

class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  ExpenseListNotifier(this._dao) : super(const ExpenseListState());

  final ExpenseDao _dao;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      page: 0,
      expenses: [],
      hasMore: true,
    );
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, page: state.page + 1);
    await _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final results = await _dao.search(
        state.searchQuery,
        categoryId: state.filterCategoryId,
        paymentMethod: state.filterPaymentMethod,
        startDate: state.startDate,
        endDate: state.endDate,
        sortBy: state.sortBy,
        limit: ExpenseListState._pageSize,
        offset: state.page * ExpenseListState._pageSize,
      );

      final newExpenses = state.page == 0
          ? results
          : [...state.expenses, ...results];

      state = state.copyWith(
        expenses: newExpenses,
        isLoading: false,
        hasMore: results.length == ExpenseListState._pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query, page: 0);
    _debouncedLoad();
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(filterCategoryId: categoryId, page: 0);
    _debouncedLoad();
  }

  void setPaymentMethodFilter(String? paymentMethod) {
    state = state.copyWith(filterPaymentMethod: paymentMethod, page: 0);
    _debouncedLoad();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end, page: 0);
    _debouncedLoad();
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy, page: 0);
    _debouncedLoad();
  }

  void clearFilters() {
    state = const ExpenseListState();
    _debouncedLoad();
  }

  Future<void> _debouncedLoad() async {
    state = state.copyWith(isLoading: true, expenses: [], hasMore: true);
    await _loadPage();
  }
}

final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>(
  (ref) {
    final dao = ref.watch(expenseDaoProvider);
    return ExpenseListNotifier(dao);
  },
);
